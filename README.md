# DTA301: Assignment Cuối Kỳ Phân Tích Dữ Liệu Kinh Tế
## Đề tài: "Tác động của hạ tầng số và phổ cập internet đến việc làm tại các nước ASEAN, giai đoạn 2010–2024"

---

## 1. Giới thiệu tổng quan

Dự án này là hệ thống xử lý, làm sạch và chuẩn bị dữ liệu bảng (panel data) tự động cho assignment cuối kỳ môn Phân tích Dữ liệu (DTA301). Mục tiêu là xây dựng bộ dữ liệu kinh tế lượng đa chiều, phong phú và chuẩn mực từ cơ sở dữ liệu **World Development Indicators (WDI)** của Ngân hàng Thế giới (World Bank) nhằm nghiên cứu mối quan hệ nhân quả và tác động của hạ tầng số, phổ cập internet đến cơ cấu việc làm, thất nghiệp và năng suất lao động tại 10 quốc gia Đông Nam Á (ASEAN).

### Phạm vi nghiên cứu
- **Không gian:** 10 quốc gia thành viên ASEAN (chuẩn ISO3):
  `BRN` (Brunei), `KHM` (Campuchia), `IDN` (Indonesia), `LAO` (Lào), `MYS` (Malaysia), `MMR` (Myanmar), `PHL` (Philippines), `SGP` (Singapore), `THA` (Thái Lan), `VNM` (Việt Nam).
- **Thời gian:** 15 năm liên tục, từ năm **2010** đến năm **2024**.
- **Kích thước bảng cân bằng (Balanced Panel Scaffold):** 10 quốc gia $\times$ 15 năm = **150 quan sát (Country-Year observations)**.

---

## 2. Cấu trúc thư mục dự án

```text
DTA301/
├── data/
│   ├── raw/                           # Dữ liệu thô từng chỉ số tải từ World Bank API
│   │   ├── metadata.csv               # Danh mục metadata: mã, tên, đơn vị, nguồn, ngày tải
│   │   ├── IT_NET_USER_ZS.csv         # Tỷ lệ dân số dùng Internet
│   │   ├── SL_UEM_TOTL_ZS.csv         # Tỷ lệ thất nghiệp tổng số (ILO)
│   │   └── ... (36 tệp CSV thô)
│   └── processed/                     # Dữ liệu đã làm sạch và các biến phái sinh
│       ├── asean_panel.csv            # Bảng panel gốc dạng Long (150 dòng x 39 cột)
│       ├── asean_panel_wide.csv       # Bảng panel dạng Wide (10 dòng x 542 cột)
│       ├── asean_panel.dta            # Định dạng Stata 118 có gán nhãn biến (variable labels)
│       ├── asean_panel_derived.csv    # Bảng panel mở rộng chứa các biến phái sinh (150 dòng x 58 cột)
│       ├── asean_panel_derived.dta    # Dữ liệu phái sinh cho Stata
│       └── data_dictionary.csv        # Bản sao từ điển dữ liệu
├── outputs/
│   ├── figures/                       # Trực quan hóa kiểm toán chất lượng và xu hướng
│   │   ├── missing_heatmap_country_var.png   # Heatmap tỷ lệ thiếu theo Quốc gia x Biến
│   │   ├── missing_heatmap_year_var.png      # Heatmap tỷ lệ thiếu theo Năm x Biến
│   │   ├── missing_matrix.png                # Ma trận khuyết thiếu 150 quan sát x Biến
│   │   └── internet_vs_unemployment_trends.png # Biểu đồ chuỗi thời gian Internet & Thất nghiệp
│   └── tables/                        # Báo cáo kiểm toán dữ liệu và thống kê mô tả
│       ├── missing_by_country.csv     # Thống kê tỷ lệ khuyết thiếu theo quốc gia
│       ├── missing_by_variable.csv    # Thống kê tỷ lệ khuyết thiếu theo từng biến
│       ├── missing_by_year.csv        # Thống kê tỷ lệ khuyết thiếu theo năm
│       ├── complete_cases_by_group.csv # Số quan sát đầy đủ theo nhóm biến
│       ├── outliers_zscore.csv        # Danh sách giá trị ngoại lai (|Z-score| > 3)
│       ├── outliers_jumps.csv         # Danh sách bất thường bước nhảy hàng năm (|Delta| > 3*std)
│       ├── summary_stats_overall.csv  # Thống kê mô tả tổng thể (mean, sd, min, max, p25, median, p75, skew)
│       └── summary_stats_by_country.csv # Thống kê mô tả theo từng nước ASEAN
├── src/                               # Mã nguồn module hóa
│   ├── __init__.py
│   ├── config.py                      # Cấu hình danh mục chỉ số, nhóm biến, quốc gia, nhãn Stata
│   ├── utils.py                       # Logger UTF-8, HTTP retry session với exponential backoff
│   ├── fetcher.py                     # Thu thập API World Bank v2, lưu raw CSV & metadata
│   ├── cleaner.py                     # Lập dàn bảng panel, merge biến, xuất CSV long/wide và Stata
│   ├── feature_engineering.py         # Tạo log, trễ L1/L2, sai phân diff, khoảng cách giới, biến giả
│   └── quality_reporter.py            # Kiểm toán missing, outliers, complete cases và vẽ biểu đồ
├── data_dictionary.csv                # Từ điển dữ liệu toàn diện (58 biến)
├── main.py                            # Tệp thực thi toàn bộ pipeline từ đầu đến cuối
├── requirements.txt                   # Danh sách thư viện phụ thuộc
└── README.md                          # Tài liệu hướng dẫn sử dụng chi tiết
```

---

## 3. Hệ thống chỉ số nghiên cứu (World Bank WDI)

Dự án thu thập **36 chỉ số gốc** được phân thành **6 nhóm logic** trong [`src/config.py`](file:///c:/Users/NGUYENLONG/Desktop/DTA301/src/config.py):

### Nhóm 1: Hạ tầng số (Digital Infrastructure)
1. `IT.NET.USER.ZS` (`internet_users`): Tỷ lệ dân số dùng Internet (% dân số).
2. `IT.NET.BBND.P2` (`fixed_broadband`): Thuê bao băng rộng cố định (trên 100 dân).
3. `IT.CEL.SETS.P2` (`mobile_cellular`): Thuê bao di động (trên 100 dân).
4. `IT.NET.SECR.P6` (`secure_servers`): Máy chủ Internet bảo mật SSL/TLS (trên 1 triệu dân).
5. `EG.ELC.ACCS.ZS` (`electricity_access`): Tỷ lệ tiếp cận điện lưới (% dân số - điều kiện tiên quyết cho chuyển đổi số).

### Nhóm 2: Kinh tế số & Công nghệ (Digital Economy)
6. `TX.VAL.ICTG.ZS.UN` (`ict_goods_exp`): Xuất khẩu hàng hóa ICT (% tổng xuất khẩu hàng hóa).
7. `BX.GSR.CCIS.ZS` (`ict_serv_exp`): Xuất khẩu dịch vụ ICT (% xuất khẩu dịch vụ, BoP).
8. `TX.VAL.TECH.MF.ZS` (`hightech_exp`): Xuất khẩu công nghệ cao (% xuất khẩu hàng chế biến chế tạo).

### Nhóm 3: Việc làm tổng thể (Employment - Total)
9. `SL.UEM.TOTL.ZS` (`unemp_total`): Tỷ lệ thất nghiệp tổng số (% LLLĐ, ước tính mô hình ILO).
10. `SL.UEM.TOTL.NE.ZS` (`unemp_total_nat`): Tỷ lệ thất nghiệp (% LLLĐ, ước tính quốc gia - dùng đối chiếu).
11. `SL.EMP.TOTL.SP.ZS` (`emp_rate_total`): Tỷ lệ việc làm trên dân số từ 15 tuổi trở lên (%).
12. `SL.TLF.CACT.ZS` (`labor_force_part`): Tỷ lệ tham gia lực lượng lao động (%).
13. `SL.UEM.1524.ZS` (`unemp_youth`): Tỷ lệ thất nghiệp thanh niên 15–24 tuổi (%).
14. `SL.UEM.NEET.ZS` (`youth_neet`): Tỷ lệ thanh niên không có việc làm, không đi học hay đào tạo (NEET, %).
15. `SL.UEM.ADVN.ZS` (`unemp_adv_edu`): Tỷ lệ thất nghiệp ở lao động có trình độ học vấn cao (%).

### Nhóm 4: Việc làm theo giới tính (Employment by Gender)
16. `SL.UEM.TOTL.FE.ZS` (`unemp_female`): Tỷ lệ thất nghiệp nữ (% LLLĐ nữ).
17. `SL.UEM.TOTL.MA.ZS` (`unemp_male`): Tỷ lệ thất nghiệp nam (% LLLĐ nam).
18. `SL.EMP.TOTL.SP.FE.ZS` (`emp_rate_female`): Tỷ lệ việc làm trên dân số nữ (%).
19. `SL.EMP.TOTL.SP.MA.ZS` (`emp_rate_male`): Tỷ lệ việc làm trên dân số nam (%).
20. `SL.TLF.CACT.FE.ZS` (`labor_force_part_fe`): Tỷ lệ tham gia lực lượng lao động nữ (%).

### Nhóm 5: Cơ cấu và chất lượng việc làm (Structure & Quality of Employment)
21. `SL.AGR.EMPL.ZS` (`emp_agriculture`): Việc làm trong nông nghiệp (% tổng việc làm).
22. `SL.IND.EMPL.ZS` (`emp_industry`): Việc làm trong công nghiệp (% tổng việc làm).
23. `SL.SRV.EMPL.ZS` (`emp_services`): Việc làm trong dịch vụ (% tổng việc làm).
24. `SL.EMP.VULN.ZS` (`emp_vulnerable`): Việc làm dễ bị tổn thương (% tổng việc làm).
25. `SL.EMP.WORK.ZS` (`emp_wage_salaried`): Lao động làm công hưởng lương (% việc làm chính thức).
26. `SL.EMP.SELF.ZS` (`emp_self`): Lao động tự doanh/hộ gia đình (% tổng việc làm).
27. `SL.GDP.PCAP.EM.KD` (`labor_productivity`): Năng suất lao động (GDP trên mỗi người có việc làm, USD PPP 2021).

### Nhóm 6: Biến kiểm soát kinh tế vĩ mô & xã hội (Controls)
28. `NY.GDP.PCAP.PP.KD` (`gdp_pc_ppp`): GDP bình quân đầu người theo sức mua tương đương (PPP, constant 2021 intl $).
29. `NY.GDP.MKTP.KD.ZG` (`gdp_growth`): Tốc độ tăng trưởng GDP hàng năm (%).
30. `NE.TRD.GNFS.ZS` (`trade_openness`): Độ mở thương mại (% GDP).
31. `BX.KLT.DINV.WD.GD.ZS` (`fdi_net_inflows`): Dòng vốn đầu tư trực tiếp nước ngoài FDI ròng (% GDP).
32. `SP.URB.TOTL.IN.ZS` (`urban_pop_rate`): Tỷ lệ dân số đô thị (% tổng dân số).
33. `SE.TER.ENRR` (`tertiary_edu_enr`): Tỷ lệ nhập học bậc đại học/cao đẳng (thô, %).
34. `SP.POP.TOTL` (`pop_total`): Tổng quy mô dân số (người).
35. `SP.POP.1564.TO.ZS` (`pop_working_age`): Tỷ lệ dân số trong độ tuổi lao động 15–64 (%).
36. `FP.CPI.TOTL.ZG` (`inflation_cpi`): Tỷ lệ lạm phát CPI hàng năm (%).

---

## 4. Các biến phái sinh kinh tế lượng (`asean_panel_derived.csv`)

Theo yêu cầu phương pháp luận phân tích bảng:
1. **Biến đổi phi tuyến (Logarithm):**
   - `ln_gdp_pc`: $\ln(\text{gdp\_pc\_ppp})$ tuyến tính hóa mối quan hệ với thu nhập và đo lường độ co giãn.
   - `ln_pop`: $\ln(\text{pop\_total})$ kiểm soát quy mô nền kinh tế.
2. **Biến trễ hạ tầng số (Lags L1 & L2):**
   - Việc đầu tư và mở rộng hạ tầng số (internet, băng rộng cố định, mạng di động) thường có độ trễ truyền dẫn (time-to-build & adoption lag) đối với thị trường lao động.
   - Các biến trễ được tính toán theo từng quốc gia (`groupby('iso3')`):
     - `lag1_internet_users`, `lag2_internet_users`
     - `lag1_fixed_broadband`, `lag2_fixed_broadband`
     - `lag1_mobile_cellular`, `lag2_mobile_cellular`
     - `lag1_secure_servers`, `lag2_secure_servers`
     - `lag1_electricity_access`, `lag2_electricity_access`
3. **Mức thay đổi hàng năm (Annual Differences / Sai phân bậc 1):**
   - $\Delta \text{Internet} = \text{Internet}_{i,t} - \text{Internet}_{i,t-1}$ (`diff_internet_users`)
   - $\Delta \text{Unemployment} = \text{Unemp}_{i,t} - \text{Unemp}_{i,t-1}$ (`diff_unemp_total`)
4. **Khoảng cách giới (Gender Disparities):**
   - `gap_unemp_gender` = $\text{Unemployment}_{\text{Female}} - \text{Unemployment}_{\text{Male}}$
   - `gap_emp_gender` = $\text{Employment Rate}_{\text{Female}} - \text{Employment Rate}_{\text{Male}}$
5. **Biến giả chính sách và cú sốc ngoại sinh (Dummy Variables):**
   - `covid`: Gán giá trị 1 cho các năm 2020 và 2021 (giai đoạn giãn cách xã hội và đứt gãy thị trường lao động do dịch bệnh), 0 cho các năm khác.
   - `myanmar_post2021`: Gán giá trị 1 cho Myanmar (`MMR`) từ năm 2021 trở đi (kiểm soát biến động chính trị nội bộ), 0 cho các nước hoặc năm khác.
   - `high_income`: Gán giá trị 1 cho nhóm nước thu nhập cao phát triển vượt trội trong ASEAN (`SGP` - Singapore và `BRN` - Brunei), 0 cho 8 quốc gia đang phát triển còn lại.

---

## 5. Hướng dẫn cài đặt và thực thi

### Yêu cầu môi trường
- Python 3.10 trở lên.
- Các thư viện chuẩn trong [`requirements.txt`](file:///c:/Users/NGUYENLONG/Desktop/DTA301/requirements.txt):
  ```bash
  pip install -r requirements.txt
  ```

### Chạy toàn bộ quy trình bằng một lệnh duy nhất
Tại thư mục gốc của dự án, thực hiện lệnh:
```bash
python main.py
```

### Các bước mà `main.py` tự động thực hiện:
1. **Kết nối World Bank API v2:** Gửi truy vấn HTTP có gắn cơ chế retry (exponential backoff) đối với từng chỉ số cho 10 nước ASEAN giai đoạn 2010–2024. Nếu chỉ số gặp lỗi mạng, hệ thống ghi log cảnh báo và tiếp tục chạy mà không gián đoạn.
2. **Lưu dữ liệu thô:** Lưu 36 file CSV vào `data/raw/` cùng catalog `data/raw/metadata.csv`.
3. **Làm sạch và gộp bảng Panel:** Ghép 36 chỉ số vào khung bảng chuẩn 150 dòng (10 nước $\times$ 15 năm), giữ nguyên giá trị `NaN` (không tự ý nội suy).
4. **Xuất các định dạng:** Lưu bảng long (`asean_panel.csv`), bảng wide (`asean_panel_wide.csv`) và bảng Stata (`asean_panel.dta`) kèm nhãn biến đầy đủ.
5. **Tính toán biến phái sinh:** Tạo log, trễ L1/L2, sai phân, khoảng cách giới và biến giả, xuất ra `asean_panel_derived.csv` và `asean_panel_derived.dta`.
6. **Tạo Data Dictionary:** Biên soạn từ điển dữ liệu chuẩn hóa gồm 58 biến (`data_dictionary.csv`).
7. **Kiểm toán chất lượng dữ liệu:**
   - Tính toán tỷ lệ khuyết thiếu theo quốc gia, biến, năm.
   - Vẽ và lưu các biểu đồ nhiệt (Heatmap) vào `outputs/figures/`.
   - Tính toán số quan sát đầy đủ (complete cases) theo từng nhóm biến.
   - Phát hiện ngoại lai bằng phương pháp Z-score ($|Z| > 3$) và bước nhảy chuỗi thời gian bất thường.
8. **Thống kê mô tả:** Xuất bảng thống kê mô tả tổng thể và theo từng quốc gia vào `outputs/tables/`.

---

## 6. Tóm tắt kết quả kiểm toán chất lượng dữ liệu

Theo báo cáo xuất ra tại `outputs/tables/`:

1. **Tỷ lệ khuyết thiếu theo quốc gia ([`missing_by_country.csv`](file:///c:/Users/NGUYENLONG/Desktop/DTA301/outputs/tables/missing_by_country.csv)):**
   - **Thái Lan (THA):** Hoàn thiện 100% (tỷ lệ khuyết 0.00%).
   - **Indonesia (IDN):** 0.74% khuyết.
   - **Singapore (SGP), Malaysia (MYS):** 1.85% khuyết.
   - **Philippines (PHL):** 2.78% khuyết.
   - **Việt Nam (VNM):** 3.52% khuyết (dữ liệu giáo dục đại học và xuất khẩu dịch vụ ICT một số năm chưa công bố).
   - **Campuchia (KHM):** 3.89% khuyết.
   - **Brunei (BRN):** 4.26% khuyết.
   - **Lào (LAO):** 8.52% khuyết.
   - **Myanmar (MMR):** 13.70% khuyết (do hạn chế thu thập số liệu giai đoạn sau 2021).

2. **Tỷ lệ quan sát đầy đủ theo nhóm biến ([`complete_cases_by_group.csv`](file:///c:/Users/NGUYENLONG/Desktop/DTA301/outputs/tables/complete_cases_by_group.csv)):**
   - **Việc làm theo giới (VIEC_LAM_THEO_GIOI):** 150/150 quan sát đầy đủ (100.0%).
   - **Cơ cấu và chất lượng việc làm (CO_CAU_CHAT_LUONG):** 150/150 quan sát đầy đủ (100.0%).
   - **Hạ tầng số (HA_TANG_SO):** 141/150 quan sát đầy đủ (94.0%).
   - **Nhóm biến cốt lõi cho mô hình kinh tế lượng (CORE_ECONOMETRIC_VARS):** 126/150 quan sát đầy đủ (84.0%).

3. **Phát hiện ngoại lai ([`outliers_zscore.csv`](file:///c:/Users/NGUYENLONG/Desktop/DTA301/outputs/tables/outliers_zscore.csv) & [`outliers_jumps.csv`](file:///c:/Users/NGUYENLONG/Desktop/DTA301/outputs/tables/outliers_jumps.csv)):**
   - Các ngoại lai về máy chủ bảo mật (`secure_servers`) xuất hiện chủ yếu ở Singapore do vị thế là trung tâm dữ liệu và tài chính hàng đầu khu vực.
   - Ngoại lai về độ mở thương mại (`trade_openness` > 300% GDP) phản ánh đặc thù cảng trung chuyển quốc tế của Singapore.
   - Các biến giả phân nhóm (`high_income`) và kiểm soát quốc gia (`country fixed effects`) được thiết kế riêng trong file phái sinh giúp xử lý triệt để hiện tượng này trong mô hình hồi quy.

---

## 7. Gợi ý phương pháp luận cho bài viết Assignment

1. **Lựa chọn biến phụ thuộc (Dependent Variables):**
   - `unemp_total` hoặc `diff_unemp_total` để đo lường biến động thất nghiệp.
   - `emp_services` và `emp_industry` để kiểm định giả thuyết chuyển dịch cơ cấu việc làm từ nông nghiệp sang dịch vụ số và công nghiệp công nghệ cao.
   - `gap_unemp_gender` và `gap_emp_gender` để phân tích tác động bất đối xứng của internet đối với cơ hội việc làm của phụ nữ.
2. **Lựa chọn biến độc lập chính (Core Explanatory Variables):**
   - `internet_users` hoặc `lag1_internet_users` (dùng trễ 1 năm để giảm thiểu vấn đề nội sinh do quan hệ nhân quả hai chiều - Reverse Causality).
   - `fixed_broadband` và `secure_servers` đại diện cho chiều sâu và chất lượng của hạ tầng công nghệ.
3. **Mô hình kinh tế lượng đề xuất:**
   - **Mô hình tác động cố định (Panel Fixed Effects - FE):** Triệt tiêu các yếu tố đặc thù bất biến theo thời gian của từng quốc gia (thể chế, địa lý, văn hóa).
   - **Kiểm định Hausman Test:** Lựa chọn giữa FE và Random Effects (RE).
   - **Kiểm soát cú sốc:** Đưa biến giả `covid` và xu hướng thời gian (`time fixed effects`) để tách biệt tác động của chu kỳ kinh tế toàn cầu.

---

## 8. Tác giả & Giấy phép
- Dự án phục vụ mục đích nghiên cứu học thuật môn **Phân tích Dữ liệu (DTA301)**.
- Dữ liệu thuộc bản quyền công khai của **The World Bank (World Development Indicators)** và **International Labour Organization (ILOSTAT)**.
