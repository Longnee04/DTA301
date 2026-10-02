"""
Main pipeline execution script for DTA301 ASEAN Digital Infrastructure & Employment Project.
Runs the complete workflow:
1. Ingestion: Fetches 36 WDI indicators for 10 ASEAN countries (2010-2024), saves raw CSVs and metadata.
2. Cleaning & Panel Construction: Assembles balanced panel (150 obs), exports Long CSV, Wide CSV, and Stata .dta.
3. Feature Engineering: Calculates logs, L1/L2 lags, differences, gender gaps, and dummies.
4. Data Dictionary: Exports comprehensive documentation table.
5. Quality Auditing: Analyzes missingness, complete cases, outliers (Z-scores & annual jumps), renders heatmaps.
6. Summary Statistics: Exports overall and per-country descriptive tables.
"""

import sys
import time
from pathlib import Path

from src.cleaner import PanelCleaner
from src.config import (
    ASEAN_PANEL_DERIVED_PATH,
    ASEAN_PANEL_DTA_PATH,
    ASEAN_PANEL_PATH,
    ASEAN_PANEL_WIDE_PATH,
    DATA_DICTIONARY_PATH,
    METADATA_PATH,
    OUTPUTS_FIGURES_DIR,
    OUTPUTS_TABLES_DIR,
)
from src.feature_engineering import FeatureEngineer
from src.fetcher import WorldBankFetcher
from src.quality_reporter import QualityReporter
from src.utils import setup_logger

logger = setup_logger("main")


def run_pipeline():
    start_time = time.time()
    logger.info("=" * 80)
    logger.info("STARTING DTA301 DATA PIPELINE: ASEAN DIGITAL INFRASTRUCTURE & EMPLOYMENT")
    logger.info("=" * 80)

    # ----------------------------------------------------
    # Step 1: Ingestion from World Bank API
    # ----------------------------------------------------
    logger.info(">>> STEP 1: Ingesting Raw WDI Data and Metadata...")
    fetcher = WorldBankFetcher()
    raw_data_map, metadata_df = fetcher.fetch_all()
    logger.info(f"Raw data ingestion completed. Total indicators retrieved: {len(raw_data_map)}")

    # ----------------------------------------------------
    # Step 2: Panel Assembly and Cleaning
    # ----------------------------------------------------
    logger.info(">>> STEP 2: Assembling Balanced Panel and Exporting Formats...")
    cleaner = PanelCleaner()
    base_panel = cleaner.assemble_panel(raw_data_map=raw_data_map)
    cleaner_outputs = cleaner.export_all(base_panel)
    logger.info(f"Base panel assembled with shape {base_panel.shape}.")

    # ----------------------------------------------------
    # Step 3: Feature Engineering (Derived Variables)
    # ----------------------------------------------------
    logger.info(">>> STEP 3: Engineering Econometric Features (Derived Variables)...")
    engineer = FeatureEngineer()
    derived_panel = engineer.compute_derived_features(base_panel)
    engineer.export_derived(derived_panel)
    logger.info(f"Derived panel assembled with shape {derived_panel.shape}.")

    # ----------------------------------------------------
    # Step 4: Data Dictionary Generation
    # ----------------------------------------------------
    logger.info(">>> STEP 4: Compiling Data Dictionary...")
    reporter = QualityReporter()
    data_dict = reporter.generate_data_dictionary()
    logger.info(f"Data dictionary compiled with {len(data_dict)} documented variables.")

    # ----------------------------------------------------
    # Step 5: Data Quality Reporting & Visualizations
    # ----------------------------------------------------
    logger.info(">>> STEP 5: Running Data Quality Audit and Generating Heatmaps...")
    missing_results = reporter.analyze_missing_data(base_panel)
    complete_cases = reporter.analyze_complete_cases(base_panel)
    outliers = reporter.detect_outliers(derived_panel)

    # ----------------------------------------------------
    # Step 6: Descriptive Statistics
    # ----------------------------------------------------
    logger.info(">>> STEP 6: Computing Descriptive Statistics (Overall & Country)...")
    summary_stats = reporter.generate_descriptive_stats(derived_panel)

    # ----------------------------------------------------
    # Final Pipeline Summary
    # ----------------------------------------------------
    elapsed = time.time() - start_time
    logger.info("=" * 80)
    logger.info("PIPELINE COMPLETED SUCCESSFULLY IN {:.2f} SECONDS".format(elapsed))
    logger.info("=" * 80)
    print("\n" + "=" * 80)
    print(" SUMMARY OF CREATED ARTIFACTS AND OUTPUTS")
    print("=" * 80)
    print(f"1. Raw Ingestion Metadata:   {METADATA_PATH}")
    print(f"2. Long Panel Dataset:       {ASEAN_PANEL_PATH} (Shape: {base_panel.shape})")
    print(f"3. Wide Panel Dataset:       {ASEAN_PANEL_WIDE_PATH}")
    print(f"4. Stata Format Dataset:     {ASEAN_PANEL_DTA_PATH}")
    print(f"5. Derived Feature Panel:    {ASEAN_PANEL_DERIVED_PATH} (Shape: {derived_panel.shape})")
    print(f"6. Data Dictionary:          {DATA_DICTIONARY_PATH} ({len(data_dict)} variables)")
    print(f"7. Audit Tables:             {OUTPUTS_TABLES_DIR}")
    print("   - missing_by_country.csv, missing_by_variable.csv, missing_by_year.csv")
    print("   - complete_cases_by_group.csv")
    print("   - outliers_zscore.csv, outliers_jumps.csv")
    print("   - summary_stats_overall.csv, summary_stats_by_country.csv")
    print(f"8. Audit Figures:            {OUTPUTS_FIGURES_DIR}")
    print("   - missing_heatmap_country_var.png")
    print("   - missing_heatmap_year_var.png")
    print("   - missing_matrix.png")
    print("   - internet_vs_unemployment_trends.png")
    print("=" * 80 + "\n")


if __name__ == "__main__":
    run_pipeline()
