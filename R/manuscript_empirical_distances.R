## Empirical curve distances and claim gates -------------------------------

summarise_manuscript_values <- function(
  values,
  comparison,
  strategy_label,
  proportion,
  method = NA_character_,
  method_pair = NA_character_
) {
  values <- as.numeric(values)
  if (length(values) < 1L || any(!is.finite(values))) {
    rlang::abort(
      "Empirical comparison contains invalid values.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  interval <- stats::quantile(values, c(0.025, 0.975), names = FALSE)
  data.frame(
    strategy_label = strategy_label,
    proportion = as.numeric(proportion),
    comparison = comparison,
    method = method,
    method_pair = method_pair,
    iterations = length(values),
    mean = mean(values),
    median = stats::median(values),
    q025 = interval[[1L]],
    q975 = interval[[2L]],
    min = min(values),
    max = max(values),
    stringsAsFactors = FALSE
  )
}

manuscript_total_variation <- function(curves, reference) {
  curves <- as.matrix(curves)
  reference <- as.matrix(reference)
  if (nrow(curves) != nrow(reference) || ncol(reference) != 1L ||
      any(!is.finite(curves)) || any(!is.finite(reference))) {
    rlang::abort(
      "Total-variation inputs are invalid or misaligned.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  values <- 0.5 * colSums(abs(sweep(curves, 1L, reference[, 1L], FUN = "-")))
  if (any(values < -1e-12 | values > 1 + 1e-12)) {
    rlang::abort(
      "Total-variation distance is outside [0, 1].",
      class = "rcdates_manuscript_figure_error"
    )
  }
  pmin(1, pmax(0, values))
}

manuscript_between_curve_total_variation <- function(first, second) {
  first <- as.matrix(first)
  second <- as.matrix(second)
  if (!identical(dim(first), dim(second)) ||
      any(!is.finite(first)) || any(!is.finite(second))) {
    rlang::abort(
      "Between-method curves are invalid or misaligned.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  values <- 0.5 * colSums(abs(first - second))
  if (any(values < -1e-12 | values > 1 + 1e-12)) {
    rlang::abort(
      "Between-method total variation is outside [0, 1].",
      class = "rcdates_manuscript_figure_error"
    )
  }
  pmin(1, pmax(0, values))
}

manuscript_mean_calBP_shift <- function(curves, reference, midpoints) {
  curves <- as.matrix(curves)
  reference <- as.matrix(reference)
  midpoints <- as.numeric(midpoints)
  if (nrow(curves) != length(midpoints) || nrow(reference) != length(midpoints) ||
      ncol(reference) != 1L || any(!is.finite(midpoints))) {
    rlang::abort(
      "Mean-cal-BP shift inputs are invalid or misaligned.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  as.numeric(crossprod(midpoints, curves)) -
    as.numeric(crossprod(midpoints, reference[, 1L, drop = FALSE]))
}

summarise_manuscript_scenario_distances <- function(
  curves,
  baseline,
  midpoints,
  strategy_label,
  proportion
) {
  methods <- c("SPD", "FD", "KDE")
  if (!identical(sort(names(curves)), sort(methods)) ||
      !identical(sort(names(baseline)), sort(methods))) {
    rlang::abort(
      "Scenario curves lack the three prespecified methods.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  retention <- lapply(methods, function(method) {
    manuscript_total_variation(curves[[method]], baseline[[method]])
  })
  names(retention) <- methods
  shifts <- lapply(methods, function(method) {
    manuscript_mean_calBP_shift(curves[[method]], baseline[[method]], midpoints)
  })
  names(shifts) <- methods
  method_pairs <- list(c("SPD", "FD"), c("SPD", "KDE"), c("FD", "KDE"))
  between <- lapply(method_pairs, function(pair) {
    manuscript_between_curve_total_variation(curves[[pair[[1L]]]], curves[[pair[[2L]]]])
  })
  names(between) <- vapply(
    method_pairs,
    function(pair) paste(pair, collapse = "-"),
    character(1)
  )
  conservative <- do.call(pmin, retention) - do.call(pmax, between)

  summaries <- c(
    lapply(methods, function(method) {
      summarise_manuscript_values(
        retention[[method]], "retention_vs_all", strategy_label, proportion,
        method = method
      )
    }),
    lapply(names(between), function(pair) {
      summarise_manuscript_values(
        between[[pair]], "between_methods", strategy_label, proportion,
        method_pair = pair
      )
    }),
    list(summarise_manuscript_values(
      conservative,
      "minimum_retention_minus_maximum_method",
      strategy_label,
      proportion
    )),
    lapply(methods, function(method) {
      summarise_manuscript_values(
        shifts[[method]], "mean_calBP_shift_vs_all", strategy_label, proportion,
        method = method
      )
    })
  )
  summary <- do.call(rbind, summaries)
  contrast_summary <- summary[
    summary$comparison == "minimum_retention_minus_maximum_method",
    ,
    drop = FALSE
  ]
  shift_summary <- summary[
    summary$comparison == "mean_calBP_shift_vs_all",
    ,
    drop = FALSE
  ]
  direction <- if (all(shift_summary$q025 > 0)) {
    "older"
  } else if (all(shift_summary$q975 < 0)) {
    "younger"
  } else {
    "not-unambiguous"
  }
  gate <- data.frame(
    strategy_label = strategy_label,
    proportion = as.numeric(proportion),
    iterations = length(conservative),
    conservative_contrast_q025 = contrast_summary$q025,
    conservative_contrast_q975 = contrast_summary$q975,
    retention_larger_than_method = contrast_summary$q025 > 0,
    temporal_direction = direction,
    stringsAsFactors = FALSE
  )
  list(summary = summary, gate = gate)
}
