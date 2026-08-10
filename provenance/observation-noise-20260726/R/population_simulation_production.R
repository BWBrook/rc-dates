# Production population-model simulation helpers ---------------------------

abort_population_simulation <- function(message, class) {
  import::from("rlang", "abort")
  abort(message, class = class)
}

#' Validate the provenance fingerprint attached to a simulation checkpoint
#' @param results Checkpoint data frame.
#' @param expected Named provenance list for the requested production run.
#' @return `TRUE` invisibly when the checkpoint fingerprint matches exactly.
#' @export
validate_population_checkpoint_provenance <- function(results, expected) {
  observed <- attr(results, "production_provenance", exact = TRUE)
  if (is.null(observed) || !identical(observed, expected)) {
    mismatch <- if (is.null(observed)) {
      "checkpoint is unstamped"
    } else {
      fields <- union(names(observed), names(expected))
      different <- fields[!vapply(fields, function(field) {
        identical(observed[[field]], expected[[field]])
      }, logical(1))]
      paste("mismatched fields:", paste(different, collapse = ", "))
    }
    abort_population_simulation(
      paste("Production checkpoint provenance is incompatible;", mismatch),
      "rcdates_sim_provenance_error"
    )
  }
  invisible(TRUE)
}

#' Derive a deterministic seed for one production simulation replicate
#' @param true_model One of `"uni"`, `"lin"`, or `"exp"`.
#' @param prop Proportion of sites subjected to within-site subsampling.
#' @param sim Positive simulation replicate number.
#' @param master_seed Master seed recorded for the production study.
#' @return A positive integer seed shared across scenarios for the replicate.
#' @export
production_simulation_seed <- function(
  true_model,
  prop,
  sim,
  master_seed = 1234L
) {
  models <- c("uni", "lin", "exp")
  proportions <- c(0.5, 0.75, 1)

  model_index <- match(true_model, models)
  prop_index <- which(abs(as.numeric(prop) - proportions) < sqrt(.Machine$double.eps))
  valid_sim <- length(sim) == 1L && is.finite(sim) && sim >= 1 && sim == as.integer(sim)
  valid_master <- length(master_seed) == 1L && is.finite(master_seed) && master_seed >= 1

  if (length(model_index) != 1L || is.na(model_index) || length(prop_index) != 1L ||
      !valid_sim || !valid_master) {
    abort_population_simulation(
      "Invalid production simulation model, proportion, replicate, or master seed.",
      "rcdates_sim_spec_error"
    )
  }

  # The full model-by-intensity matrix uses common random numbers. This keeps
  # each replicate paired across scenarios and makes the all-dates reference exact.
  seed <- as.double(master_seed) + as.integer(sim)
  if (seed > .Machine$integer.max) {
    abort_population_simulation(
      "Derived production simulation seed exceeds the R integer limit.",
      "rcdates_sim_spec_error"
    )
  }
  as.integer(seed)
}

#' Construct the stable filename for one production simulation scenario
#' @param true_model One of `"uni"`, `"lin"`, or `"exp"`.
#' @param prop Proportion of sites subjected to within-site subsampling.
#' @param nsim Number of simulation replicates.
#' @param master_seed Master seed recorded for the production study.
#' @param ratio Multiplicative population increase for growth models.
#' @return An RDS filename containing the complete scenario specification.
#' @export
production_simulation_filename <- function(
  true_model,
  prop,
  nsim = 1000L,
  master_seed = 1234L,
  ratio = 10L
) {
  production_simulation_seed(true_model, prop, sim = 1L, master_seed = master_seed)
  valid_nsim <- length(nsim) == 1L && is.finite(nsim) && nsim >= 1 &&
    nsim == as.integer(nsim)
  valid_ratio <- length(ratio) == 1L && is.finite(ratio) && ratio > 1
  if (!valid_nsim || !valid_ratio) {
    abort_population_simulation(
      "Production simulation count and growth ratio must be positive valid values.",
      "rcdates_sim_spec_error"
    )
  }
  prop_label <- format(as.numeric(prop), scientific = FALSE, trim = TRUE)
  sprintf(
    "results_%s_p%s_ratio%s_nsim%s_seed%s.rds",
    true_model,
    prop_label,
    format(ratio, scientific = FALSE, trim = TRUE),
    as.integer(nsim),
    as.integer(master_seed)
  )
}

#' Parse command-line arguments for one production simulation scenario
#' @param args Character vector from `commandArgs(trailingOnly = TRUE)`.
#' @return Validated runner settings.
#' @export
parse_population_simulation_args <- function(args) {
  defaults <- list(
    true_model = NULL,
    prop = NULL,
    nsim = 1000L,
    cores = 1L,
    batch_size = 20L,
    master_seed = 1234L,
    output = NULL
  )
  key_map <- c(
    model = "true_model",
    prop = "prop",
    nsim = "nsim",
    cores = "cores",
    `batch-size` = "batch_size",
    seed = "master_seed",
    output = "output"
  )
  parsed <- defaults

  for (argument in args) {
    parts <- regmatches(argument, regexec("^--([^=]+)=(.*)$", argument))[[1L]]
    if (length(parts) != 3L || !parts[[2L]] %in% names(key_map)) {
      abort_population_simulation(
        paste("Unknown or malformed production simulation argument:", argument),
        "rcdates_sim_spec_error"
      )
    }
    parsed[[key_map[[parts[[2L]]]]]] <- parts[[3L]]
  }

  parsed$prop <- suppressWarnings(as.numeric(parsed$prop))
  for (field in c("nsim", "cores", "batch_size", "master_seed")) {
    parsed[[field]] <- suppressWarnings(as.integer(parsed[[field]]))
  }
  if (is.null(parsed$true_model) || length(parsed$prop) != 1L || !is.finite(parsed$prop)) {
    abort_population_simulation(
      "Production runner requires valid --model and --prop arguments.",
      "rcdates_sim_spec_error"
    )
  }
  production_simulation_seed(
    parsed$true_model,
    parsed$prop,
    sim = 1L,
    master_seed = parsed$master_seed
  )
  positive_integer <- vapply(
    parsed[c("nsim", "cores", "batch_size", "master_seed")],
    function(x) length(x) == 1L && !is.na(x) && x >= 1L,
    logical(1)
  )
  if (!all(positive_integer)) {
    abort_population_simulation(
      "Simulation count, cores, batch size, and seed must be positive integers.",
      "rcdates_sim_spec_error"
    )
  }

  if (is.null(parsed$output)) {
    parsed$output <- file.path(
      "out",
      "production",
      production_simulation_filename(
        parsed$true_model,
        parsed$prop,
        parsed$nsim,
        parsed$master_seed
      )
    )
  }
  if (length(parsed$output) != 1L || !nzchar(parsed$output)) {
    abort_population_simulation(
      "Production simulation output path must be non-empty.",
      "rcdates_sim_spec_error"
    )
  }
  parsed
}

#' Apply minimum-AIC and modified one-standard-error model selection
#' @param pointwise_aic Data frame with `uni`, `lin`, and `exp` AIC contributions.
#' @param type Likelihood label carried into the result.
#' @return Three-row model-selection table.
#' @export
select_population_models_from_aic <- function(pointwise_aic, type) {
  models <- c("uni", "lin", "exp")
  if (!is.data.frame(pointwise_aic) || nrow(pointwise_aic) < 2L ||
      !all(models %in% names(pointwise_aic))) {
    abort_population_simulation(
      "Pointwise AIC input must contain at least two rows for all three models.",
      "rcdates_sim_result_error"
    )
  }
  pointwise_aic <- pointwise_aic[, models, drop = FALSE]
  if (any(!is.finite(as.matrix(pointwise_aic)))) {
    abort_population_simulation(
      "Pointwise AIC values must all be finite.",
      "rcdates_sim_result_error"
    )
  }

  totals <- colSums(pointwise_aic)
  minimum_model <- names(which.min(totals))
  delta <- sweep(pointwise_aic, 1L, pointwise_aic[[minimum_model]], FUN = "-")
  delta_total <- colSums(delta)
  delta_se <- vapply(delta, stats::sd, numeric(1)) * sqrt(nrow(delta))
  dimensions <- c(uni = 0L, lin = 1L, exp = 1L)
  supported <- delta_total <= delta_se
  supported_dimension <- min(dimensions[supported])
  ose_models <- models[supported & dimensions == supported_dimension]

  data.frame(
    model = models,
    type = rep(type, length(models)),
    min = as.integer(models == minimum_model),
    ose = as.integer(models %in% ose_models),
    stringsAsFactors = FALSE
  )
}

#' Prepare the empirical specification for the production simulation study
#' @param data Filtered AustArch data with `SITE`, `AGE`, and `ERROR` columns.
#' @param min_age Young limit of the calendar-age analysis window.
#' @param max_age Old limit of the calendar-age analysis window.
#' @param ratio Multiplicative increase represented by growth-model simulations.
#' @return A list of fitted empirical distributions and fixed study parameters.
#' @export
prepare_population_simulation <- function(
  data,
  min_age = 651,
  max_age = 11650,
  ratio = 10
) {
  required <- c("SITE", "AGE", "ERROR")
  missing_columns <- setdiff(required, names(data))
  if (!is.data.frame(data) || length(missing_columns) > 0L) {
    abort_population_simulation(
      "Population simulations require SITE, AGE, and ERROR input columns.",
      "rcdates_sim_spec_error"
    )
  }
  if (any(!is.finite(data$AGE)) || any(!is.finite(data$ERROR)) || any(data$ERROR <= 0)) {
    abort_population_simulation(
      "Population simulation ages and errors must be finite and errors must be positive.",
      "rcdates_sim_spec_error"
    )
  }

  dates_per_site <- as.numeric(table(data$SITE))
  if (length(dates_per_site) < 2L || min(dates_per_site) < 5L) {
    abort_population_simulation(
      "Production simulations require at least five dates per empirical site.",
      "rcdates_sim_spec_error"
    )
  }
  # Positive bounds prevent finite-difference probes outside the distribution's
  # parameter space. The ill-conditioned covariance is not used by the simulation.
  fit_n_dates <- suppressWarnings(fitdistrplus::fitdist(
    dates_per_site,
    "tnbinom",
    method = "mle",
    start = list(size = 5, mu = 5),
    fix.arg = list(low = 5),
    lower = c(size = 1e-8, mu = 1e-8)
  ))
  fit_age_to_error <- stats::lm(log(ERROR) ~ AGE, data = data)
  span <- max_age - min_age

  list(
    n_sites = as.integer(length(dates_per_site)),
    min_age = min_age,
    max_age = max_age,
    ratio = ratio,
    slope = 2 * (ratio - 1) / ((ratio + 1) * span^2),
    rate = log(ratio) / span,
    fit_n_dates = fit_n_dates,
    fit_age_to_error = fit_age_to_error,
    strategies = c("r_1", "r_3", "r_5", "r_old", "r_young", "r_bracket", "r_all")
  )
}

prepare_population_likelihood_data <- function(
  grids,
  low,
  up,
  drop_empty = FALSE
) {
  trimmed <- lapply(grids, function(grid) {
    keep <- grid$calBP > low & grid$calBP < up
    ages <- grid$calBP[keep]
    probabilities <- grid$PrDens[keep]
    total <- sum(probabilities)
    if (length(ages) == 0L || !is.finite(total) || total <= 0) {
      if (isTRUE(drop_empty)) return(NULL)
      abort_population_simulation(
        "A calibrated date has no probability within the analysis window.",
        "rcdates_sim_result_error"
      )
    }
    list(age = ages, probability = probabilities / total)
  })
  dropped <- vapply(trimmed, is.null, logical(1))
  trimmed <- trimmed[!dropped]
  if (length(trimmed) < 2L) {
    abort_population_simulation(
      "Fewer than two calibrated dates retain probability inside the analysis window.",
      "rcdates_sim_result_error"
    )
  }
  lengths <- vapply(trimmed, function(x) length(x$age), integer(1))
  list(
    age = unlist(lapply(trimmed, `[[`, "age"), use.names = FALSE),
    probability = unlist(lapply(trimmed, `[[`, "probability"), use.names = FALSE),
    group = rep.int(seq_along(trimmed), lengths),
    n_dates = as.integer(length(trimmed)),
    n_dropped = as.integer(sum(dropped))
  )
}

population_pointwise_log_likelihood <- function(densities, likelihood_data, type) {
  contributions <- if (type == "l1") {
    densities * likelihood_data$probability
  } else {
    log(densities) * likelihood_data$probability
  }
  pointwise <- as.numeric(rowsum(
    contributions,
    likelihood_data$group,
    reorder = FALSE
  ))
  if (type == "l1") log(pointwise) else pointwise
}

population_nll_linear <- function(
  slope,
  likelihood_data,
  low,
  up,
  type,
  summed = TRUE
) {
  densities <- dtlin(
    likelihood_data$age,
    slope = slope / 1e6,
    low = low,
    up = up
  )
  pointwise <- -population_pointwise_log_likelihood(densities, likelihood_data, type)
  if (summed) sum(pointwise) else pointwise
}

population_nll_exponential <- function(
  rate,
  likelihood_data,
  low,
  up,
  type,
  summed = TRUE
) {
  densities <- dtexp(
    likelihood_data$age,
    rate = rate / 1e3,
    low = low,
    upp = up
  )
  pointwise <- -population_pointwise_log_likelihood(densities, likelihood_data, type)
  if (summed) sum(pointwise) else pointwise
}

population_pointwise_aic <- function(
  estimate_linear,
  estimate_exponential,
  type,
  likelihood_data,
  low,
  up
) {
  n_dates <- likelihood_data$n_dates
  data.frame(
    uni = rep(-2 * log(1 / (up - low)), n_dates),
    lin = 2 * population_nll_linear(
      estimate_linear$minimum,
      likelihood_data,
      low,
      up,
      type,
      summed = FALSE
    ) + 2 / n_dates,
    exp = 2 * population_nll_exponential(
      estimate_exponential$minimum,
      likelihood_data,
      low,
      up,
      type,
      summed = FALSE
    ) + 2 / n_dates
  )
}

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
#' @export
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

#' Validate production population-simulation results
#' @param results Data frame produced by the production simulation runner.
#' @param nsim Optional expected number of replicates in each scenario.
#' @return `TRUE`, invisibly, or an error for an incomplete result block.
#' @export
validate_population_simulation_results <- function(results, nsim = NULL) {
  required <- c(
    "sim", "true", "prop", "strategy", "type", "model", "min", "ose", "bias"
  )
  expected_strategies <- c(
    "r_1", "r_3", "r_5", "r_old", "r_young", "r_bracket", "r_all"
  )
  expected_types <- c("l1", "l2")
  expected_models <- c("uni", "lin", "exp")

  fail <- function(message) {
    abort_population_simulation(message, "rcdates_sim_result_error")
  }
  if (!is.data.frame(results) || nrow(results) == 0L) {
    fail("Production simulation results must be a non-empty data frame.")
  }
  missing_columns <- setdiff(required, names(results))
  if (length(missing_columns) > 0L) {
    fail(paste("Production results are missing columns:", paste(missing_columns, collapse = ", ")))
  }
  if (any(!results$min %in% c(0, 1)) || any(!results$ose %in% c(0, 1))) {
    fail("Production result selection columns must contain only zeroes and ones.")
  }

  scenario <- interaction(results$true, results$prop, drop = TRUE, lex.order = TRUE)
  block <- interaction(scenario, results$sim, drop = TRUE, lex.order = TRUE)
  complete_block <- vapply(split(results, block), function(x) {
    nrow(x) == 42L &&
      identical(sort(unique(x$strategy)), sort(expected_strategies)) &&
      identical(sort(unique(x$type)), expected_types) &&
      identical(sort(unique(x$model)), sort(expected_models)) &&
      !anyDuplicated(interaction(x$strategy, x$type, x$model, drop = TRUE))
  }, logical(1))
  if (!all(complete_block)) {
    fail("Each production replicate must contain one complete 42-row result block.")
  }

  selection_group <- interaction(
    scenario,
    results$sim,
    results$strategy,
    results$type,
    drop = TRUE,
    lex.order = TRUE
  )
  one_minimum <- vapply(split(results$min, selection_group), sum, numeric(1)) == 1
  one_or_more_ose <- vapply(split(results$ose, selection_group), sum, numeric(1)) >= 1
  if (!all(one_minimum) || !all(one_or_more_ose)) {
    fail("Every fitted result must have one minimum-AIC model and at least one OSE model.")
  }

  if (!is.null(nsim)) {
    valid_nsim <- length(nsim) == 1L && is.finite(nsim) && nsim >= 1 &&
      nsim == as.integer(nsim)
    if (!valid_nsim) fail("`nsim` must be a positive integer.")
    complete_ids <- vapply(split(results$sim, scenario), function(x) {
      identical(sort(unique(as.integer(x))), seq_len(as.integer(nsim)))
    }, logical(1))
    if (!all(complete_ids)) {
      fail("Production result replicate identifiers are incomplete.")
    }
  }

  invisible(TRUE)
}

read_population_simulation_metadata <- function(path) {
  if (!file.exists(path)) {
    abort_population_simulation(
      paste("Missing production metadata sidecar:", path),
      "rcdates_sim_provenance_error"
    )
  }
  lines <- readLines(path, warn = FALSE)
  records <- grep("^[a-z][a-z0-9_]*:[[:space:]]*", lines, value = TRUE)
  keys <- sub(":.*$", "", records)
  values <- sub("^[^:]+:[[:space:]]*", "", records)
  if (length(records) == 0L || anyDuplicated(keys)) {
    abort_population_simulation(
      "Production metadata is empty or contains duplicate keys.",
      "rcdates_sim_provenance_error"
    )
  }
  stats::setNames(values, keys)
}

#' Validate a production RDS file and its provenance sidecar
#' @param path Path to a production RDS file.
#' @param nsim Expected number of complete simulation replicates.
#' @return `TRUE` invisibly when data, checkpoint provenance, and metadata agree.
#' @export
validate_population_simulation_artifact <- function(path, nsim = NULL) {
  if (!file.exists(path)) {
    abort_population_simulation(
      paste("Missing production simulation artifact:", path),
      "rcdates_sim_provenance_error"
    )
  }
  results <- readRDS(path)
  provenance <- attr(results, "production_provenance", exact = TRUE)
  required_provenance <- c(
    "schema_version", "true_model", "prop", "nsim", "master_seed",
    "input_md5", "renv_lock_md5", "production_source_md5",
    "legacy_helper_md5", "runner_source_md5", "container_recipe_md5",
    "container_install_md5", "container_image_id", "provenance_origin",
    "r_version"
  )
  if (is.null(provenance) ||
      !identical(sort(names(provenance)), sort(required_provenance))) {
    abort_population_simulation(
      "Production artifact lacks a complete provenance fingerprint.",
      "rcdates_sim_provenance_error"
    )
  }
  md5_fields <- c(
    "input_md5", "renv_lock_md5", "production_source_md5",
    "legacy_helper_md5", "runner_source_md5", "container_recipe_md5"
  )
  valid_md5 <- vapply(provenance[md5_fields], function(value) {
    length(value) == 1L && grepl("^[0-9a-f]{32}$", value)
  }, logical(1))
  positive_integer <- function(value) {
    length(value) == 1L && is.finite(value) && value >= 1L &&
      identical(value, as.integer(value))
  }
  valid_string <- function(value, pattern) {
    length(value) == 1L && !is.na(value) && grepl(pattern, value)
  }
  valid_header <- identical(provenance$schema_version, 1L) &&
    positive_integer(provenance$nsim) &&
    positive_integer(provenance$master_seed) &&
    valid_string(provenance$true_model, "^(uni|lin|exp)$") &&
    length(provenance$prop) == 1L && is.finite(provenance$prop) &&
    any(abs(provenance$prop - c(0.5, 0.75, 1)) < sqrt(.Machine$double.eps)) &&
    valid_string(
      provenance$container_install_md5,
      "^([0-9a-f]{32}|inline-in-recipe)$"
    ) &&
    valid_string(provenance$container_image_id, "^sha256:[0-9a-f]{64}$") &&
    valid_string(provenance$provenance_origin, "^(native-checkpoint|post-run-stamp)$") &&
    valid_string(provenance$r_version, "^R version 4\\.5\\.3 \\(")
  if (!all(valid_md5) || !valid_header) {
    abort_population_simulation(
      "Production artifact contains malformed provenance values.",
      "rcdates_sim_provenance_error"
    )
  }
  validate_population_checkpoint_provenance(results, provenance)
  expected_nsim <- if (is.null(nsim)) provenance$nsim else as.integer(nsim)
  if (!identical(as.integer(provenance$nsim), expected_nsim)) {
    abort_population_simulation(
      "Production artifact replicate count conflicts with its provenance.",
      "rcdates_sim_provenance_error"
    )
  }
  validate_population_simulation_results(results, nsim = expected_nsim)
  result_scenario_matches <- identical(unique(results$true), provenance$true_model) &&
    length(unique(results$prop)) == 1L &&
    abs(unique(results$prop) - provenance$prop) < sqrt(.Machine$double.eps)
  if (!result_scenario_matches) {
    abort_population_simulation(
      "Production result values conflict with their scenario provenance.",
      "rcdates_sim_provenance_error"
    )
  }

  metadata <- read_population_simulation_metadata(paste0(path, ".metadata.txt"))
  metadata_map <- c(
    schema_version = "schema_version",
    r_version = "r_version",
    true_model = "true_model",
    site_subsampling_proportion = "prop",
    replicates = "nsim",
    master_seed = "master_seed",
    input_md5 = "input_md5",
    renv_lock_md5 = "renv_lock_md5",
    production_source_md5 = "production_source_md5",
    legacy_helper_md5 = "legacy_helper_md5",
    runner_source_md5 = "runner_source_md5",
    container_recipe_md5 = "container_recipe_md5",
    container_install_md5 = "container_install_md5",
    container_image_id = "container_image_id",
    provenance_origin = "provenance_origin"
  )
  required_metadata <- c(
    names(metadata_map),
    "generation_completed_utc",
    "metadata_recorded_utc",
    "output_md5"
  )
  if (!all(required_metadata %in% names(metadata))) {
    abort_population_simulation(
      "Production metadata sidecar is incomplete.",
      "rcdates_sim_provenance_error"
    )
  }
  metadata_matches <- vapply(names(metadata_map), function(key) {
    identical(metadata[[key]], as.character(provenance[[metadata_map[[key]]]]))
  }, logical(1))
  output_matches <- identical(
    metadata[["output_md5"]],
    unname(tools::md5sum(path))
  )
  valid_times <- all(grepl(
    "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} UTC$",
    metadata[c("generation_completed_utc", "metadata_recorded_utc")]
  ))
  if (!all(metadata_matches) || !output_matches || !valid_times) {
    abort_population_simulation(
      "Production artifact and metadata fingerprints do not agree.",
      "rcdates_sim_provenance_error"
    )
  }
  invisible(TRUE)
}

population_summary_seed <- function(strategy, type, prop, seed) {
  strategy_levels <- c("r_all", "r_1", "r_3", "r_5", "r_bracket", "r_old", "r_young")
  strategy_index <- match(strategy, strategy_levels)
  type_index <- match(type, c("l1", "l2"))
  prop_index <- if (strategy == "r_all") 0L else match(prop, c(0.5, 0.75, 1))
  as.integer(seed + strategy_index * 1000L + type_index * 100L + prop_index)
}

cluster_bootstrap_summary <- function(values, clusters, n_boot, seed) {
  cluster_means <- vapply(split(values, clusters), mean, numeric(1))
  bootstrap <- withr::with_seed(seed, replicate(
    as.integer(n_boot),
    mean(cluster_means[sample.int(length(cluster_means), replace = TRUE)])
  ))
  interval <- stats::quantile(bootstrap, c(0.025, 0.975), names = FALSE)
  list(
    estimate = mean(cluster_means),
    n_simulations = length(values),
    n_clusters = length(cluster_means),
    ci_low = interval[[1L]],
    ci_high = interval[[2L]]
  )
}

#' Summarise minimum-AIC model-recovery accuracy
#' @param results Combined production simulation results.
#' @param n_boot Number of bootstrap resamples used for confidence intervals.
#' @param seed Seed used for deterministic bootstrap resampling.
#' @return One row per likelihood, sampling proportion, and sampling strategy.
#' @export
summarise_population_accuracy <- function(results, n_boot = 1000L, seed = 1234L) {
  required <- c("prop", "strategy", "type", "sim", "true", "model", "min")
  missing_columns <- setdiff(required, names(results))
  valid_boot <- length(n_boot) == 1L && is.finite(n_boot) && n_boot >= 2L &&
    n_boot == as.integer(n_boot)
  if (!is.data.frame(results) || length(missing_columns) > 0L || !valid_boot) {
    abort_population_simulation(
      "Accuracy summaries require complete selection columns and at least two resamples.",
      "rcdates_sim_result_error"
    )
  }

  selected <- results[results$min == 1, required, drop = FALSE]
  summary_group <- interaction(
    selected$type,
    selected$prop,
    selected$strategy,
    drop = TRUE,
    lex.order = TRUE
  )
  summaries <- lapply(split(selected, summary_group), function(x) {
    correct <- as.character(x$model) == as.character(x$true)
    bootstrap_seed <- population_summary_seed(
      x$strategy[[1L]],
      x$type[[1L]],
      x$prop[[1L]],
      seed
    )
    summary <- cluster_bootstrap_summary(correct, x$sim, n_boot, bootstrap_seed)
    data.frame(
      type = x$type[[1L]],
      prop = x$prop[[1L]],
      strategy = x$strategy[[1L]],
      accuracy = summary$estimate,
      n_simulations = summary$n_simulations,
      n_clusters = summary$n_clusters,
      ci_low = summary$ci_low,
      ci_high = summary$ci_high,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, summaries)
  rownames(out) <- NULL
  out[order(out$type, out$prop, out$strategy), , drop = FALSE]
}

#' Summarise replicate-level population-parameter bias
#' @param results Combined production simulation results.
#' @return One row per likelihood, truth, sampling proportion, and strategy.
#' @export
summarise_population_bias <- function(results) {
  required <- c("prop", "strategy", "type", "true", "bias")
  missing_columns <- setdiff(required, names(results))
  if (!is.data.frame(results) || length(missing_columns) > 0L) {
    abort_population_simulation(
      "Bias summaries require complete production bias columns.",
      "rcdates_sim_result_error"
    )
  }

  selected <- results[!is.na(results$bias), required, drop = FALSE]
  summary_group <- interaction(
    selected$type,
    selected$true,
    selected$prop,
    selected$strategy,
    drop = TRUE,
    lex.order = TRUE
  )
  summaries <- lapply(split(selected, summary_group), function(x) {
    interval <- stats::quantile(x$bias, c(0.025, 0.975), names = FALSE)
    data.frame(
      type = x$type[[1L]],
      true = x$true[[1L]],
      prop = x$prop[[1L]],
      strategy = x$strategy[[1L]],
      mean_bias = mean(x$bias),
      ci_low = interval[[1L]],
      ci_high = interval[[2L]],
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, summaries)
  rownames(out) <- NULL
  out[order(out$type, out$true, out$prop, out$strategy), , drop = FALSE]
}

#' Summarise unambiguous one-standard-error model selection
#' @param results Combined production simulation results.
#' @return One row per likelihood, sampling proportion, and sampling strategy.
#' @export
summarise_unique_ose <- function(results, n_boot = 1000L, seed = 1234L) {
  required <- c("prop", "strategy", "type", "sim", "true", "model", "ose")
  missing_columns <- setdiff(required, names(results))
  valid_boot <- length(n_boot) == 1L && is.finite(n_boot) && n_boot >= 2L &&
    n_boot == as.integer(n_boot)
  if (!is.data.frame(results) || length(missing_columns) > 0L || !valid_boot) {
    abort_population_simulation(
      "OSE summaries require complete selection columns and at least two resamples.",
      "rcdates_sim_result_error"
    )
  }

  selected <- results[results$ose == 1, required, drop = FALSE]
  replicate_group <- interaction(
    selected$prop,
    selected$strategy,
    selected$type,
    selected$sim,
    selected$true,
    drop = TRUE,
    lex.order = TRUE
  )
  replicate_rows <- lapply(split(selected, replicate_group), function(x) {
    data.frame(
      prop = x$prop[[1L]],
      strategy = x$strategy[[1L]],
      type = x$type[[1L]],
      sim = x$sim[[1L]],
      true = x$true[[1L]],
      is_unique_true = all(x$model == x$true[[1L]]),
      stringsAsFactors = FALSE
    )
  })
  replicate_summary <- do.call(rbind, replicate_rows)

  summary_group <- interaction(
    replicate_summary$type,
    replicate_summary$prop,
    replicate_summary$strategy,
    drop = TRUE,
    lex.order = TRUE
  )
  summaries <- lapply(split(replicate_summary, summary_group), function(x) {
    bootstrap_seed <- population_summary_seed(
      x$strategy[[1L]],
      x$type[[1L]],
      x$prop[[1L]],
      seed
    )
    summary <- cluster_bootstrap_summary(
      x$is_unique_true,
      x$sim,
      n_boot,
      bootstrap_seed
    )
    data.frame(
      type = x$type[[1L]],
      prop = x$prop[[1L]],
      strategy = x$strategy[[1L]],
      p = summary$estimate,
      n_simulations = summary$n_simulations,
      n_clusters = summary$n_clusters,
      ci_low = summary$ci_low,
      ci_high = summary$ci_high,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, summaries)
  rownames(out) <- NULL
  out[order(out$type, out$prop, out$strategy), , drop = FALSE]
}
