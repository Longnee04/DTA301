"""
Utility functions for logging, networking with retries, and data formatting.
"""

import logging
import sys
from pathlib import Path
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from src.config import LOG_FILE_PATH


def setup_logger(name: str = "dta301_pipeline") -> logging.Logger:
    """
    Configures and returns a thread-safe logger writing to both console and log file.
    Uses UTF-8 encoding to support Vietnamese text.
    """
    logger = logging.getLogger(name)
    if logger.handlers:
        return logger

    logger.setLevel(logging.INFO)

    log_format = logging.Formatter(
        fmt="%(asctime)s [%(levelname)s] [%(name)s]: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    # Console Handler (StreamHandler)
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(log_format)
    logger.addHandler(console_handler)

    # File Handler
    try:
        LOG_FILE_PATH.parent.mkdir(parents=True, exist_ok=True)
        file_handler = logging.FileHandler(LOG_FILE_PATH, mode="a", encoding="utf-8")
        file_handler.setLevel(logging.INFO)
        file_handler.setFormatter(log_format)
        logger.addHandler(file_handler)
    except Exception as e:
        logger.warning(f"Could not initialize file handler at {LOG_FILE_PATH}: {e}")

    return logger


def get_retry_session(
    retries: int = 5,
    backoff_factor: float = 1.0,
    status_forcelist: tuple = (429, 500, 502, 503, 504),
) -> requests.Session:
    """
    Creates a requests.Session equipped with automatic exponential backoff retry.
    """
    session = requests.Session()
    retry_strategy = Retry(
        total=retries,
        read=retries,
        connect=retries,
        backoff_factor=backoff_factor,
        status_forcelist=status_forcelist,
        raise_on_status=False,
    )
    adapter = HTTPAdapter(max_retries=retry_strategy)
    session.mount("http://", adapter)
    session.mount("https://", adapter)
    return session


def sanitize_filename(code: str) -> str:
    """
    Converts indicator code with dots into a filesystem-safe filename.
    e.g. 'IT.NET.USER.ZS' -> 'IT_NET_USER_ZS'
    """
    return code.replace(".", "_")
