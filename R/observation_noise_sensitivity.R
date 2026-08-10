## Paired realised-observation-noise sensitivity helpers -------------------

normalize_observation_noise_strategies <- function(strategies) {
  available <- c("r_all", "r_1", "r_3", "r_5", "r_old", "r_young", "r_bracket")
  strategies <- unique(as.character(strategies))
  if (length(strategies) == 0L || anyNA(strategies) ||
      any(!strategies %in% available)) {
    abort_population_simulation(
      paste(
        "Observation-noise strategies must be drawn from:",
        paste(available, collapse = ", ")
      ),
      "rcdates_sim_spec_error"
    )
  }
  strategies
}

#' Construct a stable filename for one paired observation-noise scenario
#' @param true_model One of `"uni"`, `"lin"`, or `"exp"`.
#' @param prop Proportion of sites subjected to within-site subsampling.
#' @param nsim Number of paired simulation replicates.
#' @param master_seed Master structural seed.
#' @param ratio Multiplicative population increase for growth models.
#' @return An RDS filename distinct from the locked production matrix.
#' @export
observation_noise_sensitivity_filename <- function(
  true_model,
  prop,
  nsim = 1000L,
  master_seed = 1234L,
  ratio = 10L
) {
  production_simulation_filename(
    true_model = true_model,
    prop = prop,
    nsim = nsim,
    master_seed = master_seed,
    ratio = ratio
  ) |>
    sub("^results_", "observation_noise_", x = _)
}

#' Parse command-line arguments for one observation-noise sensitivity scenario
#' @param args Character vector from `commandArgs(trailingOnly = TRUE)`.
#' @return Validated runner settings.
#' @export
parse_observation_noise_sensitivity_args <- function(args) {
  defaults <- list(
    true_model = NULL,
    prop = NULL,
    nsim = 1000L,
    cores = 1L,
    batch_size = 20L,
    master_seed = 1234L,
    strategies = c("r_all", "r_1", "r_3", "r_5"),
    output = NULL
  )
  key_map <- c(
    model = "true_model",
    prop = "prop",
    nsim = "nsim",
    cores = "cores",
    `batch-size` = "batch_size",
    seed = "master_seed",
    strategies = "strategies",
    output = "output"
  )
  parsed <- defaults

  for (argument in args) {
    parts <- regmatches(argument, regexec("^--([^=]+)=(.*)$", argument))[[1L]]
    if (length(parts) != 3L || !parts[[2L]] %in% names(key_map)) {
      abort_population_simulation(
        paste("Unknown or malformed observation-noise argument:", argument),
        "rcdates_sim_spec_error"
      )
    }
    parsed[[key_map[[parts[[2L]]]]]] <- parts[[3L]]
  }

  parsed$prop <- suppressWarnings(as.numeric(parsed$prop))
  for (field in c("nsim", "cores", "batch_size", "master_seed")) {
    parsed[[field]] <- suppressWarnings(as.integer(parsed[[field]]))
  }
  if (is.null(parsed$true_model) || length(parsed$prop) != 1L ||
      !is.finite(parsed$prop)) {
    abort_population_simulation(
      "Observation-noise runner requires valid --model and --prop arguments.",
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

  if (is.character(parsed$strategies) && length(parsed$strategies) == 1L) {
    parsed$strategies <- strsplit(parsed$strategies, ",", fixed = TRUE)[[1L]]
  }
  parsed$strategies <- normalize_observation_noise_strategies(
    trimws(parsed$strategies)
  )

  if (is.null(parsed$output)) {
    parsed$output <- file.path(
      "out",
      "sensitivity",
      "observation-noise",
      observation_noise_sensitivity_filename(
        parsed$true_model,
        parsed$prop,
        parsed$nsim,
        parsed$master_seed
      )
    )
  }
  if (length(parsed$output) != 1L || !nzchar(parsed$output)) {
    abort_population_simulation(
      "Observation-noise output path must be non-empty.",
      "rcdates_sim_spec_error"
    )
  }
  parsed
}

population_pair_hash <- function(data, columns) {
  digest::digest(
    data[, columns, drop = FALSE],
    algo = "sha256",
    serialize = TRUE,
    serializeVersion = 3
  )
}

population_posterior_mass_in_window <- function(simulated_data, low, up) {
  vapply(simulated_data$grid, function(grid) {
    keep <- grid$calBP >= low & grid$calBP <= up
    sum(grid$PrDens[keep])
  }, numeric(1))
}

#' Run one paired expectation-versus-realised observation-noise replicate
#' @param sim Positive replicate number.
#' @param true_model Generating population model.
#' @param prop Proportion of treated sites.
#' @param specification Output of [prepare_population_simulation()].
#' @param master_seed Master structural seed.
#' @param strategies Sampling strategies to evaluate.
#' @return List containing a result block and one-row pair manifest.
#' @export
run_observation_noise_sensitivity_replicate <- function(
  sim,
  true_model,
  prop,
  specification,
  master_seed = 1234L,
  strategies = c("r_all", "r_1", "r_3", "r_5")
) {
  strategies <- normalize_observation_noise_strategies(strategies)
  if (any(!strategies %in% specification$strategies)) {
    abort_population_simulation(
      "Requested sensitivity strategies are absent from the simulation specification.",
      "rcdates_sim_spec_error"
    )
  }

  requireNamespace("rcarbon", quietly = TRUE)
  requireNamespace("digest", quietly = TRUE)
  seed <- production_simulation_seed(true_model, prop, sim, master_seed)

  simulate_arm <- function(observation_model) {
    set.seed(seed, kind = "L'Ecuyer-CMRG")
    data <- simulate_population_data_set(
      true_model = true_model,
      prop = prop,
      specification = specification,
      observation_model = observation_model
    )
    list(data = data, rng_state = .Random.seed)
  }

  expectation <- simulate_arm("curve_mean")
  realised <- simulate_arm("realised")
  shared_columns <- c(
    "site",
    "site_treated",
    "age_calendar",
    "age_uncalibrated_expected",
    "error",
    "r_1",
    "r_3",
    "r_5",
    "r_all"
  )
  if (!identical(expectation$data[shared_columns], realised$data[shared_columns]) ||
      !identical(expectation$rng_state, realised$rng_state)) {
    abort_population_simulation(
      "Observation-noise arms do not share an exact structural and sampling pair.",
      "rcdates_sim_pairing_error"
    )
  }

  structure_columns <- c(
    "site",
    "age_calendar",
    "age_uncalibrated_expected",
    "error"
  )
  selection_columns <- c(
    "site",
    "site_treated",
    "r_1",
    "r_3",
    "r_5",
    "r_all"
  )
  structure_hash <- population_pair_hash(expectation$data, structure_columns)
  selection_hash <- population_pair_hash(expectation$data, selection_columns)
  prop_label <- format(as.numeric(prop), scientific = FALSE, trim = TRUE)
  pair_id <- sprintf(
    "%s_p%s_sim%s_seed%s",
    true_model,
    prop_label,
    as.integer(sim),
    as.integer(master_seed)
  )

  evaluate_arm <- function(arm) {
    rows <- do.call(rbind, lapply(strategies, function(strategy) {
      evaluate_population_models(
        simulated_data = arm$data,
        true_model = true_model,
        strategy = strategy,
        prop = prop,
        sim = sim,
        specification = specification,
        drop_empty = TRUE
      )
    }))
    rows$observation_model <- unique(arm$data$observation_model)
    rows$pair_id <- pair_id
    rows$structure_hash <- structure_hash
    rows$selection_hash <- selection_hash
    rows
  }

  results <- rbind(evaluate_arm(expectation), evaluate_arm(realised))
  rownames(results) <- NULL
  validate_observation_noise_sensitivity_results(
    results,
    strategies = strategies
  )

  expectation_mass <- population_posterior_mass_in_window(
    expectation$data,
    specification$min_age,
    specification$max_age
  )
  realised_mass <- population_posterior_mass_in_window(
    realised$data,
    specification$min_age,
    specification$max_age
  )
  pair_manifest <- data.frame(
    pair_id = pair_id,
    sim = as.integer(sim),
    true = true_model,
    prop = as.numeric(prop),
    n_sites = length(unique(expectation$data$site)),
    n_dates = nrow(expectation$data),
    n_treated_sites = length(unique(
      expectation$data$site[as.logical(expectation$data$site_treated)]
    )),
    structure_hash = structure_hash,
    selection_hash = selection_hash,
    expectation_observation_hash = population_pair_hash(
      expectation$data,
      c("site", "age_uncalibrated")
    ),
    realised_observation_hash = population_pair_hash(
      realised$data,
      c("site", "age_uncalibrated")
    ),
    expectation_low_mass_rate = mean(expectation_mass < 0.95),
    realised_low_mass_rate = mean(realised_mass < 0.95),
    expectation_zero_mass_rate = mean(expectation_mass <= 0),
    realised_zero_mass_rate = mean(realised_mass <= 0),
    stringsAsFactors = FALSE
  )

  list(results = results, pair_manifest = pair_manifest)
}

#' Validate paired observation-noise sensitivity results
#' @param results Result rows from the paired sensitivity runner.
#' @param nsim Optional expected paired replicate count.
#' @param strategies Expected sampling strategies.
#' @return `TRUE` invisibly, or a typed error.
#' @export
validate_observation_noise_sensitivity_results <- function(
  results,
  nsim = NULL,
  strategies = c("r_all", "r_1", "r_3", "r_5")
) {
  strategies <- normalize_observation_noise_strategies(strategies)
  required <- c(
    "sim", "true", "prop", "strategy", "type", "model", "min", "ose", "bias",
    "n_observations", "n_dropped", "observation_model", "pair_id",
    "structure_hash", "selection_hash"
  )
  expected_arms <- c("curve_mean", "realised")
  expected_types <- c("l1", "l2")
  expected_models <- c("uni", "lin", "exp")
  fail <- function(message) {
    abort_population_simulation(message, "rcdates_sim_result_error")
  }

  if (!is.data.frame(results) || nrow(results) == 0L) {
    fail("Observation-noise results must be a non-empty data frame.")
  }
  missing_columns <- setdiff(required, names(results))
  if (length(missing_columns) > 0L) {
    fail(paste(
      "Observation-noise results are missing columns:",
      paste(missing_columns, collapse = ", ")
    ))
  }
  if (any(!results$min %in% c(0, 1)) || any(!results$ose %in% c(0, 1))) {
    fail("Observation-noise selection columns must contain only zeroes and ones.")
  }
  if (any(!is.finite(results$n_observations)) ||
      any(!is.finite(results$n_dropped)) ||
      any(results$n_observations < 2L) ||
      any(results$n_dropped < 0L)) {
    fail("Observation-noise likelihood inclusion counts are invalid.")
  }

  scenario <- interaction(results$true, results$prop, drop = TRUE, lex.order = TRUE)
  block <- interaction(scenario, results$sim, drop = TRUE, lex.order = TRUE)
  rows_per_block <- 2L * length(strategies) * 2L * 3L
  complete_block <- vapply(split(results, block), function(x) {
    nrow(x) == rows_per_block &&
      identical(sort(unique(x$observation_model)), expected_arms) &&
      identical(sort(unique(x$strategy)), sort(strategies)) &&
      identical(sort(unique(x$type)), expected_types) &&
      identical(sort(unique(x$model)), sort(expected_models)) &&
      length(unique(x$pair_id)) == 1L &&
      length(unique(x$structure_hash)) == 1L &&
      length(unique(x$selection_hash)) == 1L &&
      !anyDuplicated(interaction(
        x$observation_model,
        x$strategy,
        x$type,
        x$model,
        drop = TRUE
      ))
  }, logical(1))
  if (!all(complete_block)) {
    fail("Each sensitivity replicate must contain one complete paired result block.")
  }

  hash_pattern <- "^[0-9a-f]{64}$"
  if (any(!grepl(hash_pattern, results$structure_hash)) ||
      any(!grepl(hash_pattern, results$selection_hash))) {
    fail("Sensitivity pairing hashes must be SHA-256 values.")
  }

  selection_group <- interaction(
    scenario,
    results$sim,
    results$observation_model,
    results$strategy,
    results$type,
    drop = TRUE,
    lex.order = TRUE
  )
  one_minimum <- vapply(split(results$min, selection_group), sum, numeric(1)) == 1
  one_or_more_ose <- vapply(split(results$ose, selection_group), sum, numeric(1)) >= 1
  if (!all(one_minimum) || !all(one_or_more_ose)) {
    fail("Each sensitivity fit must have one minimum-AIC and at least one OSE model.")
  }

  if (!is.null(nsim)) {
    valid_nsim <- length(nsim) == 1L && is.finite(nsim) && nsim >= 1L &&
      nsim == as.integer(nsim)
    if (!valid_nsim) fail("`nsim` must be a positive integer.")
    complete_ids <- vapply(split(results$sim, scenario), function(x) {
      identical(sort(unique(as.integer(x))), seq_len(as.integer(nsim)))
    }, logical(1))
    if (!all(complete_ids)) {
      fail("Sensitivity replicate identifiers are incomplete.")
    }
  }

  invisible(TRUE)
}

#' Validate the one-row-per-replicate observation-noise pair manifest
#' @param pair_manifest Pair-manifest data frame.
#' @param nsim Optional expected replicate count per scenario.
#' @return `TRUE` invisibly, or a typed error.
#' @export
validate_observation_noise_pair_manifest <- function(pair_manifest, nsim = NULL) {
  required <- c(
    "pair_id", "sim", "true", "prop", "n_sites", "n_dates",
    "n_treated_sites", "structure_hash", "selection_hash",
    "expectation_observation_hash", "realised_observation_hash",
    "expectation_low_mass_rate", "realised_low_mass_rate",
    "expectation_zero_mass_rate", "realised_zero_mass_rate"
  )
  fail <- function(message) {
    abort_population_simulation(message, "rcdates_sim_result_error")
  }
  if (!is.data.frame(pair_manifest) || nrow(pair_manifest) == 0L) {
    fail("Observation-noise pair manifest must be a non-empty data frame.")
  }
  missing_columns <- setdiff(required, names(pair_manifest))
  if (length(missing_columns) > 0L) {
    fail(paste(
      "Observation-noise pair manifest is missing columns:",
      paste(missing_columns, collapse = ", ")
    ))
  }
  scenario <- interaction(
    pair_manifest$true,
    pair_manifest$prop,
    drop = TRUE,
    lex.order = TRUE
  )
  if (anyDuplicated(pair_manifest$pair_id) ||
      anyDuplicated(interaction(scenario, pair_manifest$sim, drop = TRUE))) {
    fail("Observation-noise pair manifest contains duplicate replicate keys.")
  }
  hash_columns <- c(
    "structure_hash",
    "selection_hash",
    "expectation_observation_hash",
    "realised_observation_hash"
  )
  valid_hashes <- vapply(pair_manifest[hash_columns], function(values) {
    all(grepl("^[0-9a-f]{64}$", values))
  }, logical(1))
  exact_treated_counts <- pair_manifest$n_treated_sites ==
    as.integer(round(pair_manifest$prop * pair_manifest$n_sites))
  valid_rates <- vapply(
    pair_manifest[c(
      "expectation_low_mass_rate",
      "realised_low_mass_rate",
      "expectation_zero_mass_rate",
      "realised_zero_mass_rate"
    )],
    function(values) all(is.finite(values) & values >= 0 & values <= 1),
    logical(1)
  )
  if (!all(valid_hashes) || !all(exact_treated_counts) || !all(valid_rates) ||
      any(pair_manifest$n_dates < pair_manifest$n_sites) ||
      any(
        pair_manifest$expectation_observation_hash ==
          pair_manifest$realised_observation_hash
      )) {
    fail("Observation-noise pair manifest contains malformed hashes or counts.")
  }
  if (!is.null(nsim)) {
    valid_nsim <- length(nsim) == 1L && is.finite(nsim) && nsim >= 1L &&
      nsim == as.integer(nsim)
    if (!valid_nsim) fail("`nsim` must be a positive integer.")
    complete_ids <- vapply(split(pair_manifest$sim, scenario), function(x) {
      identical(sort(unique(as.integer(x))), seq_len(as.integer(nsim)))
    }, logical(1))
    if (!all(complete_ids)) {
      fail("Observation-noise pair-manifest replicate identifiers are incomplete.")
    }
  }
  invisible(TRUE)
}

#' Validate exact result-to-manifest pairing fingerprints
#' @param results Paired observation-noise result rows.
#' @param pair_manifest One-row-per-replicate pairing manifest.
#' @return `TRUE` invisibly, or a typed error.
#' @export
validate_observation_noise_result_manifest_pairing <- function(
  results,
  pair_manifest
) {
  required_results <- c("pair_id", "structure_hash", "selection_hash")
  required_manifest <- c("pair_id", "structure_hash", "selection_hash")
  fail <- function(message) {
    abort_population_simulation(message, "rcdates_sim_result_error")
  }
  if (!is.data.frame(results) || !is.data.frame(pair_manifest) ||
      !all(required_results %in% names(results)) ||
      !all(required_manifest %in% names(pair_manifest))) {
    fail("Observation-noise result-to-manifest pairing fields are incomplete.")
  }

  result_pairs <- unique(results[, required_results, drop = FALSE])
  if (anyDuplicated(result_pairs$pair_id) ||
      anyDuplicated(pair_manifest$pair_id) ||
      !setequal(result_pairs$pair_id, pair_manifest$pair_id)) {
    fail("Observation-noise results and manifest do not define the same pairs.")
  }
  result_pairs <- result_pairs[
    order(result_pairs$pair_id),
    required_results,
    drop = FALSE
  ]
  manifest_pairs <- pair_manifest[
    order(pair_manifest$pair_id),
    required_manifest,
    drop = FALSE
  ]
  rownames(result_pairs) <- NULL
  rownames(manifest_pairs) <- NULL
  if (!identical(result_pairs, manifest_pairs)) {
    fail("Observation-noise result hashes do not match the pair manifest.")
  }
  invisible(TRUE)
}
