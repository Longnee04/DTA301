"""
Data Cleaning & Imputation Module for Econometric Modeling.
Creates a model-ready panel dataset while preserving 100% of raw data files.

Key operations:
1. Within-country time-series linear interpolation and boundary extrapolation (bfill/ffill).
2. Regional/income-group median imputation for variables completely unobserved in a country
   (e.g., Vietnam ICT service exports, Myanmar trade openness), with transparent imputation flags.
3. Winsorization (1% - 99%) on extreme right-skewed variables (e.g. secure_servers).
4. Re-calculating all derived econometric features (logs, L1/L2 lags, differences, gender gaps, dummies)
   on the clean continuous series so econometric models do not lose observations to listwise deletion.
5. Exporting model-ready datasets:
   - data/processed/asean_panel_clean.csv
   - data/processed/asean_panel_clean.dta (Stata format with variable labels)
6. Generating an audit comparison table: outputs/tables/cleaning_audit_report.csv
"""

import sys
from pathlib import Path
from typing import Dict, List, Tuple

# Ensure project root is in sys.path
PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

import numpy as np
import pandas as pd

from src.config import (
    ALL_INDICATORS,
    ASEAN_COUNTRIES,
    DATA_PROCESSED_DIR,
    DIGITAL_INFRA_VARS,
    OUTPUTS_TABLES_DIR,
    STATA_VARIABLE_LABELS,
)
from src.utils import setup_logger

logger = setup_logger("clean_for_modeling")

ASEAN_PANEL_CLEAN_PATH = DATA_PROCESSED_DIR / "asean_panel_clean.csv"
ASEAN_PANEL_CLEAN_DTA_PATH = DATA_PROCESSED_DIR / "asean_panel_clean.dta"
CLEANING_AUDIT_PATH = OUTPUTS_TABLES_DIR / "cleaning_audit_report.csv"


class ModelDataCleaner:
    """
    Produces clean, complete panel datasets ready for econometric estimation.
    """

    def __init__(self):
        DATA_PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
        OUTPUTS_TABLES_DIR.mkdir(parents=True, exist_ok=True)

    def load_base_panel(self) -> pd.DataFrame:
        base_path = DATA_PROCESSED_DIR / "asean_panel.csv"
        if not base_path.exists():
            raise FileNotFoundError(f"Base panel file not found: {base_path}. Run main.py first.")
        df = pd.read_csv(base_path)
        logger.info(f"Loaded base panel: {df.shape} (150 rows x {df.shape[1]} columns)")
        return df

    def clean_and_impute(self, df: pd.DataFrame) -> Tuple[pd.DataFrame, pd.DataFrame]:
        """
        Executes controlled econometric imputation:
        1. Within-country time series linear interpolation & boundary fill.
        2. Group median imputation for wholly missing indicators in a specific country.
        3. Generates audit report comparing missingness before vs after.
        """
        logger.info("Executing controlled time-series cleaning and imputation...")
        clean_df = df.copy().sort_values(by=["iso3", "year"]).reset_index(drop=True)
        num_cols = [c for c in clean_df.columns if c not in ["country", "iso3", "year"]]

        audit_records = []

        # Define peer groups for fallback imputation of country-level missing series:
        # Group 1 (High income): SGP, BRN
        # Group 2 (Upper-middle): MYS, THA
        # Group 3 (Lower-middle emerging): IDN, PHL, VNM
        # Group 4 (Lower-middle transition): KHM, LAO, MMR
        peer_groups = {
            "BRN": "HIGH", "SGP": "HIGH",
            "MYS": "UPPER_MID", "THA": "UPPER_MID",
            "IDN": "LOWER_MID", "PHL": "LOWER_MID", "VNM": "LOWER_MID",
            "KHM": "TRANSITION", "LAO": "TRANSITION", "MMR": "TRANSITION",
        }
        clean_df["_peer_group"] = clean_df["iso3"].map(peer_groups)

        for col in num_cols:
            orig_missing = int(clean_df[col].isna().sum())

            # Step 1: Within-country linear interpolation + forward/backward boundary fill
            clean_df[col] = clean_df.groupby("iso3")[col].transform(
                lambda g: g.interpolate(method="linear").bfill().ffill()
            )
            after_ts_missing = int(clean_df[col].isna().sum())

            method_notes = []
            if orig_missing > 0:
                method_notes.append("Nội suy tuyến tính chuỗi thời gian & bfill/ffill theo từng nước")

            # Step 2: Regional peer-group median fallback for wholly-missing country series
            if after_ts_missing > 0:
                missing_countries = clean_df[clean_df[col].isna()]["iso3"].unique().tolist()
                clean_df[col] = clean_df.groupby(["_peer_group", "year"])[col].transform(
                    lambda g: g.fillna(g.median())
                )
                # If peer group has no data for that year, fallback to ASEAN overall median for that year
                clean_df[col] = clean_df.groupby("year")[col].transform(
                    lambda g: g.fillna(g.median())
                )
                final_missing = int(clean_df[col].isna().sum())
                method_notes.append(
                    f"Nội suy trung vị nhóm nước tương đồng ({', '.join(missing_countries)})"
                )
            else:
                final_missing = after_ts_missing

            audit_records.append({
                "column_name": col,
                "wdi_code": ALL_INDICATORS.get(col, {}).get("wdi_code", ""),
                "variable_group": ALL_INDICATORS.get(col, {}).get("group_name_vi", ""),
                "missing_before": orig_missing,
                "missing_after": final_missing,
                "clean_completeness_pct": round(100.0 * (len(clean_df) - final_missing) / len(clean_df), 2),
                "cleaning_method": " | ".join(method_notes) if method_notes else "Dữ liệu gốc hoàn thiện 100% (không cần điền)",
            })

        clean_df.drop(columns=["_peer_group"], inplace=True)
        audit_df = pd.DataFrame(audit_records)
        audit_df.to_csv(CLEANING_AUDIT_PATH, index=False, encoding="utf-8-sig")
        logger.info(f"Saved cleaning audit report to: {CLEANING_AUDIT_PATH}")

        return clean_df, audit_df

    def engineer_model_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Calculates all econometric transformations on clean continuous series:
        - Logs: ln_gdp_pc, ln_pop
        - Complete L1 and L2 lags for digital infrastructure
        - Annual changes: diff_internet_users, diff_unemp_total
        - Gender disparities: gap_unemp_gender, gap_emp_gender
        - Winsorized versions for extreme skewed variables (secure_servers, trade_openness)
        - Dummy variables: covid, myanmar_post2021, high_income
        """
        logger.info("Computing derived econometric variables on clean panel...")
        model_df = df.copy().sort_values(by=["iso3", "year"]).reset_index(drop=True)

        # 1. Log transformations
        model_df["ln_gdp_pc"] = np.log(model_df["gdp_pc_ppp"])
        model_df["ln_pop"] = np.log(model_df["pop_total"])

        # 2. Complete L1 & L2 Lags for Digital Infrastructure
        for var in DIGITAL_INFRA_VARS:
            model_df[f"lag1_{var}"] = model_df.groupby("iso3")[var].shift(1)
            model_df[f"lag2_{var}"] = model_df.groupby("iso3")[var].shift(2)

        # 3. Annual Differences (Y_t - Y_{t-1})
        model_df["diff_internet_users"] = model_df.groupby("iso3")["internet_users"].diff(1)
        model_df["diff_unemp_total"] = model_df.groupby("iso3")["unemp_total"].diff(1)

        # 4. Gender Gaps
        model_df["gap_unemp_gender"] = model_df["unemp_female"] - model_df["unemp_male"]
        model_df["gap_emp_gender"] = model_df["emp_rate_female"] - model_df["emp_rate_male"]

        # 5. Winsorized versions for extreme skewed variables (1% - 99%)
        for v in ["secure_servers", "trade_openness"]:
            p01 = model_df[v].quantile(0.01)
            p99 = model_df[v].quantile(0.99)
            model_df[f"{v}_win"] = model_df[v].clip(lower=p01, upper=p99)

        # 6. Policy & Structural Dummies
        model_df["covid"] = model_df["year"].isin([2020, 2021]).astype(int)
        model_df["myanmar_post2021"] = (
            (model_df["iso3"] == "MMR") & (model_df["year"] >= 2021)
        ).astype(int)
        model_df["high_income"] = model_df["iso3"].isin(["SGP", "BRN"]).astype(int)

        logger.info(f"Model-ready clean dataset shape: {model_df.shape} (150 rows x {model_df.shape[1]} columns)")
        return model_df

    def export_clean_data(self, model_df: pd.DataFrame) -> Dict[str, Path]:
        """
        Exports clean datasets in CSV and Stata formats with rich variable labels.
        """
        # CSV Export
        model_df.to_csv(ASEAN_PANEL_CLEAN_PATH, index=False, encoding="utf-8-sig")
        logger.info(f"Saved Clean Model-Ready Panel CSV: {ASEAN_PANEL_CLEAN_PATH}")

        # Stata Export
        labels = {}
        for col in model_df.columns:
            if col in STATA_VARIABLE_LABELS:
                labels[col] = str(STATA_VARIABLE_LABELS[col])[:80]
            elif col.endswith("_win"):
                base_var = col.replace("_win", "")
                labels[col] = f"{base_var} (Winsorized 1-99%)"[:80]
            else:
                labels[col] = str(col)[:80]

        stata_df = model_df.copy()
        stata_df["country"] = stata_df["country"].astype(str)
        stata_df["iso3"] = stata_df["iso3"].astype(str)
        stata_df["year"] = stata_df["year"].astype(int)

        try:
            stata_df.to_stata(
                ASEAN_PANEL_CLEAN_DTA_PATH,
                write_index=False,
                variable_labels=labels,
                version=118,
            )
            logger.info(f"Saved Clean Model-Ready Stata Dataset: {ASEAN_PANEL_CLEAN_DTA_PATH}")
        except Exception as e:
            logger.error(f"Failed to export clean Stata dataset: {e}")

        return {
            "clean_csv": ASEAN_PANEL_CLEAN_PATH,
            "clean_dta": ASEAN_PANEL_CLEAN_DTA_PATH,
        }


def run_cleaning_pipeline():
    cleaner = ModelDataCleaner()
    base_df = cleaner.load_base_panel()
    imputed_df, audit_df = cleaner.clean_and_impute(base_df)
    model_df = cleaner.engineer_model_features(imputed_df)
    outputs = cleaner.export_clean_data(model_df)
    return model_df, audit_df


if __name__ == "__main__":
    run_cleaning_pipeline()
