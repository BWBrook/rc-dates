## Paired observation-noise sensitivity summaries --------------------------

observation_noise_true_parameters <- function(
  min_age = 651,
  max_age = 11650,
  ratio = 10
) {
  span <- as.numeric(max_age) - as.numeric(min_age)
  if (length(span) != 1L || !is.finite(span) || span <= 0 ||
      length(ratio) != 1L || !is.finite(ratio) || ratio <= 1) {
    stop("Invalid analysis window or growth ratio.", call. = FALSE)
  }
  c(
    lin = 2 * (ratio - 1) / ((ratio + 1) * span^2),
    exp = log(ratio) / span
  )
}

observation_noise_abort <- function(message) {
  if (exists("abort_population_simulation", mode = "function")) {
    abort_population_simulation(message, "rcdates_sim_result_error")
  }
  stop(message, call. = FALSE)
}

read_observation_noise_metadata <- function(path) {
  if (!file.exists(path)) {
    observation_noise_abort(paste("Missing observation-noise metadata:", path))
  }
  lines <- readLines(path, warn = FALSE)
  records <- grep("^[a-z][a-z0-9_]*:[[:space:]]*", lines, value = TRUE)
  keys <- sub(":.*$", "", records)
  values <- sub("^[^:]+:[[:space:]]*", "", records)
  if (length(records) == 0L || anyDuplicated(keys)) {
    observation_noise_abort(
      "Observation-noise metadata are empty or contain duplicate keys."
    )
  }
  stats::setNames(values, keys)
}

validate_observation_noise_frozen_snapshot <- function(
  provenance_dir = file.path("provenance", "observation-noise-20260726")
) {
  manifest_path <- file.path(provenance_dir, "SHA256SUMS")
  if (!file.exists(manifest_path) ||
      !requireNamespace("digest", quietly = TRUE)) {
    observation_noise_abort(
      "Frozen observation-noise provenance or the digest package is unavailable."
    )
  }
  records <- readLines(manifest_path, warn = FALSE)
  pattern <- "^([0-9a-f]{64})[[:space:]]{2}(.+)$"
  matches <- regmatches(records, regexec(pattern, records))
  if (length(records) == 0L ||
      any(vapply(matches, length, integer(1)) != 3L)) {
    observation_noise_abort("Frozen observation-noise SHA-256 inventory is malformed.")
  }
  expected <- vapply(matches, `[[`, character(1), 2L)
  relative <- vapply(matches, `[[`, character(1), 3L)
  paths <- file.path(provenance_dir, relative)
  if (any(!file.exists(paths))) {
    observation_noise_abort("Frozen observation-noise provenance files are missing.")
  }
  observed <- vapply(paths, function(path) {
    digest::digest(file = path, algo = "sha256", serialize = FALSE)
  }, character(1))
  if (!identical(unname(observed), unname(expected))) {
    observation_noise_abort("Frozen observation-noise SHA-256 inventory does not verify.")
  }
  list(
    directory = provenance_dir,
    manifest_path = manifest_path,
    manifest_sha256 = digest::digest(
      file = manifest_path,
      algo = "sha256",
      serialize = FALSE
    )
  )
}

observation_noise_frozen_md5 <- function(provenance_dir) {
  paths <- c(
    production_source_md5 = file.path(
      provenance_dir,
      "R",
      "population_simulation_production.R"
    ),
    sensitivity_source_md5 = file.path(
      provenance_dir,
      "R",
      "observation_noise_sensitivity.R"
    ),
    legacy_helper_md5 = file.path(
      provenance_dir,
      "R",
      "legacy_simulation_helpers.R"
    ),
    runner_source_md5 = file.path(
      provenance_dir,
      "scripts",
      "run_observation_noise_sensitivity.R"
    ),
    container_recipe_md5 = file.path(
      provenance_dir,
      "docker",
      "production-simulation.Dockerfile"
    ),
    container_install_md5 = file.path(
      provenance_dir,
      "docker",
      "install-production-packages.R"
    )
  )
  if (any(!file.exists(paths))) {
    observation_noise_abort("Frozen observation-noise source snapshot is incomplete.")
  }
  unname(tools::md5sum(paths)) |>
    stats::setNames(names(paths))
}

observation_noise_manifest_matches_csv <- function(pair_manifest, csv_path) {
  if (!file.exists(csv_path)) {
    observation_noise_abort(paste("Missing observation-noise pair CSV:", csv_path))
  }
  csv <- utils::read.csv(
    csv_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if (!identical(names(csv), names(pair_manifest)) ||
      nrow(csv) != nrow(pair_manifest)) {
    observation_noise_abort(
      "Observation-noise pair CSV does not match the checkpoint manifest schema."
    )
  }
  csv <- csv[order(csv$pair_id), , drop = FALSE]
  pair_manifest <- pair_manifest[order(pair_manifest$pair_id), , drop = FALSE]
  rownames(csv) <- NULL
  rownames(pair_manifest) <- NULL
  if (!isTRUE(all.equal(
    csv,
    pair_manifest,
    check.attributes = FALSE,
    tolerance = 1e-14
  ))) {
    observation_noise_abort(
      "Observation-noise pair CSV does not match the checkpoint manifest values."
    )
  }
  invisible(TRUE)
}

validate_observation_noise_artifact <- function(
  path,
  provenance_dir = file.path("provenance", "observation-noise-20260726"),
  input_path = file.path("data", "austarch_filtered.csv"),
  lock_path = "renv.lock",
  image_id_path = file.path(dirname(path), "container_image_id.txt"),
  expected_nsim = 1000L,
  expected_seed = 1234L,
  expected_strategies = c("r_all", "r_1", "r_3", "r_5")
) {
  required_files <- c(path, input_path, lock_path, image_id_path)
  if (any(!file.exists(required_files))) {
    observation_noise_abort(
      paste(
        "Observation-noise artifact validation is missing:",
        paste(required_files[!file.exists(required_files)], collapse = ", ")
      )
    )
  }
  snapshot <- validate_observation_noise_frozen_snapshot(provenance_dir)
  checkpoint <- readRDS(path)
  if (!is.list(checkpoint) ||
      !identical(
        sort(names(checkpoint)),
        sort(c("results", "pair_manifest", "provenance"))
      )) {
    observation_noise_abort(
      "Observation-noise checkpoint does not have the required exact schema."
    )
  }
  provenance <- checkpoint$provenance
  required_provenance <- c(
    "schema_version", "sensitivity_design", "observation_models",
    "assay_equation", "calibration_curve", "roundyear",
    "window_exclusion_rule", "rng_kind", "stream_mapping", "true_model",
    "prop", "nsim", "master_seed", "strategies", "input_md5",
    "renv_lock_md5", "production_source_md5", "sensitivity_source_md5",
    "legacy_helper_md5", "runner_source_md5", "container_recipe_md5",
    "container_install_md5", "container_image_id", "r_version",
    "rcarbon_version"
  )
  if (!is.list(provenance) ||
      !identical(sort(names(provenance)), sort(required_provenance))) {
    observation_noise_abort(
      "Observation-noise checkpoint provenance has an incompatible schema."
    )
  }

  image_id <- trimws(readLines(image_id_path, warn = FALSE))
  frozen_md5 <- observation_noise_frozen_md5(provenance_dir)
  observed_md5 <- unlist(provenance[names(frozen_md5)], use.names = TRUE)
  valid_header <- identical(provenance$schema_version, 1L) &&
    identical(
      provenance$sensitivity_design,
      "paired_curve_mean_vs_realised_v1"
    ) &&
    identical(provenance$observation_models, c("curve_mean", "realised")) &&
    identical(
      provenance$assay_equation,
      "rCRA=round(ccCRA+Z*sqrt(ccError^2+quoted_error^2))"
    ) &&
    identical(provenance$calibration_curve, "shcal20") &&
    isTRUE(provenance$roundyear) &&
    identical(
      provenance$window_exclusion_rule,
      "drop selected observations with zero posterior mass in 651-11650"
    ) &&
    identical(provenance$rng_kind, "L'Ecuyer-CMRG") &&
    identical(
      provenance$stream_mapping,
      "structural=current; realised_assay=nextRNGStream(structural)"
    ) &&
    identical(as.integer(provenance$nsim), as.integer(expected_nsim)) &&
    identical(as.integer(provenance$master_seed), as.integer(expected_seed)) &&
    identical(as.character(provenance$strategies), expected_strategies) &&
    identical(provenance$r_version, "R version 4.5.3 (2026-03-11)") &&
    identical(provenance$rcarbon_version, "1.5.2") &&
    length(image_id) == 1L &&
    grepl("^sha256:[0-9a-f]{64}$", image_id) &&
    identical(provenance$container_image_id, image_id)
  valid_fingerprints <- identical(
    unname(observed_md5),
    unname(frozen_md5)
  ) &&
    identical(
      provenance$input_md5,
      unname(tools::md5sum(input_path))
    ) &&
    identical(
      provenance$renv_lock_md5,
      unname(tools::md5sum(lock_path))
    )
  if (!valid_header || !valid_fingerprints) {
    observation_noise_abort(
      "Observation-noise checkpoint does not match the frozen run provenance."
    )
  }

  validate_observation_noise_sensitivity_results(
    checkpoint$results,
    nsim = as.integer(expected_nsim),
    strategies = expected_strategies
  )
  validate_observation_noise_pair_manifest(
    checkpoint$pair_manifest,
    nsim = as.integer(expected_nsim)
  )
  validate_observation_noise_result_manifest_pairing(
    checkpoint$results,
    checkpoint$pair_manifest
  )

  pair_path <- sub("\\.rds$", ".pairs.csv", path)
  if (identical(pair_path, path)) pair_path <- paste0(path, ".pairs.csv")
  metadata_path <- paste0(path, ".metadata.txt")
  observation_noise_manifest_matches_csv(checkpoint$pair_manifest, pair_path)
  metadata <- read_observation_noise_metadata(metadata_path)
  metadata_map <- c(
    schema_version = "schema_version",
    r_version = "r_version",
    rcarbon_version = "rcarbon_version",
    true_model = "true_model",
    site_subsampling_proportion = "prop",
    paired_replicates = "nsim",
    master_seed = "master_seed",
    sensitivity_design = "sensitivity_design",
    assay_equation = "assay_equation",
    window_exclusion_rule = "window_exclusion_rule",
    rng_kind = "rng_kind",
    stream_mapping = "stream_mapping",
    input_md5 = "input_md5",
    renv_lock_md5 = "renv_lock_md5",
    production_source_md5 = "production_source_md5",
    sensitivity_source_md5 = "sensitivity_source_md5",
    legacy_helper_md5 = "legacy_helper_md5",
    runner_source_md5 = "runner_source_md5",
    container_recipe_md5 = "container_recipe_md5",
    container_install_md5 = "container_install_md5",
    container_image_id = "container_image_id"
  )
  required_metadata <- c(
    names(metadata_map),
    "generation_completed_utc",
    "strategies",
    "output_md5",
    "pair_manifest_md5",
    "packages"
  )
  if (!all(required_metadata %in% names(metadata))) {
    observation_noise_abort("Observation-noise metadata sidecar is incomplete.")
  }
  metadata_matches <- vapply(names(metadata_map), function(key) {
    expected <- provenance[[metadata_map[[key]]]]
    identical(metadata[[key]], as.character(expected))
  }, logical(1))
  valid_metadata <- all(metadata_matches) &&
    identical(metadata[["strategies"]], paste(expected_strategies, collapse = ",")) &&
    identical(metadata[["output_md5"]], unname(tools::md5sum(path))) &&
    identical(metadata[["pair_manifest_md5"]], unname(tools::md5sum(pair_path))) &&
    grepl(
      "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} UTC$",
      metadata[["generation_completed_utc"]]
    )
  if (!all(valid_metadata)) {
    observation_noise_abort(
      "Observation-noise checkpoint and metadata fingerprints do not agree."
    )
  }
  list(
    checkpoint = checkpoint,
    path = path,
    pair_path = pair_path,
    metadata_path = metadata_path,
    checkpoint_md5 = unname(tools::md5sum(path)),
    pair_md5 = unname(tools::md5sum(pair_path)),
    metadata_md5 = unname(tools::md5sum(metadata_path)),
    frozen_manifest_sha256 = snapshot$manifest_sha256
  )
}

observation_noise_scenario_key <- function(true, prop) {
  paste(as.character(true), format(as.numeric(prop), trim = TRUE, scientific = FALSE), sep = "|")
}

observation_noise_validate_provenance <- function(checkpoints) {
  if (!is.list(checkpoints) || length(checkpoints) == 0L) {
    observation_noise_abort("No observation-noise checkpoints were supplied.")
  }
  required <- c("results", "pair_manifest", "provenance")
  if (any(!vapply(checkpoints, function(x) is.list(x) && all(required %in% names(x)), logical(1)))) {
    observation_noise_abort("Every checkpoint must contain results, pair_manifest, and provenance.")
  }
  scenario_fields <- c("true_model", "prop", "nsim", "strategies")
  provenance <- lapply(checkpoints, `[[`, "provenance")
  if (any(vapply(provenance, is.null, logical(1)))) {
    observation_noise_abort("Every checkpoint must contain provenance.")
  }
  common_names <- Reduce(intersect, lapply(provenance, names))
  if (length(common_names) == 0L) {
    observation_noise_abort("Checkpoints have no common provenance fields.")
  }
  common_names <- sort(setdiff(common_names, scenario_fields))
  comparable_names <- lapply(provenance, function(x) setdiff(names(x), scenario_fields))
  if (any(vapply(comparable_names, function(x) !identical(sort(x), sort(comparable_names[[1L]])), logical(1)))) {
    observation_noise_abort("Sensitivity checkpoints have incompatible provenance schemas.")
  }
  same <- vapply(seq_along(provenance)[-1L], function(i) {
    identical(provenance[[i]][common_names], provenance[[1L]][common_names])
  }, logical(1))
  if (length(same) > 0L && !all(same)) {
    observation_noise_abort("Sensitivity checkpoints do not share common provenance.")
  }
  invisible(TRUE)
}

observation_noise_check_all_dates <- function(results) {
  all_dates <- results[results$strategy == "r_all", , drop = FALSE]
  if (nrow(all_dates) == 0L) observation_noise_abort("No all-dates results were supplied.")
  props <- sort(unique(all_dates$prop))
  if (length(props) < 2L) return(invisible(TRUE))
  # Pairing hashes certify the design but selection_hash intentionally changes
  # with the treated-site proportion; neither hash is an all-dates outcome.
  comparison_columns <- setdiff(
    names(all_dates), c("prop", "pair_id", "structure_hash", "selection_hash")
  )
  reference <- all_dates[all_dates$prop == props[[1L]], comparison_columns, drop = FALSE]
  reference <- reference[order(reference$true, reference$sim, reference$observation_model,
                              reference$type, reference$model), , drop = FALSE]
  rownames(reference) <- NULL
  for (prop in props[-1L]) {
    candidate <- all_dates[all_dates$prop == prop, comparison_columns, drop = FALSE]
    candidate <- candidate[order(candidate$true, candidate$sim, candidate$observation_model,
                                 candidate$type, candidate$model), , drop = FALSE]
    rownames(candidate) <- NULL
    if (!identical(candidate, reference)) {
      observation_noise_abort(
        paste("All-dates results differ across proportions within an observation arm (prop", prop, ").")
      )
    }
  }
  invisible(TRUE)
}

validate_observation_noise_summary_inputs <- function(
  checkpoints,
  strategies = c("r_all", "r_1", "r_3", "r_5"),
  require_complete_scenarios = TRUE
) {
  observation_noise_validate_provenance(checkpoints)
  if (exists("normalize_observation_noise_strategies", mode = "function")) {
    strategies <- normalize_observation_noise_strategies(strategies)
  }
  for (checkpoint in checkpoints) {
    provenance <- checkpoint$provenance
    valid_nsim <- length(provenance$nsim) == 1L && is.finite(provenance$nsim) &&
      provenance$nsim >= 1L && provenance$nsim == as.integer(provenance$nsim)
    if (!valid_nsim) observation_noise_abort("Each checkpoint provenance must declare a positive nsim.")
    if (!identical(sort(unique(as.character(checkpoint$results$true))), as.character(provenance$true_model)) ||
        length(unique(checkpoint$results$prop)) != 1L ||
        !isTRUE(abs(unique(checkpoint$results$prop) - as.numeric(provenance$prop)) < sqrt(.Machine$double.eps))) {
      observation_noise_abort("Checkpoint results do not match their scenario provenance.")
    }
    if (!identical(sort(unique(as.character(checkpoint$pair_manifest$true))), as.character(provenance$true_model)) ||
        length(unique(checkpoint$pair_manifest$prop)) != 1L ||
        !isTRUE(abs(unique(checkpoint$pair_manifest$prop) - as.numeric(provenance$prop)) < sqrt(.Machine$double.eps))) {
      observation_noise_abort("Checkpoint pair manifest does not match its scenario provenance.")
    }
    if (!identical(sort(unique(as.integer(checkpoint$results$sim))), seq_len(as.integer(provenance$nsim))) ||
        !identical(sort(unique(as.integer(checkpoint$pair_manifest$sim))), seq_len(as.integer(provenance$nsim)))) {
      observation_noise_abort("Checkpoint replicates are incomplete relative to provenance$nsim.")
    }
    if (exists("validate_observation_noise_sensitivity_results", mode = "function")) {
      validate_observation_noise_sensitivity_results(
        checkpoint$results, nsim = as.integer(provenance$nsim), strategies = strategies
      )
      validate_observation_noise_pair_manifest(
        checkpoint$pair_manifest, nsim = as.integer(provenance$nsim)
      )
    }
    if (!identical(sort(unique(checkpoint$results$observation_model)), c("curve_mean", "realised"))) {
      observation_noise_abort("Each checkpoint must contain both observation-noise arms.")
    }
    if (!identical(sort(unique(checkpoint$results$strategy)), sort(strategies))) {
      observation_noise_abort("Checkpoint strategies do not match the requested sensitivity strategies.")
    }
    if (anyDuplicated(checkpoint$pair_manifest$pair_id)) {
      observation_noise_abort("Checkpoint pair manifests contain duplicate pair identifiers.")
    }
  }
  nsims <- vapply(checkpoints, function(x) as.integer(x$provenance$nsim), integer(1))
  if (length(unique(nsims)) != 1L) observation_noise_abort("Checkpoints must share one declared nsim.")
  scenarios <- vapply(checkpoints, function(x) {
    p <- x$provenance
    observation_noise_scenario_key(p$true_model, p$prop)
  }, character(1))
  if (anyDuplicated(scenarios)) observation_noise_abort("Duplicate sensitivity scenarios were supplied.")
  if (isTRUE(require_complete_scenarios)) {
    expected <- unlist(lapply(c(0.5, 0.75, 1), function(prop) {
      vapply(c("uni", "lin", "exp"), observation_noise_scenario_key,
             character(1), prop = prop)
    }), use.names = FALSE)
    if (!setequal(scenarios, expected)) {
      observation_noise_abort("The sensitivity set must contain all 3 truths at all 3 proportions.")
    }
  }
  results <- do.call(rbind, lapply(checkpoints, `[[`, "results"))
  manifests <- do.call(rbind, lapply(checkpoints, `[[`, "pair_manifest"))
  rownames(results) <- NULL
  rownames(manifests) <- NULL
  if (anyDuplicated(manifests$pair_id) || !setequal(unique(results$pair_id), manifests$pair_id)) {
    observation_noise_abort("Results and pair manifests do not define one unique pair per replicate.")
  }
  if (exists(
    "validate_observation_noise_result_manifest_pairing",
    mode = "function"
  )) {
    validate_observation_noise_result_manifest_pairing(results, manifests)
  }
  observation_noise_check_all_dates(results)
  list(results = results, pair_manifest = manifests, provenance = checkpoints[[1L]]$provenance,
       strategies = strategies, scenarios = scenarios)
}

observation_noise_metric_rows <- function(results, pair_manifest, true_parameters) {
  key <- interaction(results$true, results$prop, results$strategy, results$type,
                     results$sim, results$observation_model, drop = TRUE, lex.order = TRUE)
  groups <- split(results, key)
  rows <- lapply(groups, function(x) {
    min_row <- x[x$min == 1L, , drop = FALSE]
    ose_rows <- x[x$ose == 1L, , drop = FALSE]
    true <- as.character(x$true[[1L]])
    n_observations <- unique(x$n_observations)
    n_dropped <- unique(x$n_dropped)
    if (length(n_observations) != 1L || length(n_dropped) != 1L) {
      observation_noise_abort(
        "Observation-noise likelihood inclusion counts are inconsistent."
      )
    }
    data.frame(
      sim = x$sim[[1L]], true = true, prop = x$prop[[1L]], strategy = x$strategy[[1L]],
      type = x$type[[1L]], observation_model = x$observation_model[[1L]],
      accuracy = as.numeric(min_row$model[[1L]] == true),
      min_model = as.character(min_row$model[[1L]]),
      ose_unique_true = as.numeric(all(as.character(ose_rows$model) == true)),
      ose_set = paste(sort(as.character(ose_rows$model)), collapse = "|"),
      n_observations = n_observations[[1L]],
      n_dropped = n_dropped[[1L]],
      drop_rate = n_dropped[[1L]] /
        (n_observations[[1L]] + n_dropped[[1L]]),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  manifest <- pair_manifest[match(unique(results$pair_id), pair_manifest$pair_id), , drop = FALSE]
  if (nrow(manifest) > 0L) {
    # Pair-manifest rates are already replicate-level summaries, so retain them as
    # one value per pair and arm for cluster bootstrap rather than reweighting dates.
    manifest_long <- rbind(
      data.frame(sim = manifest$sim, true = manifest$true, prop = manifest$prop,
                 strategy = "manifest", type = "mass", observation_model = "curve_mean",
                 low_mass = manifest$expectation_low_mass_rate,
                 zero_mass = manifest$expectation_zero_mass_rate),
      data.frame(sim = manifest$sim, true = manifest$true, prop = manifest$prop,
                 strategy = "manifest", type = "mass", observation_model = "realised",
                 low_mass = manifest$realised_low_mass_rate,
                 zero_mass = manifest$realised_zero_mass_rate)
    )
    out$true_parameter <- ifelse(out$true %in% names(true_parameters), true_parameters[out$true], NA_real_)
    attr(out, "manifest_long") <- manifest_long
  }
  out
}

observation_noise_paired_bootstrap <- function(
  data,
  value,
  metric,
  n_boot = 5000L,
  seed = 1234L,
  normalise = NULL
) {
  required <- c("sim", "true", "prop", "strategy", "type", "observation_model")
  if (!all(required %in% names(data)) || length(value) != nrow(data)) {
    observation_noise_abort("Paired bootstrap input is malformed.")
  }
  data$value <- as.numeric(value)
  data <- data[is.finite(data$value), , drop = FALSE]
  if (nrow(data) == 0L) return(data.frame())
  group_key <- interaction(data$prop, data$strategy, data$type, drop = TRUE, lex.order = TRUE)
  groups <- split(data, group_key)
  sims <- sort(unique(data$sim))
  cell_labels <- list()
  cell_values <- list()
  for (g in groups) {
    specs <- c("pooled", sort(unique(as.character(g$true))))
    for (scope in specs) {
      z <- if (scope == "pooled") g else g[g$true == scope, , drop = FALSE]
      arm_values <- lapply(c("curve_mean", "realised"), function(arm) {
        vapply(sims, function(sim) {
          rows <- z[z$sim == sim & z$observation_model == arm, , drop = FALSE]
          if (nrow(rows) == 0L) return(NA_real_)
          mean(rows$value)
        }, numeric(1))
      })
      if (any(!vapply(arm_values, function(x) all(is.finite(x)), logical(1)))) {
        observation_noise_abort("Paired bootstrap encountered a missing arm or simulation.")
      }
      if (!is.null(normalise)) arm_values <- lapply(arm_values, `/`, normalise)
      for (i in seq_along(arm_values)) {
        cell_labels[[length(cell_labels) + 1L]] <- list(
          scope = scope, prop = g$prop[[1L]], strategy = g$strategy[[1L]],
          type = g$type[[1L]], arm = c("curve_mean", "realised")[[i]]
        )
        cell_values[[length(cell_values) + 1L]] <- arm_values[[i]]
      }
      cell_labels[[length(cell_labels) + 1L]] <- list(
        scope = scope, prop = g$prop[[1L]], strategy = g$strategy[[1L]],
        type = g$type[[1L]], arm = "difference"
      )
      cell_values[[length(cell_values) + 1L]] <- arm_values[[2L]] - arm_values[[1L]]
    }
  }
  cluster_matrix <- do.call(cbind, cell_values)
  estimates <- colMeans(cluster_matrix)
  set.seed(seed)
  counts <- stats::rmultinom(
    as.integer(n_boot), size = length(sims), prob = rep(1 / length(sims), length(sims))
  )
  boot <- crossprod(counts, cluster_matrix) / length(sims)
  max_dev <- apply(abs(sweep(boot, 2L, estimates, FUN = "-")), 1L, max)
  half_width <- stats::quantile(max_dev, 0.95, names = FALSE)
  out <- do.call(rbind, lapply(seq_along(cell_labels), function(i) {
    label <- cell_labels[[i]]
    data.frame(
      metric = metric, scope = label$scope,
      true = if (label$scope == "pooled") NA_character_ else label$scope,
      prop = label$prop, strategy = label$strategy, type = label$type,
      arm = label$arm, estimate = estimates[[i]], ci_low = estimates[[i]] - half_width,
      ci_high = estimates[[i]] + half_width, n_clusters = length(sims),
      stringsAsFactors = FALSE
    )
  }))
  rownames(out) <- NULL
  out
}

observation_noise_decision_discordance <- function(metric_rows, field, metric, n_boot, seed) {
  required <- c("sim", "true", "prop", "strategy", "type", "observation_model", field)
  if (!all(required %in% names(metric_rows))) observation_noise_abort("Decision field is missing.")
  x <- metric_rows
  key <- interaction(x$true, x$prop, x$strategy, x$type, x$sim, drop = TRUE, lex.order = TRUE)
  rows <- lapply(split(x, key), function(z) {
    if (length(unique(z$observation_model)) != 2L) observation_noise_abort("Unpaired decision rows detected.")
    curve <- z[z$observation_model == "curve_mean", field][[1L]]
    realised <- z[z$observation_model == "realised", field][[1L]]
    data.frame(
      sim = z$sim[[1L]], true = z$true[[1L]], prop = z$prop[[1L]],
      strategy = z$strategy[[1L]], type = z$type[[1L]],
      observation_model = "difference", value = as.numeric(!identical(curve, realised)),
      stringsAsFactors = FALSE
    )
  })
  d <- do.call(rbind, rows)
  # The result is already a paired scalar per replicate; use the same simultaneous
  # cluster bootstrap implementation with a synthetic two-arm representation.
  paired <- rbind(
    transform(d, observation_model = "curve_mean", value = 0),
    transform(d, observation_model = "realised", value = d$value)
  )
  out <- observation_noise_paired_bootstrap(paired, paired$value, metric, n_boot, seed)
  out[out$arm == "difference", , drop = FALSE]
}

observation_noise_realised_strategy_contrasts <- function(
  metric_rows,
  field,
  metric,
  n_boot,
  seed,
  targets = c("r_all", "r_3", "r_5"),
  reference = "r_1"
) {
  required <- c(
    "sim", "true", "prop", "strategy", "type", "observation_model", field
  )
  if (!all(required %in% names(metric_rows))) {
    observation_noise_abort("Realised strategy-contrast input is incomplete.")
  }
  x <- metric_rows[
    metric_rows$observation_model == "realised" &
      metric_rows$strategy %in% c(reference, targets),
    ,
    drop = FALSE
  ]
  if (nrow(x) == 0L) return(data.frame())
  sims <- sort(unique(x$sim))
  cells <- list()
  for (prop in sort(unique(x$prop))) {
    for (type in sort(unique(x$type))) {
      block <- x[x$prop == prop & x$type == type, , drop = FALSE]
      scopes <- c("pooled", sort(unique(as.character(block$true))))
      for (scope in scopes) {
        scoped <- if (scope == "pooled") {
          block
        } else {
          block[block$true == scope, , drop = FALSE]
        }
        for (target in targets) {
          values <- vapply(sims, function(sim) {
            target_value <- scoped[
              scoped$sim == sim & scoped$strategy == target,
              field,
              drop = TRUE
            ]
            reference_value <- scoped[
              scoped$sim == sim & scoped$strategy == reference,
              field,
              drop = TRUE
            ]
            if (length(target_value) == 0L ||
                length(reference_value) == 0L) {
              return(NA_real_)
            }
            mean(target_value) - mean(reference_value)
          }, numeric(1))
          if (any(!is.finite(values))) {
            observation_noise_abort(
              "Realised strategy contrast is missing a simulation or strategy."
            )
          }
          cells[[length(cells) + 1L]] <- list(
            scope = scope,
            true = if (scope == "pooled") NA_character_ else scope,
            prop = prop,
            strategy = target,
            reference_strategy = reference,
            type = type,
            values = values
          )
        }
      }
    }
  }
  cluster_matrix <- do.call(cbind, lapply(cells, `[[`, "values"))
  estimates <- colMeans(cluster_matrix)
  set.seed(seed)
  counts <- stats::rmultinom(
    as.integer(n_boot),
    size = length(sims),
    prob = rep(1 / length(sims), length(sims))
  )
  boot <- crossprod(counts, cluster_matrix) / length(sims)
  max_dev <- apply(
    abs(sweep(boot, 2L, estimates, FUN = "-")),
    1L,
    max
  )
  half_width <- stats::quantile(max_dev, 0.95, names = FALSE)
  do.call(rbind, lapply(seq_along(cells), function(i) {
    cell <- cells[[i]]
    data.frame(
      metric = metric,
      scope = cell$scope,
      true = cell$true,
      prop = cell$prop,
      strategy = cell$strategy,
      reference_strategy = cell$reference_strategy,
      type = cell$type,
      arm = "difference",
      estimate = estimates[[i]],
      ci_low = estimates[[i]] - half_width,
      ci_high = estimates[[i]] + half_width,
      n_clusters = length(sims),
      stringsAsFactors = FALSE
    )
  }))
}

observation_noise_accuracy_advantage <- function(metric_rows, n_boot, seed) {
  out <- observation_noise_realised_strategy_contrasts(
    metric_rows = metric_rows,
    field = "accuracy",
    metric = "accuracy_advantage_over_r1",
    n_boot = n_boot,
    seed = seed,
    targets = c("r_3", "r_5"),
    reference = "r_1"
  )
  out[
    out$prop == 1 & out$scope == "pooled",
    ,
    drop = FALSE
  ]
}

observation_noise_rmse_summary <- function(bias_rows, n_boot, seed) {
  if (nrow(bias_rows) == 0L) return(data.frame())
  bias_rows$se <- bias_rows$bias / bias_rows$parameter
  groups <- split(bias_rows, interaction(bias_rows$prop, bias_rows$strategy,
                                          bias_rows$type, drop = TRUE, lex.order = TRUE))
  labels <- list()
  curve_sq <- list()
  realised_sq <- list()
  sims <- sort(unique(bias_rows$sim))
  for (g in groups) {
    scopes <- c("pooled", sort(unique(g$true)))
    for (scope in scopes) {
      z <- if (scope == "pooled") g else g[g$true == scope, , drop = FALSE]
      cvals <- vapply(sims, function(sim) {
        b <- z$se[z$sim == sim & z$observation_model == "curve_mean"]
        if (length(b) == 0L) NA_real_ else mean(b^2)
      }, numeric(1))
      rvals <- vapply(sims, function(sim) {
        b <- z$se[z$sim == sim & z$observation_model == "realised"]
        if (length(b) == 0L) NA_real_ else mean(b^2)
      }, numeric(1))
      if (any(!is.finite(cvals)) || any(!is.finite(rvals))) {
        observation_noise_abort("RMSE ratio encountered a missing paired arm or simulation.")
      }
      labels[[length(labels) + 1L]] <- list(
        scope = scope, true = if (scope == "pooled") NA_character_ else scope,
        prop = g$prop[[1L]], strategy = g$strategy[[1L]], type = g$type[[1L]]
      )
      curve_sq[[length(curve_sq) + 1L]] <- cvals
      realised_sq[[length(realised_sq) + 1L]] <- rvals
    }
  }
  curve_sq <- do.call(cbind, curve_sq)
  realised_sq <- do.call(cbind, realised_sq)
  point <- sqrt(colSums(realised_sq) / colSums(curve_sq))
  set.seed(seed)
  counts <- stats::rmultinom(as.integer(n_boot), size = length(sims),
                             prob = rep(1 / length(sims), length(sims)))
  curve_boot <- crossprod(counts, curve_sq)
  realised_boot <- crossprod(counts, realised_sq)
  log_boot <- 0.5 * (log(realised_boot) - log(curve_boot))
  log_point <- log(point)
  max_dev <- apply(abs(sweep(log_boot, 2L, log_point, FUN = "-")), 1L, max)
  half_width <- stats::quantile(max_dev, 0.95, names = FALSE)
  out <- do.call(rbind, lapply(seq_along(labels), function(i) {
    label <- labels[[i]]
    data.frame(
      metric = "rmse_ratio", scope = label$scope, true = label$true,
      prop = label$prop, strategy = label$strategy, type = label$type, arm = "ratio",
      estimate = point[[i]], ci_low = exp(log_point[[i]] - half_width),
      ci_high = exp(log_point[[i]] + half_width), n_clusters = length(sims),
      stringsAsFactors = FALSE
    )
  }))
  rownames(out) <- NULL
  out
}

observation_noise_optimizer_boundary_hit <- function(
  true_model,
  fitted_parameter,
  min_age = 651,
  max_age = 11650
) {
  if (length(true_model) != 1L || length(fitted_parameter) != 1L ||
      !true_model %in% c("lin", "exp") ||
      !is.finite(fitted_parameter)) {
    observation_noise_abort(
      "Optimizer-boundary detection requires one finite generating parameter."
    )
  }
  bounds <- if (true_model == "lin") {
    c(1e-12, 2 / (max_age - min_age)^2)
  } else {
    c(1e-10, 1e-3)
  }
  scale <- if (true_model == "lin") 1e6 else 1e3
  scaled_bounds <- bounds * scale
  # `evaluate_population_models()` uses the default `stats::optimize()`
  # tolerance on these scaled intervals. A monotone objective can therefore
  # return this far inside a true endpoint optimum.
  scaled_tolerance <- .Machine$double.eps^0.25 +
    3 * .Machine$double.eps * max(abs(scaled_bounds))
  any(abs(fitted_parameter * scale - scaled_bounds) <= scaled_tolerance)
}

observation_noise_result_metrics <- function(
  validated,
  n_boot = 5000L,
  seed = 1234L
) {
  params <- observation_noise_true_parameters()
  metric_rows <- observation_noise_metric_rows(validated$results, validated$pair_manifest, params)
  out <- list(
    accuracy = observation_noise_paired_bootstrap(metric_rows, metric_rows$accuracy,
                                                  "minimum_aic_accuracy", n_boot, seed),
    ose_support = observation_noise_paired_bootstrap(metric_rows, metric_rows$ose_unique_true,
                                                     "unique_ose_support", n_boot, seed + 10L),
    n_dropped = observation_noise_paired_bootstrap(metric_rows, metric_rows$n_dropped,
                                                   "n_dropped", n_boot, seed + 20L),
    drop_rate = observation_noise_paired_bootstrap(
      metric_rows,
      metric_rows$drop_rate,
      "strict_window_drop_rate",
      n_boot,
      seed + 21L
    )
  )
  out$decision_discordance <- observation_noise_decision_discordance(
    metric_rows, "min_model", "minimum_aic_decision_discordance", n_boot, seed + 5L
  )
  out$ose_set_discordance <- observation_noise_decision_discordance(
    metric_rows, "ose_set", "ose_set_discordance", n_boot, seed + 6L
  )
  out$realised_accuracy_contrasts <- observation_noise_realised_strategy_contrasts(
    metric_rows,
    "accuracy",
    "realised_accuracy_contrast_vs_r1",
    n_boot,
    seed + 7L
  )
  out$realised_ose_contrasts <- observation_noise_realised_strategy_contrasts(
    metric_rows,
    "ose_unique_true",
    "realised_ose_contrast_vs_r1",
    n_boot,
    seed + 8L
  )
  out$accuracy_advantage <- out$realised_accuracy_contrasts[
    out$realised_accuracy_contrasts$prop == 1 &
      out$realised_accuracy_contrasts$scope == "pooled" &
      out$realised_accuracy_contrasts$strategy %in% c("r_3", "r_5"),
    ,
    drop = FALSE
  ]
  out$accuracy_advantage$metric <- "accuracy_advantage_over_r1"
  bias_rows <- validated$results[!is.na(validated$results$bias) &
                                   validated$results$model == validated$results$true, , drop = FALSE]
  if (nrow(bias_rows) > 0L) {
    bias_rows$parameter <- params[as.character(bias_rows$true)]
    bias_rows$bias_relative <- bias_rows$bias / bias_rows$parameter
    bias_rows$boundary_hit <- vapply(seq_len(nrow(bias_rows)), function(i) {
      observation_noise_optimizer_boundary_hit(
        true_model = bias_rows$true[[i]],
        fitted_parameter = bias_rows$parameter[[i]] + bias_rows$bias[[i]]
      )
    }, logical(1))
    out$bias <- observation_noise_paired_bootstrap(
      bias_rows, bias_rows$bias_relative, "signed_bias_relative", n_boot, seed + 30L
    )
    out$paired_bias_shift <- observation_noise_paired_bootstrap(
      bias_rows, bias_rows$bias_relative, "paired_bias_shift_relative", n_boot, seed + 40L
    )
    # RMSE is summarised on the replicate scale; convert back from squared relative bias.
    out$rmse <- observation_noise_rmse_summary(bias_rows, n_boot, seed + 50L)
    out$boundary <- observation_noise_paired_bootstrap(
      bias_rows, as.numeric(bias_rows$boundary_hit), "optimizer_boundary_hit", n_boot, seed + 60L
    )
  } else {
    out$bias <- out$paired_bias_shift <- out$rmse <- out$boundary <- data.frame()
  }
  manifest_long <- attr(metric_rows, "manifest_long")
  if (!is.null(manifest_long)) {
    out$mass_low <- observation_noise_paired_bootstrap(manifest_long, manifest_long$low_mass,
                                                      "low_window_mass_rate", n_boot, seed + 70L)
    out$mass_zero <- observation_noise_paired_bootstrap(manifest_long, manifest_long$zero_mass,
                                                       "zero_window_mass_rate", n_boot, seed + 80L)
  }
  out
}

observation_noise_resolved_opposite_count <- function(
  data,
  group_columns
) {
  required <- c(group_columns, "type", "estimate", "ci_low", "ci_high")
  if (!is.data.frame(data) || nrow(data) == 0L) return(0L)
  if (!all(required %in% names(data))) {
    observation_noise_abort("L1/L2 consistency input is incomplete.")
  }
  keys <- lapply(data[group_columns], function(values) {
    values <- as.character(values)
    values[is.na(values)] <- "<NA>"
    values
  })
  key <- do.call(paste, c(keys, sep = "\r"))
  conflicts <- vapply(split(data, key), function(z) {
    if (!all(c("l1", "l2") %in% z$type)) return(0L)
    one <- z[z$type == "l1", , drop = FALSE]
    two <- z[z$type == "l2", , drop = FALSE]
    if (nrow(one) != 1L || nrow(two) != 1L) {
      observation_noise_abort("L1/L2 consistency cells are duplicated.")
    }
    resolved_one <- one$ci_low[[1L]] > 0 || one$ci_high[[1L]] < 0
    resolved_two <- two$ci_low[[1L]] > 0 || two$ci_high[[1L]] < 0
    as.integer(
      resolved_one &&
        resolved_two &&
        sign(one$estimate[[1L]]) != sign(two$estimate[[1L]])
    )
  }, integer(1))
  as.integer(sum(conflicts))
}

observation_noise_likelihood_consistency <- function(metrics) {
  arm_effect_conflicts <- sum(vapply(
    c("accuracy", "ose_support"),
    function(metric_name) {
      x <- metrics[[metric_name]]
      if (!is.data.frame(x) || nrow(x) == 0L) return(0L)
      x <- x[x$arm == "difference", , drop = FALSE]
      observation_noise_resolved_opposite_count(
        x,
        c("prop", "strategy", "scope", "true")
      )
    },
    integer(1)
  ))
  strategy_conflicts <- sum(vapply(
    c("realised_accuracy_contrasts", "realised_ose_contrasts"),
    function(metric_name) {
      x <- metrics[[metric_name]]
      if (!is.data.frame(x) || nrow(x) == 0L) return(0L)
      observation_noise_resolved_opposite_count(
        x,
        c(
          "prop", "strategy", "reference_strategy", "scope", "true"
        )
      )
    },
    integer(1)
  ))
  bias_conflicts <- sum(vapply(
    c("bias", "paired_bias_shift"),
    function(metric_name) {
      x <- metrics[[metric_name]]
      if (!is.data.frame(x) || nrow(x) == 0L) return(0L)
      arm <- if (metric_name == "bias") "realised" else "difference"
      x <- x[x$arm == arm, , drop = FALSE]
      observation_noise_resolved_opposite_count(
        x,
        c("prop", "strategy", "scope", "true")
      )
    },
    integer(1)
  ))
  conflicts <- arm_effect_conflicts + strategy_conflicts + bias_conflicts
  data.frame(
    pass = conflicts == 0L,
    conflicts = conflicts,
    arm_effect_conflicts = arm_effect_conflicts,
    strategy_conflicts = strategy_conflicts,
    bias_conflicts = bias_conflicts,
    details = paste(
      "Opposite, statistically resolved L1/L2 directions are checked for",
      "observation-arm effects, realised strategy contrasts, and bias."
    ),
    stringsAsFactors = FALSE
  )
}

observation_noise_gate_report <- function(metrics) {
  rows <- list()
  add <- function(gate, pass, observed, threshold, details = "", recommendation = "") {
    rows[[length(rows) + 1L]] <<- data.frame(
      gate = gate, pass = isTRUE(pass), observed = as.numeric(observed),
      threshold = as.numeric(threshold), details = details,
      recommendation = recommendation, stringsAsFactors = FALSE
    )
  }
  for (name in c("accuracy", "ose_support")) {
    x <- metrics[[name]][metrics[[name]]$arm == "difference", , drop = FALSE]
    if (nrow(x) > 0L) {
      bound <- ifelse(is.na(x$true), 0.03, 0.05)
      add(paste0(name, "_difference_ci"), all(x$ci_low >= -bound & x$ci_high <= bound),
          max(abs(c(x$ci_low, x$ci_high))), max(bound),
          "Simultaneous paired arm-difference interval.")
    }
  }
  if (nrow(metrics$accuracy) > 0L) {
    x <- metrics$decision_discordance
    add(
      "minimum_aic_discordance",
      nrow(x) > 0L && max(x$ci_high, na.rm = TRUE) <= 0.10,
      if (nrow(x) == 0L) NA_real_ else max(x$ci_high, na.rm = TRUE),
      0.10,
      "Upper simultaneous bound for paired selected-model discordance."
    )
    x <- metrics$ose_set_discordance
    add(
      "ose_set_discordance",
      nrow(x) > 0L && max(x$ci_high, na.rm = TRUE) <= 0.10,
      if (nrow(x) == 0L) NA_real_ else max(x$ci_high, na.rm = TRUE),
      0.10,
      "Upper simultaneous bound for paired OSE-set discordance."
    )
    noisy <- metrics$accuracy[metrics$accuracy$arm == "realised" &
                                is.na(metrics$accuracy$true) & metrics$accuracy$prop == 1 &
                                metrics$accuracy$type %in% c("l1", "l2") &
                                metrics$accuracy$strategy %in% c("r_3", "r_5"), , drop = FALSE]
    add("prop1_random3_random5_accuracy", nrow(noisy) == 4L &&
          all(noisy$estimate >= 0.90 & noisy$ci_low > 0.88),
        if (nrow(noisy) == 0L) NA_real_ else min(noisy$estimate, na.rm = TRUE), 0.90)
    truth_noisy <- metrics$accuracy[
      metrics$accuracy$arm == "realised" &
        !is.na(metrics$accuracy$true) &
        metrics$accuracy$prop == 1 &
        metrics$accuracy$type %in% c("l1", "l2") &
        metrics$accuracy$strategy %in% c("r_3", "r_5"),
      ,
      drop = FALSE
    ]
    add(
      "prop1_truth_specific_random3_random5_accuracy",
      nrow(truth_noisy) == 12L &&
        all(truth_noisy$estimate >= 0.85),
      if (nrow(truth_noisy) == 0L) {
        NA_real_
      } else {
        min(truth_noisy$estimate, na.rm = TRUE)
      },
      0.85,
      "Truth-specific safeguard against a pooled-accuracy mask."
    )
    add(
      "prop1_truth_specific_random3_random5_lower",
      nrow(truth_noisy) == 12L &&
        all(truth_noisy$ci_low > 0.80),
      if (nrow(truth_noisy) == 0L) {
        NA_real_
      } else {
        min(truth_noisy$ci_low, na.rm = TRUE)
      },
      0.80,
      "Truth-specific simultaneous lower-bound safeguard."
    )
    for (strategy in c("r_3", "r_5")) {
      advantage <- metrics$realised_accuracy_contrasts[
        metrics$realised_accuracy_contrasts$prop == 1 &
          metrics$realised_accuracy_contrasts$scope == "pooled" &
          metrics$realised_accuracy_contrasts$strategy == strategy,
        ,
        drop = FALSE
      ]
      lower <- if (nrow(advantage) == 0L) NA_real_ else min(advantage$ci_low)
      add(paste0("prop1_", strategy, "_advantage_over_r1"), is.finite(lower) && lower > 0,
          lower, 0, "Direct paired realised-arm contrast, target strategy minus random-1.")
    }
    consistency <- observation_noise_likelihood_consistency(metrics)
    add("l1_l2_qualitative_consistency", consistency$pass[[1L]],
        consistency$conflicts[[1L]], 0, consistency$details[[1L]])
  }
  if (nrow(metrics$bias) > 0L) {
    x <- metrics$bias[metrics$bias$arm == "realised", , drop = FALSE]
    add("noisy_absolute_mean_bias", nrow(x) > 0L && all(abs(x$estimate) < 0.05 &
                                                          x$ci_low >= -0.10 & x$ci_high <= 0.10, na.rm = TRUE),
        if (nrow(x) == 0L) NA_real_ else max(abs(x$estimate), na.rm = TRUE), 0.05,
        "Signed mean relative bias: absolute point estimate <5%; interval within +/-10%.")
    x <- metrics$paired_bias_shift[metrics$paired_bias_shift$arm == "difference", , drop = FALSE]
    add(
      "paired_bias_shift",
      nrow(x) > 0L && all(
        abs(x$estimate) < 0.05 &
          x$ci_low >= -0.10 &
          x$ci_high <= 0.10
      ),
      if (nrow(x) == 0L) {
        NA_real_
      } else {
        max(abs(c(x$ci_low, x$ci_high)), na.rm = TRUE)
      },
      0.10
    )
    x <- metrics$rmse[metrics$rmse$arm == "ratio", , drop = FALSE]
    add(
      "rmse_relative",
      nrow(x) > 0L &&
        all(x$ci_low >= 0.85 & x$ci_high <= 1.15),
      if (nrow(x) == 0L) {
        NA_real_
      } else {
        max(c(
          1 - min(x$ci_low, na.rm = TRUE),
          max(x$ci_high, na.rm = TRUE) - 1
        ))
      },
      0.15,
      "Entire simultaneous interval must remain within 0.85-1.15."
    )
    x <- metrics$boundary[metrics$boundary$arm == "difference", , drop = FALSE]
    add(
      "boundary_hit_increase",
      nrow(x) > 0L && all(x$ci_high < 0.01),
      if (nrow(x) == 0L) NA_real_ else max(x$ci_high, na.rm = TRUE),
      0.01,
      "Upper simultaneous bound for generating-parameter boundary hits."
    )
  }
  if (nrow(metrics$drop_rate) > 0L) {
    realised <- metrics$drop_rate[
      metrics$drop_rate$arm == "realised",
      ,
      drop = FALSE
    ]
    difference <- metrics$drop_rate[
      metrics$drop_rate$arm == "difference",
      ,
      drop = FALSE
    ]
    add(
      "strict_window_drop_rate",
      nrow(realised) > 0L && all(realised$ci_high < 0.01),
      if (nrow(realised) == 0L) {
        NA_real_
      } else {
        max(realised$ci_high, na.rm = TRUE)
      },
      0.01,
      "Upper simultaneous bound for the likelihood's strict-window drop rate."
    )
    add(
      "strict_window_drop_increase",
      nrow(difference) > 0L && all(difference$ci_high < 0.01),
      if (nrow(difference) == 0L) {
        NA_real_
      } else {
        max(difference$ci_high, na.rm = TRUE)
      },
      0.01,
      "Upper simultaneous bound for the arm increase in strict-window drops."
    )
  }
  if (nrow(metrics$mass_zero) > 0L) {
    x <- metrics$mass_zero[metrics$mass_zero$arm == "realised" &
                             is.na(metrics$mass_zero$true), , drop = FALSE]
    add(
      "zero_mass_rate",
      nrow(x) > 0L && all(x$ci_high < 0.01),
      if (nrow(x) == 0L) NA_real_ else max(x$ci_high, na.rm = TRUE),
      0.01,
      "Inclusive-window mass diagnostic; upper simultaneous bound."
    )
    low <- metrics$mass_low[metrics$mass_low$arm == "difference" &
                              is.na(metrics$mass_low$true), , drop = FALSE]
    add(
      "low_mass_arm_increase",
      nrow(low) > 0L && all(low$ci_high < 0.01),
      if (nrow(low) == 0L) NA_real_ else max(low$ci_high, na.rm = TRUE),
      0.01,
      "Inclusive-window mass diagnostic; upper simultaneous bound."
    )
  }
  if (length(rows) == 0L) return(data.frame())
  do.call(rbind, rows)
}

summarise_observation_noise_sensitivity <- function(
  checkpoints,
  n_boot = 5000L,
  seed = 1234L,
  strategies = c("r_all", "r_1", "r_3", "r_5"),
  require_complete_scenarios = TRUE
) {
  if (length(n_boot) != 1L || !is.finite(n_boot) || n_boot < 2L || n_boot != as.integer(n_boot)) {
    observation_noise_abort("`n_boot` must be a positive integer of at least two.")
  }
  validated <- validate_observation_noise_summary_inputs(
    checkpoints, strategies = strategies, require_complete_scenarios = require_complete_scenarios
  )
  metrics <- observation_noise_result_metrics(validated, n_boot = as.integer(n_boot), seed = seed)
  gates <- observation_noise_gate_report(metrics)
  required_gates <- c(
    "accuracy_difference_ci", "ose_support_difference_ci", "minimum_aic_discordance",
    "ose_set_discordance",
    "prop1_random3_random5_accuracy", "prop1_r_3_advantage_over_r1",
    "prop1_r_5_advantage_over_r1",
    "prop1_truth_specific_random3_random5_accuracy",
    "prop1_truth_specific_random3_random5_lower",
    "l1_l2_qualitative_consistency",
    "noisy_absolute_mean_bias", "paired_bias_shift", "rmse_relative",
    "boundary_hit_increase", "strict_window_drop_rate",
    "strict_window_drop_increase", "zero_mass_rate", "low_mass_arm_increase"
  )
  gate_pass <- all(required_gates %in% gates$gate) &&
    all(gates$pass[match(required_gates, gates$gate)])
  list(metrics = metrics, gates = gates, validated = validated, gate_pass = gate_pass)
}
