# Population likelihoods and model selection --------------------------------

#' Apply minimum-criterion and modified one-standard-error model selection
#' @param pointwise_criterion Penalized contributions for `uni`, `lin`, and `exp`.
#' @param type Primary-likelihood or scoring-sensitivity label.
#' @return Three-row model-selection table.
select_population_models_from_criterion <- function(pointwise_criterion, type) {
  models <- c("uni", "lin", "exp")
  if (!is.data.frame(pointwise_criterion) || nrow(pointwise_criterion) < 2L ||
      !all(models %in% names(pointwise_criterion))) {
    abort_population_simulation(
      "Pointwise criterion input must contain at least two rows for all three models.",
      "rcdates_sim_result_error"
    )
  }
  pointwise_criterion <- pointwise_criterion[, models, drop = FALSE]
  if (any(!is.finite(as.matrix(pointwise_criterion)))) {
    abort_population_simulation(
      "Pointwise criterion values must all be finite.",
      "rcdates_sim_result_error"
    )
  }

  totals <- colSums(pointwise_criterion)
  minimum_model <- names(which.min(totals))
  delta <- sweep(
    pointwise_criterion,
    1L,
    pointwise_criterion[[minimum_model]],
    FUN = "-"
  )
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
    strategies = population_simulation_contract("signed-v1")$strategies
  )
}

population_fit_bounds <- function(low, up) {
  if (length(low) != 1L || length(up) != 1L || !is.finite(low) ||
      !is.finite(up) || low >= up) {
    abort_population_simulation(
      "Fitted population models require a valid analysis interval.",
      "rcdates_sim_spec_error"
    )
  }
  span <- up - low
  list(
    lin = c(-2 / span^2, 2 / span^2) * 1e6,
    exp = c(-1e-3, 1e-3) * 1e3,
    tolerance = 1e-6
  )
}

population_fit_at_boundary <- function(estimate, bounds, tolerance) {
  min(abs(estimate - bounds)) <= 5 * tolerance
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

population_pointwise_criterion <- function(
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
