# ==============================================================================
# R/config.R: Cấu hình hệ thống chỉ số, nhóm biến, quốc gia và đường dẫn dự án
# DTA301 - Tác động của hạ tầng số và phổ cập internet đến việc làm tại ASEAN (2010-2025)
# ==============================================================================

# Đảm bảo nạp thư viện cục bộ nếu có
local({
  lib_local <- file.path(getwd(), ".r_lib")
  if (dir.exists(lib_local)) {
    .libPaths(unique(c(lib_local, .libPaths())))
  }
})

# Đường dẫn cơ sở
PROJECT_ROOT <- getwd()
DATA_DIR <- file.path(PROJECT_ROOT, "data")
DATA_RAW_DIR <- file.path(DATA_DIR, "raw")
DATA_PROCESSED_DIR <- file.path(DATA_DIR, "processed")
OUTPUTS_DIR <- file.path(PROJECT_ROOT, "outputs")
OUTPUTS_FIGURES_DIR <- file.path(OUTPUTS_DIR, "figures")
OUTPUTS_TABLES_DIR <- file.path(OUTPUTS_DIR, "tables")

# Đường dẫn các tệp đầu ra cốt lõi
ASEAN_PANEL_PATH <- file.path(DATA_PROCESSED_DIR, "asean_panel.csv")
ASEAN_PANEL_WIDE_PATH <- file.path(DATA_PROCESSED_DIR, "asean_panel_wide.csv")
ASEAN_PANEL_DTA_PATH <- file.path(DATA_PROCESSED_DIR, "asean_panel.dta")
ASEAN_PANEL_DERIVED_PATH <- file.path(DATA_PROCESSED_DIR, "asean_panel_derived.csv")
ASEAN_PANEL_DERIVED_DTA_PATH <- file.path(DATA_PROCESSED_DIR, "asean_panel_derived.dta")
ASEAN_PANEL_CLEAN_PATH <- file.path(DATA_PROCESSED_DIR, "asean_panel_clean.csv")
ASEAN_PANEL_CLEAN_DTA_PATH <- file.path(DATA_PROCESSED_DIR, "asean_panel_clean.dta")
CLEANING_AUDIT_PATH <- file.path(OUTPUTS_TABLES_DIR, "cleaning_audit_report.csv")
METADATA_PATH <- file.path(DATA_RAW_DIR, "metadata.csv")
DATA_DICTIONARY_PATH <- file.path(PROJECT_ROOT, "data_dictionary.csv")
DATA_DICTIONARY_PROCESSED_PATH <- file.path(DATA_PROCESSED_DIR, "data_dictionary.csv")
LOG_FILE_PATH <- file.path(PROJECT_ROOT, "pipeline.log")
OUT_EXCEL_RAW <- file.path(DATA_RAW_DIR, "asean_raw_data.xlsx")
OUT_EXCEL_OUTPUTS <- file.path(OUTPUTS_DIR, "asean_raw_data.xlsx")

# Phạm vi nghiên cứu
START_YEAR <- 2010
END_YEAR <- 2025
YEARS <- START_YEAR:END_YEAR

# 10 Quốc gia ASEAN (chuẩn ISO3)
ASEAN_COUNTRIES <- list(
  "BRN" = list(name_en = "Brunei Darussalam", name_vi = "Brunei"),
  "KHM" = list(name_en = "Cambodia", name_vi = "Campuchia"),
  "IDN" = list(name_en = "Indonesia", name_vi = "Indonesia"),
  "LAO" = list(name_en = "Lao PDR", name_vi = "Lào"),
  "MYS" = list(name_en = "Malaysia", name_vi = "Malaysia"),
  "MMR" = list(name_en = "Myanmar", name_vi = "Myanmar"),
  "PHL" = list(name_en = "Philippines", name_vi = "Philippines"),
  "SGP" = list(name_en = "Singapore", name_vi = "Singapore"),
  "THA" = list(name_en = "Thailand", name_vi = "Thái Lan"),
  "VNM" = list(name_en = "Viet Nam", name_vi = "Việt Nam")
)

ISO3_LIST <- names(ASEAN_COUNTRIES)

# Cấu trúc 6 nhóm chỉ số WDI
INDICATOR_GROUPS <- list(
  "HA_TANG_SO" = list(
    group_name_vi = "Hạ tầng số",
    group_name_en = "Digital Infrastructure",
    indicators = list(
      "IT.NET.USER.ZS" = list(
        short_name = "internet_users",
        name_vi = "Tỷ lệ dân số dùng Internet",
        unit = "% dân số",
        notes = "ITU / WDI. Cá nhân sử dụng internet từ bất kỳ địa điểm nào trong 3 tháng qua.",
        stata_label = "Internet users (% of population)"
      ),
      "IT.NET.BBND.P2" = list(
        short_name = "fixed_broadband",
        name_vi = "Thuê bao băng rộng cố định",
        unit = "Thuê bao / 100 dân",
        notes = "ITU / WDI. Kết nối băng rộng cố định tốc độ >= 256 kbit/s.",
        stata_label = "Fixed broadband subs per 100 people"
      ),
      "IT.CEL.SETS.P2" = list(
        short_name = "mobile_cellular",
        name_vi = "Thuê bao điện thoại di động",
        unit = "Thuê bao / 100 dân",
        notes = "ITU / WDI. Thuê bao mạng di động trả trước và trả sau.",
        stata_label = "Mobile cellular subs per 100 people"
      ),
      "IT.NET.SECR.P6" = list(
        short_name = "secure_servers",
        name_vi = "Máy chủ Internet bảo mật",
        unit = "Máy chủ / 1 triệu dân",
        notes = "Netcraft / WDI. Máy chủ hỗ trợ mã hóa SSL/TLS cho giao dịch trực tuyến.",
        stata_label = "Secure Internet servers per 1M people"
      ),
      "EG.ELC.ACCS.ZS" = list(
        short_name = "electricity_access",
        name_vi = "Tỷ lệ tiếp cận điện lưới",
        unit = "% dân số",
        notes = "World Bank ESMAP. Tỷ lệ dân cư có nguồn cung cấp điện ổn định.",
        stata_label = "Access to electricity (% of population)"
      )
    )
  ),
  "KINH_TE_SO" = list(
    group_name_vi = "Kinh tế số",
    group_name_en = "Digital Economy",
    indicators = list(
      "TX.VAL.ICTG.ZS.UN" = list(
        short_name = "ict_goods_exp",
        name_vi = "Xuất khẩu hàng hóa ICT",
        unit = "% tổng xuất khẩu hàng hóa",
        notes = "UNCTAD / WDI. Máy tính, thiết bị truyền thông, linh kiện điện tử.",
        stata_label = "ICT goods exports (% total goods exports)"
      ),
      "BX.GSR.CCIS.ZS" = list(
        short_name = "ict_serv_exp",
        name_vi = "Xuất khẩu dịch vụ ICT",
        unit = "% xuất khẩu dịch vụ (BoP)",
        notes = "IMF / WDI. Dịch vụ viễn thông, máy tính và xử lý thông tin.",
        stata_label = "ICT service exports (% service exports)"
      ),
      "TX.VAL.TECH.MF.ZS" = list(
        short_name = "hightech_exp",
        name_vi = "Xuất khẩu công nghệ cao",
        unit = "% xuất khẩu hàng chế tạo",
        notes = "UN Comtrade / WDI. Hàng hóa có cường độ nghiên cứu & phát triển (R&D) cao.",
        stata_label = "High-tech exports (% manufactured exports)"
      )
    )
  ),
  "VIEC_LAM_TONG" = list(
    group_name_vi = "Việc làm (Tổng)",
    group_name_en = "Employment (Total)",
    indicators = list(
      "SL.UEM.TOTL.ZS" = list(
        short_name = "unemp_total",
        name_vi = "Tỷ lệ thất nghiệp tổng số (ILO)",
        unit = "% lực lượng lao động",
        notes = "Ước tính mô hình của ILO (modeled ILO estimate), chuẩn hóa quốc tế.",
        stata_label = "Unemployment total (% labor force, ILO)"
      ),
      "SL.UEM.TOTL.NE.ZS" = list(
        short_name = "unemp_total_nat",
        name_vi = "Tỷ lệ thất nghiệp (ước tính quốc gia)",
        unit = "% lực lượng lao động",
        notes = "Dữ liệu khảo sát quốc gia / Tổng cục Thống kê, dùng để đối chiếu với ILO.",
        stata_label = "Unemployment total (% labor force, nat)"
      ),
      "SL.EMP.TOTL.SP.ZS" = list(
        short_name = "emp_rate_total",
        name_vi = "Tỷ lệ việc làm trên dân số (15+)",
        unit = "% dân số 15+",
        notes = "Ước tính mô hình của ILO (modeled ILO estimate).",
        stata_label = "Employment to pop ratio 15+ (%, ILO)"
      ),
      "SL.TLF.CACT.ZS" = list(
        short_name = "labor_force_part",
        name_vi = "Tỷ lệ tham gia lực lượng lao động",
        unit = "% dân số 15+",
        notes = "Ước tính mô hình của ILO (modeled ILO estimate).",
        stata_label = "Labor force participation rate (%, ILO)"
      ),
      "SL.UEM.1524.ZS" = list(
        short_name = "unemp_youth",
        name_vi = "Tỷ lệ thất nghiệp thanh niên (15-24)",
        unit = "% lực lượng lao động 15-24",
        notes = "Ước tính mô hình của ILO (modeled ILO estimate).",
        stata_label = "Youth unemployment 15-24 (%, ILO)"
      ),
      "SL.UEM.NEET.ZS" = list(
        short_name = "youth_neet",
        name_vi = "Tỷ lệ thanh niên NEET (không học, không làm)",
        unit = "% thanh niên",
        notes = "ILOSTAT. Đo lường tỷ lệ thanh niên bị tách khỏi giáo dục và việc làm.",
        stata_label = "Youth NEET (% youth population, ILO)"
      ),
      "SL.UEM.ADVN.ZS" = list(
        short_name = "unemp_adv_edu",
        name_vi = "Thất nghiệp ở lao động trình độ cao",
        unit = "% LLLĐ trình độ cao",
        notes = "ILOSTAT / WDI. Tỷ lệ thất nghiệp ở người có trình độ đại học trở lên.",
        stata_label = "Unemp with advanced edu (% LF adv edu)"
      )
    )
  ),
  "VIEC_LAM_THEO_GIOI" = list(
    group_name_vi = "Việc làm theo giới",
    group_name_en = "Employment by Gender",
    indicators = list(
      "SL.UEM.TOTL.FE.ZS" = list(
        short_name = "unemp_female",
        name_vi = "Tỷ lệ thất nghiệp nữ",
        unit = "% lực lượng lao động nữ",
        notes = "Ước tính mô hình của ILO (modeled ILO estimate).",
        stata_label = "Unemployment female (% female LF, ILO)"
      ),
      "SL.UEM.TOTL.MA.ZS" = list(
        short_name = "unemp_male",
        name_vi = "Tỷ lệ thất nghiệp nam",
        unit = "% lực lượng lao động nam",
        notes = "Ước tính mô hình của ILO (modeled ILO estimate).",
        stata_label = "Unemployment male (% male LF, ILO)"
      ),
      "SL.EMP.TOTL.SP.FE.ZS" = list(
        short_name = "emp_rate_female",
        name_vi = "Tỷ lệ việc làm trên dân số nữ",
        unit = "% dân số nữ 15+",
        notes = "Ước tính mô hình của ILO (modeled ILO estimate).",
        stata_label = "Employment to pop ratio female (%, ILO)"
      ),
      "SL.EMP.TOTL.SP.MA.ZS" = list(
        short_name = "emp_rate_male",
        name_vi = "Tỷ lệ việc làm trên dân số nam",
        unit = "% dân số nam 15+",
        notes = "Ước tính mô hình của ILO (modeled ILO estimate).",
        stata_label = "Employment to pop ratio male (%, ILO)"
      ),
      "SL.TLF.CACT.FE.ZS" = list(
        short_name = "labor_force_part_fe",
        name_vi = "Tỷ lệ tham gia LLLĐ nữ",
        unit = "% dân số nữ 15+",
        notes = "Ước tính mô hình của ILO (modeled ILO estimate).",
        stata_label = "Labor force part rate female (%, ILO)"
      )
    )
  ),
  "CO_CAU_CHAT_LUONG" = list(
    group_name_vi = "Cơ cấu và chất lượng việc làm",
    group_name_en = "Employment Structure & Quality",
    indicators = list(
      "SL.AGR.EMPL.ZS" = list(
        short_name = "emp_agriculture",
        name_vi = "Tỷ lệ việc làm trong nông nghiệp",
        unit = "% tổng việc làm",
        notes = "Ước tính mô hình của ILO (modeled ILO estimate).",
        stata_label = "Employment in agriculture (% total, ILO)"
      ),
      "SL.IND.EMPL.ZS" = list(
        short_name = "emp_industry",
        name_vi = "Tỷ lệ việc làm trong công nghiệp",
        unit = "% tổng việc làm",
        notes = "Ước tính mô hình của ILO (modeled ILO estimate).",
        stata_label = "Employment in industry (% total, ILO)"
      ),
      "SL.SRV.EMPL.ZS" = list(
        short_name = "emp_services",
        name_vi = "Tỷ lệ việc làm trong dịch vụ",
        unit = "% tổng việc làm",
        notes = "Ước tính mô hình của ILO (modeled ILO estimate).",
        stata_label = "Employment in services (% total, ILO)"
      ),
      "SL.EMP.VULN.ZS" = list(
        short_name = "emp_vulnerable",
        name_vi = "Tỷ lệ việc làm dễ bị tổn thương",
        unit = "% tổng việc làm",
        notes = "Ước tính mô hình của ILO. Tổng lao động tự doanh và lao động gia đình.",
        stata_label = "Vulnerable employment (% total, ILO)"
      ),
      "SL.EMP.WORK.ZS" = list(
        short_name = "emp_wage_salaried",
        name_vi = "Lao động làm công ăn lương",
        unit = "% tổng việc làm",
        notes = "Ước tính mô hình của ILO. Đại diện cho việc làm khu vực chính thức.",
        stata_label = "Wage and salaried workers (% total, ILO)"
      ),
      "SL.EMP.SELF.ZS" = list(
        short_name = "emp_self",
        name_vi = "Lao động tự làm việc (tự doanh)",
        unit = "% tổng việc làm",
        notes = "Ước tính mô hình của ILO (tự chủ kinh doanh, hộ gia đình).",
        stata_label = "Self-employed workers (% total, ILO)"
      ),
      "SL.GDP.PCAP.EM.KD" = list(
        short_name = "labor_productivity",
        name_vi = "Năng suất lao động (GDP/lao động)",
        unit = "USD PPP 2021",
        notes = "ILOSTAT / WDI. GDP bình quân chia tổng số lao động có việc làm.",
        stata_label = "GDP per person employed (const 2021 PPP)"
      )
    )
  ),
  "KIEM_SOAT" = list(
    group_name_vi = "Biến kiểm soát kinh tế vĩ mô & xã hội",
    group_name_en = "Control Variables",
    indicators = list(
      "NY.GDP.PCAP.PP.KD" = list(
        short_name = "gdp_pc_ppp",
        name_vi = "GDP bình quân đầu người (PPP)",
        unit = "USD quốc tế 2021",
        notes = "World Bank ICP. Đo lường mức thu nhập bình quân theo giá trị sức mua tương đương.",
        stata_label = "GDP per capita PPP (const 2021 intl $)"
      ),
      "NY.GDP.MKTP.KD.ZG" = list(
        short_name = "gdp_growth",
        name_vi = "Tăng trưởng GDP hàng năm",
        unit = "% hàng năm",
        notes = "World Bank national accounts. Tăng trưởng kinh tế thực tế theo đồng nội tệ.",
        stata_label = "GDP growth (annual %)"
      ),
      "NE.TRD.GNFS.ZS" = list(
        short_name = "trade_openness",
        name_vi = "Độ mở thương mại",
        unit = "% GDP",
        notes = "World Bank / OECD. (Xuất khẩu + Nhập khẩu) / GDP.",
        stata_label = "Trade openness (% of GDP)"
      ),
      "BX.KLT.DINV.WD.GD.ZS" = list(
        short_name = "fdi_net_inflows",
        name_vi = "Dòng vốn FDI ròng",
        unit = "% GDP",
        notes = "IMF / World Bank. Vốn đầu tư trực tiếp nước ngoài ròng đổ vào quốc gia.",
        stata_label = "FDI net inflows (% of GDP)"
      ),
      "SP.URB.TOTL.IN.ZS" = list(
        short_name = "urban_pop_rate",
        name_vi = "Tỷ lệ dân số đô thị",
        unit = "% tổng dân số",
        notes = "UN Population Division / WDI. Tỷ lệ dân cư sinh sống tại khu vực thành thị.",
        stata_label = "Urban population (% of total pop)"
      ),
      "SE.TER.ENRR" = list(
        short_name = "tertiary_edu_enr",
        name_vi = "Tỷ lệ nhập học đại học/cao đẳng",
        unit = "% thô",
        notes = "UNESCO Institute for Statistics. Phản ánh mức độ tích lũy vốn con người bậc cao.",
        stata_label = "Gross tertiary school enrollment (%)"
      ),
      "SP.POP.TOTL" = list(
        short_name = "pop_total",
        name_vi = "Tổng dân số",
        unit = "Người",
        notes = "Ước tính dân số giữa năm của Liên Hợp Quốc và World Bank.",
        stata_label = "Population, total"
      ),
      "SP.POP.1564.TO.ZS" = list(
        short_name = "pop_working_age",
        name_vi = "Tỷ lệ dân số 15-64 tuổi",
        unit = "% tổng dân số",
        notes = "UN Population Division / WDI. Tỷ trọng dân số trong độ tuổi lao động vàng.",
        stata_label = "Population ages 15-64 (% of total pop)"
      ),
      "FP.CPI.TOTL.ZG" = list(
        short_name = "inflation_cpi",
        name_vi = "Tỷ lệ lạm phát (CPI)",
        unit = "% hàng năm",
        notes = "IMF International Financial Statistics. Biến động chỉ số giá tiêu dùng bình quân.",
        stata_label = "Inflation, consumer prices (annual %)"
      )
    )
  )
)

# Danh sách biến hạ tầng số để tạo trễ
DIGITAL_INFRA_VARS <- c(
  "internet_users",
  "fixed_broadband",
  "mobile_cellular",
  "secure_servers",
  "electricity_access"
)

# Danh mục các biến phái sinh kinh tế lượng
DERIVED_VARIABLES <- list(
  "ln_gdp_pc" = list(
    name_vi = "Logarit tự nhiên của GDP/người (PPP)",
    unit = "log(USD)",
    group_name_vi = "Biến phái sinh",
    notes = "ln(gdp_pc_ppp) dùng để tuyến tính hóa quan hệ và đo lường hệ số co giãn.",
    stata_label = "Log GDP per capita (PPP)"
  ),
  "ln_pop" = list(
    name_vi = "Logarit tự nhiên của tổng dân số",
    unit = "log(người)",
    group_name_vi = "Biến phái sinh",
    notes = "ln(pop_total) kiểm soát quy mô thị trường.",
    stata_label = "Log total population"
  ),
  "diff_internet_users" = list(
    name_vi = "Mức thay đổi hàng năm tỷ lệ dùng internet",
    unit = "Điểm phần trăm",
    group_name_vi = "Biến phái sinh",
    notes = "Delta Internet = Internet(t) - Internet(t-1) theo từng nước.",
    stata_label = "Annual change in internet users (% pt)"
  ),
  "diff_unemp_total" = list(
    name_vi = "Mức thay đổi hàng năm tỷ lệ thất nghiệp",
    unit = "Điểm phần trăm",
    group_name_vi = "Biến phái sinh",
    notes = "Delta Thất nghiệp = Unemp(t) - Unemp(t-1) theo từng nước.",
    stata_label = "Annual change in unemp (% pt)"
  ),
  "gap_unemp_gender" = list(
    name_vi = "Khoảng cách giới trong thất nghiệp (Nữ - Nam)",
    unit = "Điểm phần trăm",
    group_name_vi = "Biến phái sinh",
    notes = "unemp_female - unemp_male. Giá trị dương nghĩa là nữ thất nghiệp cao hơn nam.",
    stata_label = "Gender gap in unemp (female - male)"
  ),
  "gap_emp_gender" = list(
    name_vi = "Khoảng cách giới trong việc làm (Nữ - Nam)",
    unit = "Điểm phần trăm",
    group_name_vi = "Biến phái sinh",
    notes = "emp_rate_female - emp_rate_male.",
    stata_label = "Gender gap in emp rate (female - male)"
  ),
  "covid" = list(
    name_vi = "Biến giả đại dịch COVID-19",
    unit = "Nhị phân (0/1)",
    group_name_vi = "Biến phái sinh",
    notes = "Gán 1 cho các năm 2020 và 2021; 0 cho các năm khác.",
    stata_label = "COVID-19 pandemic dummy (2020-2021)"
  ),
  "myanmar_post2021" = list(
    name_vi = "Biến giả biến động chính trị Myanmar",
    unit = "Nhị phân (0/1)",
    group_name_vi = "Biến phái sinh",
    notes = "Gán 1 cho Myanmar (MMR) từ năm 2021 trở đi; 0 cho các trường hợp còn lại.",
    stata_label = "Myanmar crisis dummy (MMR >= 2021)"
  ),
  "high_income" = list(
    name_vi = "Biến giả nhóm thu nhập cao (Singapore, Brunei)",
    unit = "Nhị phân (0/1)",
    group_name_vi = "Biến phái sinh",
    notes = "Gán 1 cho Singapore (SGP) và Brunei (BRN); 0 cho 8 nước ASEAN còn lại.",
    stata_label = "High income ASEAN dummy (SGP, BRN)"
  )
)

# Thêm biến trễ L1 và L2 của hạ tầng số
for (v in DIGITAL_INFRA_VARS) {
  DERIVED_VARIABLES[[paste0("lag1_", v)]] <- list(
    name_vi = sprintf("Biến trễ 1 năm (L1) của %s", v),
    unit = "Theo biến gốc",
    group_name_vi = "Biến phái sinh",
    notes = sprintf("Trễ 1 năm L1 của biến hạ tầng số %s theo từng nước.", v),
    stata_label = substr(sprintf("Lag 1 of %s", v), 1, 80)
  )
  DERIVED_VARIABLES[[paste0("lag2_", v)]] <- list(
    name_vi = sprintf("Biến trễ 2 năm (L2) của %s", v),
    unit = "Theo biến gốc",
    group_name_vi = "Biến phái sinh",
    notes = sprintf("Trễ 2 năm L2 của biến hạ tầng số %s theo từng nước.", v),
    stata_label = substr(sprintf("Lag 2 of %s", v), 1, 80)
  )
}

# Bản đồ tra cứu phẳng
ALL_INDICATORS <- list()
SHORT_TO_WDI <- list()
WDI_TO_SHORT <- list()
WDI_TO_GROUP <- list()
STATA_VARIABLE_LABELS <- list(
  "iso3" = "ISO-3 Country Code",
  "country" = "Country Name",
  "year" = "Calendar Year"
)

for (grp_key in names(INDICATOR_GROUPS)) {
  grp_data <- INDICATOR_GROUPS[[grp_key]]
  for (wdi_code in names(grp_data$indicators)) {
    ind_data <- grp_data$indicators[[wdi_code]]
    s_name <- ind_data$short_name
    
    ind_data$group_key <- grp_key
    ind_data$group_name_vi <- grp_data$group_name_vi
    ind_data$group_name_en <- grp_data$group_name_en
    
    ALL_INDICATORS[[wdi_code]] <- ind_data
    SHORT_TO_WDI[[s_name]] <- wdi_code
    WDI_TO_SHORT[[wdi_code]] <- s_name
    WDI_TO_GROUP[[wdi_code]] <- grp_key
    STATA_VARIABLE_LABELS[[s_name]] <- ind_data$stata_label
  }
}

for (der_var in names(DERIVED_VARIABLES)) {
  STATA_VARIABLE_LABELS[[der_var]] <- DERIVED_VARIABLES[[der_var]]$stata_label
}
