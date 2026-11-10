# ==============================================================================
# R/export_clean_excel.R: Xuất dữ liệu sạch mô hình hóa ra bảng tính Excel (.xlsx) định dạng cao cấp
# DTA301 - Tác động của hạ tầng số và phổ cập internet đến việc làm tại ASEAN (2010-2025)
# ==============================================================================

source("R/config.R")
source("R/utils.R")

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(openxlsx)
})

logger <- setup_logger("export_clean_excel")

OUT_EXCEL_CLEAN <- file.path(DATA_PROCESSED_DIR, "asean_panel_clean.xlsx")
OUT_EXCEL_CLEAN_OUTPUTS <- file.path(OUTPUTS_DIR, "asean_panel_clean.xlsx")

create_clean_excel <- function() {
  logger$info("Loading clean datasets to compile formatted Clean Excel workbook...")

  # 1. Panel Clean Model
  df_clean <- if (file.exists(ASEAN_PANEL_CLEAN_PATH)) {
    readr::read_csv(ASEAN_PANEL_CLEAN_PATH, show_col_types = FALSE)
  } else data.frame()

  # 2. Audit Report
  df_audit <- if (file.exists(CLEANING_AUDIT_PATH)) {
    readr::read_csv(CLEANING_AUDIT_PATH, show_col_types = FALSE)
  } else data.frame()

  # 3. Summary Statistics
  summary_path <- file.path(OUTPUTS_TABLES_DIR, "summary_stats_overall.csv")
  df_summary <- if (file.exists(summary_path)) {
    readr::read_csv(summary_path, show_col_types = FALSE)
  } else data.frame()

  # 4. Data Dictionary
  dict_path <- DATA_DICTIONARY_PATH
  df_dict <- if (file.exists(dict_path)) {
    readr::read_csv(dict_path, show_col_types = FALSE)
  } else data.frame()

  # 5. Readme Overview Table
  df_readme <- data.frame(
    "Thông tin" = c(
      "Tên bộ dữ liệu",
      "Mục đích sử dụng",
      "Phạm vi thời gian",
      "Tỷ lệ quan sát đầy đủ",
      "Số lượng biến",
      "Phương pháp xử lý khuyết",
      "Phương pháp xử lý ngoại lai",
      "Sheet: Panel_Clean_Model",
      "Sheet: Cleaning_Audit",
      "Sheet: Summary_Statistics",
      "Sheet: Data_Dictionary"
    ),
    "Nội dung" = c(
      "DTA301 - ASEAN Panel Data (Clean & Model-Ready)",
      "Sử dụng trực tiếp để chạy mô hình hồi quy (OLS, Fixed Effects, Random Effects, GMM)",
      "2010 - 2025 (16 năm liên tục)",
      "100% Complete Cases (160/160 quan sát - 10 nước x 16 năm)",
      "60 biến (gồm 36 biến gốc sau xử lý + biến trễ L1/L2 + logarit + sai phân + biến giả)",
      "Nội suy chuỗi thời gian nội bộ từng nước (Linear Interpolation) + Trung vị nhóm nước",
      "Winsorization 1% - 99% đối với biến phân phối lệch (secure_servers, trade_openness)",
      "Toàn bộ bảng dữ liệu sạch 160 dòng x 60 cột, 100% hoàn chỉnh không còn giá trị rỗng",
      "Báo cáo đối chiếu Before vs After (số lượng giá trị NA trước và sau khi xử lý)",
      "Bảng thống kê mô tả tổng thể (Mean, Std, Min, Max, P25, Median, P75, Skewness)",
      "Từ điển 60 biến số kinh tế lượng với giải thích chi tiết tiếng Việt và nhãn Stata"
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  sheets <- list(
    "Readme_Overview" = df_readme,
    "Panel_Clean_Model" = df_clean,
    "Cleaning_Audit" = df_audit,
    "Summary_Statistics" = df_summary,
    "Data_Dictionary" = df_dict
  )

  logger$info("Writing formatted Clean Excel workbook with openxlsx...")
  wb <- openxlsx::createWorkbook()

  header_style <- openxlsx::createStyle(
    fontName = "Segoe UI",
    fontSize = 11,
    fontColour = "#FFFFFF",
    textDecoration = "bold",
    fgFill = "#1F4E79",
    halign = "center",
    valign = "center",
    wrapText = TRUE,
    border = "TopBottomLeftRight",
    borderColour = "#1B365D"
  )

  regular_style <- openxlsx::createStyle(
    fontName = "Segoe UI",
    fontSize = 10,
    valign = "center",
    border = "TopBottomLeftRight",
    borderColour = "#D9D9D9"
  )

  num_dec_style <- openxlsx::createStyle(
    fontName = "Segoe UI",
    fontSize = 10,
    valign = "center",
    halign = "right",
    numFmt = "#,##0.0000",
    border = "TopBottomLeftRight",
    borderColour = "#D9D9D9"
  )

  for (s_name in names(sheets)) {
    data_tab <- sheets[[s_name]]
    if (nrow(data_tab) == 0 && ncol(data_tab) == 0) next

    openxlsx::addWorksheet(wb, s_name, gridLines = TRUE)
    openxlsx::writeData(wb, s_name, data_tab, startRow = 1, startCol = 1, headerStyle = header_style)
    openxlsx::setRowHeights(wb, s_name, rows = 1, heights = 28)

    if (nrow(data_tab) > 0) {
      openxlsx::setRowHeights(wb, s_name, rows = 2:(nrow(data_tab) + 1), heights = 20)
      openxlsx::addStyle(wb, s_name, style = regular_style, rows = 2:(nrow(data_tab) + 1), cols = 1:ncol(data_tab), gridExpand = TRUE)

      for (c_idx in 1:ncol(data_tab)) {
        if (is.numeric(data_tab[[c_idx]])) {
          openxlsx::addStyle(wb, s_name, style = num_dec_style, rows = 2:(nrow(data_tab) + 1), cols = c_idx, gridExpand = TRUE)
        }
      }
    }

    if (s_name == "Panel_Clean_Model") {
      openxlsx::freezePane(wb, s_name, firstActiveRow = 2, firstActiveCol = 4)
    } else {
      openxlsx::freezePane(wb, s_name, firstActiveRow = 2)
    }

    openxlsx::setColWidths(wb, s_name, cols = 1:ncol(data_tab), widths = "auto")
  }

  if (!dir.exists(dirname(OUT_EXCEL_CLEAN))) dir.create(dirname(OUT_EXCEL_CLEAN), recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(dirname(OUT_EXCEL_CLEAN_OUTPUTS))) dir.create(dirname(OUT_EXCEL_CLEAN_OUTPUTS), recursive = TRUE, showWarnings = FALSE)

  openxlsx::saveWorkbook(wb, OUT_EXCEL_CLEAN, overwrite = TRUE)
  logger$info(sprintf("Saved clean Excel workbook to: %s", OUT_EXCEL_CLEAN))

  openxlsx::saveWorkbook(wb, OUT_EXCEL_CLEAN_OUTPUTS, overwrite = TRUE)
  logger$info(sprintf("Saved copy to: %s", OUT_EXCEL_CLEAN_OUTPUTS))

  invisible(OUT_EXCEL_CLEAN)
}

if (sys.nframe() == 0L) {
  create_clean_excel()
}
