"""
Data fetching module for World Bank World Development Indicators (WDI).
Communicates with World Bank API v2 with automatic retry, error handling,
per-indicator raw CSV saving, and metadata generation.
"""

from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import pandas as pd
import requests

from src.config import (
    ALL_INDICATORS,
    DATA_RAW_DIR,
    END_YEAR,
    ISO3_LIST,
    METADATA_PATH,
    START_YEAR,
)
from src.utils import get_retry_session, sanitize_filename, setup_logger

logger = setup_logger("fetcher")


class WorldBankFetcher:
    """
    Handles robust fetching of WDI data and indicator metadata from World Bank API v2.
    """

    BASE_API_URL = "http://api.worldbank.org/v2"

    def __init__(self, session: Optional[requests.Session] = None):
        self.session = session or get_retry_session()
        DATA_RAW_DIR.mkdir(parents=True, exist_ok=True)

    def fetch_indicator_metadata(self, indicator_code: str) -> Dict[str, str]:
        """
        Fetches official metadata for a given indicator from World Bank API.
        Falls back to local config metadata if remote lookup fails.
        """
        url = f"{self.BASE_API_URL}/indicator/{indicator_code}?format=json"
        config_info = ALL_INDICATORS.get(indicator_code, {})

        meta = {
            "indicator_code": indicator_code,
            "indicator_name": config_info.get("name_vi", indicator_code),
            "short_name": config_info.get("short_name", ""),
            "group_vi": config_info.get("group_name_vi", ""),
            "group_en": config_info.get("group_name_en", ""),
            "unit": config_info.get("unit", ""),
            "source": "World Development Indicators (World Bank)",
            "source_organization": "World Bank",
            "source_note": config_info.get("notes", ""),
            "download_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        }

        try:
            resp = self.session.get(url, timeout=12)
            if resp.status_code == 200:
                data = resp.json()
                if isinstance(data, list) and len(data) > 1 and len(data[1]) > 0:
                    info = data[1][0]
                    meta["indicator_name_en"] = info.get("name", "")
                    if info.get("unit"):
                        meta["unit"] = info.get("unit")
                    if info.get("sourceOrganization"):
                        meta["source_organization"] = info.get("sourceOrganization")
                    if info.get("sourceNote"):
                        meta["source_note"] = (
                            info.get("sourceNote") + f" | Ghi chú thêm: {config_info.get('notes', '')}"
                        )
            else:
                logger.warning(
                    f"Metadata API returned status {resp.status_code} for {indicator_code}. Using config fallback."
                )
        except Exception as e:
            logger.warning(
                f"Failed to fetch remote metadata for {indicator_code}: {e}. Using config fallback."
            )

        return meta

    def fetch_indicator_data(
        self, indicator_code: str, iso3_list: List[str], start_year: int, end_year: int
    ) -> Optional[pd.DataFrame]:
        """
        Fetches time-series data for a single indicator across specified countries and years.
        Returns a cleaned raw DataFrame or None if an error occurs.
        """
        countries_param = ";".join(iso3_list)
        url = (
            f"{self.BASE_API_URL}/country/{countries_param}/indicator/{indicator_code}"
            f"?date={start_year}:{end_year}&format=json&per_page=1500"
        )

        try:
            logger.info(f"Downloading [{indicator_code}] ({ALL_INDICATORS.get(indicator_code, {}).get('short_name', '')})...")
            resp = self.session.get(url, timeout=20)

            if resp.status_code != 200:
                logger.warning(
                    f"HTTP {resp.status_code} when querying indicator '{indicator_code}'. Skipping."
                )
                return None

            data = resp.json()

            # WB API returns [page_info, records] on success or [{'message': [...]}] on error
            if not isinstance(data, list) or len(data) < 2:
                logger.warning(
                    f"No data records found or invalid API response for indicator '{indicator_code}'. Payload: {data}"
                )
                return None

            records = data[1]
            if not records:
                logger.warning(f"Empty data list returned for indicator '{indicator_code}'.")
                return None

            rows = []
            for rec in records:
                country_iso3 = rec.get("countryiso3code")
                if not country_iso3:
                    # In some WB API versions country.id may hold ISO2, but countryiso3code is standard
                    country_obj = rec.get("country", {})
                    country_iso3 = country_obj.get("id", "")

                country_name = rec.get("country", {}).get("value", "")
                year = rec.get("date")
                val = rec.get("value")

                rows.append({
                    "indicator_code": indicator_code,
                    "indicator_name": rec.get("indicator", {}).get("value", indicator_code),
                    "iso3": country_iso3,
                    "country": country_name,
                    "year": int(year) if year and str(year).isdigit() else None,
                    "value": float(val) if val is not None else None,
                })

            df = pd.DataFrame(rows)
            # Filter only requested countries and years in case API returns aggregates
            df = df[df["iso3"].isin(iso3_list) & df["year"].between(start_year, end_year)]
            df = df.sort_values(by=["iso3", "year"]).reset_index(drop=True)

            logger.info(
                f"Successfully downloaded [{indicator_code}]: {len(df)} rows, "
                f"non-null: {df['value'].notna().sum()}/{len(df)}"
            )
            return df

        except Exception as e:
            logger.warning(
                f"Unexpected error while fetching indicator '{indicator_code}': {e}. Continuing pipeline..."
            )
            return None

    def fetch_all(
        self,
        indicators: Optional[Dict[str, dict]] = None,
        iso3_list: Optional[List[str]] = None,
        start_year: int = START_YEAR,
        end_year: int = END_YEAR,
    ) -> Tuple[Dict[str, pd.DataFrame], pd.DataFrame]:
        """
        Executes the entire ingestion pipeline:
        - Fetches raw time-series data for each indicator.
        - Saves each raw indicator dataset to data/raw/{indicator_code}.csv.
        - Gathers metadata and saves data/raw/metadata.csv.
        """
        target_indicators = indicators or ALL_INDICATORS
        target_iso3 = iso3_list or ISO3_LIST

        logger.info(
            f"=== Starting World Bank Ingestion: {len(target_indicators)} indicators, "
            f"{len(target_iso3)} countries ({start_year}-{end_year}) ==="
        )

        raw_data_map: Dict[str, pd.DataFrame] = {}
        metadata_records: List[Dict[str, str]] = []

        for code, info in target_indicators.items():
            # 1. Fetch metadata
            meta = self.fetch_indicator_metadata(code)
            metadata_records.append(meta)

            # 2. Fetch raw indicator data
            df_ind = self.fetch_indicator_data(code, target_iso3, start_year, end_year)
            if df_ind is not None and not df_ind.empty:
                raw_data_map[code] = df_ind
                # Save raw CSV
                safe_name = sanitize_filename(code)
                raw_csv_path = DATA_RAW_DIR / f"{safe_name}.csv"
                df_ind.to_csv(raw_csv_path, index=False, encoding="utf-8-sig")
            else:
                logger.warning(
                    f"Warning: Indicator '{code}' has no records retrieved. Raw CSV not written."
                )

        # 3. Save metadata.csv
        df_meta = pd.DataFrame(metadata_records)
        df_meta.to_csv(METADATA_PATH, index=False, encoding="utf-8-sig")
        logger.info(f"Saved metadata catalog to: {METADATA_PATH} ({len(df_meta)} indicators)")

        logger.info(
            f"=== Ingestion Complete: {len(raw_data_map)}/{len(target_indicators)} indicators retrieved ==="
        )
        return raw_data_map, df_meta


if __name__ == "__main__":
    fetcher = WorldBankFetcher()
    fetcher.fetch_all()
