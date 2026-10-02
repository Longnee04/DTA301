"""
Data Quality Reporting & Descriptive Statistics Module.
Generates:
- Data dictionary (CSV)
- Missing rate analysis by country, variable, and year (CSV + Heatmap figures)
- Complete cases count by indicator group (CSV)
- Outlier detection via Z-score (>3) and annual jumps (CSV)
- Descriptive statistics overall and by country (CSV)
"""

from pathlib import Path
from typing import Dict, List, Optional
import matplotlib
matplotlib.use("Agg")  # Non-interactive backend for headless execution
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

from src.config import (
    ALL_INDICATORS,
    ASEAN_COUNTRIES,
    DATA_DICTIONARY_PATH,
    DATA_DICTIONARY_PROCESSED_PATH,
    DERIVED_VARIABLES,
    INDICATOR_GROUPS,
    OUTPUTS_FIGURES_DIR,
    OUTPUTS_TABLES_DIR,
    SHORT_TO_WDI,
)
from src.utils import setup_logger

logger = setup_logger("quality_reporter")


class QualityReporter:
    """
    Performs comprehensive data auditing, summary statistics, and visualization generation.
    """

    def __init__(self):
        OUTPUTS_TABLES_DIR.mkdir(parents=True, exist_ok=True)
        OUTPUTS_FIGURES_DIR.mkdir(parents=True, exist_ok=True)

    def generate_data_dictionary(self) -> pd.DataFrame:
        """
        Creates a structured Data Dictionary documenting all indicators and derived variables.
        """
        logger.info("Generating Data Dictionary (data_dictionary.csv)...")
        records = []

        # 1. Base panel identifier columns
        scaffold_vars = [
            ("country", "Tên quốc gia (tiếng Anh)", "Scaffold", "Tên văn bản", "Định danh", "Tên chính thức từ World Bank", "Country Name"),
            ("iso3", "Mã ISO-3 của quốc gia", "Scaffold", "Mã 3 ký tự", "Định danh", "Chuẩn ISO 3166-1 alpha-3", "ISO-3 Country Code"),
            ("year", "Năm quan sát", "Scaffold", "Năm (2010-2024)", "Định danh", "Chuỗi thời gian hàng năm", "Calendar Year"),
        ]
        for col, desc_vi, wdi, unit, grp, notes, stata_lbl in scaffold_vars:
            records.append({
                "column_name": col,
                "vietnamese_description": desc_vi,
                "wdi_code": wdi,
                "unit": unit,
                "variable_group": grp,
                "notes": notes,
                "stata_label": stata_lbl,
                "is_derived": False,
            })

        # 2. Raw WDI indicators
        for code, info in ALL_INDICATORS.items():
            records.append({
                "column_name": info["short_name"],
                "vietnamese_description": info["name_vi"],
                "wdi_code": code,
                "unit": info["unit"],
                "variable_group": info["group_name_vi"],
                "notes": info["notes"],
                "stata_label": info["stata_label"],
                "is_derived": False,
            })

        # 3. Derived variables
        for der_col, der_info in DERIVED_VARIABLES.items():
            records.append({
                "column_name": der_col,
                "vietnamese_description": der_info["name_vi"],
                "wdi_code": "Phái sinh",
                "unit": der_info["unit"],
                "variable_group": der_info["group_name_vi"],
                "notes": der_info["notes"],
                "stata_label": der_info["stata_label"],
                "is_derived": True,
            })

        dict_df = pd.DataFrame(records)
        dict_df.to_csv(DATA_DICTIONARY_PATH, index=False, encoding="utf-8-sig")
        dict_df.to_csv(DATA_DICTIONARY_PROCESSED_PATH, index=False, encoding="utf-8-sig")
        logger.info(f"Data Dictionary saved to {DATA_DICTIONARY_PATH} ({len(dict_df)} variables)")
        return dict_df

    def analyze_missing_data(self, df: pd.DataFrame) -> Dict[str, pd.DataFrame]:
        """
        Calculates missing data rates by country, by variable, and by year.
        Generates corresponding CSV tables and heatmap visualizations.
        """
        logger.info("Computing missing data statistics and rendering heatmaps...")
        feature_cols = [c for c in df.columns if c not in ["country", "iso3", "year"]]

        # 1. Missing rate by Variable
        var_records = []
        for col in feature_cols:
            wdi_code = SHORT_TO_WDI.get(col, "Phái sinh")
            group_name = ALL_INDICATORS.get(wdi_code, {}).get("group_name_vi", "Phái sinh")
            n_missing = int(df[col].isna().sum())
            total = len(df)
            var_records.append({
                "column_name": col,
                "wdi_code": wdi_code,
                "variable_group": group_name,
                "total_observations": total,
                "missing_count": n_missing,
                "missing_rate_pct": round((n_missing / total) * 100, 2),
                "available_count": total - n_missing,
            })
        df_missing_var = pd.DataFrame(var_records).sort_values(
            by=["missing_rate_pct", "column_name"], ascending=[False, True]
        )
        df_missing_var.to_csv(
            OUTPUTS_TABLES_DIR / "missing_by_variable.csv", index=False, encoding="utf-8-sig"
        )

        # 2. Missing rate by Country
        country_records = []
        for iso3 in df["iso3"].unique():
            c_df = df[df["iso3"] == iso3]
            c_name = c_df["country"].iloc[0]
            total_cells = len(c_df) * len(feature_cols)
            missing_cells = int(c_df[feature_cols].isna().sum().sum())
            country_records.append({
                "iso3": iso3,
                "country": c_name,
                "total_cells": total_cells,
                "missing_cells": missing_cells,
                "missing_rate_pct": round((missing_cells / total_cells) * 100, 2),
                "complete_rate_pct": round(100 - (missing_cells / total_cells) * 100, 2),
            })
        df_missing_country = pd.DataFrame(country_records).sort_values(
            by="missing_rate_pct", ascending=False
        )
        df_missing_country.to_csv(
            OUTPUTS_TABLES_DIR / "missing_by_country.csv", index=False, encoding="utf-8-sig"
        )

        # 3. Missing rate by Year
        year_records = []
        for yr in sorted(df["year"].unique()):
            y_df = df[df["year"] == yr]
            total_cells = len(y_df) * len(feature_cols)
            missing_cells = int(y_df[feature_cols].isna().sum().sum())
            year_records.append({
                "year": yr,
                "total_cells": total_cells,
                "missing_cells": missing_cells,
                "missing_rate_pct": round((missing_cells / total_cells) * 100, 2),
                "complete_rate_pct": round(100 - (missing_cells / total_cells) * 100, 2),
            })
        df_missing_year = pd.DataFrame(year_records)
        df_missing_year.to_csv(
            OUTPUTS_TABLES_DIR / "missing_by_year.csv", index=False, encoding="utf-8-sig"
        )

        # 4. Heatmap: Missing rate by Country x Variable
        plt.figure(figsize=(16, 8))
        matrix_c_var = (
            df.groupby("iso3")[feature_cols]
            .apply(lambda g: (g.isna().sum() / len(g)) * 100)
            .T
        )
        sns.heatmap(
            matrix_c_var,
            cmap="YlOrRd",
            annot=False,
            cbar_kws={"label": "Tỷ lệ thiếu (%)"},
            linewidths=0.5,
        )
        plt.title("Tỷ lệ dữ liệu khuyết thiếu theo Biến và Quốc gia ASEAN (2010-2024)", fontsize=13, weight="bold")
        plt.xlabel("Mã quốc gia (ISO3)", fontsize=11)
        plt.ylabel("Biến số", fontsize=11)
        plt.tight_layout()
        plt.savefig(
            OUTPUTS_FIGURES_DIR / "missing_heatmap_country_var.png", dpi=300
        )
        plt.close()

        # 5. Heatmap: Missing rate by Year x Variable
        plt.figure(figsize=(16, 8))
        matrix_y_var = (
            df.groupby("year")[feature_cols]
            .apply(lambda g: (g.isna().sum() / len(g)) * 100)
            .T
        )
        sns.heatmap(
            matrix_y_var,
            cmap="YlOrRd",
            annot=False,
            cbar_kws={"label": "Tỷ lệ thiếu (%)"},
            linewidths=0.5,
        )
        plt.title("Tỷ lệ dữ liệu khuyết thiếu theo Biến và Năm quan sát (2010-2024)", fontsize=13, weight="bold")
        plt.xlabel("Năm", fontsize=11)
        plt.ylabel("Biến số", fontsize=11)
        plt.tight_layout()
        plt.savefig(
            OUTPUTS_FIGURES_DIR / "missing_heatmap_year_var.png", dpi=300
        )
        plt.close()

        # 6. Overall Missing Matrix (150 rows x variables)
        plt.figure(figsize=(18, 9))
        df_sorted = df.sort_values(by=["iso3", "year"]).reset_index(drop=True)
        missing_bin = df_sorted[feature_cols].isna().astype(int)
        y_labels = [f"{row['iso3']}_{row['year']}" for _, row in df_sorted.iterrows()]

        sns.heatmap(
            missing_bin,
            cmap="Blues",
            cbar=True,
            yticklabels=False,
            xticklabels=True,
            cbar_kws={"ticks": [0, 1], "label": "0 = Có dữ liệu, 1 = Khuyết (NaN)"},
        )
        plt.title("Ma trận khuyết thiếu quan sát Panel ASEAN (150 quan sát x Biến)", fontsize=13, weight="bold")
        plt.xlabel("Biến số", fontsize=11)
        plt.ylabel("Quan sát Quốc gia - Năm (Sắp xếp theo Nước & Năm)", fontsize=11)
        plt.xticks(rotation=90, fontsize=8)
        plt.tight_layout()
        plt.savefig(OUTPUTS_FIGURES_DIR / "missing_matrix.png", dpi=300)
        plt.close()

        logger.info("Missing data reports and heatmaps successfully saved.")
        return {
            "by_variable": df_missing_var,
            "by_country": df_missing_country,
            "by_year": df_missing_year,
        }

    def analyze_complete_cases(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Computes the number and percentage of complete observations (rows without NaNs)
        for each indicator group and across all variables.
        """
        logger.info("Computing complete cases across indicator groups...")
        results = []
        total_rows = len(df)

        for grp_key, grp_data in INDICATOR_GROUPS.items():
            grp_vars = [
                ind["short_name"]
                for ind in grp_data["indicators"].values()
                if ind["short_name"] in df.columns
            ]
            if not grp_vars:
                continue

            subset = df[grp_vars]
            complete_count = int(subset.dropna().shape[0])
            results.append({
                "group_key": grp_key,
                "group_name_vi": grp_data["group_name_vi"],
                "num_variables": len(grp_vars),
                "variables_list": ", ".join(grp_vars),
                "total_observations": total_rows,
                "complete_cases": complete_count,
                "complete_rate_pct": round((complete_count / total_rows) * 100, 2),
            })

        # All 36 raw variables combined
        raw_vars = [
            info["short_name"]
            for info in ALL_INDICATORS.values()
            if info["short_name"] in df.columns
        ]
        complete_all_raw = int(df[raw_vars].dropna().shape[0])
        results.append({
            "group_key": "ALL_RAW_INDICATORS",
            "group_name_vi": "Tất cả 36 chỉ số gốc WDI",
            "num_variables": len(raw_vars),
            "variables_list": "Toàn bộ 36 biến WDI",
            "total_observations": total_rows,
            "complete_cases": complete_all_raw,
            "complete_rate_pct": round((complete_all_raw / total_rows) * 100, 2),
        })

        # Core econometric model variables (e.g. internet, unemployment, gdp_pc, trade, fdi)
        core_vars = [
            v for v in [
                "internet_users", "fixed_broadband", "unemp_total", "emp_rate_total",
                "labor_force_part", "gdp_pc_ppp", "trade_openness", "fdi_net_inflows"
            ] if v in df.columns
        ]
        complete_core = int(df[core_vars].dropna().shape[0])
        results.append({
            "group_key": "CORE_ECONOMETRIC_VARS",
            "group_name_vi": "Nhóm biến cốt lõi cho mô hình kinh tế lượng",
            "num_variables": len(core_vars),
            "variables_list": ", ".join(core_vars),
            "total_observations": total_rows,
            "complete_cases": complete_core,
            "complete_rate_pct": round((complete_core / total_rows) * 100, 2),
        })

        complete_df = pd.DataFrame(results)
        complete_df.to_csv(
            OUTPUTS_TABLES_DIR / "complete_cases_by_group.csv", index=False, encoding="utf-8-sig"
        )
        logger.info("Saved complete cases report to outputs/tables/complete_cases_by_group.csv")
        return complete_df

    def detect_outliers(self, df: pd.DataFrame) -> Dict[str, pd.DataFrame]:
        """
        Detects potential anomalies using:
        1. Z-Score (|Z| > 3.0) across the panel.
        2. Abnormal annual jumps between consecutive years for each country (|delta| > 3*std(delta) or extreme shifts).
        """
        logger.info("Running outlier detection (Z-scores & annual jumps)...")
        num_cols = [
            c for c in df.select_dtypes(include=[np.number]).columns
            if c not in ["year", "covid", "myanmar_post2021", "high_income"]
        ]

        # 1. Z-Score Outliers
        z_records = []
        for col in num_cols:
            series = df[col].dropna()
            if len(series) < 10 or series.std() == 0:
                continue

            mean = series.mean()
            std = series.std()
            z_scores = (df[col] - mean) / std

            outliers = df[z_scores.abs() > 3.0]
            for _, row in outliers.iterrows():
                val = row[col]
                z_val = (val - mean) / std
                z_records.append({
                    "iso3": row["iso3"],
                    "country": row["country"],
                    "year": int(row["year"]),
                    "variable": col,
                    "value": round(float(val), 4),
                    "panel_mean": round(float(mean), 4),
                    "panel_std": round(float(std), 4),
                    "z_score": round(float(z_val), 2),
                    "outlier_type": "High outlier (z > 3)" if z_val > 0 else "Low outlier (z < -3)",
                })

        z_df = pd.DataFrame(z_records)
        if not z_df.empty:
            z_df = z_df.sort_values(by=["variable", "z_score"], ascending=[True, False])
        z_df.to_csv(
            OUTPUTS_TABLES_DIR / "outliers_zscore.csv", index=False, encoding="utf-8-sig"
        )
        logger.info(f"Detected {len(z_df)} Z-score outlier observations (|Z| > 3).")

        # 2. Abnormal Annual Jumps
        jump_records = []
        df_sorted = df.sort_values(by=["iso3", "year"]).reset_index(drop=True)

        for col in num_cols:
            # Calculate annual change by country
            df_sorted[f"_diff_{col}"] = df_sorted.groupby("iso3")[col].diff(1)
            diff_series = df_sorted[f"_diff_{col}"].dropna()

            if len(diff_series) < 10 or diff_series.std() == 0:
                df_sorted.drop(columns=[f"_diff_{col}"], inplace=True)
                continue

            diff_mean = diff_series.mean()
            diff_std = diff_series.std()
            jump_threshold = 3.0 * diff_std

            abnormal_jumps = df_sorted[df_sorted[f"_diff_{col}"].abs() > jump_threshold]
            for _, row in abnormal_jumps.iterrows():
                diff_val = row[f"_diff_{col}"]
                prev_val = row[col] - diff_val
                jump_records.append({
                    "iso3": row["iso3"],
                    "country": row["country"],
                    "year": int(row["year"]),
                    "variable": col,
                    "previous_year_value": round(float(prev_val), 4),
                    "current_year_value": round(float(row[col]), 4),
                    "absolute_jump": round(float(diff_val), 4),
                    "jump_std_ratio": round(float(abs(diff_val) / diff_std), 2),
                    "notes": f"Jump exceeds 3*std of annual delta ({round(jump_threshold, 2)})",
                })
            df_sorted.drop(columns=[f"_diff_{col}"], inplace=True)

        jump_df = pd.DataFrame(jump_records)
        if not jump_df.empty:
            jump_df = jump_df.sort_values(by=["jump_std_ratio", "variable"], ascending=[False, True])
        jump_df.to_csv(
            OUTPUTS_TABLES_DIR / "outliers_jumps.csv", index=False, encoding="utf-8-sig"
        )
        logger.info(f"Detected {len(jump_df)} abnormal annual jump events.")

        return {"z_score": z_df, "jumps": jump_df}

    def generate_descriptive_stats(self, df: pd.DataFrame) -> Dict[str, pd.DataFrame]:
        """
        Produces detailed summary statistics (mean, sd, min, max, quantiles)
        both overall and disaggregated by country.
        """
        logger.info("Generating descriptive statistics tables...")
        num_cols = [
            c for c in df.select_dtypes(include=[np.number]).columns
            if c not in ["year", "covid", "myanmar_post2021", "high_income"]
        ]

        # 1. Overall Panel Summary
        overall_records = []
        for col in num_cols:
            s = df[col].dropna()
            wdi_code = SHORT_TO_WDI.get(col, "Phái sinh")
            grp = ALL_INDICATORS.get(wdi_code, {}).get("group_name_vi", "Phái sinh")
            n = len(s)
            overall_records.append({
                "variable": col,
                "wdi_code": wdi_code,
                "variable_group": grp,
                "count": n,
                "missing_pct": round(((len(df) - n) / len(df)) * 100, 2),
                "mean": round(float(s.mean()), 4) if n > 0 else np.nan,
                "std": round(float(s.std()), 4) if n > 1 else np.nan,
                "min": round(float(s.min()), 4) if n > 0 else np.nan,
                "p25": round(float(s.quantile(0.25)), 4) if n > 0 else np.nan,
                "median": round(float(s.median()), 4) if n > 0 else np.nan,
                "p75": round(float(s.quantile(0.75)), 4) if n > 0 else np.nan,
                "max": round(float(s.max()), 4) if n > 0 else np.nan,
                "skewness": round(float(s.skew()), 4) if n > 2 else np.nan,
            })
        df_overall = pd.DataFrame(overall_records)
        df_overall.to_csv(
            OUTPUTS_TABLES_DIR / "summary_stats_overall.csv", index=False, encoding="utf-8-sig"
        )
        logger.info("Saved outputs/tables/summary_stats_overall.csv")

        # 2. Summary by Country
        country_records = []
        for (iso3, country), group in df.groupby(["iso3", "country"]):
            for col in num_cols:
                s = group[col].dropna()
                n = len(s)
                country_records.append({
                    "iso3": iso3,
                    "country": country,
                    "variable": col,
                    "count": n,
                    "mean": round(float(s.mean()), 4) if n > 0 else np.nan,
                    "std": round(float(s.std()), 4) if n > 1 else np.nan,
                    "min": round(float(s.min()), 4) if n > 0 else np.nan,
                    "max": round(float(s.max()), 4) if n > 0 else np.nan,
                })
        df_country = pd.DataFrame(country_records)
        df_country.to_csv(
            OUTPUTS_TABLES_DIR / "summary_stats_by_country.csv", index=False, encoding="utf-8-sig"
        )
        logger.info("Saved outputs/tables/summary_stats_by_country.csv")

        # 3. Extra Visualization: Trends of Internet Penetration and Unemployment Rate
        self._plot_key_trends(df)

        return {"overall": df_overall, "by_country": df_country}

    def _plot_key_trends(self, df: pd.DataFrame) -> None:
        """
        Renders illustrative multi-country time series plots for internet penetration and unemployment.
        """
        try:
            fig, axes = plt.subplots(1, 2, figsize=(18, 6), sharex=True)

            # Internet penetration
            if "internet_users" in df.columns:
                sns.lineplot(
                    data=df,
                    x="year",
                    y="internet_users",
                    hue="iso3",
                    marker="o",
                    ax=axes[0],
                )
                axes[0].set_title("Phổ cập Internet (% dân số) tại ASEAN, 2010-2024", fontsize=12, weight="bold")
                axes[0].set_xlabel("Năm")
                axes[0].set_ylabel("% Dân số dùng Internet")
                axes[0].grid(True, linestyle="--", alpha=0.5)

            # Unemployment total
            if "unemp_total" in df.columns:
                sns.lineplot(
                    data=df,
                    x="year",
                    y="unemp_total",
                    hue="iso3",
                    marker="s",
                    ax=axes[1],
                )
                axes[1].set_title("Tỷ lệ thất nghiệp (% LLLĐ, ILO) tại ASEAN, 2010-2024", fontsize=12, weight="bold")
                axes[1].set_xlabel("Năm")
                axes[1].set_ylabel("Tỷ lệ thất nghiệp (%)")
                axes[1].grid(True, linestyle="--", alpha=0.5)

            plt.tight_layout()
            plt.savefig(
                OUTPUTS_FIGURES_DIR / "internet_vs_unemployment_trends.png", dpi=300
            )
            plt.close()
            logger.info("Saved trend visualization to outputs/figures/internet_vs_unemployment_trends.png")
        except Exception as e:
            logger.warning(f"Could not render trend plots: {e}")
