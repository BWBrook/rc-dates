import::from("dplyr", mutate, filter, count, arrange, summarise, group_by, ungroup, bind_rows, n)
import::from("ggplot2", ggplot, aes, geom_line, theme_minimal, labs, scale_x_reverse)
import::from("tibble", tibble)
import::from("zoo", rollmean)

#' Bin age values into discrete time intervals
#'
#' Converts numeric age data into time bins for histogramming or line plots.
#'
#' @param df A dataframe of calibrated or uncalibrated radiocarbon dates.
#' @param age_col Name of the column containing age values.
#' @param bin_width Width of each time bin (default = 250).
#' @param min_age Minimum age to include (default = 0).
#' @param max_age Maximum age to include (default = 12000).
#' @return A dataframe of binned counts.
bin_age_distribution <- function(df, age_col, bin_width = 250, min_age = 0, max_age = 12000) {
  df %>%
    mutate(
      bin = floor(.data[[age_col]] / bin_width) * bin_width
    ) %>%
    filter(bin >= min_age & bin <= max_age) %>%
    count(bin) %>%
    arrange(bin)
}

#' Plot radiocarbon vs calibrated age distributions
#'
#' Generates a dual-line trajectory plot comparing uncalibrated and calibrated dates across time.
#'
#' @param df A dataframe containing both AGE and weighted_mean_calBP columns.
#' @param bin_width Bin width for time intervals (default = 250).
#' @param min_age Minimum age for x-axis (default = 0).
#' @param max_age Maximum age for x-axis (default = 12000).
#' @return A ggplot object.
plot_radiocarbon_vs_calibrated <- function(df, bin_width = 250, min_age = 0, max_age = 12000) {
  rc_bins <- bin_age_distribution(df, "AGE", bin_width, min_age, max_age)
  cal_bins <- bin_age_distribution(df, "weighted_mean_calBP", bin_width, min_age, max_age)

  rc_bins$source <- "Radiocarbon age"
  cal_bins$source <- "Calibrated weighted mean"

  combined <- bind_rows(rc_bins, cal_bins)

  ggplot(combined, aes(x = bin, y = n, color = source)) +
    geom_line(linewidth = 1) +
    scale_x_reverse(limits = c(max_age, min_age)) +
    labs(
      title = "Temporal Distribution of Radiocarbon vs Calibrated Ages",
      x = "Years cal BP",
      y = "Count per bin",
      color = "Date type"
    ) +
    theme_minimal()
}

#' Summarise properties of the calibrated dataset
#'
#' Reports counts by material, site type, site-level date density, and temporal spread.
#'
#' @param df A filtered dataframe of calibrated radiocarbon data.
#' @return A list of summary tables.
summarise_calibrated_dataset <- function(df) {
  
  material_summary <- df %>%
    count(MATERIAL, sort = TRUE)

  site_type_summary <- df %>%
    count(SITE_TYPE, sort = TRUE)

  dates_per_site <- df %>%
    count(SITE) %>%
    arrange(desc(n))

  temporal_spread <- df %>%
    group_by(SITE) %>%
    summarise(
      min_cal = min(weighted_mean_calBP),
      max_cal = max(weighted_mean_calBP),
      span = max_cal - min_cal,
      n_dates = n(),
      .groups = "drop"
    ) %>%
    arrange(desc(span))

  summary_list <- list(
    materials = material_summary,
    site_types = site_type_summary,
    dates_per_site = dates_per_site,
    temporal_spread = temporal_spread
  )

  return(summary_list)
}

#' Plot baseline SPD, FD, and KDE curves with optional smoothing and standardization
#'
#' Produces a single ggplot comparing normalized SPD, FD, and KDE curves on a common scale.
#'
#' @param spd_obj An SPD object from rcarbon::spd().
#' @param fd_df A tibble of frequency bins from generate_fd_baseline().
#' @param kde_df A tibble of density values from generate_kde_baseline().
#' @param smooth_fd Logical: apply moving average smoothing to FD? (default = TRUE)
#' @param smooth_window Integer: width of moving average (default = 3)
#' @param standardise Logical: scale all curves to max = 1? (default = TRUE)
#' @return A ggplot object.
plot_baseline_methods <- function(spd_obj, fd_df, kde_df, smooth_fd = TRUE, smooth_window = 3, standardise = TRUE) {
  # SPD
  spd_df <- spd_obj$grid %>%
    dplyr::select(calBP, PrDens) %>%
    dplyr::mutate(source = "SPD")

  # KDE
  kde_df <- kde_df %>%
    dplyr::mutate(source = "KDE", PrDens = density) %>%
    dplyr::select(calBP, PrDens, source)

  # FD: convert to true density
  bin_width <- fd_df$bin[2] - fd_df$bin[1]  # assumes regular bins
  fd_df <- fd_df %>%
    dplyr::mutate(
      PrDens = n / sum(n) / bin_width,
      source = "FD",
      calBP = bin
    ) %>%
    dplyr::select(calBP, PrDens, source)

  # Optional smoothing of FD
  if (smooth_fd) {
    fd_df <- fd_df %>%
      dplyr::arrange(calBP) %>%
      dplyr::mutate(PrDens = zoo::rollmean(PrDens, k = smooth_window, fill = NA, align = "center"))
  }

  # Combine
  combined <- dplyr::bind_rows(spd_df, fd_df, kde_df)
  combined <- combined %>% filter(!is.na(PrDens))

  # Standardize (scale each method to max = 1)
  if (standardise) {
    combined <- combined %>%
      dplyr::group_by(source) %>%
      dplyr::mutate(PrDens = PrDens / max(PrDens, na.rm = TRUE)) %>%
      dplyr::ungroup()
  }

  # Plot
  ggplot(combined, aes(x = calBP, y = PrDens, color = source)) +
    geom_line(linewidth = 1) +
    scale_x_reverse() +
    labs(
      title = "Baseline SPD, FD, and KDE (Standardised)",
      x = "Years cal BP",
      y = "Scaled Density",
      color = "Method"
    ) +
    theme_minimal()
}
