# ==============================================================================
# R/utils.R: Hàm tiện ích cho ghi log, xử lý tên tệp và mạng với cơ chế thử lại (retry)
# DTA301 - Tác động của hạ tầng số và phổ cập internet đến việc làm tại ASEAN (2010-2025)
# ==============================================================================

source("R/config.R")

#' Tạo hoặc cấu hình cơ chế ghi log ra console và tệp pipeline.log
setup_logger <- function(module_name = "pipeline") {
  # Đảm bảo thư mục chứa log tồn tại
  log_dir <- dirname(LOG_FILE_PATH)
  if (!dir.exists(log_dir)) {
    dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
  }

  log_msg <- function(level, msg) {
    timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    formatted <- sprintf("%s [%s] [%s]: %s", timestamp, level, module_name, msg)
    
    # In ra console (stdout)
    cat(formatted, "\n", sep = "")
    flush.console()
    
    # Ghi nối vào file log với encoding UTF-8
    tryCatch({
      cat(formatted, "\n", file = LOG_FILE_PATH, append = TRUE, sep = "")
    }, error = function(e) {
      # Không ngắt chương trình nếu không ghi được log file
    })
  }

  list(
    info = function(msg) log_msg("INFO", msg),
    warn = function(msg) log_msg("WARN", msg),
    warning = function(msg) log_msg("WARN", msg),
    error = function(msg) log_msg("ERROR", msg)
  )
}

#' Chuyển mã chỉ số WDI có dấu chấm thành tên tệp an toàn
#' Ví dụ: "IT.NET.USER.ZS" -> "IT_NET_USER_ZS"
sanitize_filename <- function(code) {
  gsub("\\.", "_", code)
}

#' Truy vấn và phân tích JSON từ URL với cơ chế thử lại (exponential backoff)
fetch_json_retry <- function(url, retries = 5, backoff_factor = 1.0, timeout_sec = 25) {
  old_timeout <- getOption("timeout")
  options(timeout = timeout_sec)
  on.exit(options(timeout = old_timeout), add = TRUE)
  
  for (attempt in 1:retries) {
    res <- tryCatch({
      # Sử dụng jsonlite::fromJSON trực tiếp với URL
      data <- jsonlite::fromJSON(url, simplifyVector = FALSE)
      return(data)
    }, error = function(e) {
      if (attempt < retries) {
        sleep_time <- backoff_factor * (2 ^ (attempt - 1))
        Sys.sleep(sleep_time)
      }
      return(NULL)
    })
    if (!is.null(res)) {
      return(res)
    }
  }
  return(NULL)
}
