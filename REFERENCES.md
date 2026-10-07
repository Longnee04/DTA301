# TÀI LIỆU THAM KHẢO & CƠ SỞ LÝ THUYẾT (LITERATURE & REFERENCES)
## Đề tài: "Tác động của hạ tầng số và phổ cập internet đến việc làm tại các nước ASEAN, giai đoạn 2010–2024"
**Dự án:** DTA301 - Phân tích Dữ liệu Kinh tế  
**Kho lưu trữ:** [https://github.com/Longnee04/DTA301](https://github.com/Longnee04/DTA301)

---

Tài liệu này tổng hợp toàn bộ các nguồn dữ liệu chính thức, bài báo khoa học kinh tế lượng quốc tế, báo cáo chính sách của các tổ chức quốc tế (World Bank, ADB, ILO, ITU) và khung pháp lý chuyển đổi số ASEAN. Sinh viên có thể trích dẫn trực tiếp các tài liệu này vào phần **Tổng quan nghiên cứu (Literature Review)** và **Khung phân tích lý thuyết** của Assignment cuối kỳ.

---

## 1. CỔNG DỮ LIỆU & TÀI LIỆU KỸ THUẬT API CHÍNH THỨC

Các nguồn dữ liệu gốc được tích hợp vào pipeline thu thập tự động:

1. **World Bank - World Development Indicators (WDI):**
   - *Mô tả:* Cơ sở dữ liệu phát triển toàn cầu chuẩn mực của Ngân hàng Thế giới bao gồm hơn 1,400 chỉ số.
   - *Cổng truy cập dữ liệu:* [https://databank.worldbank.org/source/world-development-indicators](https://databank.worldbank.org/source/world-development-indicators)
   - *Tài liệu API v2:* [World Bank Indicators API Documentation](https://datahelpdesk.worldbank.org/knowledgebase/articles/889392-about-the-indicators-api-documentation)

2. **International Labour Organization (ILOSTAT):**
   - *Mô tả:* Cơ sở dữ liệu thị trường lao động toàn cầu của Tổ chức Lao động Quốc tế, cung cấp dữ liệu mô hình hóa chuẩn hóa quốc tế (*modeled ILO estimates*).
   - *Cổng dữ liệu:* [https://ilostat.ilo.org/data/](https://ilostat.ilo.org/data/)
   - *Phương pháp luận:* [ILO Modelled Estimates Methodology](https://ilostat.ilo.org/resources/concepts-and-definitions/ilo-modelled-estimates/)

3. **International Telecommunication Union (ITU):**
   - *Mô tả:* Cơ quan viễn thông của Liên Hợp Quốc, nguồn gốc của các chỉ số `IT.NET.USER.ZS`, `IT.NET.BBND.P2`, `IT.CEL.SETS.P2`.
   - *Cổng số liệu:* [ITU DataHub](https://datahub.itu.int/)
   - *Báo cáo thường niên:* [Facts and Figures: Focus on Least Developed Countries](https://www.itu.int/itu-d/reports/statistics/facts-figures-2023/)

4. **United Nations Conference on Trade and Development (UNCTAD):**
   - *Mô tả:* Cung cấp số liệu thống kê thương mại hàng hóa và dịch vụ công nghệ thông tin truyền thông (ICT goods & services exports).
   - *Cổng dữ liệu:* [UNCTADstat Data Centre](https://unctadstat.unctad.org/)

---

## 2. LINK TRANG WEB TRA CỨU TRỰC QUAN TỪNG CHỈ SỐ TRÊN GIAO DIỆN WORLD BANK

Dưới đây là các đường link giao diện đồ họa chính thức trên cổng World Bank Data Portal (bao gồm biểu đồ chuỗi thời gian, bản đồ nhiệt thế giới và phân tích so sánh giữa các quốc gia ASEAN):

### A. Nhóm Hạ tầng số (Digital Infrastructure)
* **Tỷ lệ dân số sử dụng Internet (`IT.NET.USER.ZS`):**  
  [https://data.worldbank.org/indicator/IT.NET.USER.ZS](https://data.worldbank.org/indicator/IT.NET.USER.ZS)
* **Thuê bao băng rộng cố định trên 100 dân (`IT.NET.BBND.P2`):**  
  [https://data.worldbank.org/indicator/IT.NET.BBND.P2](https://data.worldbank.org/indicator/IT.NET.BBND.P2)
* **Thuê bao điện thoại di động trên 100 dân (`IT.CEL.SETS.P2`):**  
  [https://data.worldbank.org/indicator/IT.CEL.SETS.P2](https://data.worldbank.org/indicator/IT.CEL.SETS.P2)
* **Máy chủ Internet bảo mật SSL/TLS trên 1 triệu dân (`IT.NET.SECR.P6`):**  
  [https://data.worldbank.org/indicator/IT.NET.SECR.P6](https://data.worldbank.org/indicator/IT.NET.SECR.P6)
* **Tỷ lệ dân số tiếp cận điện lưới (`EG.ELC.ACCS.ZS`):**  
  [https://data.worldbank.org/indicator/EG.ELC.ACCS.ZS](https://data.worldbank.org/indicator/EG.ELC.ACCS.ZS)

### B. Nhóm Kinh tế số & Xuất khẩu công nghệ cao (Digital Economy)
* **Xuất khẩu hàng hóa ICT (% tổng xuất khẩu hàng hóa - `TX.VAL.ICTG.ZS.UN`):**  
  [https://data.worldbank.org/indicator/TX.VAL.ICTG.ZS.UN](https://data.worldbank.org/indicator/TX.VAL.ICTG.ZS.UN)
* **Xuất khẩu dịch vụ ICT (% xuất khẩu dịch vụ - `BX.GSR.CCIS.ZS`):**  
  [https://data.worldbank.org/indicator/BX.GSR.CCIS.ZS](https://data.worldbank.org/indicator/BX.GSR.CCIS.ZS)
* **Xuất khẩu công nghệ cao (% xuất khẩu hàng chế biến chế tạo - `TX.VAL.TECH.MF.ZS`):**  
  [https://data.worldbank.org/indicator/TX.VAL.TECH.MF.ZS](https://data.worldbank.org/indicator/TX.VAL.TECH.MF.ZS)

### C. Nhóm Việc làm & Thất nghiệp (Employment & Unemployment)
* **Tỷ lệ thất nghiệp tổng thể (ước tính mô hình ILO - `SL.UEM.TOTL.ZS`):**  
  [https://data.worldbank.org/indicator/SL.UEM.TOTL.ZS](https://data.worldbank.org/indicator/SL.UEM.TOTL.ZS)
* **Tỷ lệ thất nghiệp tổng thể (ước tính quốc gia - `SL.UEM.TOTL.NE.ZS`):**  
  [https://data.worldbank.org/indicator/SL.UEM.TOTL.NE.ZS](https://data.worldbank.org/indicator/SL.UEM.TOTL.NE.ZS)
* **Tỷ lệ thất nghiệp ở nữ giới (`SL.UEM.TOTL.FE.ZS`):**  
  [https://data.worldbank.org/indicator/SL.UEM.TOTL.FE.ZS](https://data.worldbank.org/indicator/SL.UEM.TOTL.FE.ZS)
* **Tỷ lệ thất nghiệp ở nam giới (`SL.UEM.TOTL.MA.ZS`):**  
  [https://data.worldbank.org/indicator/SL.UEM.TOTL.MA.ZS](https://data.worldbank.org/indicator/SL.UEM.TOTL.MA.ZS)
* **Tỷ lệ việc làm trên dân số 15+ (`SL.EMP.TOTL.SP.ZS`):**  
  [https://data.worldbank.org/indicator/SL.EMP.TOTL.SP.ZS](https://data.worldbank.org/indicator/SL.EMP.TOTL.SP.ZS)
* **Tỷ lệ tham gia lực lượng lao động (`SL.TLF.CACT.ZS`):**  
  [https://data.worldbank.org/indicator/SL.TLF.CACT.ZS](https://data.worldbank.org/indicator/SL.TLF.CACT.ZS)
* **Tỷ lệ thất nghiệp thanh niên 15–24 tuổi (`SL.UEM.1524.ZS`):**  
  [https://data.worldbank.org/indicator/SL.UEM.1524.ZS](https://data.worldbank.org/indicator/SL.UEM.1524.ZS)
* **Tỷ lệ thanh niên không học, không làm - NEET (`SL.UEM.NEET.ZS`):**  
  [https://data.worldbank.org/indicator/SL.UEM.NEET.ZS](https://data.worldbank.org/indicator/SL.UEM.NEET.ZS)
* **Thất nghiệp ở lao động trình độ cao (`SL.UEM.ADVN.ZS`):**  
  [https://data.worldbank.org/indicator/SL.UEM.ADVN.ZS](https://data.worldbank.org/indicator/SL.UEM.ADVN.ZS)

### D. Nhóm Cơ cấu ngành & Chất lượng việc làm (Structure & Quality)
* **Tỷ lệ việc làm trong nông nghiệp (`SL.AGR.EMPL.ZS`):**  
  [https://data.worldbank.org/indicator/SL.AGR.EMPL.ZS](https://data.worldbank.org/indicator/SL.AGR.EMPL.ZS)
* **Tỷ lệ việc làm trong dịch vụ (`SL.SRV.EMPL.ZS`):**  
  [https://data.worldbank.org/indicator/SL.SRV.EMPL.ZS](https://data.worldbank.org/indicator/SL.SRV.EMPL.ZS)
* **Tỷ lệ việc làm trong công nghiệp (`SL.IND.EMPL.ZS`):**  
  [https://data.worldbank.org/indicator/SL.IND.EMPL.ZS](https://data.worldbank.org/indicator/SL.IND.EMPL.ZS)
* **Tỷ lệ việc làm dễ bị tổn thương (`SL.EMP.VULN.ZS`):**  
  [https://data.worldbank.org/indicator/SL.EMP.VULN.ZS](https://data.worldbank.org/indicator/SL.EMP.VULN.ZS)
* **Lao động làm công ăn lương (`SL.EMP.WORK.ZS`):**  
  [https://data.worldbank.org/indicator/SL.EMP.WORK.ZS](https://data.worldbank.org/indicator/SL.EMP.WORK.ZS)
* **Lao động tự doanh/hộ gia đình (`SL.EMP.SELF.ZS`):**  
  [https://data.worldbank.org/indicator/SL.EMP.SELF.ZS](https://data.worldbank.org/indicator/SL.EMP.SELF.ZS)
* **Năng suất lao động GDP/lao động (`SL.GDP.PCAP.EM.KD`):**  
  [https://data.worldbank.org/indicator/SL.GDP.PCAP.EM.KD](https://data.worldbank.org/indicator/SL.GDP.PCAP.EM.KD)

### E. Nhóm Kinh tế vĩ mô & Kiểm soát (Macroeconomic Controls)
* **GDP bình quân đầu người theo sức mua tương đương - PPP (`NY.GDP.PCAP.PP.KD`):**  
  [https://data.worldbank.org/indicator/NY.GDP.PCAP.PP.KD](https://data.worldbank.org/indicator/NY.GDP.PCAP.PP.KD)
* **Tốc độ tăng trưởng GDP hàng năm (`NY.GDP.MKTP.KD.ZG`):**  
  [https://data.worldbank.org/indicator/NY.GDP.MKTP.KD.ZG](https://data.worldbank.org/indicator/NY.GDP.MKTP.KD.ZG)
* **Độ mở thương mại % GDP (`NE.TRD.GNFS.ZS`):**  
  [https://data.worldbank.org/indicator/NE.TRD.GNFS.ZS](https://data.worldbank.org/indicator/NE.TRD.GNFS.ZS)
* **Dòng vốn FDI ròng % GDP (`BX.KLT.DINV.WD.GD.ZS`):**  
  [https://data.worldbank.org/indicator/BX.KLT.DINV.WD.GD.ZS](https://data.worldbank.org/indicator/BX.KLT.DINV.WD.GD.ZS)
* **Tỷ lệ dân số đô thị (`SP.URB.TOTL.IN.ZS`):**  
  [https://data.worldbank.org/indicator/SP.URB.TOTL.IN.ZS](https://data.worldbank.org/indicator/SP.URB.TOTL.IN.ZS)
* **Tỷ lệ nhập học đại học/cao đẳng thô (`SE.TER.ENRR`):**  
  [https://data.worldbank.org/indicator/SE.TER.ENRR](https://data.worldbank.org/indicator/SE.TER.ENRR)
* **Tổng dân số (`SP.POP.TOTL`):**  
  [https://data.worldbank.org/indicator/SP.POP.TOTL](https://data.worldbank.org/indicator/SP.POP.TOTL)
* **Tỷ lệ dân số trong độ tuổi lao động 15–64 (`SP.POP.1564.TO.ZS`):**  
  [https://data.worldbank.org/indicator/SP.POP.1564.TO.ZS](https://data.worldbank.org/indicator/SP.POP.1564.TO.ZS)
* **Tỷ lệ lạm phát CPI hàng năm (`FP.CPI.TOTL.ZG`):**  
  [https://data.worldbank.org/indicator/FP.CPI.TOTL.ZG](https://data.worldbank.org/indicator/FP.CPI.TOTL.ZG)

---

## 3. CÁC BÀI BÁO KHOA HỌC KINH TẾ LƯỢNG TIÊU BIỂU (EMPIRICAL PAPERS)

Dưới đây là các công trình nghiên cứu kinh tế lượng đã xuất bản trên các tạp chí hàng đầu thế giới (AER, JEP, WBER), cung cấp nền tảng lý thuyết và cơ sở để lựa chọn biến số trong mô hình:

### Nhóm A: Hạ tầng số, Phổ cập Internet và Tạo việc làm tại các nước đang phát triển

1. **Hjort, J., & Poulsen, J. (2019).**  
   *The Arrival of Fast Internet and Employment in Africa.*  
   **American Economic Review**, 109(3), 1032–1079.  
   - *DOI:* [10.1257/aer.20161385](https://doi.org/10.1257/aer.20161385)  
   - *Bài viết trực tuyến:* [AER Article Link](https://www.aeaweb.org/articles?id=10.1257/aer.20161385)  
   - *Ý nghĩa cho đề tài:* Bài báo kinh điển chứng minh sự xuất hiện của cáp quang biển và internet tốc độ cao làm tăng việc làm ròng ở cả lao động kỹ năng cao và kỹ năng trung bình tại các quốc gia đang phát triển. **(Dùng để biện minh cho việc dùng biến trễ L1, L2 của internet)**.

2. **Atasoy, H. (2013).**  
   *The Effects of Broadband Internet Expansion on Labor Market Outcomes.*  
   **ILR Review**, 66(2), 315–345.  
   - *DOI:* [10.1177/001979391306600202](https://doi.org/10.1177/001979391306600202)  
   - *Ý nghĩa cho đề tài:* Phân tích tác động lan tỏa của hạ tầng băng rộng đến tỷ lệ có việc làm tổng thể và sự phân hóa theo trình độ học vấn.

3. **Katz, R. L. (2012).**  
   *The Impact of Broadband on the Economy: Research to Date and Policy Issues.*  
   **ITU Broadband Series**, Geneva: International Telecommunication Union.  
   - *Link tài liệu:* [ITU Publication PDF](https://www.itu.int/ITU-D/treg/broadband/ITU-BB-Reports_Impact-of-Broadband-on-the-Economy.pdf)  
   - *Ý nghĩa cho đề tài:* Tổng hợp các bằng chứng thực nghiệm về tác động kích thích tăng trưởng kinh tế và năng suất lao động từ việc tăng 10% tỷ lệ phổ cập băng rộng.

### Nhóm B: Chuyển dịch cơ cấu ngành và Chất lượng việc làm (Structural Transformation)

4. **Autor, D. H. (2015).**  
   *Why Are There Still So Many Jobs? The History and Future of Workplace Automation.*  
   **Journal of Economic Perspectives**, 29(3), 3–30.  
   - *DOI:* [10.1257/jep.29.3.3](https://doi.org/10.1257/jep.29.3.3)  
   - *Bài viết trực tuyến:* [JEP Article Link](https://www.aeaweb.org/articles?id=10.1257/jep.29.3.3)  
   - *Ý nghĩa cho đề tài:* Làm rõ tác động phân cực lao động (job polarization) và sự dịch chuyển từ việc làm chân tay sang việc làm dịch vụ hiện đại. **(Dùng cho biến `emp_agriculture`, `emp_industry`, `emp_services`)**.

5. **Acemoglu, D., & Restrepo, P. (2018).**  
   *The Race between Man and Machine: Implications of Technology for Training, Wages, and Skills.*  
   **American Economic Review**, 108(6), 1488–1542.  
   - *DOI:* [10.1257/aer.20160696](https://doi.org/10.1257/aer.20160696)  
   - *Ý nghĩa cho đề tài:* Phân tích cơ chế thay thế (displacement effect) và cơ chế tái tạo việc làm (reinstatement effect) của công nghệ mới.

### Nhóm C: Hạ tầng số và Bình đẳng giới trên thị trường lao động (Gender Gap)

6. **Viollaz, M., & Winkler, H. (2022).**  
   *Does the Internet Promote Gender Equality in the Labor Market? Evidence from Chile.*  
   **The World Bank Economic Review**, 36(3), 675–701.  
   - *DOI:* [10.1093/wber/lhac006](https://doi.org/10.1093/wber/lhac006)  
   - *Bài viết trực tuyến:* [Oxford Academic Link](https://academic.oup.com/wber/article/36/3/675/6584284)  
   - *Ý nghĩa cho đề tài:* Bằng chứng thực nghiệm cho thấy internet giúp phụ nữ tiếp cận thông tin việc làm và hình thức làm việc linh hoạt, qua đó thu hẹp khoảng cách tham gia lực lượng lao động. **(Dùng trực tiếp cho biến `gap_unemp_gender` và `gap_emp_gender`)**.

---

## 4. BÁO CÁO CỦA CÁC TỔ CHỨC QUỐC TẾ VỀ ASEAN & CHUYỂN ĐỔI SỐ

Các báo cáo định chế cung cấp góc nhìn thực tế và các số liệu ngữ cảnh sinh động cho ASEAN:

1. **World Bank (2016).**  
   *World Development Report 2016: Digital Dividends.*  
   Washington, DC: World Bank.  
   - *Link toàn văn báo cáo:* [World Bank Open Knowledge Repository](https://www.worldbank.org/en/publication/wdr2016)  
   - *Luận điểm chính:* Công nghệ số mở rộng cơ hội việc làm nhưng cần đi kèm với "các yếu tố bổ trợ tương tự" (analog complements) bao gồm kỹ năng và thể chế.

2. **Asian Development Bank - ADB (2018).**  
   *Asian Development Outlook 2018: How Technology Affects Jobs.*  
   Manila: Asian Development Bank.  
   - *Link toàn văn:* [ADB Publications](https://www.adb.org/publications/asian-development-outlook-2018-how-technology-affects-jobs)  
   - *Luận điểm chính:* Đánh giá toàn diện khu vực châu Á, chỉ ra công nghệ tạo thêm việc làm nhiều hơn số việc làm bị mất đi nhờ hiệu ứng thu nhập và tăng năng suất.

3. **International Labour Organization & ADB (2020).**  
   *The Future of Work in ASEAN: Exploring the Impact of Technologies on Jobs and Decent Work.*  
   Geneva & Manila: ILO/ADB.  
   - *Link báo cáo:* [ILO Resource Guide](https://www.ilo.org/asia/publications/WCMS_644380/lang--en/index.htm)  
   - *Luận điểm chính:* Phân tích tác động của tự động hóa và kinh tế nền tảng (gig economy) đến ASEAN-10, đặc biệt đối với lao động dễ bị tổn thương (`emp_vulnerable`).

4. **Google, Temasek, & Bain & Company (2023, 2024).**  
   *e-Conomy SEA Report: The Roar of the Digital Decade in Southeast Asia.*  
   - *Link tải báo cáo:* [Google e-Conomy SEA](https://economysea.withgoogle.com/)  
   - *Luận điểm chính:* Báo cáo thường niên uy tín nhất về quy mô tổng giá trị hàng hóa (GMV) kinh tế số, việc làm công nghệ và xu hướng số hóa tại các nền kinh tế hàng đầu Đông Nam Á.

5. **ASEAN Secretariat (2021).**  
   *Bandar Seri Begawan Roadmap (BSBR): An ASEAN Digital Transformation Agenda to Accelerate ASEAN's Economic Recovery.*  
   Jakarta: The ASEAN Secretariat.  
   - *Link văn bản:* [ASEAN Official Website](https://asean.org/wp-content/uploads/2021/09/Bandar-Seri-Begawan-Roadmap-Final.pdf)  
   - *Kế hoạch tổng thể:* [ASEAN Digital Masterplan 2025 (ADM 2025)](https://asean.org/book/asean-digital-masterplan-2025/)  
   - *Ý nghĩa cho đề tài:* Cung cấp khung thể chế và cam kết hội nhập số của 10 quốc gia ASEAN.

---

## 5. DANH MỤC TRÍCH DẪN CHUẨN APA 7TH (COPY-PASTE VÀO BÀI TIỂU LUẬN)

```text
Acemoglu, D., & Restrepo, P. (2018). The race between man and machine: Implications of technology for training, wages, and skills. American Economic Review, 108(6), 1488-1542. https://doi.org/10.1257/aer.20160696

Asian Development Bank. (2018). Asian Development Outlook 2018: How technology affects jobs. Manila: Asian Development Bank.

Atasoy, H. (2013). The effects of broadband internet expansion on labor market outcomes. ILR Review, 66(2), 315-345. https://doi.org/10.1177/001979391306600202

Autor, D. H. (2015). Why are there still so many jobs? The history and future of workplace automation. Journal of Economic Perspectives, 29(3), 3-30. https://doi.org/10.1257/jep.29.3.3

Google, Temasek, & Bain & Company. (2023). e-Conomy SEA 2023: The roar of the digital decade. https://economysea.withgoogle.com/

Hjort, J., & Poulsen, J. (2019). The arrival of fast internet and employment in Africa. American Economic Review, 109(3), 1032-1079. https://doi.org/10.1257/aer.20161385

International Labour Organization. (2020). The future of work in ASEAN: Exploring the impact of technologies on jobs and decent work. Geneva: ILO.

Katz, R. L. (2012). The impact of broadband on the economy: Research to date and policy issues. Geneva: International Telecommunication Union.

Viollaz, M., & Winkler, H. (2022). Does the internet promote gender equality in the labor market? Evidence from Chile. The World Bank Economic Review, 36(3), 675-701. https://doi.org/10.1093/wber/lhac006

World Bank. (2016). World Development Report 2016: Digital dividends. Washington, DC: World Bank. https://doi.org/10.1596/978-1-4648-0671-1

World Bank. (2024). World Development Indicators database. Washington, DC: World Bank. https://databank.worldbank.org/source/world-development-indicators
```
