# ==============================================================================
# main.R: Điều phối toàn bộ quy trình thu thập, xử lý và phân tích dữ liệu R
# DTA301 - Tác động của hạ tầng số và phổ cập internet đến việc làm tại ASEAN (2010-2025)
# ==============================================================================

# Thiết lập thư viện cục bộ nếu có
local({
  lib_local <- file.path(getwd(), ".r_lib")
  if (dir.exists(lib_local)) {
    .libPaths(unique(c(lib_local, .libPaths())))
  }
})

source("R/config.R")
source("R/utils.R")
source("R/fetcher.R")
source("R/cleaner.R")
source("R/feature_engineering.R")
source("R/clean_for_modeling.R")
source("R/quality_reporter.R")
source("R/export_raw_excel.R")
source("R/export_clean_excel.R")

logger <- setup_logger("main")

run_pipeline <- function() {
  start_time <- Sys.time()
  logger$info(paste(rep("=", 80), collapse = ""))
  logger$info("STARTING DTA301 DATA PIPELINE IN R: ASEAN DIGITAL INFRASTRUCTURE & EMPLOYMENT (2010-2025)")
  logger$info(paste(rep("=", 80), collapse = ""))

  # ----------------------------------------------------
  # Bước 1: Thu thập dữ liệu từ World Bank API v2
  # ----------------------------------------------------
  logger$info(">>> STEP 1: Ingesting Raw WDI Data and Metadata...")
  ingest_res <- fetch_all()
  raw_data_map <- ingest_res$raw_data_map
  logger$info(sprintf("Raw data ingestion completed. Total indicators retrieved: %d", length(raw_data_map)))

  # ----------------------------------------------------
  # Bước 2: Hợp nhất bảng Panel cân đối và xuất các định dạng
  # ----------------------------------------------------
  logger$info(">>> STEP 2: Assembling Balanced Panel and Exporting Formats...")
  base_panel <- assemble_panel(raw_data_map = raw_data_map)
  cleaner_outputs <- export_all(base_panel)
  logger$info(sprintf("Base panel assembled with shape %d rows x %d columns.", nrow(base_panel), ncol(base_panel)))

  # Xuất dữ liệu thô ra file Excel định dạng đa trang
  tryCatch({
    create_raw_excel()
    logger$info(sprintf("Exported Raw Data to Excel: %s", OUT_EXCEL_RAW))
  }, error = function(e) {
    logger$warn(sprintf("Failed to export Raw Excel: %s", e$message))
  })

  # ----------------------------------------------------
  # Bước 3: Tạo các biến phái sinh kinh tế lượng
  # ----------------------------------------------------
  logger$info(">>> STEP 3: Engineering Econometric Features (Derived Variables)...")
  derived_panel <- compute_derived_features(base_panel)
  export_derived(derived_panel)
  logger$info(sprintf("Derived panel assembled with shape %d rows x %d columns.", nrow(derived_panel), ncol(derived_panel)))

  # ----------------------------------------------------
  # Bước 4: Làm sạch và nội suy có kiểm soát cho mô hình
  # ----------------------------------------------------
  logger$info(">>> STEP 4: Creating Clean Model-Ready Panel (Controlled Imputation & Winsorization)...")
  clean_res <- clean_and_impute(base_panel)
  clean_panel <- engineer_model_features(clean_res$clean_df)
  export_clean_data(clean_panel)
  logger$info(sprintf("Clean model-ready panel created with shape %d rows x %d columns (100%% complete cases).", nrow(clean_panel), ncol(clean_panel)))

  # ----------------------------------------------------
  # Bước 5: Biên soạn từ điển dữ liệu Data Dictionary
  # ----------------------------------------------------
  logger$info(">>> STEP 5: Compiling Data Dictionary...")
  data_dict <- generate_data_dictionary()
  logger$info(sprintf("Data dictionary compiled with %d documented variables.", nrow(data_dict)))

  # ----------------------------------------------------
  # Bước 6: Kiểm định chất lượng dữ liệu và trực quan hóa Heatmap
  # ----------------------------------------------------
  logger$info(">>> STEP 6: Running Data Quality Audit and Generating Heatmaps...")
  missing_results <- analyze_missing_data(base_panel)
  complete_cases <- analyze_complete_cases(base_panel)
  outliers <- detect_outliers(derived_panel)

  # ----------------------------------------------------
  # Bước 7: Thống kê mô tả tổng quan và theo từng quốc gia
  # ----------------------------------------------------
  logger$info(">>> STEP 7: Computing Descriptive Statistics (Overall & Country)...")
  summary_stats <- generate_descriptive_stats(derived_panel)

  # Xuất bảng dữ liệu sạch và đối chiếu ra sổ làm việc Excel
  tryCatch({
    create_clean_excel()
    logger$info(sprintf("Exported Clean Data to Excel: %s", OUT_EXCEL_CLEAN))
  }, error = function(e) {
    logger$warn(sprintf("Failed to export Clean Excel: %s", e$message))
  })

  # ----------------------------------------------------
  # Tổng kết kết quả toàn bộ pipeline
  # ----------------------------------------------------
  elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  logger$info(paste(rep("=", 80), collapse = ""))
  logger$info(sprintf("PIPELINE COMPLETED SUCCESSFULLY IN %.2f SECONDS", elapsed))
  logger$info(paste(rep("=", 80), collapse = ""))

  cat("\n", paste(rep("=", 80), collapse = ""), "\n", sep = "")
  cat(" SUMMARY OF CREATED ARTIFACTS AND OUTPUTS (R PIPELINE)\n")
  cat(paste(rep("=", 80), collapse = ""), "\n", sep = "")
  cat(sprintf("1. Raw Ingestion Metadata:   %s\n", METADATA_PATH))
  cat(sprintf("2. Long Panel Dataset:       %s (Shape: %d x %d, preserving NaNs)\n", ASEAN_PANEL_PATH, nrow(base_panel), ncol(base_panel)))
  cat(sprintf("   - Raw Excel Workbook:     %s\n", OUT_EXCEL_RAW))
  cat(sprintf("3. Wide Panel Dataset:       %s\n", ASEAN_PANEL_WIDE_PATH))
  cat(sprintf("4. Stata Format Dataset:     %s\n", ASEAN_PANEL_DTA_PATH))
  cat(sprintf("5. Derived Feature Panel:    %s (Shape: %d x %d)\n", ASEAN_PANEL_DERIVED_PATH, nrow(derived_panel), ncol(derived_panel)))
  cat(sprintf("6. Clean Model-Ready Panel:  %s (Shape: %d x %d, 100%% complete!)\n", ASEAN_PANEL_CLEAN_PATH, nrow(clean_panel), ncol(clean_panel)))
  cat(sprintf("   - Clean Excel Workbook:   %s\n", OUT_EXCEL_CLEAN))
  cat(sprintf("   - Stata Model Dataset:    %s\n", ASEAN_PANEL_CLEAN_DTA_PATH))
  cat(sprintf("7. Data Dictionary:          %s (%d variables)\n", DATA_DICTIONARY_PATH, nrow(data_dict)))
  cat(sprintf("8. Audit Tables:             %s\n", OUTPUTS_TABLES_DIR))
  cat("   - cleaning_audit_report.csv (Before vs After imputation comparison)\n")
  cat("   - missing_by_country.csv, missing_by_variable.csv, missing_by_year.csv\n")
  cat("   - complete_cases_by_group.csv\n")
  cat("   - outliers_zscore.csv, outliers_jumps.csv\n")
  cat("   - summary_stats_overall.csv, summary_stats_by_country.csv\n")
  cat(sprintf("9. Audit Figures:            %s\n", OUTPUTS_FIGURES_DIR))
  cat("   - missing_heatmap_country_var.png\n")
  cat("   - missing_heatmap_year_var.png\n")
  cat("   - missing_matrix.png\n")
  cat("   - internet_vs_unemployment_trends.png\n")
  cat(paste(rep("=", 80), collapse = ""), "\n\n", sep = "")
}

if (sys.nframe() == 0L) {
  run_pipeline()
}
