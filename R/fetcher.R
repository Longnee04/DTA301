# ==============================================================================
# R/fetcher.R: Thu thập dữ liệu từ World Bank World Development Indicators (WDI) API v2
# DTA301 - Tác động của hạ tầng số và phổ cập internet đến việc làm tại ASEAN (2010-2025)
# ==============================================================================

source("R/config.R")
source("R/utils.R")

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(jsonlite)
})

logger <- setup_logger("fetcher")

BASE_API_URL <- "http://api.worldbank.org/v2"

#' Kiểm tra khả năng kết nối tới máy chủ World Bank API
check_api_connectivity <- function(timeout_sec = 3) {
  test_url <- sprintf("%s/indicator/IT.NET.USER.ZS?format=json", BASE_API_URL)
  old_timeout <- getOption("timeout")
  options(timeout = timeout_sec)
  on.exit(options(timeout = old_timeout), add = TRUE)

  is_connected <- tryCatch({
    con <- url(test_url, open = "rb")
    close(con)
    TRUE
  }, error = function(e) {
    FALSE
  })
  is_connected
}

#' Lấy thông tin metadata chính thức của chỉ số từ API World Bank
fetch_indicator_metadata <- function(indicator_code, is_online = TRUE) {
  config_info <- ALL_INDICATORS[[indicator_code]]
  if (is.null(config_info)) config_info <- list()

  meta <- list(
    indicator_code = indicator_code,
    indicator_name = if (!is.null(config_info$name_vi)) config_info$name_vi else indicator_code,
    indicator_name_en = if (!is.null(config_info$name_en)) config_info$name_en else "",
    short_name = if (!is.null(config_info$short_name)) config_info$short_name else "",
    group_vi = if (!is.null(config_info$group_name_vi)) config_info$group_name_vi else "",
    group_en = if (!is.null(config_info$group_name_en)) config_info$group_name_en else "",
    unit = if (!is.null(config_info$unit)) config_info$unit else "",
    source = "World Development Indicators (World Bank)",
    source_organization = "World Bank",
    source_note = if (!is.null(config_info$notes)) config_info$notes else "",
    download_date = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )

  if (is_online) {
    url <- sprintf("%s/indicator/%s?format=json", BASE_API_URL, indicator_code)
    data <- fetch_json_retry(url, retries = 2, timeout_sec = 8)
    if (!is.null(data) && is.list(data) && length(data) > 1 && length(data[[2]]) > 0) {
      info <- data[[2]][[1]]
      if (!is.null(info$name) && nzchar(info$name)) {
        meta$indicator_name_en <- info$name
      }
      if (!is.null(info$unit) && nzchar(info$unit)) {
        meta$unit <- info$unit
      }
      if (!is.null(info$sourceOrganization) && nzchar(info$sourceOrganization)) {
        meta$source_organization <- info$sourceOrganization
      }
      if (!is.null(info$sourceNote) && nzchar(info$sourceNote)) {
        extra_note <- if (!is.null(config_info$notes)) sprintf(" | Ghi chú thêm: %s", config_info$notes) else ""
        meta$source_note <- paste0(info$sourceNote, extra_note)
      }
    }
  }

  as.data.frame(meta, stringsAsFactors = FALSE)
}

#' Thu thập chuỗi thời gian của một chỉ số cho 10 quốc gia ASEAN và giai đoạn xác định
fetch_indicator_data <- function(indicator_code, iso3_list = ISO3_LIST, start_year = START_YEAR, end_year = END_YEAR, is_online = TRUE) {
  short_name <- if (!is.null(ALL_INDICATORS[[indicator_code]]$short_name)) ALL_INDICATORS[[indicator_code]]$short_name else ""
  safe_name <- sanitize_filename(indicator_code)
  raw_path <- file.path(DATA_RAW_DIR, paste0(safe_name, ".csv"))

  # Nếu không có mạng hoặc API offline, đọc thẳng tệp thô cục bộ nếu có
  if (!is_online) {
    if (file.exists(raw_path)) {
      df_cached <- tryCatch(readr::read_csv(raw_path, show_col_types = FALSE), error = function(e) NULL)
      if (!is.null(df_cached)) {
        logger$info(sprintf("Loaded cached raw data [%s] (%s): %d rows", indicator_code, short_name, nrow(df_cached)))
        return(df_cached)
      }
    }
    logger$warn(sprintf("No local cached data for indicator '%s'.", indicator_code))
    return(NULL)
  }

  countries_param <- paste(iso3_list, collapse = ";")
  url <- sprintf(
    "%s/country/%s/indicator/%s?date=%d:%d&format=json&per_page=1500",
    BASE_API_URL, countries_param, indicator_code, start_year, end_year
  )

  logger$info(sprintf("Downloading [%s] (%s)...", indicator_code, short_name))

  data <- fetch_json_retry(url, retries = 3, timeout_sec = 15)
  
  if (is.null(data) || !is.list(data) || length(data) < 2) {
    if (file.exists(raw_path)) {
      logger$warn(sprintf("API response empty for '%s'. Falling back to local cached raw data.", indicator_code))
      df_cached <- tryCatch(readr::read_csv(raw_path, show_col_types = FALSE), error = function(e) NULL)
      return(df_cached)
    }
    logger$warn(sprintf("No records retrieved or invalid API response for indicator '%s'.", indicator_code))
    return(NULL)
  }

  records <- data[[2]]
  if (length(records) == 0) {
    logger$warn(sprintf("Empty data list returned for indicator '%s'.", indicator_code))
    return(NULL)
  }

  rows <- lapply(records, function(rec) {
    c_iso3 <- rec$countryiso3code
    if (is.null(c_iso3) || !nzchar(c_iso3)) {
      if (!is.null(rec$country) && !is.null(rec$country$id)) {
        c_iso3 <- rec$country$id
      } else {
        c_iso3 <- NA_character_
      }
    }

    c_name <- if (!is.null(rec$country$value)) rec$country$value else ""
    yr <- suppressWarnings(as.integer(rec$date))
    val <- if (!is.null(rec$value)) suppressWarnings(as.numeric(rec$value)) else NA_real_

    data.frame(
      indicator_code = indicator_code,
      indicator_name = if (!is.null(rec$indicator$value)) rec$indicator$value else indicator_code,
      iso3 = as.character(c_iso3),
      country = as.character(c_name),
      year = yr,
      value = val,
      stringsAsFactors = FALSE
    )
  })

  df <- do.call(rbind, rows)
  
  df <- df %>%
    filter(iso3 %in% iso3_list, year >= start_year, year <= end_year) %>%
    arrange(iso3, year)

  non_null_count <- sum(!is.na(df$value))
  logger$info(sprintf("Successfully retrieved [%s]: %d rows, non-null: %d/%d", 
                      indicator_code, nrow(df), non_null_count, nrow(df)))
  df
}

#' Thực thi toàn bộ quy trình thu thập dữ liệu World Bank
fetch_all <- function(indicators = ALL_INDICATORS, iso3_list = ISO3_LIST, start_year = START_YEAR, end_year = END_YEAR) {
  if (!dir.exists(DATA_RAW_DIR)) {
    dir.create(DATA_RAW_DIR, recursive = TRUE, showWarnings = FALSE)
  }

  # Kiểm tra kết nối mạng trước khi gửi 36 yêu cầu
  is_online <- check_api_connectivity(timeout_sec = 3)
  if (is_online) {
    logger$info("World Bank API is online and reachable.")
  } else {
    logger$warn("World Bank API is unreachable (offline or sandboxed). Will prioritize local cached raw files.")
  }

  logger$info(sprintf(
    "=== Starting World Bank Ingestion: %d indicators, %d countries (%d-%d) ===",
    length(indicators), length(iso3_list), start_year, end_year
  ))

  raw_data_map <- list()
  metadata_list <- list()

  for (code in names(indicators)) {
    # 1. Fetch metadata
    meta <- fetch_indicator_metadata(code, is_online = is_online)
    metadata_list[[code]] <- meta

    # 2. Fetch raw indicator data
    df_ind <- fetch_indicator_data(code, iso3_list, start_year, end_year, is_online = is_online)
    if (!is.null(df_ind) && nrow(df_ind) > 0) {
      raw_data_map[[code]] <- df_ind
      if (is_online) {
        safe_name <- sanitize_filename(code)
        raw_csv_path <- file.path(DATA_RAW_DIR, paste0(safe_name, ".csv"))
        readr::write_csv(df_ind, raw_csv_path)
      }
    } else {
      logger$warn(sprintf("Indicator '%s' has no records. Raw CSV not written.", code))
    }
  }

  # 3. Save metadata.csv
  df_meta <- bind_rows(metadata_list)
  if (is_online || !file.exists(METADATA_PATH)) {
    readr::write_csv(df_meta, METADATA_PATH)
  }
  logger$info(sprintf("Saved metadata catalog to: %s (%d indicators)", METADATA_PATH, nrow(df_meta)))

  logger$info(sprintf(
    "=== Ingestion Complete: %d/%d indicators retrieved ===",
    length(raw_data_map), length(indicators)
  ))

  list(raw_data_map = raw_data_map, metadata = df_meta)
}

if (sys.nframe() == 0L) {
  fetch_all()
}
