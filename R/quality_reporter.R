# ==============================================================================
# R/quality_reporter.R: Kiểm định chất lượng dữ liệu, thống kê mô tả và trực quan hóa
# DTA301 - Tác động của hạ tầng số và phổ cập internet đến việc làm tại ASEAN (2010-2025)
# ==============================================================================

source("R/config.R")
source("R/utils.R")

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(scales)
})

logger <- setup_logger("quality_reporter")

#' Tính độ lệch (skewness) của vector số liệu
calc_skewness <- function(x) {
  x <- x[!is.na(x)]
  n <- length(x)
  if (n < 3) return(NA_real_)
  m <- mean(x)
  s <- sd(x)
  if (s == 0) return(0)
  (sum((x - m)^3) / n) / (s^3)
}

#' Tạo từ điển dữ liệu Data Dictionary
generate_data_dictionary <- function() {
  logger$info("Generating Data Dictionary (data_dictionary.csv)...")
  records <- list()

  # 1. Các biến định danh bảng nền
  scaffold_vars <- list(
    list(col = "country", desc = "Tên quốc gia (tiếng Anh)", wdi = "Scaffold", unit = "Tên văn bản", grp = "Định danh", notes = "Tên chính thức từ World Bank", stata = "Country Name"),
    list(col = "iso3", desc = "Mã ISO-3 của quốc gia", wdi = "Scaffold", unit = "Mã 3 ký tự", grp = "Định danh", notes = "Chuẩn ISO 3166-1 alpha-3", stata = "ISO-3 Country Code"),
    list(col = "year", desc = "Năm quan sát", wdi = "Scaffold", unit = "Năm (2010-2025)", grp = "Định danh", notes = "Chuỗi thời gian hàng năm", stata = "Calendar Year")
  )
  for (item in scaffold_vars) {
    records[[length(records) + 1]] <- data.frame(
      column_name = item$col,
      vietnamese_description = item$desc,
      wdi_code = item$wdi,
      unit = item$unit,
      variable_group = item$grp,
      notes = item$notes,
      stata_label = item$stata,
      is_derived = FALSE,
      stringsAsFactors = FALSE
    )
  }

  # 2. 36 chỉ số thô WDI
  for (code in names(ALL_INDICATORS)) {
    info <- ALL_INDICATORS[[code]]
    records[[length(records) + 1]] <- data.frame(
      column_name = info$short_name,
      vietnamese_description = info$name_vi,
      wdi_code = code,
      unit = info$unit,
      variable_group = info$group_name_vi,
      notes = info$notes,
      stata_label = info$stata_label,
      is_derived = FALSE,
      stringsAsFactors = FALSE
    )
  }

  # 3. Các biến phái sinh
  for (der_col in names(DERIVED_VARIABLES)) {
    der_info <- DERIVED_VARIABLES[[der_col]]
    records[[length(records) + 1]] <- data.frame(
      column_name = der_col,
      vietnamese_description = der_info$name_vi,
      wdi_code = "Phái sinh",
      unit = der_info$unit,
      variable_group = der_info$group_name_vi,
      notes = der_info$notes,
      stata_label = der_info$stata_label,
      is_derived = TRUE,
      stringsAsFactors = FALSE
    )
  }

  # 4. Các biến đã xử lý ngoại lai phục vụ mô hình hóa (Winsorized)
  winsor_vars <- list(
    list(col = "secure_servers_win", desc = "Máy chủ bảo mật (Winsorized 1-99%)", wdi = "Phái sinh/Làm sạch", unit = "Máy chủ / 1M dân", grp = "Biến phái sinh", notes = "Đã xử lý ngoại lai cực lớn của Singapore ở phân vị 99%", stata = "Secure servers (Winsorized 1-99%)"),
    list(col = "trade_openness_win", desc = "Độ mở thương mại (Winsorized 1-99%)", wdi = "Phái sinh/Làm sạch", unit = "% GDP", grp = "Biến phái sinh", notes = "Đã xử lý ngoại lai cảng trung chuyển ở phân vị 99%", stata = "Trade openness (Winsorized 1-99%)")
  )
  for (item in winsor_vars) {
    records[[length(records) + 1]] <- data.frame(
      column_name = item$col,
      vietnamese_description = item$desc,
      wdi_code = item$wdi,
      unit = item$unit,
      variable_group = item$grp,
      notes = item$notes,
      stata_label = item$stata,
      is_derived = TRUE,
      stringsAsFactors = FALSE
    )
  }

  dict_df <- bind_rows(records)
  readr::write_csv(dict_df, DATA_DICTIONARY_PATH)
  readr::write_csv(dict_df, DATA_DICTIONARY_PROCESSED_PATH)
  logger$info(sprintf("Data Dictionary saved to %s (%d variables)", DATA_DICTIONARY_PATH, nrow(dict_df)))
  dict_df
}

#' Phân tích tỷ lệ khuyết thiếu dữ liệu và vẽ biểu đồ nhiệt (Heatmaps)
analyze_missing_data <- function(df) {
  logger$info("Computing missing data statistics and rendering heatmaps...")
  feature_cols <- setdiff(names(df), c("country", "iso3", "year"))

  if (!dir.exists(OUTPUTS_TABLES_DIR)) dir.create(OUTPUTS_TABLES_DIR, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(OUTPUTS_FIGURES_DIR)) dir.create(OUTPUTS_FIGURES_DIR, recursive = TRUE, showWarnings = FALSE)

  # 1. Tỷ lệ thiếu theo Biến
  var_records <- list()
  for (col in feature_cols) {
    wdi_code <- if (!is.null(SHORT_TO_WDI[[col]])) SHORT_TO_WDI[[col]] else "Phái sinh"
    grp_name <- if (!is.null(ALL_INDICATORS[[wdi_code]]$group_name_vi)) ALL_INDICATORS[[wdi_code]]$group_name_vi else "Phái sinh"
    n_missing <- sum(is.na(df[[col]]))
    total <- nrow(df)
    var_records[[length(var_records) + 1]] <- data.frame(
      column_name = col,
      wdi_code = wdi_code,
      variable_group = grp_name,
      total_observations = total,
      missing_count = n_missing,
      missing_rate_pct = round((n_missing / total) * 100, 2),
      available_count = total - n_missing,
      stringsAsFactors = FALSE
    )
  }
  df_missing_var <- bind_rows(var_records) %>%
    arrange(desc(missing_rate_pct), column_name)
  readr::write_csv(df_missing_var, file.path(OUTPUTS_TABLES_DIR, "missing_by_variable.csv"))

  # 2. Tỷ lệ thiếu theo Quốc gia
  country_records <- list()
  for (iso in unique(df$iso3)) {
    c_df <- df %>% filter(iso3 == iso)
    c_name <- c_df$country[1]
    total_cells <- nrow(c_df) * length(feature_cols)
    missing_cells <- sum(is.na(c_df[feature_cols]))
    country_records[[length(country_records) + 1]] <- data.frame(
      iso3 = iso,
      country = c_name,
      total_cells = total_cells,
      missing_cells = missing_cells,
      missing_rate_pct = round((missing_cells / total_cells) * 100, 2),
      complete_rate_pct = round(100 - (missing_cells / total_cells) * 100, 2),
      stringsAsFactors = FALSE
    )
  }
  df_missing_country <- bind_rows(country_records) %>%
    arrange(desc(missing_rate_pct))
  readr::write_csv(df_missing_country, file.path(OUTPUTS_TABLES_DIR, "missing_by_country.csv"))

  # 3. Tỷ lệ thiếu theo Năm
  year_records <- list()
  for (yr in sort(unique(df$year))) {
    y_df <- df %>% filter(year == yr)
    total_cells <- nrow(y_df) * length(feature_cols)
    missing_cells <- sum(is.na(y_df[feature_cols]))
    year_records[[length(year_records) + 1]] <- data.frame(
      year = yr,
      total_cells = total_cells,
      missing_cells = missing_cells,
      missing_rate_pct = round((missing_cells / total_cells) * 100, 2),
      complete_rate_pct = round(100 - (missing_cells / total_cells) * 100, 2),
      stringsAsFactors = FALSE
    )
  }
  df_missing_year <- bind_rows(year_records)
  readr::write_csv(df_missing_year, file.path(OUTPUTS_TABLES_DIR, "missing_by_year.csv"))

  # 4. Biểu đồ nhiệt: Tỷ lệ thiếu theo Quốc gia x Biến
  heat_c_var <- df %>%
    group_by(iso3) %>%
    summarise(across(all_of(feature_cols), ~ mean(is.na(.)) * 100), .groups = "drop") %>%
    pivot_longer(-iso3, names_to = "variable", values_to = "missing_pct")

  p1 <- ggplot(heat_c_var, aes(x = iso3, y = variable, fill = missing_pct)) +
    geom_tile(color = "white", linewidth = 0.3) +
    scale_fill_gradient(low = "#FFFFD4", high = "#B10026", limits = c(0, 100), name = "Tỷ lệ thiếu (%)") +
    theme_minimal(base_size = 10) +
    labs(
      title = "Tỷ lệ dữ liệu khuyết thiếu theo Biến và Quốc gia ASEAN (2010-2025)",
      x = "Mã quốc gia (ISO3)",
      y = "Biến số"
    ) +
    theme(
      plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
      axis.text.y = element_text(size = 7),
      axis.text.x = element_text(face = "bold")
    )
  ggsave(file.path(OUTPUTS_FIGURES_DIR, "missing_heatmap_country_var.png"), plot = p1, width = 12, height = 9, dpi = 300)

  # 5. Biểu đồ nhiệt: Tỷ lệ thiếu theo Năm x Biến
  heat_y_var <- df %>%
    group_by(year) %>%
    summarise(across(all_of(feature_cols), ~ mean(is.na(.)) * 100), .groups = "drop") %>%
    pivot_longer(-year, names_to = "variable", values_to = "missing_pct")

  p2 <- ggplot(heat_y_var, aes(x = factor(year), y = variable, fill = missing_pct)) +
    geom_tile(color = "white", linewidth = 0.3) +
    scale_fill_gradient(low = "#FFFFD4", high = "#B10026", limits = c(0, 100), name = "Tỷ lệ thiếu (%)") +
    theme_minimal(base_size = 10) +
    labs(
      title = "Tỷ lệ dữ liệu khuyết thiếu theo Biến và Năm quan sát (2010-2025)",
      x = "Năm",
      y = "Biến số"
    ) +
    theme(
      plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
      axis.text.y = element_text(size = 7),
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
  ggsave(file.path(OUTPUTS_FIGURES_DIR, "missing_heatmap_year_var.png"), plot = p2, width = 12, height = 9, dpi = 300)

  # 6. Toàn cảnh ma trận khuyết thiếu quan sát Panel (160 quan sát x biến)
  matrix_data <- df %>%
    arrange(iso3, year) %>%
    mutate(obs_id = paste(iso3, year, sep = "_")) %>%
    select(obs_id, all_of(feature_cols)) %>%
    pivot_longer(-obs_id, names_to = "variable", values_to = "val") %>%
    mutate(is_missing = factor(ifelse(is.na(val), "Khuyết (NA)", "Có dữ liệu"), levels = c("Có dữ liệu", "Khuyết (NA)")))

  matrix_data$obs_id <- factor(matrix_data$obs_id, levels = unique(matrix_data$obs_id))

  p3 <- ggplot(matrix_data, aes(x = variable, y = obs_id, fill = is_missing)) +
    geom_tile() +
    scale_fill_manual(values = c("Có dữ liệu" = "#2B5C8F", "Khuyết (NA)" = "#E8ECEF"), name = "Trạng thái") +
    theme_minimal(base_size = 9) +
    labs(
      title = sprintf("Ma trận khuyết thiếu quan sát Panel ASEAN (%d quan sát x Biến)", nrow(df)),
      x = "Biến số",
      y = "Quan sát Quốc gia - Năm"
    ) +
    theme(
      plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
      axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 7),
      axis.text.y = element_blank(),
      axis.ticks.y = element_blank()
    )
  ggsave(file.path(OUTPUTS_FIGURES_DIR, "missing_matrix.png"), plot = p3, width = 14, height = 8, dpi = 300)

  logger$info("Missing data reports and heatmaps successfully saved.")
  list(by_variable = df_missing_var, by_country = df_missing_country, by_year = df_missing_year)
}

#' Phân tích số lượng quan sát hoàn chỉnh (Complete Cases) theo nhóm biến
analyze_complete_cases <- function(df) {
  logger$info("Computing complete cases across indicator groups...")
  results <- list()
  total_rows <- nrow(df)

  for (grp_key in names(INDICATOR_GROUPS)) {
    grp_data <- INDICATOR_GROUPS[[grp_key]]
    grp_vars <- unlist(lapply(grp_data$indicators, function(ind) ind$short_name))
    grp_vars <- intersect(grp_vars, names(df))
    if (length(grp_vars) == 0) next

    subset_df <- df[grp_vars]
    comp_count <- sum(complete.cases(subset_df))
    results[[length(results) + 1]] <- data.frame(
      group_key = grp_key,
      group_name_vi = grp_data$group_name_vi,
      num_variables = length(grp_vars),
      variables_list = paste(grp_vars, collapse = ", "),
      total_observations = total_rows,
      complete_cases = comp_count,
      complete_rate_pct = round((comp_count / total_rows) * 100, 2),
      stringsAsFactors = FALSE
    )
  }

  # Tất cả 36 chỉ số gốc WDI
  raw_vars <- unlist(lapply(ALL_INDICATORS, function(info) info$short_name))
  raw_vars <- intersect(raw_vars, names(df))
  complete_raw <- sum(complete.cases(df[raw_vars]))
  results[[length(results) + 1]] <- data.frame(
    group_key = "ALL_RAW_INDICATORS",
    group_name_vi = "Tất cả 36 chỉ số gốc WDI",
    num_variables = length(raw_vars),
    variables_list = "Toàn bộ 36 biến WDI",
    total_observations = total_rows,
    complete_cases = complete_raw,
    complete_rate_pct = round((complete_raw / total_rows) * 100, 2),
    stringsAsFactors = FALSE
  )

  # Nhóm biến cốt lõi cho mô hình kinh tế lượng
  core_vars <- c("internet_users", "fixed_broadband", "unemp_total", "emp_rate_total",
                 "labor_force_part", "gdp_pc_ppp", "trade_openness", "fdi_net_inflows")
  core_vars <- intersect(core_vars, names(df))
  complete_core <- sum(complete.cases(df[core_vars]))
  results[[length(results) + 1]] <- data.frame(
    group_key = "CORE_ECONOMETRIC_VARS",
    group_name_vi = "Nhóm biến cốt lõi cho mô hình kinh tế lượng",
    num_variables = length(core_vars),
    variables_list = paste(core_vars, collapse = ", "),
    total_observations = total_rows,
    complete_cases = complete_core,
    complete_rate_pct = round((complete_core / total_rows) * 100, 2),
    stringsAsFactors = FALSE
  )

  complete_df <- bind_rows(results)
  readr::write_csv(complete_df, file.path(OUTPUTS_TABLES_DIR, "complete_cases_by_group.csv"))
  logger$info("Saved complete cases report to outputs/tables/complete_cases_by_group.csv")
  complete_df
}

#' Phát hiện dị biệt/ngoại lai (Outliers) qua Z-Score (|Z| > 3) và bước nhảy đột biến qua từng năm
detect_outliers <- function(df) {
  logger$info("Running outlier detection (Z-scores & annual jumps)...")
  num_cols <- names(df)[sapply(df, is.numeric)]
  num_cols <- setdiff(num_cols, c("year", "covid", "myanmar_post2021", "high_income"))

  # 1. Ngoại lai theo Z-Score
  z_records <- list()
  for (col in num_cols) {
    v <- df[[col]]
    s <- v[!is.na(v)]
    if (length(s) < 10 || sd(s) == 0) next
    m <- mean(s)
    std_val <- sd(s)
    z_scores <- (v - m) / std_val

    out_idx <- which(abs(z_scores) > 3.0)
    for (i in out_idx) {
      z_val <- z_scores[i]
      z_records[[length(z_records) + 1]] <- data.frame(
        iso3 = df$iso3[i],
        country = df$country[i],
        year = as.integer(df$year[i]),
        variable = col,
        value = round(v[i], 4),
        panel_mean = round(m, 4),
        panel_std = round(std_val, 4),
        z_score = round(z_val, 2),
        outlier_type = if (z_val > 0) "High outlier (z > 3)" else "Low outlier (z < -3)",
        stringsAsFactors = FALSE
      )
    }
  }

  z_df <- if (length(z_records) > 0) bind_rows(z_records) %>% arrange(variable, desc(z_score)) else data.frame()
  readr::write_csv(z_df, file.path(OUTPUTS_TABLES_DIR, "outliers_zscore.csv"))
  logger$info(sprintf("Detected %d Z-score outlier observations (|Z| > 3).", nrow(z_df)))

  # 2. Dị biệt bước nhảy hàng năm theo từng quốc gia
  jump_records <- list()
  df_sorted <- df %>% arrange(iso3, year)

  for (col in num_cols) {
    diff_val <- df_sorted %>%
      group_by(iso3) %>%
      mutate(d = .data[[col]] - dplyr::lag(.data[[col]], 1)) %>%
      pull(d)

    diff_series <- diff_val[!is.na(diff_val)]
    if (length(diff_series) < 10 || sd(diff_series) == 0) next

    diff_std <- sd(diff_series)
    jump_threshold <- 3.0 * diff_std

    jump_idx <- which(abs(diff_val) > jump_threshold)
    for (i in jump_idx) {
      d <- diff_val[i]
      prev_val <- df_sorted[[col]][i] - d
      jump_records[[length(jump_records) + 1]] <- data.frame(
        iso3 = df_sorted$iso3[i],
        country = df_sorted$country[i],
        year = as.integer(df_sorted$year[i]),
        variable = col,
        previous_year_value = round(prev_val, 4),
        current_year_value = round(df_sorted[[col]][i], 4),
        absolute_jump = round(d, 4),
        jump_std_ratio = round(abs(d) / diff_std, 2),
        notes = sprintf("Jump exceeds 3*std of annual delta (%.2f)", jump_threshold),
        stringsAsFactors = FALSE
      )
    }
  }

  jump_df <- if (length(jump_records) > 0) bind_rows(jump_records) %>% arrange(desc(jump_std_ratio), variable) else data.frame()
  readr::write_csv(jump_df, file.path(OUTPUTS_TABLES_DIR, "outliers_jumps.csv"))
  logger$info(sprintf("Detected %d abnormal annual jump events.", nrow(jump_df)))

  list(z_score = z_df, jumps = jump_df)
}

#' Thống kê mô tả tổng quát và theo từng quốc gia
generate_descriptive_stats <- function(df) {
  logger$info("Generating descriptive statistics tables...")
  num_cols <- names(df)[sapply(df, is.numeric)]
  num_cols <- setdiff(num_cols, c("year", "covid", "myanmar_post2021", "high_income"))

  # 1. Toàn bộ quan sát panel
  overall_records <- list()
  for (col in num_cols) {
    v <- df[[col]]
    s <- v[!is.na(v)]
    wdi_code <- if (!is.null(SHORT_TO_WDI[[col]])) SHORT_TO_WDI[[col]] else "Phái sinh"
    grp <- if (!is.null(ALL_INDICATORS[[wdi_code]]$group_name_vi)) ALL_INDICATORS[[wdi_code]]$group_name_vi else "Phái sinh"
    n <- length(s)

    q_vals <- if (n > 0) stats::quantile(s, probs = c(0.25, 0.5, 0.75)) else c(NA, NA, NA)

    overall_records[[length(overall_records) + 1]] <- data.frame(
      variable = col,
      wdi_code = wdi_code,
      variable_group = grp,
      count = n,
      missing_pct = round(((nrow(df) - n) / nrow(df)) * 100, 2),
      mean = if (n > 0) round(mean(s), 4) else NA_real_,
      std = if (n > 1) round(sd(s), 4) else NA_real_,
      min = if (n > 0) round(min(s), 4) else NA_real_,
      p25 = if (n > 0) round(q_vals[1], 4) else NA_real_,
      median = if (n > 0) round(q_vals[2], 4) else NA_real_,
      p75 = if (n > 0) round(q_vals[3], 4) else NA_real_,
      max = if (n > 0) round(max(s), 4) else NA_real_,
      skewness = if (n > 2) round(calc_skewness(s), 4) else NA_real_,
      stringsAsFactors = FALSE
    )
  }
  df_overall <- bind_rows(overall_records)
  readr::write_csv(df_overall, file.path(OUTPUTS_TABLES_DIR, "summary_stats_overall.csv"))
  logger$info("Saved outputs/tables/summary_stats_overall.csv")

  # 2. Thống kê theo từng quốc gia
  country_records <- list()
  for (iso in unique(df$iso3)) {
    c_df <- df %>% filter(iso3 == iso)
    c_name <- c_df$country[1]
    for (col in num_cols) {
      s <- c_df[[col]][!is.na(c_df[[col]])]
      n <- length(s)
      country_records[[length(country_records) + 1]] <- data.frame(
        iso3 = iso,
        country = c_name,
        variable = col,
        count = n,
        mean = if (n > 0) round(mean(s), 4) else NA_real_,
        std = if (n > 1) round(sd(s), 4) else NA_real_,
        min = if (n > 0) round(min(s), 4) else NA_real_,
        max = if (n > 0) round(max(s), 4) else NA_real_,
        stringsAsFactors = FALSE
      )
    }
  }
  df_country <- bind_rows(country_records)
  readr::write_csv(df_country, file.path(OUTPUTS_TABLES_DIR, "summary_stats_by_country.csv"))
  logger$info("Saved outputs/tables/summary_stats_by_country.csv")

  # 3. Trực quan hóa xu hướng chính (Internet vs Thất nghiệp)
  plot_key_trends(df)

  list(overall = df_overall, by_country = df_country)
}

#' Vẽ đồ thị chuỗi thời gian so sánh giữa các quốc gia
plot_key_trends <- function(df) {
  tryCatch({
    has_net <- "internet_users" %in% names(df)
    has_unemp <- "unemp_total" %in% names(df)

    if (has_net && has_unemp) {
      p_net <- ggplot(df, aes(x = year, y = internet_users, color = iso3, group = iso3)) +
        geom_line(linewidth = 0.8) +
        geom_point(size = 1.6) +
        theme_minimal(base_size = 11) +
        labs(
          title = "Phổ cập Internet (% dân số) tại ASEAN, 2010-2025",
          x = "Năm",
          y = "% Dân số dùng Internet",
          color = "Quốc gia"
        ) +
        theme(plot.title = element_text(face = "bold", size = 11))

      p_unemp <- ggplot(df, aes(x = year, y = unemp_total, color = iso3, group = iso3)) +
        geom_line(linewidth = 0.8) +
        geom_point(size = 1.6) +
        theme_minimal(base_size = 11) +
        labs(
          title = "Tỷ lệ thất nghiệp (% LLLĐ, ILO) tại ASEAN, 2010-2025",
          x = "Năm",
          y = "Tỷ lệ thất nghiệp (%)",
          color = "Quốc gia"
        ) +
        theme(plot.title = element_text(face = "bold", size = 11))

      # Lưu 2 đồ thị ghép đôi
      trend_fig_path <- file.path(OUTPUTS_FIGURES_DIR, "internet_vs_unemployment_trends.png")
      
      # Tạo canvas 2 panel
      png(trend_fig_path, width = 16, height = 6, units = "in", res = 300)
      grid::grid.newpage()
      grid::pushViewport(grid::viewport(layout = grid::grid.layout(1, 2)))
      print(p_net, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1))
      print(p_unemp, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 2))
      dev.off()

      logger$info("Saved trend visualization to outputs/figures/internet_vs_unemployment_trends.png")
    }
  }, error = function(e) {
    logger$warn(sprintf("Could not render trend plots: %s", e$message))
  })
}

if (sys.nframe() == 0L) {
  generate_data_dictionary()
  df_base <- readr::read_csv(ASEAN_PANEL_PATH, show_col_types = FALSE)
  analyze_missing_data(df_base)
  analyze_complete_cases(df_base)
  df_der <- readr::read_csv(ASEAN_PANEL_DERIVED_PATH, show_col_types = FALSE)
  detect_outliers(df_der)
  generate_descriptive_stats(df_der)
}
