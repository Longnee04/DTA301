# BÁO CÁO DỰ ÁN DTA301: PHÂN TÍCH DỮ LIỆU KINH TẾ
## ĐỀ TÀI: TÁC ĐỘNG CỦA HẠ TẦNG SỐ VÀ PHỔ CẬP INTERNET ĐẾN VIỆC LÀM TẠI CÁC NƯỚC ASEAN, GIAI ĐOẠN 2010–2025
### Giải pháp Dữ liệu Bảng Kinh tế lượng (Panel Data Econometrics): Mô hình Fixed Effects, Random Effects, Đánh giá Độ trễ Thời gian & Chuyển dịch Cơ cấu Lao động

---

* **Môn học:** Phân tích Dữ liệu Kinh tế (DTA301)
* **Quy mô bộ dữ liệu:** 10 quốc gia ASEAN × 16 năm liên tục (2010–2025) = 160 quan sát Country-Year
* **Nguồn số liệu:** World Bank World Development Indicators (WDI API v2) & ILOSTAT
* **Kho lưu trữ mã nguồn:** [https://github.com/Longnee04/DTA301](https://github.com/Longnee04/DTA301)

---

## MỤC LỤC BÁO CÁO • AGENDA
1. **PHẦN 1: MÔ TẢ BÀI TOÁN & QUY MÔ BỘ DỮ LIỆU**
   - 1.1. Bối cảnh nghiên cứu, mục tiêu & phạm vi không gian - thời gian
   - 1.2. Chi tiết cấu trúc 36 chỉ số WDI gốc thuộc 6 nhóm logic
   - 1.3. Hệ thống 3 cặp giả thuyết nghiên cứu thực nghiệm (H0 / H1)
2. **PHẦN 2: QUY TRÌNH LÀM SẠCH DỮ LIỆU & KỸ THUẬT TẠO ĐẶC TRƯNG**
   - 2.1. Bảo toàn dữ liệu gốc và phương pháp nội suy chuỗi thời gian có kiểm soát
   - 2.2. Báo cáo kiểm toán dữ liệu làm sạch (Cleaning Audit Report)
   - 2.3. Kỹ thuật tạo đặc trưng kinh tế lượng (Log, Lag L1/L2, Diff, Gap, Dummies)
3. **PHẦN 3: PHÂN TÍCH KHÁM PHÁ DỮ LIỆU (EDA)**
   - 3.1. Phân tích thực trạng khuyết thiếu dữ liệu (Missing Data Audit theo Nước, Biến, Năm)
   - 3.2. Đánh giá tỷ lệ quan sát hoàn chỉnh (Complete Cases) theo từng nhóm biến
   - 3.3. Phát hiện và xử lý dị biệt/ngoại lai (Z-Score & Bước nhảy chuỗi thời gian)
   - 3.4. Trực quan hóa xu hướng: Phổ cập Internet vs Tỷ lệ thất nghiệp ASEAN (2010–2025)
   - 3.5. Bảng thống kê mô tả tổng thể các biến số nghiên cứu
4. **PHẦN 4: MÔ HÌNH HÓA KINH TẾ LƯỢNG CHUYÊN SÂU**
   - 4.1. Thiết lập phương trình kinh tế lượng dữ liệu bảng (Panel Model Specification)
   - 4.2. Bảng kết quả ước lượng: Pooled OLS, Fixed Effects (FE), Random Effects (RE)
   - 4.3. Kiểm định lựa chọn mô hình: Hausman Test & Kiểm định đa cộng tuyến (VIF)
   - 4.4. Đánh giá độ trễ thời gian lan tỏa (Lag Effects L1 & L2) của hạ tầng số
   - 4.5. Kiểm định chuyển dịch cơ cấu việc làm (H2) & Thu hẹp khoảng cách giới (H3)
5. **PHẦN 5: KẾT LUẬN TỔNG HỢP, KHUYẾN NGHỊ CHÍNH SÁCH & HẠN CHẾ**
   - 5.1. Tổng kết các phát hiện định lượng then chốt
   - 5.2. Khuyến nghị chính sách cho Chính phủ các quốc gia ASEAN
   - 5.3. Khuyến nghị chiến lược cho Doanh nghiệp & Nhà đầu tư công nghệ
   - 5.4. Hạn chế của đề tài & Hướng nghiên cứu mở rộng
6. **PHẦN 6: DANH MỤC TÀI LIỆU THAM KHẢO (APA 7TH)**

---

# PHẦN 1: MÔ TẢ BÀI TOÁN & QUY MÔ BỘ DỮ LIỆU

### 1.1. Bối cảnh nghiên cứu, mục tiêu & phạm vi
Trong kỷ nguyên số hóa toàn cầu, hạ tầng số (viễn thông băng rộng cố định, mạng di động cáp quang, điện toán đám mây và máy chủ bảo mật) được xem là "hạ tầng cứng" mới của mọi nền kinh tế tri thức. Khu vực Hiệp hội các Quốc gia Đông Nam Á (ASEAN) là một trong những khu vực kinh tế phát triển năng động nhất thế giới với quy mô nền kinh tế số dự kiến đạt hơn 300 tỷ USD vào năm 2025. Tuy nhiên, nội bộ ASEAN đang tồn tại sự phân cực phát triển sâu sắc ("Khoảng cách số" - Digital Divide) giữa nhóm tiên phong thu nhập cao (Singapore, Brunei, Malaysia) với nhóm các quốc gia đang phát triển và chuyển đổi (Campuchia, Lào, Myanmar, Việt Nam, Indonesia, Philippines).

Mục tiêu cốt lõi của nghiên cứu là đánh giá tác động định lượng của quá trình phổ cập Internet và hiện đại hóa hạ tầng số đến thị trường lao động tại 10 nước ASEAN giai đoạn 2010–2025. Nghiên cứu tập trung giải quyết 3 câu hỏi chính:
1. Phổ cập Internet giúp giảm tỷ lệ thất nghiệp hay gây ra hiện tượng dịch chuyển/mất việc làm do công nghệ?
2. Hạ tầng số thúc đẩy quá trình chuyển dịch lao động từ nông nghiệp truyền thống sang dịch vụ hiện đại như thế nào?
3. Internet có góp phần thu hẹp bất bình đẳng giới trên thị trường việc làm hay không?

* **Không gian nghiên cứu:** 10 quốc gia thành viên ASEAN chuẩn ISO-3 (`BRN`, `KHM`, `IDN`, `LAO`, `MYS`, `MMR`, `PHL`, `SGP`, `THA`, `VNM`).
* **Thời gian nghiên cứu:** 16 năm liên tục (2010 – 2025).
* **Khung bảng cân bằng (Balanced Panel Scaffold):** 10 nước × 16 năm = **160 quan sát Country-Year**.

### 1.2. Chi tiết cấu trúc 36 chỉ số WDI gốc thuộc 6 nhóm
Dữ liệu được trích xuất trực tiếp từ cổng API v2 của World Bank (World Development Indicators - WDI) và cơ sở dữ liệu mô hình hóa của ILO (ILOSTAT), phân loại thành 6 nhóm chỉ số kinh tế lượng chuẩn hóa:

| Nhóm chỉ số | Tên biến trong mô hình | Mã chỉ số World Bank | Đơn vị đo lường | Ý nghĩa kinh tế |
| :--- | :--- | :--- | :--- | :--- |
| **1. Hạ tầng số** | `internet_users` | IT.NET.USER.ZS | % dân số | Tỷ lệ cá nhân dùng Internet trong 3 tháng qua (ITU) |
| | `fixed_broadband` | IT.NET.BBND.P2 | Thuê bao / 100 dân | Độ thâm nhập băng rộng cố định tốc độ cao ≥ 256 kbps |
| | `mobile_cellular` | IT.CEL.SETS.P2 | Thuê bao / 100 dân | Mức độ phổ cập thuê bao mạng di động trả trước/sau |
| | `secure_servers` | IT.NET.SECR.P6 | Máy chủ / 1M dân | Hạ tầng an toàn số hóa, mã hóa giao dịch trực tuyến SSL/TLS |
| | `electricity_access` | EG.ELC.ACCS.ZS | % dân số | Tiếp cận điện lưới - điều kiện tiên quyết cho chuyển đổi số |
| **2. Kinh tế số** | `ict_goods_exp` | TX.VAL.ICTG.ZS.UN | % xuất khẩu hàng hóa | Tỷ trọng xuất khẩu thiết bị phần cứng, máy tính, viễn thông |
| | `ict_serv_exp` | BX.GSR.CCIS.ZS | % xuất khẩu dịch vụ | Xuất khẩu dịch vụ máy tính, phần mềm và viễn thông (BoP) |
| | `hightech_exp` | TX.VAL.TECH.MF.ZS | % hàng chế tạo | Hàng hóa công nghệ cao (R&D chuyên sâu, điện tử) |
| **3. Việc làm tổng thể** | `unemp_total` | SL.UEM.TOTL.ZS | % lực lượng lao động | Tỷ lệ thất nghiệp tổng số (ước tính chuẩn mô hình ILO) |
| | `emp_rate_total` | SL.EMP.TOTL.SP.ZS | % dân số ≥ 15 tuổi | Tỷ lệ dân số có việc làm trên tổng dân số trưởng thành |
| | `labor_force_part` | SL.TLF.CACT.ZS | % dân số ≥ 15 tuổi | Tỷ lệ tham gia lực lượng lao động |
| | `unemp_youth` | SL.UEM.1524.ZS | % LLLĐ thanh niên | Thất nghiệp thanh niên độ tuổi 15–24 (nhóm dễ tổn thương) |
| **4. Việc làm theo giới** | `unemp_female` / `male` | SL.UEM.TOTL.FE.ZS / MA | % LLLĐ nữ / nam | Tỷ lệ thất nghiệp phân rã theo giới tính |
| | `emp_rate_female` / `male`| SL.EMP.TOTL.SP.FE.ZS / MA | % dân số nữ / nam | Tỷ lệ việc làm trên dân số phân rã theo giới tính |
| | `labor_force_part_fe` | SL.TLF.CACT.FE.ZS | % dân số nữ ≥ 15 | Mức độ tham gia lực lượng lao động của phụ nữ |
| **5. Cơ cấu việc làm** | `emp_agriculture` | SL.AGR.EMPL.ZS | % tổng việc làm | Lao động nông nghiệp truyền thống |
| | `emp_services` | SL.SRV.EMPL.ZS | % tổng việc làm | Lao động khu vực dịch vụ hiện đại, kinh tế số |
| | `labor_productivity` | SL.GDP.PCAP.EM.KD | USD PPP 2021 / người | Năng suất lao động thực tế (GDP trên mỗi lao động có việc làm) |
| **6. Biến kiểm soát** | `gdp_pc_ppp` | NY.GDP.PCAP.PP.KD | USD PPP (2021 constant) | GDP bình quân đầu người theo sức mua tương đương |
| | `trade_openness` | NE.TRD.GNFS.ZS | % GDP | Độ mở thương mại = (Xuất khẩu + Nhập khẩu) / GDP |
| | `fdi_net_inflows` | BX.KLT.DINV.WD.GD.ZS | % GDP | Dòng vốn đầu tư trực tiếp nước ngoài FDI ròng vào nền kinh tế |
| | `inflation_cpi` | FP.CPI.TOTL.ZG | % hàng năm | Lạm phát theo chỉ số giá tiêu dùng CPI (ổn định vĩ mô) |

### 1.3. Hệ thống 3 cặp giả thuyết nghiên cứu thực nghiệm
* **Giả thuyết 1 ($H_1$): Tác động đến Thất nghiệp**
  * *Giả thuyết không ($H_0$):* Phổ cập Internet và hạ tầng số không có tác động đáng kể đến tỷ lệ thất nghiệp tại ASEAN ($\beta = 0$).
  * *Giả thuyết đối ($H_1$):* Phổ cập Internet có tác động tiêu cực đáng kể đến tỷ lệ thất nghiệp ($\beta < 0$), giúp giảm thất nghiệp nhờ giảm ma sát tìm kiếm việc làm (job search cost) và tạo việc làm mới trong kinh tế nền tảng.
* **Giả thuyết 2 ($H_2$): Chuyển dịch cơ cấu việc làm**
  * *Giả thuyết không ($H_0$):* Hạ tầng số không làm thay đổi tỷ trọng lao động giữa khu vực nông nghiệp và dịch vụ.
  * *Giả thuyết đối ($H_1$):* Internet thúc đẩy tái cơ cấu lao động: giảm tỷ trọng việc làm nông nghiệp năng suất thấp ($\beta_{\text{agr}} < 0$) và gia tăng việc làm dịch vụ số hóa ($\beta_{\text{srv}} > 0$).
* **Giả thuyết 3 ($H_3$): Thu hẹp khoảng cách giới**
  * *Giả thuyết không ($H_0$):* Tác động của hạ tầng số đến việc làm của nam và nữ là như nhau, không làm thay đổi khoảng cách giới.
  * *Giả thuyết đối ($H_1$):* Internet mang lại tác động vượt trội cho phụ nữ nhờ cơ hội làm việc linh hoạt từ xa (remote work, e-commerce), giúp thu hẹp khoảng cách thất nghiệp giới ($\beta_{\text{gap}} < 0$).

---

# PHẦN 2: QUY TRÌNH LÀM SẠCH DỮ LIỆU & KỸ THUẬT TẠO ĐẶC TRƯNG

### 2.1. Bảo toàn dữ liệu gốc và phương pháp nội suy chuỗi thời gian có kiểm soát
* **Bảo toàn 100% dữ liệu thô:** Lưu trữ nguyên bản trong `data/raw/*.csv` và sổ làm việc Excel `asean_raw_data.xlsx`, không can thiệp hay ghi đè.
* **Quy trình làm sạch chuyên sâu 3 bước (Model-Ready Cleaning):**
  1. *Nội suy tuyến tính chuỗi thời gian nội bộ từng nước (Within-country Linear Interpolation & Boundary Fill):* Sử dụng `stats::approx` với `rule = 2` trên trục thời gian của chính quốc gia đó, duy trì đặc thù xu hướng riêng biệt.
  2. *Dự phòng trung vị nhóm nước tương đồng (Peer-group Median Imputation):* Phân nhóm 4 phân tầng thu nhập (High-income, Upper-middle, Lower-middle emerging, Transition) để bù đắp các chuỗi thiếu toàn bộ của một quốc gia (dịch vụ ICT Việt Nam, thương mại Myanmar).
  3. *Xử lý ngoại lai phân phối lệch bằng Winsorization (1% - 99%):* Cắt ngọn các cực trị bất thường của Singapore về máy chủ bảo mật (`secure_servers_win`) và độ mở cảng biển (`trade_openness_win`).
* **Kết quả:** Đạt **100% Complete Cases (160/160 dòng × 60 cột)**, loại bỏ triệt để nguy cơ mất mẫu khi ước lượng mô hình.

### 2.2. Báo cáo kiểm toán làm sạch (Cleaning Audit Report)
Trích xuất từ `outputs/tables/cleaning_audit_report.csv`:
* `internet_users`: 12 ô khuyết ban đầu $\rightarrow$ 0 ô khuyết (Độ hoàn thiện 100.0% sau nội suy chuỗi thời gian).
* `fixed_broadband`: 11 ô khuyết $\rightarrow$ 0 ô khuyết (Độ hoàn thiện 100.0%).
* `unemp_total`, `emp_rate_total`, `labor_force_part`: 0 ô khuyết (Dữ liệu gốc hoàn thiện 100.0%).
* `ict_serv_exp`: 28 ô khuyết $\rightarrow$ 0 ô khuyết (Nội suy chuỗi thời gian & Trung vị nhóm nước).
* `trade_openness`: 13 ô khuyết $\rightarrow$ 0 ô khuyết (Nội suy chuỗi thời gian & Trung vị nhóm nước).

### 2.3. Kỹ thuật tạo đặc trưng kinh tế lượng (Feature Engineering)
* **Tuyến tính hóa Logarit:** `ln_gdp_pc` = $\ln(\text{gdp\_pc\_ppp})$ và `ln_pop` = $\ln(\text{pop\_total})$.
* **Biến trễ hạ tầng số (Lags L1 & L2):** `lag1_internet_users`, `lag2_internet_users`, `lag1_fixed_broadband`...
* **Sai phân bậc 1 ($\Delta$ Differences):** `diff_internet_users` = $\text{Internet}_{i,t} - \text{Internet}_{i,t-1}$ và `diff_unemp_total` = $\text{Unemp}_{i,t} - \text{Unemp}_{i,t-1}$.
* **Khoảng cách giới (Gender Disparities):** `gap_unemp_gender` = $\text{Thất nghiệp}_{\text{Nữ}} - \text{Thất nghiệp}_{\text{Nam}}$ và `gap_emp_gender` = $\text{Việc làm}_{\text{Nữ}} - \text{Việc làm}_{\text{Nam}}$.
* **Biến giả chính sách & cú sốc:** `covid` (2020–2021), `myanmar_post2021` (MMR ≥ 2021), `high_income` (Singapore & Brunei).

---

# PHẦN 3: PHÂN TÍCH KHÁM PHÁ DỮ LIỆU (EDA)

### 3.1. Phân tích thực trạng khuyết thiếu dữ liệu (Missing Data Audit)
* **Tỷ lệ khuyết thiếu theo quốc gia:** Thái Lan (1.39%), Indonesia (2.60%), Singapore (3.30%), Malaysia (3.99%), Philippines (4.51%), Campuchia (5.56%), Việt Nam (5.56%), Brunei (5.90%), Lào (10.42%), Myanmar (15.45%).
* **Tỷ lệ quan sát đầy đủ:** Nhóm việc làm theo giới (100.0%), Nhóm cơ cấu việc làm (100.0%), Nhóm hạ tầng số (88.1%), Nhóm biến cốt lõi (78.8% trên dữ liệu thô và 100.0% sau làm sạch).

### 3.2. Dị biệt ngoại lai (Outliers Detection)
* Nhận diện 71 giá trị có $|Z\text{-score}| > 3.0$, phần lớn tập trung ở Singapore đối với `secure_servers` (vượt 120.000 máy chủ / 1M dân) và `trade_openness` (> 300% GDP).
* Kỹ thuật Winsorization 1%-99% đã chuẩn hóa biên độ dữ liệu an toàn cho mô hình hồi quy.

### 3.3. Bảng thống kê mô tả tổng thể (N = 160 quan sát)
* `internet_users` (%): Mean = 54.21%, SD = 27.84%, Min = 1.15%, Median = 56.30%, Max = 99.00%.
* `fixed_broadband` (/100 dân): Mean = 7.82, SD = 9.65, Min = 0.05, Median = 3.45, Max = 38.92.
* `unemp_total` (%): Mean = 2.58%, SD = 1.52%, Min = 0.45%, Median = 2.10%, Max = 7.25%.
* `emp_services` (%): Mean = 48.95%, SD = 14.20%, Min = 21.50%, Median = 49.10%, Max = 84.50%.
* `emp_agriculture` (%): Mean = 27.60%, SD = 15.80%, Min = 0.10%, Median = 28.90%, Max = 65.20%.
* `gdp_pc_ppp` (USD): Mean = $26,450, SD = $32,150, Min = $2,650, Median = $12,850, Max = $135,000.

---

# PHẦN 4: MÔ HÌNH HÓA KINH TẾ LƯỢNG CHUYÊN SÂU

### 4.1. Thiết lập phương trình kinh tế lượng dữ liệu bảng
$$\text{Unemp}_{i,t} = \beta_0 + \beta_1 \text{Internet}_{i,t-1} + \beta_2 \ln(\text{GDP\_PC}_{i,t}) + \beta_3 \text{Trade}_{i,t} + \beta_4 \text{FDI}_{i,t} + \delta \text{COVID}_t + \alpha_i + \varepsilon_{i,t}$$

### 4.2. Bảng kết quả ước lượng mô hình Panel

| Biến độc lập | Pooled OLS | Random Effects (RE) | Fixed Effects (FE) [Mô hình tối ưu] |
| :--- | :--- | :--- | :--- |
| **`lag1_internet_users`** | -0.0215*** (0.0051) | -0.0198*** (0.0058) | **-0.0184** (0.0069, p = 0.008)** |
| **`ln_gdp_pc`** | -0.4820* (0.2410) | -0.6210* (0.3120) | **-0.8912** (0.3950, p = 0.026)** |
| **`trade_openness_win`** | -0.0031 (0.0022) | -0.0012 (0.0031) | **+0.0042 (0.0041)** |
| **`fdi_net_inflows`** | -0.0112 (0.0145) | -0.0104 (0.0152) | **-0.0089 (0.0160)** |
| **`covid`** | +0.7420*** (0.1980) | +0.7105*** (0.2010) | **+0.6890*** (0.2045, p = 0.001)** |
| **$R^2$ (Within)** | 0.284 | 0.395 | **0.421** |
| **F-statistic / Wald Chi2**| 18.45*** | 46.82*** | **21.14*** (p < 0.001)** |
| **Kiểm định Hausman** | — | — | **Chi-Square = 14.28, p = 0.014 < 0.05 $\rightarrow$ CHỌN FIXED EFFECTS** |

### 4.3. Biện luận kinh tế lượng
1. **Kiểm định Hausman ($p = 0.014 < 0.05$):** Khẳng định có tương quan giữa đặc thù quốc gia $\alpha_i$ với các biến giải thích. Mô hình Fixed Effects (FE) là ước lượng không chệch và phù hợp nhất.
2. **Ủng hộ Giả thuyết $H_1$ ($\beta_1 = -0.0184, p < 0.01$):** Phổ cập Internet năm trước tăng 10 điểm phần trăm giúp giảm tỷ lệ thất nghiệp năm sau bình quân **0.184 điểm phần trăm**.
3. **Ủng hộ Giả thuyết $H_2$ (Chuyển dịch cơ cấu):** Hồi quy trên `emp_services` cho hệ số $\beta = +0.1420$ ($p < 0.001$), trong khi hồi quy trên `emp_agriculture` cho hệ số $\beta = -0.1650$ ($p < 0.001$). Internet đẩy nhanh quá trình rút lao động khỏi nông nghiệp sang dịch vụ số.
4. **Ủng hộ Giả thuyết $H_3$ (Thu hẹp khoảng cách giới):** Hệ số trên `gap_unemp_gender` đạt $\beta = -0.0062$ ($p = 0.041 < 0.05$), phản ánh kinh tế số hỗ trợ phụ nữ tiếp cận việc làm linh hoạt.

---

# PHẦN 5: KẾT LUẬN TỔNG HỢP, KHUYẾN NGHỊ CHÍNH SÁCH & HẠN CHẾ

### 5.1. Khuyến nghị cho Chính phủ các nước ASEAN
* Mở rộng mạng cáp quang băng rộng và phủ sóng 5G đến vùng sâu vùng xa để tránh "bẫy phân cực số" (digital divide).
* Triển khai chiến lược đào tạo kỹ năng số toàn dân, đổi mới giáo dục nghề nghiệp nhằm giải quyết thất nghiệp thanh niên.
* Ban hành khung pháp lý an sinh xã hội cho lao động nền tảng (Gig economy).

### 5.2. Khuyến nghị cho Doanh nghiệp & Nhà đầu tư
* Đón đầu thị trường dịch vụ số và thương mại điện tử tại nhóm nước CLMV (Campuchia, Lào, Myanmar, Việt Nam).
* Đầu tư trung tâm dữ liệu an toàn (Data Centers & Cloud) tại Indonesia, Việt Nam và Thái Lan.

### 5.3. Hạn chế nghiên cứu & Hướng mở rộng
* Nghiên cứu dựa trên dữ liệu WDI/ILO chưa đo lường hết quy mô lao động tự do phi chính thức.
* Hướng mở rộng: Ứng dụng mô hình System GMM để kiểm soát tính nội sinh động và bổ sung dữ liệu điều tra vi mô cấp hộ gia đình.

---

# PHẦN 6: TÀI LIỆU THAM KHẢO (APA 7TH)
* Autor, D. H. (2015). Why are there still so many jobs? The history and future of workplace automation. *Journal of Economic Perspectives*, 29(3), 3–30.
* Asian Development Bank. (2018). *Asian Development Outlook 2018: How technology affects jobs*. Asian Development Bank.
* Google, Temasek, & Bain & Company. (2024). *e-Conomy SEA 2024: Profitable growth in Southeast Asia’s digital economy*.
* Hjort, J., & Poulsen, J. (2019). The arrival of fast internet and employment in Africa. *American Economic Review*, 109(3), 1032–1079.
* Viollaz, M., & Winkler, H. (2022). Does the internet reduce gender gaps? The case of Jordan. *The World Bank Economic Review*, 36(2), 437–460.
* World Bank. (2016). *World Development Report 2016: Digital dividends*. World Bank Publications.
