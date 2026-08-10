## Post-unblinding estimand-aligned observation-noise summaries --------------

observation_noise_estimand_aligned_abort <- function(message) {
  if (exists("observation_noise_abort", mode = "function")) {
    observation_noise_abort(message)
  }
  stop(message, call. = FALSE)
}

observation_noise_estimand_aligned_cells <- function(
  metric_rows,
  field,
  metric,
  boundary_only = FALSE
) {
  required <- c(
    "sim", "true", "prop", "strategy", "type", "observation_model", field
  )
  if (!is.data.frame(metric_rows) || !all(required %in% names(metric_rows))) {
    observation_noise_estimand_aligned_abort(
      "Estimand-aligned metric rows are malformed."
    )
  }
  if (nrow(metric_rows) == 0L || any(!is.finite(metric_rows[[field]]))) {
    observation_noise_estimand_aligned_abort(
      "Estimand-aligned metric rows contain no finite values."
    )
  }
  groups <- split(
    metric_rows,
    interaction(
      metric_rows$prop, metric_rows$strategy, metric_rows$type,
      drop = TRUE, lex.order = TRUE
    )
  )
  cells <- list()
  for (group in groups) {
    truths <- sort(unique(as.character(group$true)))
    scopes <- c("pooled", truths)
    if (isTRUE(boundary_only)) scopes <- c("pooled", setdiff(truths, "uni"))
    for (scope in scopes) {
      scoped <- if (scope == "pooled") group else group[group$true == scope, , drop = FALSE]
      if (nrow(scoped) == 0L) {
        observation_noise_estimand_aligned_abort(
          "An estimand-aligned truth scope is missing."
        )
      }
      sims <- sort(unique(scoped$sim))
      values <- vapply(sims, function(sim) {
        curve <- scoped[
          scoped$sim == sim & scoped$observation_model == "curve_mean", field,
          drop = TRUE
        ]
        realised <- scoped[
          scoped$sim == sim & scoped$observation_model == "realised", field,
          drop = TRUE
        ]
        if (length(curve) == 0L || length(realised) == 0L) return(NA_real_)
        mean(as.numeric(realised)) - mean(as.numeric(curve))
      }, numeric(1))
      if (any(!is.finite(values))) {
        observation_noise_estimand_aligned_abort(
          "A paired difference cell is missing an observation arm or replicate."
        )
      }
      cells[[length(cells) + 1L]] <- list(
        metric = metric,
        scope = scope,
        true = if (scope == "pooled") NA_character_ else scope,
        prop = group$prop[[1L]],
        strategy = group$strategy[[1L]],
        type = group$type[[1L]],
        sims = sims,
        values = values
      )
    }
  }
  cells
}

observation_noise_estimand_aligned_bootstrap <- function(
  metric_rows,
  field,
  metric,
  n_boot = 50000L,
  seed = 1234L,
  boundary_only = FALSE,
  one_sided = FALSE
) {
  if (length(n_boot) != 1L || !is.finite(n_boot) || n_boot < 2L ||
      n_boot != as.integer(n_boot) || length(seed) != 1L ||
      !is.finite(seed)) {
    observation_noise_estimand_aligned_abort(
      "`n_boot` and `seed` must be finite scalar integers."
    )
  }
  cells <- observation_noise_estimand_aligned_cells(
    metric_rows, field, metric, boundary_only = boundary_only
  )
  cluster_counts <- vapply(cells, function(cell) length(cell$sims), integer(1))
  if (length(unique(cluster_counts)) != 1L || cluster_counts[[1L]] < 1L) {
    observation_noise_estimand_aligned_abort(
      "Estimand-aligned cells do not share one paired cluster count."
    )
  }
  reference_sims <- cells[[1L]]$sims
  if (!all(vapply(
    cells,
    function(cell) identical(cell$sims, reference_sims),
    logical(1)
  ))) {
    observation_noise_estimand_aligned_abort(
      "Estimand-aligned cells do not share identical ordered simulation identifiers."
    )
  }
  cluster_matrix <- do.call(cbind, lapply(cells, `[[`, "values"))
  estimates <- colMeans(cluster_matrix)
  set.seed(as.integer(seed))
  counts <- stats::rmultinom(
    as.integer(n_boot),
    size = nrow(cluster_matrix),
    prob = rep(1 / nrow(cluster_matrix), nrow(cluster_matrix))
  )
  bootstrap <- crossprod(counts, cluster_matrix) / nrow(cluster_matrix)
  deviations <- sweep(bootstrap, 2L, estimates, FUN = "-")
  margin <- if (isTRUE(one_sided)) {
    stats::quantile(
      apply(pmax(deviations, 0), 1L, max), 0.95, names = FALSE
    )
  } else {
    stats::quantile(
      apply(abs(deviations), 1L, max), 0.95, names = FALSE
    )
  }
  interval <- if (isTRUE(one_sided)) {
    "one_sided_maximum_positive_deviation_upper_95"
  } else {
    "two_sided_max_deviation_95"
  }
  out <- do.call(rbind, lapply(seq_along(cells), function(i) {
    cell <- cells[[i]]
    estimate <- estimates[[i]]
    data.frame(
      metric = cell$metric,
      scope = cell$scope,
      true = cell$true,
      prop = cell$prop,
      strategy = cell$strategy,
      type = cell$type,
      arm = "difference",
      estimate = estimate,
      ci_low = if (isTRUE(one_sided)) NA_real_ else estimate - margin,
      ci_high = estimate + margin,
      margin = margin,
      interval = interval,
      n_clusters = length(cell$sims),
      stringsAsFactors = FALSE
    )
  }))
  rownames(out) <- NULL
  out
}

observation_noise_estimand_aligned_metrics <- function(
  validated,
  n_boot = 50000L,
  master_seed = 1234L
) {
  if (!is.list(validated) || !all(c("results", "pair_manifest") %in% names(validated))) {
    observation_noise_estimand_aligned_abort("Validated checkpoints are malformed.")
  }
  if (!exists("observation_noise_metric_rows", mode = "function")) {
    observation_noise_estimand_aligned_abort(
      "Load R/observation_noise_summaries.R before the estimand-aligned path."
    )
  }
  parameters <- observation_noise_true_parameters()
  rows <- observation_noise_metric_rows(
    validated$results, validated$pair_manifest, parameters
  )
  accuracy <- observation_noise_estimand_aligned_bootstrap(
    rows, "accuracy", "minimum_aic_accuracy", n_boot, master_seed
  )
  ose <- observation_noise_estimand_aligned_bootstrap(
    rows, "ose_unique_true", "unique_ose_support", n_boot, master_seed + 10L
  )
  bias_rows <- validated$results[
    !is.na(validated$results$bias) &
      validated$results$model == validated$results$true,
    ,
    drop = FALSE
  ]
  if (nrow(bias_rows) == 0L) {
    observation_noise_estimand_aligned_abort(
      "Boundary estimand requires generating-model bias rows."
    )
  }
  bias_rows$boundary_hit <- vapply(seq_len(nrow(bias_rows)), function(i) {
    observation_noise_optimizer_boundary_hit(
      as.character(bias_rows$true[[i]]),
      parameters[[as.character(bias_rows$true[[i]])]] + bias_rows$bias[[i]]
    )
  }, logical(1))
  boundary <- observation_noise_estimand_aligned_bootstrap(
    bias_rows,
    "boundary_hit",
    "optimizer_boundary_hit",
    n_boot,
    master_seed + 60L,
    boundary_only = TRUE,
    one_sided = TRUE
  )
  list(accuracy = accuracy, ose = ose, boundary = boundary)
}

observation_noise_estimand_aligned_gate_report <- function(metrics) {
  if (!is.list(metrics) || !all(c("accuracy", "ose", "boundary") %in% names(metrics))) {
    observation_noise_estimand_aligned_abort("Estimand-aligned metrics are incomplete.")
  }
  specifications <- data.frame(
    gate = c("accuracy_difference", "ose_difference", "boundary_difference"),
    threshold_pooled = c(0.03, 0.03, 0.01),
    threshold_truth = c(0.05, 0.05, 0.01),
    stringsAsFactors = FALSE
  )
  rows <- lapply(seq_len(nrow(specifications)), function(i) {
    metric <- metrics[[c("accuracy", "ose", "boundary")[[i]]]]
    pooled <- metric[metric$scope == "pooled", , drop = FALSE]
    truth <- metric[metric$scope != "pooled", , drop = FALSE]
    pooled_max <- if (nrow(pooled) == 0L) NA_real_ else {
      if (i == 3L) max(pooled$ci_high, na.rm = TRUE) else {
        max(abs(c(pooled$ci_low, pooled$ci_high)), na.rm = TRUE)
      }
    }
    truth_max <- if (nrow(truth) == 0L) NA_real_ else {
      if (i == 3L) max(truth$ci_high, na.rm = TRUE) else {
        max(abs(c(truth$ci_low, truth$ci_high)), na.rm = TRUE)
      }
    }
    pooled_margin <- specifications$threshold_pooled[[i]] - pooled_max
    truth_margin <- specifications$threshold_truth[[i]] - truth_max
    pass <- if (i == 3L) {
      is.finite(pooled_margin) && is.finite(truth_margin) &&
        pooled_margin > 0 && truth_margin > 0
    } else {
      is.finite(pooled_margin) && is.finite(truth_margin) &&
        pooled_margin >= 0 && truth_margin >= 0
    }
    data.frame(
      gate = specifications$gate[[i]],
      pass = pass,
      pooled_max = pooled_max,
      truth_max = truth_max,
      threshold_pooled = specifications$threshold_pooled[[i]],
      threshold_truth = specifications$threshold_truth[[i]],
      pooled_margin = pooled_margin,
      truth_margin = truth_margin,
      details = if (i == 3L) {
        "One-sided upper bound on maximum positive boundary difference."
      } else {
        "Two-sided max-deviation interval on paired difference estimands only."
      },
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

observation_noise_estimand_aligned_summary <- function(
  validated,
  n_boot = 50000L,
  master_seed = 1234L,
  stability_seed = 5678L
) {
  primary <- observation_noise_estimand_aligned_metrics(
    validated, n_boot = n_boot, master_seed = master_seed
  )
  stability <- observation_noise_estimand_aligned_metrics(
    validated, n_boot = n_boot, master_seed = stability_seed
  )
  primary_gates <- observation_noise_estimand_aligned_gate_report(primary)
  stability_gates <- observation_noise_estimand_aligned_gate_report(stability)
  critical_width <- function(metric) max(metric$margin, na.rm = TRUE)
  stability_status <- data.frame(
    gate = primary_gates$gate,
    primary_pass = primary_gates$pass,
    stability_pass = stability_gates$pass,
    status = ifelse(primary_gates$pass == stability_gates$pass, "AGREE", "DISAGREE"),
    primary_width = vapply(primary, critical_width, numeric(1)),
    stability_width = vapply(stability, critical_width, numeric(1)),
    primary_pooled_max = primary_gates$pooled_max,
    stability_pooled_max = stability_gates$pooled_max,
    primary_truth_max = primary_gates$truth_max,
    stability_truth_max = stability_gates$truth_max,
    primary_pooled_margin = primary_gates$pooled_margin,
    stability_pooled_margin = stability_gates$pooled_margin,
    primary_truth_margin = primary_gates$truth_margin,
    stability_truth_margin = stability_gates$truth_margin,
    stringsAsFactors = FALSE
  )
  list(
    metrics = primary,
    gates = primary_gates,
    stability_metrics = stability,
    stability_gates = stability_gates,
    stability = stability_status,
    gate_pass = all(primary_gates$pass),
    stability_agree = all(stability_status$status == "AGREE")
  )
}
