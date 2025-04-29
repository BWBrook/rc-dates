import::from("rcarbon", calibrate, combine, spd)
import::from("stats", density)
import::from("dplyr", mutate, filter, count, arrange, rename, select, if_else, pull)
import::from("tibble", tibble)
import::from("tidyr", crossing)

#' Calibrate terrestrial and marine radiocarbon dates
#'
#' Uses appropriate calibration curves (SHCal20 or Marine20) and assigns unique IDs based on ADSID.
#'
#' @param df Dataframe of filtered AustArch records.
#' @param terrestrial_curve Calibration curve for terrestrial samples.
#' @param marine_curve Calibration curve for marine samples.
#' @param reservoir_age Marine reservoir offset (default = 0).
#' @param reservoir_error Error on reservoir offset (default = 0).
#' @return A CalDates object with all calibrated records.
calibrate_dates <- function(df, terrestrial_curve = "shcal20", marine_curve = "marine20", reservoir_age = 0, reservoir_error = 0) {
  df <- df %>%
    mutate(UNIQUE_ID = as.character(ADSID)) %>%
    filter(!is.na(UNIQUE_ID))  # ensure all are present

  terrestrial_samples <- df %>% filter(TIME_SERIES_RELEVANT == "Terrestrial")
  marine_samples <- df %>% filter(TIME_SERIES_RELEVANT == "Marine")

  message("Calibrating ", nrow(terrestrial_samples), " terrestrial and ", nrow(marine_samples), " marine dates...")

  calibrated_list <- list()

  if (nrow(terrestrial_samples) > 0) {
    cal_terrestrial <- calibrate(
      x = terrestrial_samples$AGE,
      errors = terrestrial_samples$ERROR,
      calCurves = terrestrial_curve,
      ids = terrestrial_samples$UNIQUE_ID
    )
    calibrated_list <- append(calibrated_list, list(cal_terrestrial))
  }

  if (nrow(marine_samples) > 0) {
    cal_marine <- calibrate(
      x = marine_samples$AGE,
      errors = marine_samples$ERROR,
      calCurves = marine_curve,
      resOffsets = reservoir_age,
      resErrors = reservoir_error,
      ids = marine_samples$UNIQUE_ID
    )
    calibrated_list <- append(calibrated_list, list(cal_marine))
  }

  if (length(calibrated_list) == 1) {
    return(calibrated_list[[1]])
  } else {
    return(do.call(rcarbon::combine, calibrated_list))
  }
}

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
generate_iteration_curves <- function(df, index_df, iteration, 
                                      min_calBP = 651, max_calBP = 11650, standardise_mode = "area") {
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

#' Run a complete sub-sampling experiment (100% or partial sites)
#'
#' @param df                Curated calibrated data frame with row_index
#' @param strategy          "random", "oldest", "youngest", or "bracketed"
#' @param n_iter            Monte‑Carlo iterations (default = 1000)
#' @param n_samples         Dates per site for random sampling (ignored otherwise)
#' @param proportion        Proportion of sites to bias (NULL ⇒ 100% sites)
#' @param seed              Random seed for site and date sampling
#' @param standardise_mode  "area" or "max" scaling (default = "area")
#' @param rebin             If TRUE also return rebinned summary
#' @return A list(index_df, raw, summary, rebinned)
run_sampling_workflow <- function(
  df,
  strategy          = "random",
  n_iter            = 1000,
  n_samples         = 1,
  proportion        = NULL,
  seed              = 1234,
  standardise_mode  = "area",
  rebin             = TRUE
) {
  # If we're sampling 100% of the sites with a fully deterministic strategy, only do one iteration
  if (is.null(proportion) &&
      strategy %in% c("oldest","youngest","bracketed")) {
    message("Deterministic full-sample; forcing n_iter → 1")
    n_iter <- 1
  }

  # 1) generate site subsets if needed
  if (!is.null(proportion)) {
    site_subset_df <- generate_site_subset_df(
                       sites      = unique(df$SITE),
                       proportion = proportion,
                       n_iter     = n_iter,
                       seed       = seed
                     )
  } else {
    site_subset_df <- tibble(
                       iteration = rep(seq_len(n_iter), each = length(unique(df$SITE))),
                       SITE      = rep(unique(df$SITE), times = n_iter)
                     )
  }
  # 2) run site simulations
  raw_out <- run_site_simulation(
               df               = df,
               site_subset_df   = site_subset_df,
               strategy         = strategy,
               n_iter           = n_iter,
               n_samples        = n_samples,
               standardise_mode = standardise_mode,
               seed             = seed
             )
  # 3) summarise
  summary_df <- summarise_iteration_curves(raw_out)
  if (rebin) {
    summary_rebinned <- rebin_summary_df(summary_df)
    return(list(
      raw      = raw_out,
      summary  = summary_df,
      rebinned = summary_rebinned
    ))
  }
  return(list(raw = raw_out, summary = summary_df))
}

#' Run Monte-Carlo simulations for partial-site sampling (memory‑efficient)
#'
#' For each iteration, retains all dates from the untouched sites and only
#' the sampled dates from the biased sites, then computes SPD, FD, and KDE.
#' Internally rebuilds the index each iteration, so it handles random, oldest,
#' youngest, or bracketed strategies seamlessly.
#'
#' @param df               Calibrated reference data frame (must have row_index column).
#' @param site_subset_df   A tibble with columns (iteration, SITE) indicating which sites are biased per iteration.
#' @param strategy         One of: "random", "oldest", "youngest", or "bracketed".
#' @param n_iter           Number of Monte‑Carlo iterations.
#' @param n_samples        Number of dates per site for random sampling (ignored for other strategies).
#' @param min_calBP        Lower bound of calibrated years (default = 651).
#' @param max_calBP        Upper bound of calibrated years (default = 11650).
#' @param standardise_mode "area" or "max" scaling (default = "area").
#' @param seed             Optional seed for reproducibility of random site sampling only.
#' @return A data.frame with columns: calBP, value, method, iteration.
run_site_simulation <- function(
  df,
  site_subset_df,
  strategy        = "random",
  n_iter          = 1000,
  n_samples       = 1,
  min_calBP       = 651,
  max_calBP       = 11650,
  standardise_mode= "area",
  seed            = NULL
) {
  if (!"row_index" %in% names(df)) df <- mutate(df, row_index = row_number())
  all_sites <- unique(df$SITE)
  # first iteration to size buffer
  i0     <- 1
  sites0 <- site_subset_df %>% filter(iteration == i0) %>% pull(SITE)
  # build index0
  idx0   <- generate_index_dataframe(
              df             = df,
              n_iter         = 1,
              strategy       = strategy,
              n_samples      = n_samples,
              seed           = seed,
              site_subset_df = site_subset_df %>% filter(iteration == i0)
            ) %>% filter(iteration == i0)
  other0_rows <- df %>% filter(!SITE %in% sites0) %>% select(row_index) %>% mutate(iteration = i0)
  index0 <- bind_rows(
              idx0 %>% select(row_index, iteration),
              other0_rows
            )
  out0 <- generate_iteration_curves(
            df               = df,
            index_df         = index0,
            iteration        = i0,
            min_calBP        = min_calBP,
            max_calBP        = max_calBP,
            standardise_mode = standardise_mode
          )
  
  # preallocate
  rows0    <- nrow(out0)
  buf_size <- ceiling(rows0 * n_iter * 1.05)
  if (n_iter > 1) message("Preallocating ", buf_size, " rows for ", n_iter, " iterations…")
  store <- data.frame(
    calBP     = numeric(buf_size),
    value     = numeric(buf_size),
    method    = character(buf_size),
    iteration = integer(buf_size),
    stringsAsFactors = FALSE
  )
  store[1:rows0, ] <- out0
  ptr <- rows0 + 1
  # main loop
  for (i in seq_len(n_iter)[-1]) {
    sites_i <- site_subset_df %>% filter(iteration == i) %>% pull(SITE)
    idx_i <- generate_index_dataframe(
               df               = df,
               n_iter           = 1,
               strategy         = strategy,
               n_samples        = n_samples,
               seed             = NULL,
               site_subset_df   = site_subset_df %>% filter(iteration == i),
               iteration        = i
             ) %>%
             select(row_index, iteration)
    other_i_rows <- df %>% filter(!SITE %in% sites_i) %>% select(row_index) %>% mutate(iteration = i)
    index_i <- bind_rows(
                idx_i %>% select(row_index, iteration),
                other_i_rows
              )
    out_i <- generate_iteration_curves(
              df               = df,
              index_df         = index_i,
              iteration        = i,
              min_calBP        = min_calBP,
              max_calBP        = max_calBP,
              standardise_mode = standardise_mode
            )
    n_i <- nrow(out_i)
    if ((ptr + n_i - 1) > buf_size) stop("Buffer overflow at iteration ", i)
    store[ptr:(ptr + n_i - 1), ] <- out_i
    ptr <- ptr + n_i
    if (i %% 10 == 0) message("Completed iteration ", i)
  }
  store <- store[complete.cases(store), ]
  return(store)
}
