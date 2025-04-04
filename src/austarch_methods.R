import::from("rcarbon", spd)
import::from("stats", density)
import::from("tibble", tibble)
import::from("dplyr", mutate, filter, count, arrange)

#' Generate baseline Summed Probability Distribution (SPD)
#'
#' Sums calibrated probability densities to produce a population proxy over time.
#'
#' @param cal_dates A CalDates object.
#' @param time_range Range of calendar years BP to include (default = c(11650, 651)).
#' @param runm Width of running mean smoother (default = 100).
#' @param normalised Whether to normalize the final SPD (default = TRUE).
#' @return An SPD object.
generate_spd_baseline <- function(cal_dates, time_range = c(11650, 651), runm = 100, normalised = TRUE) {
  spd_obj <- spd(
    x = cal_dates,
    timeRange = time_range,
    runm = runm,
    spdnormalised = normalised
  )
  return(spd_obj)
}

#' Generate Frequency Distribution (FD) from weighted calibrated dates
#'
#' Bins weighted means into count-based intervals to create a frequency histogram.
#'
#' @param df A dataframe with weighted_mean_calBP.
#' @param bin_width Width of each time bin (default = 100).
#' @param min_age Minimum cal BP (default = 651).
#' @param max_age Maximum cal BP (default = 11650).
#' @return A dataframe of binned frequencies.
generate_fd_baseline <- function(df, bin_width = 100, min_age = 651, max_age = 11650) {
  df %>%
    mutate(bin = floor(weighted_mean_calBP / bin_width) * bin_width) %>%
    filter(bin >= min_age & bin <= max_age) %>%
    count(bin) %>%
    arrange(bin)
}

#' Generate Kernel Density Estimate (KDE) from calibrated date points
#'
#' Uses Gaussian smoothing on weighted mean calibrated dates to infer temporal density.
#'
#' @param df A dataframe with weighted_mean_calBP values.
#' @param from Minimum cal BP (default = 651).
#' @param to Maximum cal BP (default = 11650).
#' @param bw Bandwidth for Gaussian kernel (default = 100).
#' @param n Number of output points (default = 1000).
#' @return A tibble with smoothed density over time.
generate_kde_baseline <- function(df, from = 651, to = 11650, bw = 100, n = 1000) {
  kde <- density(df$weighted_mean_calBP, from = from, to = to, bw = bw, n = n)
  tibble(calBP = kde$x, density = kde$y)
}
