# ==============================================================================
# R/clean_for_modeling.R: Làm sạch và nội suy có kiểm soát cho ước lượng kinh tế lượng
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

logger <- setup_logger("clean_for_modeling")

#' Hàm bổ trợ nội suy chuỗi thời gian tuyến tính và bfill/ffill cho một vector
impute_ts_vector <- function(v) {
  if (all(is.na(v))) return(v)
  valid_idx <- which(!is.na(v))
  if (length(valid_idx) == 1) {
    return(rep(v[valid_idx], length(v)))
  }
  stats::approx(x = valid_idx, y = v[valid_idx], xout = seq_along(v), rule = 2)$y
}

#' Tải bảng panel gốc
load_base_panel <- function() {
  if (!file.exists(ASEAN_PANEL_PATH)) {
    stop(sprintf("Base panel file not found: %s. Run previous steps first.", ASEAN_PANEL_PATH))
  }
  df <- readr::read_csv(ASEAN_PANEL_PATH, show_col_types = FALSE)
  logger$info(sprintf("Loaded base panel: %d rows x %d columns", nrow(df), ncol(df)))
  df
}

#' Thực hiện quy trình nội suy có kiểm soát và xuất báo cáo kiểm định (audit report)
clean_and_impute <- function(df) {
  logger$info("Executing controlled time-series cleaning and imputation...")
  clean_df <- df %>% arrange(iso3, year)
  num_cols <- setdiff(names(clean_df), c("country", "iso3", "year"))

  # Phân nhóm các nước tương đồng về cơ cấu kinh tế
  peer_groups <- c(
    "BRN" = "HIGH", "SGP" = "HIGH",
    "MYS" = "UPPER_MID", "THA" = "UPPER_MID",
    "IDN" = "LOWER_MID", "PHL" = "LOWER_MID", "VNM" = "LOWER_MID",
    "KHM" = "TRANSITION", "LAO" = "TRANSITION", "MMR" = "TRANSITION"
  )
  clean_df$`_peer_group` <- peer_groups[clean_df$iso3]

  audit_records <- list()

  for (col in num_cols) {
    orig_missing <- sum(is.na(clean_df[[col]]))

    # Bước 1: Nội suy tuyến tính theo từng nước và bfill/ffill
    clean_df <- clean_df %>%
      group_by(iso3) %>%
      mutate(!!col := impute_ts_vector(.data[[col]])) %>%
      ungroup()

    after_ts_missing <- sum(is.na(clean_df[[col]]))
    method_notes <- character()

    if (orig_missing > 0) {
      method_notes <- c(method_notes, "Nội suy tuyến tính chuỗi thời gian & bfill/ffill theo từng nước")
    }

    # Bước 2: Dự phòng trung vị nhóm nước tương đồng nếu cả chuỗi của nước đó bị khuyết hoàn toàn
    if (after_ts_missing > 0) {
      missing_countries <- unique(clean_df$iso3[is.na(clean_df[[col]])])

      # Trung vị theo nhóm nước và năm
      clean_df <- clean_df %>%
        group_by(`_peer_group`, year) %>%
        mutate(!!col := ifelse(is.na(.data[[col]]), median(.data[[col]], na.rm = TRUE), .data[[col]])) %>%
        ungroup()

      # Nếu nhóm nước trong năm đó vẫn khuyết, lấy trung vị toàn ASEAN trong năm đó
      clean_df <- clean_df %>%
        group_by(year) %>%
        mutate(!!col := ifelse(is.na(.data[[col]]), median(.data[[col]], na.rm = TRUE), .data[[col]])) %>%
        ungroup()

      final_missing <- sum(is.na(clean_df[[col]]))
      method_notes <- c(
        method_notes,
        sprintf("Nội suy trung vị nhóm nước tương đồng (%s)", paste(missing_countries, collapse = ", "))
      )
    } else {
      final_missing <- after_ts_missing
    }

    wdi_code <- if (!is.null(SHORT_TO_WDI[[col]])) SHORT_TO_WDI[[col]] else ""
    grp_vi <- if (!is.null(ALL_INDICATORS[[wdi_code]]$group_name_vi)) ALL_INDICATORS[[wdi_code]]$group_name_vi else ""

    audit_records[[length(audit_records) + 1]] <- data.frame(
      column_name = col,
      wdi_code = wdi_code,
      variable_group = grp_vi,
      missing_before = orig_missing,
      missing_after = final_missing,
      clean_completeness_pct = round(100.0 * (nrow(clean_df) - final_missing) / nrow(clean_df), 2),
      cleaning_method = if (length(method_notes) > 0) paste(method_notes, collapse = " | ") else "Dữ liệu gốc hoàn thiện 100% (không cần điền)",
      stringsAsFactors = FALSE
    )
  }

  clean_df$`_peer_group` <- NULL
  audit_df <- bind_rows(audit_records)

  if (!dir.exists(OUTPUTS_TABLES_DIR)) {
    dir.create(OUTPUTS_TABLES_DIR, recursive = TRUE, showWarnings = FALSE)
  }
  readr::write_csv(audit_df, CLEANING_AUDIT_PATH)
  logger$info(sprintf("Saved cleaning audit report to: %s", CLEANING_AUDIT_PATH))

  list(clean_df = clean_df, audit_df = audit_df)
}

#' Tạo các biến phái sinh kinh tế lượng trên bộ số liệu liên tục đã làm sạch
engineer_model_features <- function(df) {
  logger$info("Computing derived econometric variables on clean panel...")
  model_df <- df %>% arrange(iso3, year)

  # 1. Log transformations
  model_df$ln_gdp_pc <- log(model_df$gdp_pc_ppp)
  model_df$ln_pop <- log(model_df$pop_total)

  # 2. L1 & L2 Lags cho các biến hạ tầng số
  model_df <- model_df %>% group_by(iso3)
  for (var in DIGITAL_INFRA_VARS) {
    lag1_col <- paste0("lag1_", var)
    lag2_col <- paste0("lag2_", var)
    model_df <- model_df %>%
      mutate(
        !!lag1_col := dplyr::lag(.data[[var]], 1),
        !!lag2_col := dplyr::lag(.data[[var]], 2)
      )
  }

  # 3. Sai phân hàng năm
  model_df <- model_df %>%
    mutate(
      diff_internet_users = internet_users - dplyr::lag(internet_users, 1),
      diff_unemp_total = unemp_total - dplyr::lag(unemp_total, 1)
    ) %>%
    ungroup()

  # 4. Khoảng cách giới
  model_df$gap_unemp_gender <- model_df$unemp_female - model_df$unemp_male
  model_df$gap_emp_gender <- model_df$emp_rate_female - model_df$emp_rate_male

  # 5. Xử lý ngoại lai Winsorization (1% - 99%)
  for (v in c("secure_servers", "trade_openness")) {
    q_vals <- stats::quantile(model_df[[v]], probs = c(0.01, 0.99), na.rm = TRUE)
    win_col <- paste0(v, "_win")
    model_df[[win_col]] <- pmin(pmax(model_df[[v]], q_vals[1]), q_vals[2])
  }

  # 6. Biến giả chính sách và cấu trúc
  model_df <- model_df %>%
    mutate(
      covid = as.integer(year %in% c(2020, 2021)),
      myanmar_post2021 = as.integer(iso3 == "MMR" & year >= 2021),
      high_income = as.integer(iso3 %in% c("SGP", "BRN"))
    )

  logger$info(sprintf("Model-ready clean dataset shape: %d rows x %d columns", nrow(model_df), ncol(model_df)))
  model_df
}

#' Xuất dữ liệu sạch mô hình hóa ra CSV và Stata .dta kèm nhãn biến
export_clean_data <- function(model_df) {
  # CSV Export
  readr::write_csv(model_df, ASEAN_PANEL_CLEAN_PATH)
  logger$info(sprintf("Saved Clean Model-Ready Panel CSV: %s", ASEAN_PANEL_CLEAN_PATH))

  # Stata Export
  stata_df <- model_df
  stata_df$country <- as.character(stata_df$country)
  stata_df$iso3 <- as.character(stata_df$iso3)
  stata_df$year <- as.integer(stata_df$year)

  for (col in names(stata_df)) {
    if (!is.null(STATA_VARIABLE_LABELS[[col]])) {
      lbl <- STATA_VARIABLE_LABELS[[col]]
    } else if (grepl("_win$", col)) {
      base_var <- gsub("_win$", "", col)
      lbl <- paste0(base_var, " (Winsorized 1-99%)")
    } else {
      lbl <- col
    }
    attr(stata_df[[col]], "label") <- substr(as.character(lbl), 1, 80)
  }

  tryCatch({
    haven::write_dta(stata_df, ASEAN_PANEL_CLEAN_DTA_PATH, version = 14)
    logger$info(sprintf("Saved Clean Model-Ready Stata Dataset: %s", ASEAN_PANEL_CLEAN_DTA_PATH))
  }, error = function(e) {
    logger$error(sprintf("Failed to export clean Stata dataset: %s", e$message))
  })

  list(
    clean_csv = ASEAN_PANEL_CLEAN_PATH,
    clean_dta = ASEAN_PANEL_CLEAN_DTA_PATH
  )
}

run_cleaning_pipeline <- function() {
  base_df <- load_base_panel()
  res <- clean_and_impute(base_df)
  model_df <- engineer_model_features(res$clean_df)
  export_clean_data(model_df)
  list(model_df = model_df, audit_df = res$audit_df)
}

if (sys.nframe() == 0L) {
  run_cleaning_pipeline()
}
