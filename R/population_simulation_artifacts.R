# Accepted-artifact validation and manuscript summaries ----------------------

#' Validate production population-simulation results
#' @param results Data frame produced by the production simulation runner.
#' @param nsim Optional expected number of replicates in each scenario.
#' @return `TRUE`, invisibly, or an error for an incomplete result block.
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
validate_population_simulation_artifact <- function(path, nsim = NULL) {
  if (!file.exists(path)) {
    abort_population_simulation(
      paste("Missing production simulation artifact:", path),
      "rcdates_sim_provenance_error"
    )
  }
  results <- readRDS(path)
  provenance <- attr(results, "production_provenance", exact = TRUE)
  schema_version <- if (is.null(provenance)) NULL else provenance$schema_version
  if (!identical(schema_version, 1L) && !identical(schema_version, 2L)) {
    abort_population_simulation(
      "Production artifact has an unsupported provenance schema.",
      "rcdates_sim_provenance_error"
    )
  }
  source_fields <- if (identical(schema_version, 1L)) {
    c("production_source_md5", "legacy_helper_md5")
  } else {
    c("model_source_md5", "distribution_source_md5")
  }
  required_provenance <- c(
    "schema_version", "true_model", "prop", "nsim", "master_seed",
    "input_md5", "renv_lock_md5", source_fields, "runner_source_md5",
    "container_recipe_md5", "container_install_md5", "container_image_id",
    "r_version"
  )
  if (identical(schema_version, 1L)) {
    required_provenance <- c(required_provenance, "provenance_origin")
  }
  if (!identical(sort(names(provenance)), sort(required_provenance))) {
    abort_population_simulation(
      "Production artifact lacks a complete provenance fingerprint.",
      "rcdates_sim_provenance_error"
    )
  }
  md5_fields <- c(
    "input_md5", "renv_lock_md5", source_fields, "runner_source_md5",
    "container_recipe_md5"
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
  install_hash_pattern <- if (identical(schema_version, 1L)) {
    "^([0-9a-f]{32}|inline-in-recipe)$"
  } else {
    "^[0-9a-f]{32}$"
  }
  valid_header <- positive_integer(provenance$nsim) &&
    positive_integer(provenance$master_seed) &&
    valid_string(provenance$true_model, "^(uni|lin|exp)$") &&
    length(provenance$prop) == 1L && is.finite(provenance$prop) &&
    any(abs(provenance$prop - c(0.5, 0.75, 1)) < sqrt(.Machine$double.eps)) &&
    valid_string(
      provenance$container_install_md5,
      install_hash_pattern
    ) &&
    valid_string(provenance$container_image_id, "^sha256:[0-9a-f]{64}$") &&
    valid_string(provenance$r_version, "^R version 4\\.5\\.3 \\(")
  if (identical(schema_version, 1L)) {
    valid_header <- valid_header && valid_string(
      provenance$provenance_origin,
      "^(native-checkpoint|post-run-stamp)$"
    )
  }
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
    runner_source_md5 = "runner_source_md5",
    container_recipe_md5 = "container_recipe_md5",
    container_install_md5 = "container_install_md5",
    container_image_id = "container_image_id"
  )
  metadata_map <- c(metadata_map, stats::setNames(source_fields, source_fields))
  if (identical(schema_version, 1L)) {
    metadata_map <- c(metadata_map, provenance_origin = "provenance_origin")
  }
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
