## Demo simulation helpers derived from the legacy resampling workflow

value_or <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}

#' Empty simulation manifest
#' @return Tibble with standard simulation manifest columns.
#' @export
empty_sim_manifest <- function() {
  import::from("tibble", "tibble")
  tibble(
    path = character(0),
    scenario = character(0),
    size = integer(0),
    origin = character(0)
  )
}

#' Normalize configured simulation mode
#' @param mode Character scalar from config.
#' @return One of `demo`, `precomputed`, or `none`.
#' @export
normalize_simulation_mode <- function(mode) {
  import::from("rlang", "abort")
  mode <- tolower(trimws(as.character(value_or(mode, "demo"))))
  valid <- c("demo", "precomputed", "none")
  if (!(mode %in% valid)) {
    abort(
      paste0("Unknown simulation mode: ", mode, ". Expected one of: ", paste(valid, collapse = ", ")),
      class = "rcdates_sim_config_error"
    )
  }
  mode
}

#' Map a demo scenario label to an underlying sampling strategy
#' @param scenario Scenario label such as `oldest` or `singleton`.
#' @return Character scalar strategy for the sampler.
#' @export
scenario_to_sampling_strategy <- function(scenario) {
  import::from("rlang", "abort")
  scenario <- as.character(scenario)
  switch(
    scenario,
    oldest = "oldest",
    youngest = "youngest",
    bracketed = "bracketed",
    singleton = "random",
    multiton = "random",
    abort(paste0("Unknown demo scenario: ", scenario), class = "rcdates_sim_config_error")
  )
}

#' Number of dates to sample for a demo scenario
#' @param scenario Scenario label.
#' @param singleton_n Integer count for singleton sampling.
#' @param multiton_n Integer count for multiton sampling.
#' @return Integer scalar.
#' @export
scenario_to_sample_n <- function(scenario, singleton_n = 1L, multiton_n = 3L) {
  scenario <- as.character(scenario)
  switch(
    scenario,
    singleton = as.integer(singleton_n),
    multiton = as.integer(multiton_n),
    1L
  )
}

#' Build demo simulation specifications from config
#' @param cfg Project config list.
#' @return Tibble of scenario specifications.
#' @export
build_demo_sim_specs <- function(cfg) {
  import::from("tibble", "tibble")
  import::from("tidyr", "crossing")
  import::from("dplyr", "mutate", "arrange")
  demo <- cfg$simulate$demo
  scenarios <- as.character(value_or(demo$strategies, c("oldest", "youngest", "bracketed", "singleton", "multiton")))
  proportions <- as.numeric(value_or(demo$site_proportions, c(0.5, 1.0)))
  specs <- crossing(
    scenario = scenarios,
    proportion = proportions
  ) |>
    mutate(
      iterations = as.integer(value_or(demo$iterations, 2L)),
      seed = as.integer(value_or(demo$seed, 1234L)),
      size = as.integer(round(proportion * 100)),
      sampling_strategy = vapply(scenario, scenario_to_sampling_strategy, character(1)),
      n_samples = vapply(
        scenario,
        scenario_to_sample_n,
        integer(1),
        singleton_n = as.integer(value_or(demo$singleton_n, 1L)),
        multiton_n = as.integer(value_or(demo$multiton_n, 3L))
      ),
      filename = sprintf("simulation_summary_%s_%d.csv", scenario, size)
    ) |>
    arrange(size, scenario)

  tibble::as_tibble(specs)
}

#' Write demo simulation summaries to CSV files
#' @param df Weighted-mean-ready filtered dataset.
#' @param cfg Project config.
#' @param specs Tibble from `build_demo_sim_specs()`.
#' @return Character vector of written file paths.
#' @export
write_demo_simulation_summaries <- function(df, cfg, specs) {
  import::from("fs", "dir_create", "path")
  import::from("readr", "write_csv")

  if (nrow(specs) == 0) return(character(0))

  out_dir <- path(cfg$outputs$dir, "simulations", "demo")
  dir_create(out_dir, recurse = TRUE)

  vapply(
    seq_len(nrow(specs)),
    function(i) {
      spec <- specs[i, , drop = FALSE]
      summary_tbl <- run_demo_sampling_workflow(df = df, cfg = cfg, spec = spec)
      out <- path(out_dir, spec$filename[[1]])
      write_csv(summary_tbl, out)
      out
    },
    character(1)
  )
}

#' Build a manifest tibble from known simulation paths
#' @param paths Character vector of simulation summary paths.
#' @param origin Source label such as `demo` or `precomputed`.
#' @return Tibble with manifest columns.
#' @export
build_sim_manifest_from_paths <- function(paths, origin = "unknown") {
  import::from("tibble", "tibble")
  import::from("dplyr", "arrange")

  paths <- unique(as.character(paths))
  paths <- paths[nzchar(paths)]
  if (length(paths) == 0) return(empty_sim_manifest())
  info <- lapply(paths, parse_sim_filename)
  tibble(
    path = normalizePath(paths, winslash = "/", mustWork = FALSE),
    scenario = vapply(info, function(x) x$scenario, character(1)),
    size = vapply(info, function(x) x$size, integer(1)),
    origin = rep(origin, length(paths))
  ) |>
    arrange(size, scenario)
}

#' Sample up to `n` random rows per site
#' @param df Data frame containing `SITE`.
#' @param n Number of rows to sample per site.
#' @return Data frame with sampled rows.
#' @export
sample_random_n <- function(df, n) {
  import::from("dplyr", "group_by", "group_modify", "ungroup")
  df |>
    group_by(SITE) |>
    group_modify(~ dplyr::slice_sample(.x, n = min(as.integer(n), nrow(.x)), replace = FALSE)) |>
    ungroup()
}

#' Sample oldest or youngest row per site
#' @param df Data frame containing `SITE` and `AGE`.
#' @param type Either `oldest` or `youngest`.
#' @return Data frame with sampled rows.
#' @export
sample_extreme <- function(df, type = c("oldest", "youngest")) {
  type <- match.arg(type)
  if (identical(type, "oldest")) {
    df |>
      dplyr::group_by(SITE) |>
      dplyr::slice_max(AGE, n = 1, with_ties = FALSE) |>
      dplyr::ungroup()
  } else {
    df |>
      dplyr::group_by(SITE) |>
      dplyr::slice_min(AGE, n = 1, with_ties = FALSE) |>
      dplyr::ungroup()
  }
}

#' Generate site subsets for demo sampling
#' @param sites Character vector of site names.
#' @param proportion Proportion of sites to resample each iteration.
#' @param n_iter Number of iterations.
#' @param seed Integer seed.
#' @return Tibble with columns `iteration` and `SITE`.
#' @export
generate_site_subset_df <- function(sites, proportion = 0.5, n_iter = 10L, seed = 1234L) {
  import::from("tibble", "tibble")
  sites <- unique(as.character(sites))
  if (length(sites) == 0) return(tibble(iteration = integer(0), SITE = character(0)))
  n_sites <- length(sites)
  n_select <- max(1L, min(n_sites, as.integer(round(n_sites * proportion))))
  set.seed(as.integer(seed))
  rows <- lapply(
    seq_len(as.integer(n_iter)),
    function(i) {
      selected <- if (n_select >= n_sites) sites else sample(sites, size = n_select, replace = FALSE)
      tibble(iteration = i, SITE = selected)
    }
  )
  dplyr::bind_rows(rows)
}

#' Build sampled row indices for a demo iteration
#' @param df Input dataset with `SITE`, `AGE`, and `row_index`.
#' @param selected_sites Character vector of sites to bias this iteration.
#' @param strategy Sampling strategy.
#' @param n_samples Dates per site for random sampling.
#' @param seed Integer seed for the iteration.
#' @return Integer row indices to retain.
#' @export
build_demo_iteration_indices <- function(df, selected_sites, strategy, n_samples = 1L, seed = 1234L) {
  selected_sites <- unique(as.character(selected_sites))
  if (!"row_index" %in% names(df)) {
    df <- dplyr::mutate(df, row_index = dplyr::row_number())
  }
  selected_df <- df[df$SITE %in% selected_sites, , drop = FALSE]
  other_rows <- df$row_index[!(df$SITE %in% selected_sites)]
  set.seed(as.integer(seed))
  sampled <- switch(
    strategy,
    random = sample_random_n(selected_df, n = n_samples),
    oldest = sample_extreme(selected_df, type = "oldest"),
    youngest = sample_extreme(selected_df, type = "youngest"),
    bracketed = dplyr::bind_rows(
      sample_extreme(selected_df, type = "oldest"),
      sample_extreme(selected_df, type = "youngest")
    ) |>
      dplyr::distinct(row_index, .keep_all = TRUE),
    selected_df
  )
  sort(unique(c(other_rows, sampled$row_index)))
}

#' Standardize SPD/FD/KDE outputs to a shared long format
#' @param spd_tbl SPD tibble.
#' @param fd_tbl FD tibble.
#' @param kde_tbl KDE tibble.
#' @param standardise_mode Standardization mode.
#' @return Tibble with `calBP`, `value`, and `method`.
#' @export
standardise_curve_outputs <- function(spd_tbl, fd_tbl, kde_tbl, standardise_mode = "area") {
  import::from("dplyr", "bind_rows", "mutate")
  import::from("tibble", "tibble")

  spd_df <- tibble(calBP = spd_tbl$calBP, value = spd_tbl$PrDens, method = "SPD")
  kde_df <- tibble(calBP = kde_tbl$calBP, value = kde_tbl$density, method = "KDE")
  fd_df <- tibble(calBP = fd_tbl$bin, value = fd_tbl$value, method = "FD")
  out <- bind_rows(spd_df, fd_df, kde_df)

  if (identical(standardise_mode, "area")) {
    out <- out |>
      dplyr::group_by(method) |>
      dplyr::mutate(
        value = dplyr::case_when(
          method %in% c("SPD", "KDE") ~ value / sum(value, na.rm = TRUE),
          TRUE ~ value
        )
      ) |>
      dplyr::ungroup()
  }

  out
}

#' Generate SPD/FD/KDE curves for one demo iteration
#' @param sample_df Sampled data frame for one iteration.
#' @param cfg Project config.
#' @return Tibble with long-form curve data.
#' @export
run_demo_iteration_curves <- function(sample_df, cfg) {
  fit <- NULL
  invisible(capture.output({
    fit <- calibrate_and_spd(
      sample_df,
      time_range = cfg$calibration$time_range,
      terrestrial_curve = cfg$calibration$terrestrial_curve,
      marine_curve = cfg$calibration$marine_curve
    )
  }))
  wm <- filter_sites_min_calibrated_dates(sample_df, fit$calibrated, min_dates = 1)
  spd_tbl <- spd_to_tibble(fit$spd)
  fd_tbl <- fd_from_weighted_means(
    wm,
    bin_width = 100,
    min_age = min(cfg$calibration$time_range),
    max_age = max(cfg$calibration$time_range)
  )
  kde_tbl <- kde_from_weighted_means(
    wm,
    from = min(cfg$calibration$time_range),
    to = max(cfg$calibration$time_range),
    bw = 100,
    n = 512
  )
  standardise_curve_outputs(spd_tbl, fd_tbl, kde_tbl, standardise_mode = "area")
}

#' Summarise simulation curves across iterations
#' @param df Long-form iteration tibble.
#' @return Tibble with mean/lower/upper by method and calBP.
#' @export
summarise_iteration_curves <- function(df) {
  if (nrow(df) == 0) {
    return(tibble::tibble(
      method = character(0),
      calBP = numeric(0),
      mean = numeric(0),
      lower = numeric(0),
      upper = numeric(0)
    ))
  }

  df |>
    dplyr::group_by(method, calBP) |>
    dplyr::summarise(
      mean = mean(value, na.rm = TRUE),
      lower = stats::quantile(value, 0.025, na.rm = TRUE),
      upper = stats::quantile(value, 0.975, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::group_by(method) |>
    dplyr::mutate(
      mean = dplyr::if_else(method == "FD", mean / sum(mean[method == "FD"], na.rm = TRUE), mean),
      lower = dplyr::if_else(method == "FD", lower / sum(lower[method == "FD"], na.rm = TRUE), lower),
      upper = dplyr::if_else(method == "FD", upper / sum(upper[method == "FD"], na.rm = TRUE), upper)
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(method, calBP)
}

#' Rebin simulation summaries to coarser bins
#' @param summary_df Tibble from `summarise_iteration_curves()`.
#' @param bin_width Bin width in cal BP.
#' @return Rebinned summary tibble.
#' @export
rebin_summary_df <- function(summary_df, bin_width = 100) {
  summary_df |>
    dplyr::mutate(bin = floor(calBP / bin_width) * bin_width) |>
    dplyr::group_by(method, bin) |>
    dplyr::summarise(
      mean = sum(mean, na.rm = TRUE),
      lower = sum(lower, na.rm = TRUE),
      upper = sum(upper, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::rename(calBP = bin) |>
    dplyr::arrange(method, calBP)
}

#' Run one demo simulation scenario end-to-end
#' @param df Input filtered dataset.
#' @param cfg Project config.
#' @param spec One-row tibble from `build_demo_sim_specs()`.
#' @return Tibble matching the `simulation_summary_*.csv` schema.
#' @export
run_demo_sampling_workflow <- function(df, cfg, spec) {
  import::from("dplyr", "bind_rows", "mutate", "row_number")

  if (nrow(spec) != 1) {
    rlang::abort("`spec` must contain exactly one scenario row.", class = "rcdates_sim_config_error")
  }

  df <- mutate(df, row_index = row_number())
  sites <- unique(df$SITE)
  site_subset_df <- generate_site_subset_df(
    sites = sites,
    proportion = spec$proportion[[1]],
    n_iter = spec$iterations[[1]],
    seed = spec$seed[[1]]
  )

  curves <- lapply(
    seq_len(spec$iterations[[1]]),
    function(i) {
      selected_sites <- site_subset_df$SITE[site_subset_df$iteration == i]
      idx <- build_demo_iteration_indices(
        df = df,
        selected_sites = selected_sites,
        strategy = spec$sampling_strategy[[1]],
        n_samples = spec$n_samples[[1]],
        seed = spec$seed[[1]] + i + spec$size[[1]]
      )
      iter_df <- df[df$row_index %in% idx, , drop = FALSE]
      run_demo_iteration_curves(iter_df, cfg) |>
        mutate(iteration = i)
    }
  )

  bind_rows(curves) |>
    summarise_iteration_curves() |>
    dplyr::select(method, calBP, mean, lower, upper)
}
