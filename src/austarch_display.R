import::from("dplyr", mutate, filter, count, arrange, summarise, group_by, ungroup, bind_rows, n)
import::from("ggplot2", ggplot, aes, geom_line, theme_minimal, labs, scale_x_reverse, facet_wrap, geom_ribbon)
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

#' Plot SPD, FD, and KDE curves from a single simulation iteration
#'
#' Produces overlaid or facetted plot of SPD, FD, and KDE results from a single iteration.
#'
#' @param df A tibble with columns calBP, value, method (e.g. from generate_iteration_curves()).
#' @param facet Logical: should methods be split into facets (default = TRUE)?
#' @return A ggplot object
plot_iteration_curves <- function(df, facet = TRUE) {
  p <- ggplot(df, aes(x = calBP, y = value, color = method)) +
    geom_line(linewidth = 1) +
    scale_x_reverse() +
    labs(
      title = "SPD, FD, and KDE from single iteration",
      x = "Years cal BP",
      y = "Scaled Value",
      color = "Method"
    ) +
    theme_minimal()

  if (facet) {
    p <- p + facet_wrap(~method, ncol = 1, scales = "free_y")
  }

  return(p)
}

#' Helper function:
#' Summarise simulation curves across iterations
#'
#' Computes mean and 95% intervals per method and calendar year.
#'
#' @param df Output of run_simulation_curves()
#' @return A summarised tibble with mean, lower, upper, and calBP
summarise_iteration_curves <- function(df) {
  df %>%
    group_by(method, calBP) %>%
    summarise(
      mean = mean(value, na.rm = TRUE),
      lower = quantile(value, 0.025, na.rm = TRUE),
      upper = quantile(value, 0.975, na.rm = TRUE),
      .groups = "drop"
    )
}

#' Plot summarised SPD, FD, KDE curves across iterations
#'
#' @param summary_df Output from summarise_iteration_curves()
#' @return A ggplot object
plot_summarised_curves <- function(summary_df) {
  ggplot(summary_df, aes(x = calBP, y = mean, color = method, fill = method)) +
    geom_line(linewidth = 1) +
    geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.2, color = NA) +
    scale_x_reverse() +
    labs(
      title = "Mean and 95% interval of SPD, FD, KDE",
      x = "Years cal BP",
      y = "Scaled Value",
      color = "Method", fill = "Method"
    ) +
    theme_minimal()
}

#' Plot raw SPD, FD, KDE iterations as a density cloud
#'
#' Useful for visualising uncertainty structure across simulations
#'
#' @param df Long-form iteration tibble (output from run_simulation_curves)
#' @param alpha Transparency of lines (default = 0.1)
#' @return A ggplot object
plot_density_cloud <- function(df, alpha = 0.1) {
  ggplot(df, aes(x = calBP, y = value, group = interaction(method, iteration), color = method)) +
    geom_line(alpha = alpha, linewidth = 0.3) +
    scale_x_reverse() +
    facet_wrap(~method, ncol = 1, scales = "free_y") +
    labs(
      title = "Density cloud of SPD, FD, and KDE across iterations",
      x = "Years cal BP",
      y = "Scaled Value",
      color = "Method"
    ) +
    theme_minimal()
}
