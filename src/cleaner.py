"""
Data cleaning and panel consolidation module.
Assembles raw indicator files into a balanced panel structure (country, iso3, year, indicators),
preserves missing values (strictly NO imputation or interpolation in main panel),
and exports to CSV (long & wide) and Stata (.dta) formats with variable labels.
"""

from pathlib import Path
from typing import Dict, Optional
import numpy as np
import pandas as pd

from src.config import (
    ALL_INDICATORS,
    ASEAN_COUNTRIES,
    ASEAN_PANEL_DTA_PATH,
    ASEAN_PANEL_PATH,
    ASEAN_PANEL_WIDE_PATH,
    DATA_PROCESSED_DIR,
    DATA_RAW_DIR,
    ISO3_LIST,
    STATA_VARIABLE_LABELS,
    YEARS,
)
from src.utils import sanitize_filename, setup_logger

logger = setup_logger("cleaner")


class PanelCleaner:
    """
    Cleans raw indicator datasets and constructs panel datasets.
    """

    def __init__(self):
        DATA_PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

    def build_panel_scaffold(self) -> pd.DataFrame:
        """
        Creates a balanced panel index of 10 ASEAN countries x 15 years (2010-2024) = 150 rows.
        """
        records = []
        for iso3 in ISO3_LIST:
            country_name = ASEAN_COUNTRIES[iso3]["name_en"]
            for yr in YEARS:
                records.append({
                    "country": country_name,
                    "iso3": iso3,
                    "year": yr,
                })
        scaffold = pd.DataFrame(records)
        return scaffold.sort_values(by=["iso3", "year"]).reset_index(drop=True)

    def load_raw_indicator(self, code: str) -> Optional[pd.DataFrame]:
        """
        Loads a raw indicator CSV from data/raw/{safe_code}.csv.
        """
        safe_name = sanitize_filename(code)
        raw_path = DATA_RAW_DIR / f"{safe_name}.csv"
        if not raw_path.exists():
            logger.warning(f"Raw file not found: {raw_path}")
            return None
        try:
            df = pd.read_csv(raw_path)
            return df
        except Exception as e:
            logger.warning(f"Error reading raw CSV {raw_path}: {e}")
            return None

    def assemble_panel(self, raw_data_map: Optional[Dict[str, pd.DataFrame]] = None) -> pd.DataFrame:
        """
        Merges all individual indicator series into a single comprehensive panel.
        Ensures NaN values are strictly preserved without imputation.
        """
        logger.info("Assembling balanced ASEAN panel (10 countries x 15 years)...")
        panel = self.build_panel_scaffold()

        for code, info in ALL_INDICATORS.items():
            short_name = info["short_name"]

            # Obtain indicator data
            if raw_data_map and code in raw_data_map:
                df_ind = raw_data_map[code]
            else:
                df_ind = self.load_raw_indicator(code)

            if df_ind is None or df_ind.empty:
                logger.warning(f"Indicator '{code}' ({short_name}) is missing. Creating empty column.")
                panel[short_name] = np.nan
                continue

            # Standardize indicator subset
            subset = df_ind[["iso3", "year", "value"]].copy()
            subset = subset.rename(columns={"value": short_name})
            subset["year"] = pd.to_numeric(subset["year"], errors="coerce").astype(int)
            subset[short_name] = pd.to_numeric(subset[short_name], errors="coerce")

            # Remove potential duplicates before merge
            subset = subset.drop_duplicates(subset=["iso3", "year"])

            # Left merge onto panel scaffold
            panel = pd.merge(panel, subset, on=["iso3", "year"], how="left")

        # Sort cleanly
        panel = panel.sort_values(by=["iso3", "year"]).reset_index(drop=True)
        logger.info(f"Assembled panel shape: {panel.shape} (150 rows expected)")
        return panel

    def create_wide_panel(self, panel_df: pd.DataFrame) -> pd.DataFrame:
        """
        Pivots the long panel into wide format: 1 row per country, columns = {var}_{year}.
        """
        logger.info("Creating wide-format panel (1 row per country, columns by year)...")
        value_vars = [c for c in panel_df.columns if c not in ["country", "iso3", "year"]]

        wide_df = panel_df.pivot(
            index=["iso3", "country"],
            columns="year",
            values=value_vars,
        )

        # Flatten multi-level columns: e.g. ('internet_users', 2010) -> 'internet_users_2010'
        wide_df.columns = [f"{var}_{yr}" for var, yr in wide_df.columns]
        wide_df = wide_df.reset_index()
        wide_df = wide_df.sort_values(by="iso3").reset_index(drop=True)

        logger.info(f"Wide panel shape: {wide_df.shape} (10 rows)")
        return wide_df

    def export_all(self, panel_df: pd.DataFrame) -> Dict[str, Path]:
        """
        Exports panel data into:
        1. data/processed/asean_panel.csv (long panel)
        2. data/processed/asean_panel_wide.csv (wide format)
        3. data/processed/asean_panel.dta (Stata format with variable labels)
        """
        # 1. Export long panel CSV
        panel_df.to_csv(ASEAN_PANEL_PATH, index=False, encoding="utf-8-sig")
        logger.info(f"Saved Long Panel CSV to: {ASEAN_PANEL_PATH}")

        # 2. Export wide panel CSV
        wide_df = self.create_wide_panel(panel_df)
        wide_df.to_csv(ASEAN_PANEL_WIDE_PATH, index=False, encoding="utf-8-sig")
        logger.info(f"Saved Wide Panel CSV to: {ASEAN_PANEL_WIDE_PATH}")

        # 3. Export Stata .dta
        stata_labels = {}
        for col in panel_df.columns:
            if col in STATA_VARIABLE_LABELS:
                # Stata labels max length is 80 characters
                stata_labels[col] = str(STATA_VARIABLE_LABELS[col])[:80]
            else:
                stata_labels[col] = str(col)[:80]

        # Prepare DataFrame for Stata (ensure string types for country and iso3)
        stata_df = panel_df.copy()
        stata_df["country"] = stata_df["country"].astype(str)
        stata_df["iso3"] = stata_df["iso3"].astype(str)
        stata_df["year"] = stata_df["year"].astype(int)

        try:
            stata_df.to_stata(
                ASEAN_PANEL_DTA_PATH,
                write_index=False,
                variable_labels=stata_labels,
                version=118,
            )
            logger.info(f"Saved Stata dataset to: {ASEAN_PANEL_DTA_PATH}")
        except Exception as e:
            logger.error(f"Failed to export Stata .dta: {e}")

        return {
            "long_csv": ASEAN_PANEL_PATH,
            "wide_csv": ASEAN_PANEL_WIDE_PATH,
            "stata_dta": ASEAN_PANEL_DTA_PATH,
        }


if __name__ == "__main__":
    cleaner = PanelCleaner()
    panel = cleaner.assemble_panel()
    cleaner.export_all(panel)
