import::from("rcarbon", spd)
import::from("stats", density)
import::from("dplyr", mutate, filter, count, arrange, rename, select)
import::from("tibble", tibble)

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

#' Generate SPD, FD, and KDE for a single iteration using sampled row indices
#'
#' @param df Full calibrated dataframe (e.g., austarch_final_calibrated_df)
#' @param index_df Subsampled index dataframe from generate_index_dataframe()
#' @param iteration Iteration number to extract
#' @param min_calBP Minimum calendar age (default = 651)
#' @param max_calBP Maximum calendar age (default = 11650)
#' @return A list with elements: spd, fd, kde
generate_iteration_curves <- function(df, index_df, iteration, min_calBP = 651, max_calBP = 11650) {
  # Pull row indices for this iteration
  selected_rows <- index_df %>%
    filter(iteration == !!iteration) %>%
    pull(row_index)

  # Extract sample
  sample_df <- df[selected_rows, ]

  # Calibrate (using ADSID as ID)
  cal_dates <- calibrate_dates(sample_df)

  # SPD (on full curves)
  spd_out <- generate_spd_baseline(cal_dates, time_range = c(max_calBP, min_calBP))

  # Weighted mean per date (for FD/KDE)
  sample_df <- sample_df %>%
    mutate(weighted_mean_calBP = sapply(cal_dates$grids, function(grid) {
      sum(grid$calBP * grid$PrDens)
    }))

  # FD (binned)
  fd_out <- generate_fd_baseline(sample_df, min_age = min_calBP, max_age = max_calBP)

  # KDE (smoothed)
  kde_out <- generate_kde_baseline(sample_df, from = min_calBP, to = max_calBP)

  return(bind_rows(
    standardise_curve_output(spd_out, "SPD"),
    standardise_curve_output(fd_out, "FD"),
    standardise_curve_output(kde_out, "KDE")
  ) %>% mutate(iteration = iteration))
}

#' Convert SPD, FD, or KDE output into a standardised, long-form tibble
#'
#' @param obj Output from one of the three methods
#' @param method One of "SPD", "FD", or "KDE"
#' @param standardise Should values be scaled to max = 1?
#' @return Tibble with calBP, value, method
standardise_curve_output <- function(obj, method, standardise = TRUE) {
  df <- switch(method,
    SPD = obj$grid %>% select(calBP, value = PrDens),
    FD  = obj %>% rename(calBP = bin, value = n),
    KDE = obj %>% rename(value = density),
    stop("Unknown method")
  )

  if (standardise) {
    df <- df %>% mutate(value = value / max(value, na.rm = TRUE))
  }

  df %>% mutate(method = method)
}

#' Run SPD, FD, and KDE generation over multiple iterations of a subsampling strategy
#'
#' @param df The full calibrated dataframe (e.g., austarch_final_calibrated_df)
#' @param index_df The sampled index dataframe from generate_index_dataframe()
#' @param n_iter Number of iterations to run
#' @param min_calBP Minimum calendar BP for analysis window (default = 651)
#' @param max_calBP Maximum calendar BP (default = 11650)
#' @return A long-form dataframe with calBP, value, method, and iteration
run_simulation_curves <- function(df, index_df, n_iter = 10, min_calBP = 651, max_calBP = 11650) {
  results <- vector("list", n_iter)

  for (i in seq_len(n_iter)) {
    iter_df <- generate_iteration_curves(
      df = df,
      index_df = index_df,
      iteration = i,
      min_calBP = min_calBP,
      max_calBP = max_calBP
    )

    results[[i]] <- iter_df
  }

  bind_rows(results)
}

