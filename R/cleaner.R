# ==============================================================================
# R/cleaner.R: Hợp nhất và làm sạch dữ liệu thô thành bảng cân đối (Balanced Panel)
# DTA301 - Tác động của hạ tầng số và phổ cập internet đến việc làm tại ASEAN (2010-2025)
# ==============================================================================

source("R/config.R")
source("R/utils.R")

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(haven)
})

logger <- setup_logger("cleaner")

#' Tạo khung nền cân đối (Balanced Panel Scaffold): 10 nước x 16 năm = 160 dòng
build_panel_scaffold <- function() {
  scaffold_list <- list()
  for (iso3 in ISO3_LIST) {
    c_name <- ASEAN_COUNTRIES[[iso3]]$name_en
    for (yr in YEARS) {
      scaffold_list[[length(scaffold_list) + 1]] <- data.frame(
        country = c_name,
        iso3 = iso3,
        year = as.integer(yr),
        stringsAsFactors = FALSE
      )
    }
  }
  scaffold <- bind_rows(scaffold_list) %>%
    arrange(iso3, year)
  scaffold
}

#' Đọc dữ liệu chỉ số thô từ data/raw/{safe_code}.csv
load_raw_indicator <- function(code) {
  safe_name <- sanitize_filename(code)
  raw_path <- file.path(DATA_RAW_DIR, paste0(safe_name, ".csv"))
  if (!file.exists(raw_path)) {
    logger$warn(sprintf("Raw file not found: %s", raw_path))
    return(NULL)
  }
  tryCatch({
    df <- readr::read_csv(raw_path, show_col_types = FALSE)
    df
  }, error = function(e) {
    logger$warn(sprintf("Error reading raw CSV %s: %s", raw_path, e$message))
    NULL
  })
}

#' Ghép nối tất cả chỉ số vào một bảng Long Panel cân đối duy nhất (bảo toàn giá trị khuyết NA)
assemble_panel <- function(raw_data_map = NULL) {
  logger$info("Assembling balanced ASEAN panel (10 countries x 16 years)...")
  panel <- build_panel_scaffold()

  for (code in names(ALL_INDICATORS)) {
    info <- ALL_INDICATORS[[code]]
    s_name <- info$short_name

    df_ind <- if (!is.null(raw_data_map) && !is.null(raw_data_map[[code]])) {
      raw_data_map[[code]]
    } else {
      load_raw_indicator(code)
    }

    if (is.null(df_ind) || nrow(df_ind) == 0) {
      logger$warn(sprintf("Indicator '%s' (%s) is missing. Creating empty NA column.", code, s_name))
      panel[[s_name]] <- NA_real_
      next
    }

    subset <- df_ind %>%
      select(iso3, year, value) %>%
      rename(!!s_name := value) %>%
      mutate(
        year = as.integer(year),
        !!s_name := as.numeric(.data[[s_name]])
      ) %>%
      distinct(iso3, year, .keep_all = TRUE)

    panel <- left_join(panel, subset, by = c("iso3", "year"))
  }

  panel <- panel %>% arrange(iso3, year)
  logger$info(sprintf("Assembled panel shape: %d rows x %d columns (160 rows expected)", nrow(panel), ncol(panel)))
  panel
}

#' Chuyển đổi bảng Panel dạng Long sang Wide (1 hàng/quốc gia, các cột theo từng năm)
create_wide_panel <- function(panel_df) {
  logger$info("Creating wide-format panel (1 row per country, columns by year)...")
  value_vars <- setdiff(names(panel_df), c("country", "iso3", "year"))

  # pivot_wider sao cho tên cột có dạng {var}_{year}
  wide_df <- panel_df %>%
    pivot_wider(
      id_cols = c("iso3", "country"),
      names_from = year,
      values_from = all_of(value_vars),
      names_glue = "{.value}_{year}"
    ) %>%
    arrange(iso3)

  logger$info(sprintf("Wide panel shape: %d rows x %d columns (10 rows)", nrow(wide_df), ncol(wide_df)))
  wide_df
}

#' Xuất dữ liệu ra các định dạng: CSV Long, CSV Wide và Stata .dta kèm nhãn biến
export_all <- function(panel_df) {
  if (!dir.exists(DATA_PROCESSED_DIR)) {
    dir.create(DATA_PROCESSED_DIR, recursive = TRUE, showWarnings = FALSE)
  }

  # 1. Export long panel CSV
  readr::write_csv(panel_df, ASEAN_PANEL_PATH)
  logger$info(sprintf("Saved Long Panel CSV to: %s", ASEAN_PANEL_PATH))

  # 2. Export wide panel CSV
  wide_df <- create_wide_panel(panel_df)
  readr::write_csv(wide_df, ASEAN_PANEL_WIDE_PATH)
  logger$info(sprintf("Saved Wide Panel CSV to: %s", ASEAN_PANEL_WIDE_PATH))

  # 3. Export Stata .dta với nhãn biến (variable labels)
  stata_df <- panel_df
  stata_df$country <- as.character(stata_df$country)
  stata_df$iso3 <- as.character(stata_df$iso3)
  stata_df$year <- as.integer(stata_df$year)

  for (col_name in names(stata_df)) {
    lbl <- if (!is.null(STATA_VARIABLE_LABELS[[col_name]])) STATA_VARIABLE_LABELS[[col_name]] else col_name
    attr(stata_df[[col_name]], "label") <- substr(as.character(lbl), 1, 80)
  }

  tryCatch({
    haven::write_dta(stata_df, ASEAN_PANEL_DTA_PATH, version = 14)
    logger$info(sprintf("Saved Stata dataset to: %s", ASEAN_PANEL_DTA_PATH))
  }, error = function(e) {
    logger$error(sprintf("Failed to export Stata .dta: %s", e$message))
  })

  list(
    long_csv = ASEAN_PANEL_PATH,
    wide_csv = ASEAN_PANEL_WIDE_PATH,
    stata_dta = ASEAN_PANEL_DTA_PATH
  )
}

if (sys.nframe() == 0L) {
  panel <- assemble_panel()
  export_all(panel)
}
