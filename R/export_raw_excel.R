# ==============================================================================
# R/export_raw_excel.R: Xuất toàn bộ dữ liệu thô ra bảng tính Excel (.xlsx) định dạng cao cấp
# DTA301 - Tác động của hạ tầng số và phổ cập internet đến việc làm tại ASEAN (2010-2025)
# ==============================================================================

source("R/config.R")
source("R/utils.R")

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(openxlsx)
})

logger <- setup_logger("export_raw_excel")

create_raw_excel <- function() {
  logger$info("Loading raw datasets to compile formatted Excel workbook...")

  # 1. Base Panel Long (Raw)
  df_panel_long <- if (file.exists(ASEAN_PANEL_PATH)) {
    readr::read_csv(ASEAN_PANEL_PATH, show_col_types = FALSE)
  } else data.frame()

  # 2. Base Panel Wide (Raw)
  df_panel_wide <- if (file.exists(ASEAN_PANEL_WIDE_PATH)) {
    readr::read_csv(ASEAN_PANEL_WIDE_PATH, show_col_types = FALSE)
  } else data.frame()

  # 3. Metadata Catalog
  df_metadata <- if (file.exists(METADATA_PATH)) {
    readr::read_csv(METADATA_PATH, show_col_types = FALSE)
  } else data.frame()

  # 4. Data Dictionary (chỉ lấy các biến thô)
  dict_path <- DATA_DICTIONARY_PATH
  df_dict <- if (file.exists(dict_path)) {
    readr::read_csv(dict_path, show_col_types = FALSE)
  } else data.frame()

  df_dict_raw <- if ("is_derived" %in% names(df_dict)) {
    df_dict %>% filter(is_derived == FALSE)
  } else df_dict

  # 5. Tất cả bản ghi thô ghép nối trực tiếp từ các file API trong data/raw/*.csv
  raw_files <- list.files(DATA_RAW_DIR, pattern = "\\.csv$", full.names = TRUE)
  raw_dfs <- list()
  for (f in raw_files) {
    if (basename(f) %in% c("metadata.csv", "data_dictionary.csv")) next
    tmp <- tryCatch(readr::read_csv(f, show_col_types = FALSE), error = function(e) NULL)
    if (!is.null(tmp) && all(c("indicator_code", "iso3", "year", "value") %in% names(tmp))) {
      raw_dfs[[length(raw_dfs) + 1]] <- tmp
    }
  }

  df_all_indicators <- if (length(raw_dfs) > 0) {
    bind_rows(raw_dfs) %>% arrange(indicator_code, iso3, year)
  } else data.frame()

  # 6. Readme Overview Table
  df_readme <- data.frame(
    "Thông tin" = c(
      "Tên dự án",
      "Nội dung tệp",
      "Phạm vi không gian",
      "Phạm vi thời gian",
      "Số lượng quan sát",
      "Số lượng chỉ số thô",
      "Sheet: Panel_Raw_Long",
      "Sheet: Panel_Raw_Wide",
      "Sheet: All_Indicators_Long",
      "Sheet: Metadata_Catalog",
      "Sheet: Data_Dictionary_Raw",
      "Sheet: Countries"
    ),
    "Nội dung" = c(
      "DTA301 - ASEAN Digital Infrastructure & Employment",
      "Dữ liệu thô (Raw Data) từ World Bank World Development Indicators (WDI)",
      "10 quốc gia ASEAN (BRN, KHM, IDN, LAO, MYS, MMR, PHL, SGP, THA, VNM)",
      "2010 - 2025 (16 năm)",
      "160 quan sát cấp quốc gia - năm (Balanced Panel scaffold)",
      "36 chỉ số chính thức từ WDI (chưa qua imputation hay winsorization)",
      "Bảng dữ liệu thô dạng Long Panel (160 dòng x 39 cột: country, iso3, year + 36 chỉ số)",
      "Bảng dữ liệu thô dạng Wide (10 dòng cho 10 quốc gia x 578 cột biến theo từng năm)",
      "Tất cả các bản ghi thô ghép nối trực tiếp từ các file API (gồm mã chỉ số, tên, giá trị)",
      "Danh mục chi tiết 36 chỉ số: mã WDI, tên tiếng Việt/Anh, đơn vị, tổ chức nguồn, ghi chú",
      "Từ điển dữ liệu cho các biến số thô (mô tả, nhóm chỉ số, đơn vị, nhãn Stata)",
      "Danh sách 10 quốc gia ASEAN và mã ISO3 tương ứng"
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  # 7. Countries
  df_countries <- data.frame(
    iso3 = c("BRN", "KHM", "IDN", "LAO", "MYS", "MMR", "PHL", "SGP", "THA", "VNM"),
    country_en = c("Brunei Darussalam", "Cambodia", "Indonesia", "Lao PDR", "Malaysia", "Myanmar", "Philippines", "Singapore", "Thailand", "Viet Nam"),
    country_vi = c("Brunei", "Campuchia", "Indonesia", "Lào", "Malaysia", "Myanmar", "Philippines", "Singapore", "Thái Lan", "Việt Nam"),
    stringsAsFactors = FALSE
  )

  sheets <- list(
    "Readme_Overview" = df_readme,
    "Panel_Raw_Long" = df_panel_long,
    "Panel_Raw_Wide" = df_panel_wide,
    "All_Indicators_Long" = df_all_indicators,
    "Metadata_Catalog" = df_metadata,
    "Data_Dictionary_Raw" = df_dict_raw,
    "Countries" = df_countries
  )

  logger$info("Writing formatted multi-sheet Excel workbook with openxlsx...")
  wb <- openxlsx::createWorkbook()

  # Styles
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

      # Định dạng số cho các cột số thực
      for (c_idx in 1:ncol(data_tab)) {
        if (is.numeric(data_tab[[c_idx]])) {
          openxlsx::addStyle(wb, s_name, style = num_dec_style, rows = 2:(nrow(data_tab) + 1), cols = c_idx, gridExpand = TRUE)
        }
      }
    }

    # Freeze panes
    if (s_name == "Panel_Raw_Long") {
      openxlsx::freezePane(wb, s_name, firstActiveRow = 2, firstActiveCol = 4)
    } else if (s_name == "Panel_Raw_Wide") {
      openxlsx::freezePane(wb, s_name, firstActiveRow = 2, firstActiveCol = 3)
    } else {
      openxlsx::freezePane(wb, s_name, firstActiveRow = 2)
    }

    # Column widths
    openxlsx::setColWidths(wb, s_name, cols = 1:ncol(data_tab), widths = "auto")
  }

  # Lưu ra cả data/raw và outputs/
  if (!dir.exists(dirname(OUT_EXCEL_RAW))) dir.create(dirname(OUT_EXCEL_RAW), recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(dirname(OUT_EXCEL_OUTPUTS))) dir.create(dirname(OUT_EXCEL_OUTPUTS), recursive = TRUE, showWarnings = FALSE)

  openxlsx::saveWorkbook(wb, OUT_EXCEL_RAW, overwrite = TRUE)
  logger$info(sprintf("Saved raw Excel workbook to: %s", OUT_EXCEL_RAW))

  openxlsx::saveWorkbook(wb, OUT_EXCEL_OUTPUTS, overwrite = TRUE)
  logger$info(sprintf("Saved copy to: %s", OUT_EXCEL_OUTPUTS))

  invisible(OUT_EXCEL_RAW)
}

if (sys.nframe() == 0L) {
  create_raw_excel()
}
