"""
Export raw ASEAN panel data and metadata to a beautifully formatted Excel (.xlsx) file.
Produces:
- data/raw/asean_raw_data.xlsx
- outputs/asean_raw_data.xlsx
"""

import os
from pathlib import Path
import pandas as pd
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_RAW_DIR = PROJECT_ROOT / "data" / "raw"
DATA_PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"
OUTPUTS_DIR = PROJECT_ROOT / "outputs"
OUTPUTS_TABLES_DIR = OUTPUTS_DIR / "tables"

OUT_EXCEL_RAW = DATA_RAW_DIR / "asean_raw_data.xlsx"
OUT_EXCEL_OUTPUTS = OUTPUTS_DIR / "asean_raw_data.xlsx"

def create_raw_excel():
    print(f"Loading raw datasets from {PROJECT_ROOT}...")

    # 1. Base Panel Long (Raw)
    panel_long_path = DATA_PROCESSED_DIR / "asean_panel.csv"
    df_panel_long = pd.read_csv(panel_long_path)

    # 2. Base Panel Wide (Raw)
    panel_wide_path = DATA_PROCESSED_DIR / "asean_panel_wide.csv"
    df_panel_wide = pd.read_csv(panel_wide_path)

    # 3. Metadata Catalog
    metadata_path = DATA_RAW_DIR / "metadata.csv"
    df_metadata = pd.read_csv(metadata_path)

    # 4. Data Dictionary (filter for raw variables only, is_derived == False or Scaffold)
    dict_path = PROJECT_ROOT / "data_dictionary.csv"
    df_dict = pd.read_csv(dict_path)
    if "is_derived" in df_dict.columns:
        df_dict_raw = df_dict[df_dict["is_derived"] == False].copy()
    else:
        df_dict_raw = df_dict.copy()

    # 5. All Raw Indicator records concatenated (5400 rows)
    raw_files = list(DATA_RAW_DIR.glob("*.csv"))
    raw_dfs = []
    for f in raw_files:
        if f.name == "metadata.csv":
            continue
        try:
            temp_df = pd.read_csv(f)
            if {"indicator_code", "iso3", "year", "value"}.issubset(temp_df.columns):
                raw_dfs.append(temp_df)
        except Exception as e:
            print(f"Skipping {f.name}: {e}")
    
    if raw_dfs:
        df_all_indicators = pd.concat(raw_dfs, ignore_index=True)
        # Sort by indicator_code, iso3, year
        df_all_indicators = df_all_indicators.sort_values(by=["indicator_code", "iso3", "year"]).reset_index(drop=True)
    else:
        df_all_indicators = pd.DataFrame()

    # 6. Readme Overview Table
    readme_data = [
        {"Thông tin": "Tên dự án", "Nội dung": "DTA301 - ASEAN Digital Infrastructure & Employment"},
        {"Thông tin": "Nội dung tệp", "Nội dung": "Dữ liệu thô (Raw Data) từ World Bank World Development Indicators (WDI)"},
        {"Thông tin": "Phạm vi không gian", "Nội dung": "10 quốc gia ASEAN (BRN, KHM, IDN, LAO, MYS, MMR, PHL, SGP, THA, VNM)"},
        {"Thông tin": "Phạm vi thời gian", "Nội dung": "2010 - 2024 (15 năm)"},
        {"Thông tin": "Số lượng quan sát", "Nội dung": "150 quan sát cấp quốc gia - năm (Balanced Panel scaffold)"},
        {"Thông tin": "Số lượng chỉ số thô", "Nội dung": "36 chỉ số chính thức từ WDI (chưa qua imputation hay winsorization)"},
        {"Thông tin": "Sheet: Panel_Raw_Long", "Nội dung": "Bảng dữ liệu thô dạng Long Panel (150 dòng x 39 cột: country, iso3, year + 36 chỉ số)"},
        {"Thông tin": "Sheet: Panel_Raw_Wide", "Nội dung": "Bảng dữ liệu thô dạng Wide (10 dòng cho 10 quốc gia x 540 cột biến theo từng năm)"},
        {"Thông tin": "Sheet: All_Indicators_Long", "Nội dung": "Tất cả 5.400 bản ghi thô ghép nối trực tiếp từ các file API (gồm mã chỉ số, tên, giá trị)"},
        {"Thông tin": "Sheet: Metadata_Catalog", "Nội dung": "Danh mục chi tiết 36 chỉ số: mã WDI, tên tiếng Việt/Anh, đơn vị, tổ chức nguồn, ghi chú"},
        {"Thông tin": "Sheet: Data_Dictionary_Raw", "Nội dung": "Từ điển dữ liệu cho 39 biến số thô (mô tả, nhóm chỉ số, đơn vị, nhãn Stata)"},
        {"Thông tin": "Sheet: Countries", "Nội dung": "Danh sách 10 quốc gia ASEAN và mã ISO3 tương ứng"},
    ]
    df_readme = pd.DataFrame(readme_data)

    # 7. Countries
    countries_data = [
        {"iso3": "BRN", "country_en": "Brunei Darussalam", "country_vi": "Brunei"},
        {"iso3": "KHM", "country_en": "Cambodia", "country_vi": "Campuchia"},
        {"iso3": "IDN", "country_en": "Indonesia", "country_vi": "Indonesia"},
        {"iso3": "LAO", "country_en": "Lao PDR", "country_vi": "Lào"},
        {"iso3": "MYS", "country_en": "Malaysia", "country_vi": "Malaysia"},
        {"iso3": "MMR", "country_en": "Myanmar", "country_vi": "Myanmar"},
        {"iso3": "PHL", "country_en": "Philippines", "country_vi": "Philippines"},
        {"iso3": "SGP", "country_en": "Singapore", "country_vi": "Singapore"},
        {"iso3": "THA", "country_en": "Thailand", "country_vi": "Thái Lan"},
        {"iso3": "VNM", "country_en": "Viet Nam", "country_vi": "Việt Nam"},
    ]
    df_countries = pd.DataFrame(countries_data)

    print("Writing to Excel workbook...")
    sheets = {
        "Readme_Overview": df_readme,
        "Panel_Raw_Long": df_panel_long,
        "Panel_Raw_Wide": df_panel_wide,
        "All_Indicators_Long": df_all_indicators,
        "Metadata_Catalog": df_metadata,
        "Data_Dictionary_Raw": df_dict_raw,
        "Countries": df_countries,
    }

    # Write using openpyxl for high-end formatting
    wb = openpyxl.Workbook()
    wb.remove(wb.active)  # remove default sheet

    header_font = Font(name="Segoe UI", size=11, bold=True, color="FFFFFF")
    header_fill = PatternFill(start_color="1F4E79", end_color="1F4E79", fill_type="solid")
    regular_font = Font(name="Segoe UI", size=10)
    thin_border = Border(
        left=Side(style="thin", color="D9D9D9"),
        right=Side(style="thin", color="D9D9D9"),
        top=Side(style="thin", color="D9D9D9"),
        bottom=Side(style="thin", color="D9D9D9"),
    )
    header_border = Border(
        left=Side(style="thin", color="1B365D"),
        right=Side(style="thin", color="1B365D"),
        top=Side(style="medium", color="1B365D"),
        bottom=Side(style="medium", color="1B365D"),
    )

    for sheet_name, df in sheets.items():
        ws = wb.create_sheet(title=sheet_name)
        ws.views.sheetView[0].showGridLines = True

        # Header
        headers = list(df.columns)
        ws.append(headers)
        ws.row_dimensions[1].height = 28

        for col_idx, h in enumerate(headers, start=1):
            cell = ws.cell(row=1, column=col_idx)
            cell.font = header_font
            cell.fill = header_fill
            cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
            cell.border = header_border

        # Rows
        # Replace NaN with empty string or None for clean representation
        records = df.where(pd.notnull(df), None).values.tolist()
        for row_idx, row_val in enumerate(records, start=2):
            ws.append(row_val)
            ws.row_dimensions[row_idx].height = 20
            for col_idx, val in enumerate(row_val, start=1):
                cell = ws.cell(row=row_idx, column=col_idx)
                cell.font = regular_font
                cell.border = thin_border
                
                # Alignments and number format
                if isinstance(val, (int, float)):
                    if isinstance(val, int) or (isinstance(val, float) and val.is_integer()):
                        cell.number_format = '#,##0'
                    else:
                        cell.number_format = '#,##0.0000'
                    cell.alignment = Alignment(horizontal="right", vertical="center")
                elif isinstance(val, str) and len(val) <= 10 and (val.isupper() or val.isdigit()):
                    cell.alignment = Alignment(horizontal="center", vertical="center")
                else:
                    cell.alignment = Alignment(horizontal="left", vertical="center")

        # Freeze panes
        if sheet_name == "Panel_Raw_Long":
            ws.freeze_panes = "D2"  # Freeze country, iso3, year
        elif sheet_name == "Panel_Raw_Wide":
            ws.freeze_panes = "C2"  # Freeze iso3, country
        elif sheet_name == "Readme_Overview":
            ws.freeze_panes = "A2"
        else:
            ws.freeze_panes = "A2"

        # Auto-adjust column width (capped between 12 and 60)
        for col_idx, col in enumerate(ws.columns, start=1):
            max_len = 0
            # sample up to 100 rows to determine width
            sample_cells = [col[0]] + list(col[1:min(100, len(col))])
            for cell in sample_cells:
                if cell.value is not None:
                    s_len = len(str(cell.value))
                    if s_len > max_len:
                        max_len = s_len
            col_letter = get_column_letter(col_idx)
            calc_width = max(max_len + 4, 12)
            ws.column_dimensions[col_letter].width = min(calc_width, 60)

    # Save to both data/raw and outputs/
    OUT_EXCEL_RAW.parent.mkdir(parents=True, exist_ok=True)
    OUT_EXCEL_OUTPUTS.parent.mkdir(parents=True, exist_ok=True)
    
    wb.save(OUT_EXCEL_RAW)
    print(f"Saved raw excel workbook to: {OUT_EXCEL_RAW}")
    
    wb.save(OUT_EXCEL_OUTPUTS)
    print(f"Saved copy to: {OUT_EXCEL_OUTPUTS}")

if __name__ == "__main__":
    create_raw_excel()
