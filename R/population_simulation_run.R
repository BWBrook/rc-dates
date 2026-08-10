# Dataset generation and replicate evaluation --------------------------------

simulate_population_data_set <- function(
  true_model,
  prop,
  specification,
  observation_model = "curve_mean"
) {
  observation_model <- normalize_population_observation_model(observation_model)
  n_sites <- specification$n_sites
  dates_per_site <- rtnbinom(
    n_sites,
    mu = specification$fit_n_dates$estimate[["mu"]],
    size = specification$fit_n_dates$estimate[["size"]],
    low = 5
  )
  site_index <- rep(seq_len(n_sites), times = dates_per_site)
  n_dates <- length(site_index)

  calendar_age <- switch(
    true_model,
    lin = rtlin(
      n_dates,
      slope = specification$slope,
      low = specification$min_age,
      up = specification$max_age
    ),
    exp = rtexp(
      n_dates,
      rate = specification$rate,
      low = specification$min_age,
      up = specification$max_age
    ),
    uni = stats::runif(n_dates, min = specification$min_age, max = specification$max_age)
  )
  uncalibration <- rcarbon::uncalibrate(calendar_age, calCurves = "shcal20")
  expected_uncalibrated <- uncalibration$ccCRA
  errors <- simulate_error(expected_uncalibrated, specification$fit_age_to_error)
  structure_rng_state <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  uncalibrated <- if (identical(observation_model, "realised")) {
    draw_realised_population_cra(
      calendar_age = calendar_age,
      errors = errors,
      structure_rng_state = structure_rng_state
    )
  } else {
    expected_uncalibrated
  }
  calibrated <- rcarbon::calibrate(
    x = uncalibrated,
    errors = errors,
    timeRange = c(15000, 0),
    calCurves = "shcal20",
    verbose = FALSE
  )
  median_age <- summary(calibrated)[, "MedianBP"]

  selected <- list(
    r_1 = integer(n_dates),
    r_3 = integer(n_dates),
    r_5 = integer(n_dates),
    r_old = integer(n_dates),
    r_young = integer(n_dates)
  )
  for (site in seq_len(n_sites)) {
    rows <- which(site_index == site)
    selected$r_1[rows[sample.int(length(rows), 1L)]] <- 1L
    selected$r_3[rows[sample.int(length(rows), 3L)]] <- 1L
    selected$r_5[rows[sample.int(length(rows), 5L)]] <- 1L
    selected$r_old[rows[which.max(median_age[rows])]] <- 1L
    selected$r_young[rows[which.min(median_age[rows])]] <- 1L
  }

  n_subsampled <- as.integer(round(prop * n_sites))
  if (abs(n_subsampled - prop * n_sites) > sqrt(.Machine$double.eps)) {
    abort_population_simulation(
      "The selected site proportion does not yield an integer number of sites.",
      "rcdates_sim_spec_error"
    )
  }
  subsampled_sites <- sample.int(n_sites, n_subsampled)
  is_subsampled <- site_index %in% subsampled_sites
  for (strategy in names(selected)) selected[[strategy]][!is_subsampled] <- 1L

  tibble::tibble(
    site = paste0("site_", site_index),
    site_treated = as.integer(is_subsampled),
    age_calendar = calendar_age,
    age_uncalibrated_expected = expected_uncalibrated,
    age_uncalibrated = uncalibrated,
    error = errors,
    age_calibrated_median = median_age,
    observation_model = observation_model,
    r_1 = selected$r_1,
    r_3 = selected$r_3,
    r_5 = selected$r_5,
    r_old = selected$r_old,
    r_young = selected$r_young,
    r_bracket = as.integer(selected$r_old | selected$r_young),
    r_all = 1L,
    grid = calibrated$grids
  )
}

evaluate_population_models <- function(
  simulated_data,
  true_model,
  strategy,
  prop,
  sim,
  specification,
  drop_empty = FALSE
) {
  grids <- simulated_data$grid[as.logical(simulated_data[[strategy]])]
  low <- specification$min_age
  up <- specification$max_age
  likelihood_data <- prepare_population_likelihood_data(
    grids,
    low,
    up,
    drop_empty = drop_empty
  )
  linear_bounds <- c(1e-12, 2 / (up - low)^2) * 1e6
  exponential_bounds <- c(1e-10, 1e-3) * 1e3

  linear_l1 <- stats::optimize(
    population_nll_linear,
    linear_bounds,
    likelihood_data = likelihood_data,
    low = low,
    up = up,
    type = "l1"
  )
  linear_l2 <- stats::optimize(
    population_nll_linear,
    linear_bounds,
    likelihood_data = likelihood_data,
    low = low,
    up = up,
    type = "l2"
  )
  exponential_l1 <- stats::optimize(
    population_nll_exponential,
    exponential_bounds,
    likelihood_data = likelihood_data,
    low = low,
    up = up,
    type = "l1"
  )
  exponential_l2 <- stats::optimize(
    population_nll_exponential,
    exponential_bounds,
    likelihood_data = likelihood_data,
    low = low,
    up = up,
    type = "l2"
  )

  selected_l1 <- select_population_models_from_aic(
    population_pointwise_aic(
      linear_l1,
      exponential_l1,
      "l1",
      likelihood_data,
      low,
      up
    ),
    type = "l1"
  )
  selected_l2 <- select_population_models_from_aic(
    population_pointwise_aic(
      linear_l2,
      exponential_l2,
      "l2",
      likelihood_data,
      low,
      up
    ),
    type = "l2"
  )
  selected <- rbind(selected_l1, selected_l2)
  selected$bias <- NA_real_
  if (true_model == "lin") {
    selected$bias[selected$model == "lin" & selected$type == "l1"] <-
      linear_l1$minimum / 1e6 - specification$slope
    selected$bias[selected$model == "lin" & selected$type == "l2"] <-
      linear_l2$minimum / 1e6 - specification$slope
  } else if (true_model == "exp") {
    selected$bias[selected$model == "exp" & selected$type == "l1"] <-
      exponential_l1$minimum / 1e3 - specification$rate
    selected$bias[selected$model == "exp" & selected$type == "l2"] <-
      exponential_l2$minimum / 1e3 - specification$rate
  }

  selected$sim <- as.integer(sim)
  selected$true <- true_model
  selected$prop <- prop
  selected$strategy <- strategy
  selected$n_observations <- likelihood_data$n_dates
  selected$n_dropped <- likelihood_data$n_dropped
  selected[, c(
    "sim", "true", "prop", "strategy", "type", "model", "min", "ose", "bias",
    "n_observations", "n_dropped"
  )]
}

#' Run one deterministic production population-model simulation replicate
#' @param sim Positive replicate number.
#' @param true_model Generating population model.
#' @param prop Proportion of sites subjected to within-site subsampling.
#' @param specification Output of [prepare_population_simulation()].
#' @param master_seed Master seed for the production matrix.
#' @return A complete 42-row model-selection result block.
run_population_simulation_replicate <- function(
  sim,
  true_model,
  prop,
  specification,
  master_seed = 1234L
) {
  requireNamespace("rcarbon", quietly = TRUE)
  seed <- production_simulation_seed(true_model, prop, sim, master_seed)
  set.seed(seed, kind = "L'Ecuyer-CMRG")
  simulated_data <- simulate_population_data_set(true_model, prop, specification)
  result <- do.call(rbind, lapply(specification$strategies, function(strategy) {
    evaluate_population_models(
      simulated_data,
      true_model = true_model,
      strategy = strategy,
      prop = prop,
      sim = sim,
      specification = specification
    )
  }))
  rownames(result) <- NULL
  validate_population_simulation_results(result)
  result
}
