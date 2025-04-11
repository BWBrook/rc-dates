import::from("rcarbon", spd)
import::from("stats", density)
import::from("dplyr", mutate, filter, count, arrange, rename, select, if_else)
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
    mutate(value = n / sum(n) / bin_width) %>%  # Turn counts into density
    select(bin, value) %>%
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
#' @param standardise_mode Rescale to unit area or max (default = area)
#' @return A list with elements: spd, fd, kde
generate_iteration_curves <- function(df, index_df, iteration, min_calBP = 651, max_calBP = 11650, standardise_mode = "area") {
  # Pull row indices for this iteration
  selected_rows <- index_df %>%
    filter(iteration == !!iteration) %>%
    pull(row_index)

  sample_df <- df[selected_rows, ]

  cal_dates <- calibrate_dates(sample_df)

  spd_out <- generate_spd_baseline(cal_dates, time_range = c(max_calBP, min_calBP))

  sample_df <- sample_df %>%
    mutate(weighted_mean_calBP = sapply(cal_dates$grids, function(grid) {
      sum(grid$calBP * grid$PrDens)
    }))

  fd_out <- generate_fd_baseline(sample_df, min_age = min_calBP, max_age = max_calBP)
  kde_out <- generate_kde_baseline(sample_df, from = min_calBP, to = max_calBP)

  bind_rows(
    standardise_curve_output(spd_out, "SPD", mode = standardise_mode),
    standardise_curve_output(fd_out,  "FD",  mode = standardise_mode),
    standardise_curve_output(kde_out, "KDE", mode = standardise_mode)
  ) %>% mutate(iteration = iteration)
}

#' Convert SPD, FD, or KDE output into a standardised long-form tibble
#'
#' @param obj Output from one of the three methods
#' @param method One of "SPD", "FD", or "KDE"
#' @param standardise Should values be rescaled? (default = TRUE)
#' @param mode One of "max" or "area" for scaling method (default = "area")
#' @return Tibble with calBP, value, method
standardise_curve_output <- function(obj, method, standardise = TRUE, mode = "area") {
  df <- switch(method,
    SPD = obj$grid %>% select(calBP, value = PrDens),
    FD  = obj %>% rename(calBP = bin),  # just rename bin, 'value' already exists
    KDE = obj %>% rename(value = density),
    stop("Unknown method")
  )
  
  if (standardise) {
    df <- df %>%
      mutate(value = case_when(
        mode == "max" ~ value / max(value, na.rm = TRUE),
        mode == "area" & method == "SPD" ~ value / sum(value, na.rm = TRUE),
        mode == "area" & method == "KDE" ~ value / sum(value, na.rm = TRUE),
        TRUE ~ value
      ))
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
#' @param standardise_mode Rescale to unit area or max (default = area)
#' @return A long-form dataframe with calBP, value, method, and iteration
run_simulation_curves <- function(df, index_df, n_iter = 10, min_calBP = 651, max_calBP = 11650, standardise_mode = "area") {
  results <- vector("list", n_iter)

  for (i in seq_len(n_iter)) {
    results[[i]] <- generate_iteration_curves(
      df = df,
      index_df = index_df,
      iteration = i,
      min_calBP = min_calBP,
      max_calBP = max_calBP,
      standardise_mode = standardise_mode
    )
  }

  bind_rows(results)
}

#' Run simulation curves in a preallocated dataframe to avoid list growth
#'
#' Runs one test iteration to get row count, then preallocates a big dataframe
#' to store results from all iterations. Preserves exact values per iteration
#' for later quantile-based summarisation. Very efficient memory-wise.
#'
#' @param df Full data (e.g., austarch_final_calibrated_df)
#' @param index_df Row index dataframe from generate_index_dataframe()
#' @param n_iter Number of iterations (default = 1000)
#' @param min_calBP Minimum calendar BP (default = 651)
#' @param max_calBP Maximum calendar BP (default = 11650)
#' @param standardise_mode "area" or "max" (default = "area")
#' @return A dataframe of all simulation results (one row per calBP × method × iteration)
run_simulation_curves_preallocated_light <- function(
  df,
  index_df,
  n_iter = 1000,
  min_calBP = 651,
  max_calBP = 11650,
  standardise_mode = "area"
) {
  message("Running test iteration to estimate row count...")

  # First iteration to estimate max size
  first_iter <- generate_iteration_curves(
    df = df,
    index_df = index_df,
    iteration = 1,
    min_calBP = min_calBP,
    max_calBP = max_calBP,
    standardise_mode = standardise_mode
  )

  rows_first <- nrow(first_iter)
  buffer_rows <- ceiling(rows_first * n_iter * 1.05)

  message("Preallocating ", buffer_rows, " rows...")

  store <- data.frame(
    calBP = numeric(buffer_rows),
    value = numeric(buffer_rows),
    method = character(buffer_rows),
    iteration = integer(buffer_rows),
    stringsAsFactors = FALSE
  )

  store[1:rows_first, ] <- data.frame(
    calBP = first_iter$calBP,
    value = first_iter$value,
    method = first_iter$method,
    iteration = 1,
    stringsAsFactors = FALSE
  )

  row_pointer <- rows_first + 1

  for (i in 2:n_iter) {
    iteration_df <- generate_iteration_curves(
      df = df,
      index_df = index_df,
      iteration = i,
      min_calBP = min_calBP,
      max_calBP = max_calBP,
      standardise_mode = standardise_mode
    )

    rows_this <- nrow(iteration_df)

    if ((row_pointer + rows_this - 1) > buffer_rows) {
      stop("Buffer too small — try increasing the preallocation margin.")
    }

    store[row_pointer:(row_pointer + rows_this - 1), ] <- data.frame(
      calBP = iteration_df$calBP,
      value = iteration_df$value,
      method = iteration_df$method,
      iteration = i,
      stringsAsFactors = FALSE
    )

    row_pointer <- row_pointer + rows_this
    message("Completed iteration ", i)
  }

  # Trim unused NA rows
  store <- store[complete.cases(store), ]

  return(store)
}

#' Run partial site sampling simulation using a preallocated data frame
#'
#' Merges sampled + full rows per iteration and stores results in a memory-efficient structure.
#' Suitable for 50% or 75% site-level bias tests. Returns the full raw output across all iterations.
#'
#' @param df Full calibrated dataset (e.g., austarch_final_calibrated_df)
#' @param sampled_index_df Row index dataframe from generate_index_dataframe()
#' @param sampled_sites_df Subset dataframe from generate_site_subset_df()
#' @param n_iter Number of iterations (default = 1000)
#' @param min_calBP Minimum year BP (default = 651)
#' @param max_calBP Maximum year BP (default = 11650)
#' @param standardise_mode "area" or "max" (default = "area")
#' @return A long-form dataframe with calBP, value, method, and iteration
run_simulation_curves_partial_preallocated <- function(
  df,
  sampled_index_df,
  sampled_sites_df,
  n_iter = 1000,
  min_calBP = 651,
  max_calBP = 11650,
  standardise_mode = "area"
) {
  message("Running iteration 1 to estimate row count...")

  # Construct merged dataset for iteration 1
  sampled_rows_iter1 <- construct_sampled_dataset(
    df = df,
    sampled_index_df = sampled_index_df,
    sampled_sites_df = sampled_sites_df,
    iteration = 1
  )

  df_iter1 <- df[sampled_rows_iter1$row_index, ]

  iteration_1_output <- generate_iteration_curves(
    df = df_iter1,
    index_df = NULL,  # already sampled
    iteration = 1,
    min_calBP = min_calBP,
    max_calBP = max_calBP,
    standardise_mode = standardise_mode
  )

  row_count_iter <- nrow(iteration_1_output)
  total_rows <- ceiling(row_count_iter * n_iter * 1.05)

  message("Preallocating ", total_rows, " rows...")

  store <- data.frame(
    calBP = numeric(total_rows),
    value = numeric(total_rows),
    method = character(total_rows),
    iteration = integer(total_rows),
    stringsAsFactors = FALSE
  )

  store[1:row_count_iter, ] <- data.frame(
    calBP = iteration_1_output$calBP,
    value = iteration_1_output$value,
    method = iteration_1_output$method,
    iteration = 1,
    stringsAsFactors = FALSE
  )

  row_pointer <- row_count_iter + 1

  for (i in 2:n_iter) {
    sampled_rows <- construct_sampled_dataset(
      df = df,
      sampled_index_df = sampled_index_df,
      sampled_sites_df = sampled_sites_df,
      iteration = i
    )

    df_iter <- df[sampled_rows$row_index, ]

    iteration_df <- generate_iteration_curves(
      df = df_iter,
      index_df = NULL,
      iteration = i,
      min_calBP = min_calBP,
      max_calBP = max_calBP,
      standardise_mode = standardise_mode
    )

    n_rows <- nrow(iteration_df)
    if ((row_pointer + n_rows - 1) > total_rows) {
      stop("Buffer too small. Increase preallocation multiplier.")
    }

    store[row_pointer:(row_pointer + n_rows - 1), ] <- data.frame(
      calBP = iteration_df$calBP,
      value = iteration_df$value,
      method = iteration_df$method,
      iteration = i,
      stringsAsFactors = FALSE
    )

    row_pointer <- row_pointer + n_rows

    if (i %% 50 == 0) message("Completed iteration ", i)
  }

  store <- store[complete.cases(store), ]
  return(store)
}
