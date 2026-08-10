# Dataset generation and replicate evaluation --------------------------------

simulate_population_data_set <- function(
  truth,
  prop,
  specification,
  observation_model = "curve_mean"
) {
  observation_model <- normalize_population_observation_model(observation_model)
  truth_spec <- population_truth_specification(
    truth,
    specification$ratio,
    specification$min_age,
    specification$max_age
  )
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
    truth_spec$family,
    lin = rtlin(
      n_dates,
      slope = truth_spec$parameter,
      low = specification$min_age,
      up = specification$max_age
    ),
    exp = rtexp(
      n_dates,
      rate = truth_spec$parameter,
      low = specification$min_age,
      up = specification$max_age
    ),
    uni = stats::runif(
      n_dates,
      min = specification$min_age,
      max = specification$max_age
    )
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

  # Random-2 is appended on an isolated RNG state so it cannot perturb the
  # original dates, treated sites, or seven retained strategies.
  draw_random_two <- function() {
    preserved_state <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    on.exit(assign(".Random.seed", preserved_state, envir = .GlobalEnv), add = TRUE)
    retained <- integer(n_dates)
    for (site in seq_len(n_sites)) {
      rows <- which(site_index == site)
      retained[rows[sample.int(length(rows), 2L)]] <- 1L
    }
    retained[!is_subsampled] <- 1L
    retained
  }
  selected$r_2 <- draw_random_two()

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
    r_2 = selected$r_2,
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
  truth,
  strategy,
  prop,
  sim,
  specification,
  drop_empty = FALSE
) {
  grids <- simulated_data$grid[as.logical(simulated_data[[strategy]])]
  low <- specification$min_age
  up <- specification$max_age
  truth_spec <- population_truth_specification(truth, specification$ratio, low, up)
  likelihood_data <- prepare_population_likelihood_data(
    grids,
    low,
    up,
    drop_empty = drop_empty
  )
  bounds <- population_fit_bounds(low, up)

  fit_model <- function(objective, interval, type) {
    stats::optimize(
      objective,
      interval,
      likelihood_data = likelihood_data,
      low = low,
      up = up,
      type = type,
      tol = bounds$tolerance
    )
  }
  fits <- list(
    l1 = list(
      lin = fit_model(population_nll_linear, bounds$lin, "l1"),
      exp = fit_model(population_nll_exponential, bounds$exp, "l1")
    ),
    l2 = list(
      lin = fit_model(population_nll_linear, bounds$lin, "l2"),
      exp = fit_model(population_nll_exponential, bounds$exp, "l2")
    )
  )

  select_for_type <- function(type) {
    fit <- fits[[type]]
    selected <- select_population_models_from_criterion(
      population_pointwise_criterion(
        fit$lin,
        fit$exp,
        type,
        likelihood_data,
        low,
        up
      ),
      type = type
    )
    estimates <- c(uni = 0, lin = fit$lin$minimum / 1e6, exp = fit$exp$minimum / 1e3)
    at_boundary <- c(
      uni = FALSE,
      lin = population_fit_at_boundary(
        fit$lin$minimum,
        bounds$lin,
        bounds$tolerance
      ),
      exp = population_fit_at_boundary(
        fit$exp$minimum,
        bounds$exp,
        bounds$tolerance
      )
    )
    selected$estimate <- unname(estimates[selected$model])
    selected$estimate_log_ratio <- vapply(seq_len(nrow(selected)), function(index) {
      population_log_density_ratio(
        selected$model[[index]],
        selected$estimate[[index]],
        low,
        up
      )
    }, numeric(1))
    selected$boundary <- unname(at_boundary[selected$model])
    selected
  }

  selected <- rbind(select_for_type("l1"), select_for_type("l2"))
  selected$bias_log_ratio <- NA_real_
  generating_family <- selected$model == truth_spec$family & truth_spec$family != "uni"
  selected$bias_log_ratio[generating_family] <-
    selected$estimate_log_ratio[generating_family] - truth_spec$log_density_ratio

  selected$sim <- as.integer(sim)
  selected$true <- truth
  selected$true_family <- truth_spec$family
  selected$true_direction <- truth_spec$direction
  selected$true_log_ratio <- truth_spec$log_density_ratio
  selected$prop <- prop
  selected$strategy <- strategy
  selected$n_observations <- likelihood_data$n_dates
  selected$n_dropped <- likelihood_data$n_dropped
  selected[, c(
    "sim", "true", "true_family", "true_direction", "true_log_ratio", "prop",
    "strategy", "type", "model", "min", "ose", "estimate", "estimate_log_ratio",
    "bias_log_ratio", "boundary", "n_observations", "n_dropped"
  )]
}

#' Run one deterministic Stage 2 signed-model simulation replicate
#' @param sim Positive replicate number.
#' @param truth Generating truth.
#' @param prop Proportion of sites subjected to within-site retention.
#' @param specification Output of [prepare_population_simulation()].
#' @param master_seed Master seed for the production matrix.
#' @return A complete 48-row signed-model result block.
run_population_simulation_replicate <- function(
  sim,
  truth,
  prop,
  specification,
  master_seed = 1234L
) {
  requireNamespace("rcarbon", quietly = TRUE)
  seed <- production_simulation_seed(truth, prop, sim, master_seed)
  set.seed(seed, kind = "L'Ecuyer-CMRG")
  simulated_data <- simulate_population_data_set(truth, prop, specification)
  result <- do.call(rbind, lapply(specification$strategies, function(strategy) {
    evaluate_population_models(
      simulated_data,
      truth = truth,
      strategy = strategy,
      prop = prop,
      sim = sim,
      specification = specification
    )
  }))
  rownames(result) <- NULL
  validate_population_simulation_results(result, design = "signed-v1")
  result
}
