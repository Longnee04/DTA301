# ==============================================================================
# R/feature_engineering.R: Tạo lập các biến phái sinh kinh tế lượng
# DTA301 - Tác động của hạ tầng số và phổ cập internet đến việc làm tại ASEAN (2010-2025)
# ==============================================================================

source("R/config.R")
source("R/utils.R")

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(haven)
})

logger <- setup_logger("feature_engineering")

#' Tính toán các biến phái sinh phục vụ mô hình kinh tế lượng
compute_derived_features <- function(df) {
  logger$info("Computing derived econometric features...")
  derived <- df %>%
    arrange(iso3, year)

  # 1. Log transformations
  if ("gdp_pc_ppp" %in% names(derived)) {
    derived <- derived %>%
      mutate(ln_gdp_pc = ifelse(!is.na(gdp_pc_ppp) & gdp_pc_ppp > 0, log(gdp_pc_ppp), NA_real_))
  } else {
    logger$warn("gdp_pc_ppp not found, ln_gdp_pc set to NA")
    derived$ln_gdp_pc <- NA_real_
  }

  if ("pop_total" %in% names(derived)) {
    derived <- derived %>%
      mutate(ln_pop = ifelse(!is.na(pop_total) & pop_total > 0, log(pop_total), NA_real_))
  } else {
    logger$warn("pop_total not found, ln_pop set to NA")
    derived$ln_pop <- NA_real_
  }

  # 2. L1 và L2 lags cho các biến hạ tầng số theo từng quốc gia
  derived <- derived %>% group_by(iso3)
  for (var in DIGITAL_INFRA_VARS) {
    lag1_col <- paste0("lag1_", var)
    lag2_col <- paste0("lag2_", var)
    if (var %in% names(derived)) {
      derived <- derived %>%
        mutate(
          !!lag1_col := dplyr::lag(.data[[var]], 1),
          !!lag2_col := dplyr::lag(.data[[var]], 2)
        )
    } else {
      logger$warn(sprintf("Digital infra variable '%s' not in panel; lags set to NA", var))
      derived[[lag1_col]] <- NA_real_
      derived[[lag2_col]] <- NA_real_
    }
  }

  # 3. Sai phân hàng năm (diff = Y_t - Y_{t-1})
  if ("internet_users" %in% names(derived)) {
    derived <- derived %>%
      mutate(diff_internet_users = internet_users - dplyr::lag(internet_users, 1))
  } else {
    derived$diff_internet_users <- NA_real_
  }

  if ("unemp_total" %in% names(derived)) {
    derived <- derived %>%
      mutate(diff_unemp_total = unemp_total - dplyr::lag(unemp_total, 1))
  } else {
    derived$diff_unemp_total <- NA_real_
  }
  derived <- derived %>% ungroup()

  # 4. Khoảng cách giới (Nữ - Nam)
  if ("unemp_female" %in% names(derived) && "unemp_male" %in% names(derived)) {
    derived$gap_unemp_gender <- derived$unemp_female - derived$unemp_male
  } else {
    derived$gap_unemp_gender <- NA_real_
  }

  if ("emp_rate_female" %in% names(derived) && "emp_rate_male" %in% names(derived)) {
    derived$gap_emp_gender <- derived$emp_rate_female - derived$emp_rate_male
  } else {
    derived$gap_emp_gender <- NA_real_
  }

  # 5. Các biến giả chính sách và cấu trúc
  derived <- derived %>%
    mutate(
      covid = as.integer(year %in% c(2020, 2021)),
      myanmar_post2021 = as.integer(iso3 == "MMR" & year >= 2021),
      high_income = as.integer(iso3 %in% c("SGP", "BRN"))
    )

  logger$info(sprintf("Derived panel successfully generated. Shape: %d rows x %d columns", nrow(derived), ncol(derived)))
  derived
}

#' Xuất tệp panel phái sinh ra định dạng CSV và Stata .dta
export_derived <- function(derived_df) {
  # CSV Export
  readr::write_csv(derived_df, ASEAN_PANEL_DERIVED_PATH)
  logger$info(sprintf("Saved Derived Panel CSV to: %s", ASEAN_PANEL_DERIVED_PATH))

  # Stata Export
  stata_df <- derived_df
  stata_df$country <- as.character(stata_df$country)
  stata_df$iso3 <- as.character(stata_df$iso3)
  stata_df$year <- as.integer(stata_df$year)

  for (col_name in names(stata_df)) {
    lbl <- if (!is.null(STATA_VARIABLE_LABELS[[col_name]])) STATA_VARIABLE_LABELS[[col_name]] else col_name
    attr(stata_df[[col_name]], "label") <- substr(as.character(lbl), 1, 80)
  }

  tryCatch({
    haven::write_dta(stata_df, ASEAN_PANEL_DERIVED_DTA_PATH, version = 14)
    logger$info(sprintf("Saved Derived Stata dataset to: %s", ASEAN_PANEL_DERIVED_DTA_PATH))
  }, error = function(e) {
    logger$error(sprintf("Failed to export Derived Stata .dta: %s", e$message))
  })

  ASEAN_PANEL_DERIVED_PATH
}

if (sys.nframe() == 0L) {
  df <- readr::read_csv(ASEAN_PANEL_PATH, show_col_types = FALSE)
  derived <- compute_derived_features(df)
  export_derived(derived)
}
