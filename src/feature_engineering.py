"""
Feature engineering module for derived variables.
Computes log transformations, panel lags (L1, L2), annual differences,
gender gaps, and regional/event dummy variables.
Exports to data/processed/asean_panel_derived.csv and Stata .dta.
"""

from pathlib import Path
import numpy as np
import pandas as pd

from src.config import (
    ASEAN_PANEL_DERIVED_DTA_PATH,
    ASEAN_PANEL_DERIVED_PATH,
    DIGITAL_INFRA_VARS,
    STATA_VARIABLE_LABELS,
)
from src.utils import setup_logger

logger = setup_logger("feature_engineering")


class FeatureEngineer:
    """
    Transforms base panel data to engineer econometric features.
    """

    def __init__(self):
        pass

    def compute_derived_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Computes all required derived variables on the panel:
        - ln_gdp_pc, ln_pop
        - L1, L2 lags for all digital infrastructure variables
        - annual differences for internet users and unemployment
        - gender gaps (female - male) in unemployment and employment rate
        - dummy variables: covid, myanmar_post2021, high_income
        """
        logger.info("Computing derived econometric features...")
        derived = df.copy()

        # Ensure correct sorting for panel operations
        derived = derived.sort_values(by=["iso3", "year"]).reset_index(drop=True)

        # 1. Log transformations
        if "gdp_pc_ppp" in derived.columns:
            derived["ln_gdp_pc"] = np.log(derived["gdp_pc_ppp"].replace(0, np.nan))
        else:
            logger.warning("gdp_pc_ppp not found, ln_gdp_pc set to NaN")
            derived["ln_gdp_pc"] = np.nan

        if "pop_total" in derived.columns:
            derived["ln_pop"] = np.log(derived["pop_total"].replace(0, np.nan))
        else:
            logger.warning("pop_total not found, ln_pop set to NaN")
            derived["ln_pop"] = np.nan

        # 2. L1 and L2 lags for digital infrastructure variables
        for var in DIGITAL_INFRA_VARS:
            if var in derived.columns:
                derived[f"lag1_{var}"] = derived.groupby("iso3")[var].shift(1)
                derived[f"lag2_{var}"] = derived.groupby("iso3")[var].shift(2)
            else:
                logger.warning(f"Digital infra variable '{var}' not in panel; lags set to NaN")
                derived[f"lag1_{var}"] = np.nan
                derived[f"lag2_{var}"] = np.nan

        # 3. Annual differences (diff = Y_t - Y_{t-1})
        if "internet_users" in derived.columns:
            derived["diff_internet_users"] = derived.groupby("iso3")["internet_users"].diff(1)
        else:
            derived["diff_internet_users"] = np.nan

        if "unemp_total" in derived.columns:
            derived["diff_unemp_total"] = derived.groupby("iso3")["unemp_total"].diff(1)
        else:
            derived["diff_unemp_total"] = np.nan

        # 4. Gender gaps (female - male)
        if "unemp_female" in derived.columns and "unemp_male" in derived.columns:
            derived["gap_unemp_gender"] = derived["unemp_female"] - derived["unemp_male"]
        else:
            derived["gap_unemp_gender"] = np.nan

        if "emp_rate_female" in derived.columns and "emp_rate_male" in derived.columns:
            derived["gap_emp_gender"] = derived["emp_rate_female"] - derived["emp_rate_male"]
        else:
            derived["gap_emp_gender"] = np.nan

        # 5. Policy & structural dummy variables
        derived["covid"] = derived["year"].isin([2020, 2021]).astype(int)
        derived["myanmar_post2021"] = (
            (derived["iso3"] == "MMR") & (derived["year"] >= 2021)
        ).astype(int)
        derived["high_income"] = derived["iso3"].isin(["SGP", "BRN"]).astype(int)

        logger.info(f"Derived panel successfully generated. Shape: {derived.shape}")
        return derived

    def export_derived(self, derived_df: pd.DataFrame) -> Path:
        """
        Exports derived panel to CSV and Stata .dta format.
        """
        # CSV Export
        derived_df.to_csv(ASEAN_PANEL_DERIVED_PATH, index=False, encoding="utf-8-sig")
        logger.info(f"Saved Derived Panel CSV to: {ASEAN_PANEL_DERIVED_PATH}")

        # Stata Export
        stata_labels = {}
        for col in derived_df.columns:
            if col in STATA_VARIABLE_LABELS:
                stata_labels[col] = str(STATA_VARIABLE_LABELS[col])[:80]
            else:
                stata_labels[col] = str(col)[:80]

        stata_df = derived_df.copy()
        stata_df["country"] = stata_df["country"].astype(str)
        stata_df["iso3"] = stata_df["iso3"].astype(str)
        stata_df["year"] = stata_df["year"].astype(int)

        try:
            stata_df.to_stata(
                ASEAN_PANEL_DERIVED_DTA_PATH,
                write_index=False,
                variable_labels=stata_labels,
                version=118,
            )
            logger.info(f"Saved Derived Stata dataset to: {ASEAN_PANEL_DERIVED_DTA_PATH}")
        except Exception as e:
            logger.error(f"Failed to export Derived Stata .dta: {e}")

        return ASEAN_PANEL_DERIVED_PATH
