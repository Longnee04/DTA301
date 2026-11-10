# ==============================================================================
# DTA301: Script cài đặt các thư viện R cần thiết vào thư mục .r_lib
# ==============================================================================

lib_dir <- file.path(getwd(), ".r_lib")
dir.create(lib_dir, recursive = TRUE, showWarnings = FALSE)
.libPaths(unique(c(lib_dir, .libPaths())))

cat(">>> Thư mục thư viện R cục bộ:", lib_dir, "\n")
options(repos = c(CRAN = "https://cloud.r-project.org"))

required_pkgs <- c(
  "jsonlite",    # Gọi và xử lý API World Bank (JSON)
  "readr",       # Đọc/ghi tệp CSV tốc độ cao
  "dplyr",       # Biến đổi và xử lý dữ liệu bảng
  "tidyr",       # Xoay bảng Long <-> Wide
  "ggplot2",     # Trực quan hóa Heatmaps và chuỗi thời gian
  "scales",      # Định dạng trục biểu đồ
  "haven",       # Xuất dữ liệu Stata (.dta) kèm nhãn biến
  "writexl",     # Xuất dữ liệu sang Excel (.xlsx)
  "openxlsx"     # Tạo file Excel đa sheet chuyên nghiệp
)

cat(">>> Đang kiểm tra và cài đặt các thư viện cần thiết...\n")
installed <- installed.packages(lib.loc = lib_dir)[, "Package"]

for (pkg in required_pkgs) {
  if (!pkg %in% installed) {
    cat(sprintf("-> Đang cài đặt gói: %s ...\n", pkg))
    tryCatch({
      install.packages(pkg, lib = lib_dir, repos = "https://cloud.r-project.org", type = "binary")
    }, error = function(e) {
      cat(sprintf("! Lỗi khi cài %s: %s\n", pkg, conditionMessage(e)))
    })
  } else {
    cat(sprintf("-> %s đã được cài đặt.\n", pkg))
  }
}

cat("\n>>> Hoàn tất! Danh sách các gói đã cài đặt trong .r_lib:\n")
current_installed <- installed.packages(lib.loc = lib_dir)[, c("Package", "Version")]
print(as.data.frame(current_installed))
