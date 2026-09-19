## Accepted signed-model manuscript figures --------------------------------

manuscript_signed_truth_labels <- function() {
  c(
    uni = "uniform",
    lin_inc = "linear increase",
    exp_inc = "exponential increase",
    lin_dec = "linear decrease",
    exp_dec = "exponential decrease"
  )
}

manuscript_signed_strategy_labels <- function() {
  c(
    r_all = "all dates",
    r_1 = "random-1",
    r_2 = "random-2",
    r_3 = "random-3",
    r_5 = "random-5",
    r_bracket = "bracketed",
    r_old = "oldest",
    r_young = "youngest"
  )
}

#' Prepare the five frozen signed generating densities for Supplementary Figure S1
#' @param low Young analysis-window boundary in cal BP.
#' @param up Old analysis-window boundary in cal BP.
#' @param ratio End-to-end density ratio for non-uniform truths.
#' @param points Number of calendar-age points per truth.
#' @return Long data frame of the five unit-integral generating densities.
prepare_manuscript_signed_truth_curves <- function(
  low = 651,
  up = 11650,
  ratio = 10,
  points = 1001L
) {
  if (length(points) != 1L || !is.finite(points) || points < 2L ||
      points != as.integer(points)) {
    rlang::abort(
      "Signed truth curves require at least two calendar-age points.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  ages <- seq(low, up, length.out = as.integer(points))
  truths <- names(manuscript_signed_truth_labels())
  curves <- do.call(rbind, lapply(truths, function(truth) {
    specification <- population_truth_specification(truth, ratio, low, up)
    density <- switch(
      specification$family,
      uni = rep(1 / (up - low), length(ages)),
      lin = dtlin(ages, specification$parameter, low, up),
      exp = dtexp(ages, specification$parameter, low, up)
    )
    data.frame(
      truth = truth,
      cal_bp = ages,
      density = density,
      stringsAsFactors = FALSE
    )
  }))
  labels <- manuscript_signed_truth_labels()
  curves$truth_label <- factor(
    curves$truth,
    levels = names(labels),
    labels = unname(labels)
  )
  rownames(curves) <- NULL
  curves
}

assert_manuscript_signed_grid <- function(data, context) {
  truths <- names(manuscript_signed_truth_labels())
  strategies <- names(manuscript_signed_strategy_labels())
  proportions <- c(0.5, 0.75, 1)
  expected <- expand.grid(
    true = truths,
    prop = proportions,
    strategy = strategies,
    stringsAsFactors = FALSE
  )
  key <- function(x) paste(x$true, x$prop, x$strategy, sep = "|")
  if (nrow(data) != nrow(expected) || anyDuplicated(key(data)) ||
      !setequal(key(data), key(expected))) {
    rlang::abort(
      paste0(context, " does not contain the complete 5 x 3 x 8 Stage 2 grid."),
      class = "rcdates_manuscript_figure_error"
    )
  }
  invisible(data)
}

#' Prepare accepted Stage 2 selection summaries for Figures 3 and 5
#' @param performance Parsed `selection_performance.csv` table.
#' @param type Primary score identifier.
#' @return Validated and labelled 120-row primary summary.
prepare_manuscript_signed_performance <- function(performance, type = "l1") {
  required <- c(
    "type", "true", "true_family", "true_direction", "true_log_ratio",
    "prop", "strategy", "n", "family_selection_rate",
    "direction_selection_rate", "direction_reversal_rate",
    "mean_selected_log_ratio", "selected_boundary_rate"
  )
  if (!is.data.frame(performance) || !all(required %in% names(performance))) {
    rlang::abort(
      "The signed-model selection summary lacks required columns.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  out <- performance[performance$type == type, required, drop = FALSE]
  numeric_columns <- setdiff(required, c(
    "type", "true", "true_family", "true_direction", "strategy"
  ))
  if (nrow(out) == 0L || any(!is.finite(unlist(out[numeric_columns], use.names = FALSE))) ||
      any(out$n != 1000L)) {
    rlang::abort(
      "The signed-model selection summary is incomplete or non-finite.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  rate_columns <- c(
    "family_selection_rate", "direction_selection_rate",
    "direction_reversal_rate", "selected_boundary_rate"
  )
  if (any(unlist(out[rate_columns], use.names = FALSE) < 0 |
      unlist(out[rate_columns], use.names = FALSE) > 1)) {
    rlang::abort(
      "Signed-model rates must lie inside [0, 1].",
      class = "rcdates_manuscript_figure_error"
    )
  }
  assert_manuscript_signed_grid(out, "The signed-model selection summary")

  all_dates <- out[out$strategy == "r_all", , drop = FALSE]
  stable_fields <- c(
    "family_selection_rate", "direction_selection_rate",
    "direction_reversal_rate", "mean_selected_log_ratio", "selected_boundary_rate"
  )
  stable <- vapply(split(all_dates, all_dates$true), function(rows) {
    all(vapply(rows[stable_fields], function(x) length(unique(x)) == 1L, logical(1)))
  }, logical(1))
  if (!all(stable)) {
    rlang::abort(
      "All-dates signed-model references differ across site-treatment files.",
      class = "rcdates_manuscript_figure_error"
    )
  }

  truth_labels <- manuscript_signed_truth_labels()
  strategy_labels <- manuscript_signed_strategy_labels()
  out$truth_label <- factor(
    out$true,
    levels = names(truth_labels),
    labels = unname(truth_labels)
  )
  out$strategy_label <- factor(
    out$strategy,
    levels = names(strategy_labels),
    labels = unname(strategy_labels)
  )
  out$prop_label <- factor(
    out$prop,
    levels = c(0.5, 0.75, 1),
    labels = c("50% of sites", "75% of sites", "100% of sites")
  )
  out$state_rate <- out$direction_selection_rate
  out$family_rate <- out$family_selection_rate
  out
}

#' Convert an endpoint log-density ratio to a bounded contrast.
#'
#' The transformation is applied to each stored fitted replicate before any
#' summary is calculated. Infinite boundary estimates therefore map to -1/+1.
endpoint_contrast_from_log_ratio <- function(log_ratio) {
  if (anyNA(log_ratio)) {
    rlang::abort(
      "Endpoint log-density ratios must not contain missing values.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  tanh(log_ratio / 2)
}

#' Prepare bounded endpoint contrasts for manuscript Figure 4.
#' @param results Parsed full-treatment signed-model result rows.
#' @param type Primary score identifier.
#' @param proportion Site-treatment proportion shown in the figure.
#' @param nsim Expected number of fitted replicates per cell.
#' @return Validated and labelled 32-row bounded-effect summary.
prepare_manuscript_endpoint_contrast_panel <- function(
  results,
  type = "l1",
  proportion = 1,
  nsim = 1000L
) {
  required <- c(
    "sim", "true", "true_family", "true_direction", "true_log_ratio",
    "prop", "strategy", "type", "model", "estimate_log_ratio", "boundary"
  )
  if (!is.data.frame(results) || !all(required %in% names(results))) {
    rlang::abort(
      "The signed-model fitted results lack required columns.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  if (length(type) != 1L || is.na(type) || length(proportion) != 1L ||
      !is.finite(proportion) || length(nsim) != 1L || !is.finite(nsim) ||
      nsim < 1L || nsim != as.integer(nsim)) {
    rlang::abort(
      "Invalid endpoint-contrast panel settings.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  keep <- results$type == type &
    abs(results$prop - proportion) < sqrt(.Machine$double.eps) &
    results$true != "uni" & results$model == results$true_family
  source_file <- if ("source_file" %in% names(results)) {
    as.character(results$source_file)
  } else {
    rep(NA_character_, nrow(results))
  }
  selected <- results[keep, required, drop = FALSE]
  selected$source_file <- source_file[keep]
  expected_truths <- setdiff(names(manuscript_signed_truth_labels()), "uni")
  expected <- expand.grid(
    true = expected_truths,
    strategy = names(manuscript_signed_strategy_labels()),
    stringsAsFactors = FALSE
  )
  key <- function(x) paste(x$true, x$strategy, sep = "|")
  cell_id <- interaction(selected$true, selected$strategy, selected$sim, drop = TRUE)
  if (nrow(selected) != 32L * as.integer(nsim) ||
      anyDuplicated(cell_id) ||
      !setequal(unique(key(selected)), key(expected)) ||
      !is.numeric(selected$sim) || any(!is.finite(selected$sim)) ||
      any(selected$sim != as.integer(selected$sim)) ||
      !is.numeric(selected$true_log_ratio) ||
      any(!is.finite(selected$true_log_ratio)) ||
      !is.numeric(selected$estimate_log_ratio) ||
      any(is.na(selected$estimate_log_ratio)) ||
      any(is.nan(selected$estimate_log_ratio)) ||
      !is.logical(selected$boundary) || anyNA(selected$boundary)) {
    rlang::abort(
      "The signed-model fitted results are incomplete or invalid.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  cell_rows <- split(selected, interaction(selected$true, selected$strategy, drop = TRUE))
  complete_ids <- vapply(cell_rows, function(rows) {
    identical(sort(unique(as.integer(rows$sim))), seq_len(as.integer(nsim)))
  }, logical(1))
  if (!all(complete_ids)) {
    rlang::abort(
      "Each endpoint-contrast cell must contain exactly one row for every replicate.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  out <- do.call(rbind, lapply(cell_rows, function(rows) {
    contrasts <- endpoint_contrast_from_log_ratio(rows$estimate_log_ratio)
    true_values <- unique(rows$true_log_ratio)
    if (length(true_values) != 1L) {
      rlang::abort(
        "Each endpoint-contrast cell must have one generating truth value.",
        class = "rcdates_manuscript_figure_error"
      )
    }
    data.frame(
      true = rows$true[[1L]],
      type = rows$type[[1L]],
      prop = rows$prop[[1L]],
      strategy = rows$strategy[[1L]],
      n = nrow(rows),
      mean_contrast = mean(contrasts),
      contrast_q025 = stats::quantile(contrasts, 0.025, type = 7, names = FALSE),
      contrast_q975 = stats::quantile(contrasts, 0.975, type = 7, names = FALSE),
      true_contrast = endpoint_contrast_from_log_ratio(true_values),
      boundary_n = sum(rows$boundary),
      boundary_rate = mean(rows$boundary),
      source_file = paste(unique(rows$source_file), collapse = ";"),
      stringsAsFactors = FALSE
    )
  }))
  rownames(out) <- NULL
  if (nrow(out) != nrow(expected) || anyDuplicated(key(out)) ||
      !setequal(key(out), key(expected)) || any(out$n != as.integer(nsim)) ||
      any(out$boundary_rate < 0 | out$boundary_rate > 1)) {
    rlang::abort(
      "The endpoint-contrast summary is incomplete or invalid.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  truth_labels <- manuscript_signed_truth_labels()[expected_truths]
  strategy_labels <- manuscript_signed_strategy_labels()
  out$truth_label <- factor(
    out$true,
    levels = names(truth_labels),
    labels = unname(truth_labels)
  )
  out$strategy_label <- factor(
    out$strategy,
    levels = rev(names(strategy_labels)),
    labels = rev(unname(strategy_labels))
  )
  out$boundary_any <- out$boundary_n > 0L
  out$boundary_label <- sprintf("%.1f%%", 100 * out$boundary_rate)
  out
}

manuscript_signed_heatmap <- function(data, rate, fill_label) {
  data$plot_rate <- data[[rate]]
  data$cell_label <- sprintf("%.0f", 100 * data$plot_rate)
  data$label_colour <- ifelse(data$plot_rate < 0.28, "white", "black")
  ggplot2::ggplot(
    data,
    ggplot2::aes(x = strategy_label, y = truth_label, fill = plot_rate)
  ) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.35) +
    ggplot2::geom_text(
      ggplot2::aes(label = cell_label, colour = label_colour),
      size = 3.1,
      show.legend = FALSE
    ) +
    ggplot2::facet_grid(cols = ggplot2::vars(prop_label)) +
    ggplot2::scale_fill_viridis_c(
      option = "C",
      limits = c(0, 1),
      breaks = c(0, 0.5, 1),
      labels = scales::label_percent(accuracy = 1),
      name = fill_label
    ) +
    ggplot2::scale_colour_identity() +
    ggplot2::labs(
      x = "Post hoc date-retention rule",
      y = "Generating truth",
      caption = "Cell labels are percentages; n = 1,000 replicates per cell."
    ) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      legend.position = "bottom",
      panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 9.5),
      axis.text.y = ggplot2::element_text(size = 9.5),
      strip.text = ggplot2::element_text(face = "plain", size = 10),
      plot.caption = ggplot2::element_text(hjust = 0)
    )
}

#' Plot truth-consistent signed-state selection for Figure 3
#' @param data Output of [prepare_manuscript_signed_performance()].
#' @return ggplot object.
manuscript_signed_state_plot <- function(data) {
  manuscript_signed_heatmap(
    data,
    rate = "state_rate",
    fill_label = "Truth-consistent\nstate selection"
  )
}

#' Plot bounded endpoint contrasts for Figure 4
#' @param data Output of [prepare_manuscript_endpoint_contrast_panel()].
#' @return ggplot object.
manuscript_endpoint_contrast_plot <- function(data) {
  references <- unique(data[c("truth_label", "true_contrast")])
  ggplot2::ggplot(
    data,
    ggplot2::aes(y = strategy_label, x = mean_contrast)
  ) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey65", linewidth = 0.35) +
    ggplot2::geom_vline(
      data = references,
      ggplot2::aes(xintercept = true_contrast),
      linetype = "dashed",
      linewidth = 0.45,
      inherit.aes = FALSE
    ) +
    ggplot2::geom_errorbar(
      ggplot2::aes(xmin = contrast_q025, xmax = contrast_q975),
      width = 0.16,
      orientation = "y",
      linewidth = 0.4
    ) +
    ggplot2::geom_point(
      ggplot2::aes(shape = boundary_any),
      size = 2.25,
      fill = "white",
      stroke = 0.65
    ) +
    ggplot2::geom_text(
      ggplot2::aes(x = Inf, label = boundary_label),
      hjust = -0.1,
      size = 3,
      colour = "grey25"
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(truth_label),
      ncol = 2,
      scales = "fixed"
    ) +
    ggplot2::scale_shape_manual(
      values = c(`FALSE` = 21, `TRUE` = 24),
      labels = c("none", "at least one"),
      name = "Near original parameter\nbound flag"
    ) +
    ggplot2::scale_x_continuous(
      limits = c(-1, 1),
      breaks = c(-1, -0.5, 0, 0.5, 1)
    ) +
    ggplot2::labs(
      x = "Normalised endpoint-density contrast, c",
      y = "Post hoc date-retention rule",
      caption = paste(
        "Percentages: near original parameter bound.",
        "Triangles indicate at least one stored flag, not an exact endpoint.",
        sep = "\n"
      )
    ) +
    ggplot2::theme_classic(base_size = 11) +
    ggplot2::theme(
      legend.position = "bottom",
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "plain"),
      panel.spacing.x = grid::unit(45, "pt"),
      plot.margin = ggplot2::margin(5.5, 40, 5.5, 5.5),
      plot.caption = ggplot2::element_text(hjust = 0)
    ) +
    ggplot2::coord_cartesian(xlim = c(-1, 1), clip = "off")
}

#' Plot minimum-AIC generating-family selection for Figure 5
#' @param data Output of [prepare_manuscript_signed_performance()].
#' @return ggplot object.
manuscript_family_selection_plot <- function(data) {
  manuscript_signed_heatmap(
    data,
    rate = "family_rate",
    fill_label = "Generating-family\nselection"
  )
}

#' Plot the signed data-generating densities for Supplementary Figure S1
#' @param data Output of [prepare_manuscript_signed_truth_curves()].
#' @return ggplot object.
manuscript_signed_truth_plot <- function(data) {
  ggplot2::ggplot(
    data,
    ggplot2::aes(
      x = cal_bp,
      y = density,
      colour = truth_label,
      linetype = truth_label
    )
  ) +
    ggplot2::geom_line(linewidth = 0.75) +
    ggplot2::scale_x_reverse(
      limits = c(11650, 651),
      breaks = c(11000, 9000, 7000, 5000, 3000, 1000)
    ) +
    ggplot2::scale_colour_manual(
      values = c("black", "#0072B2", "#D55E00", "#56B4E9", "#E69F00")
    ) +
    ggplot2::scale_linetype_manual(
      values = c("solid", "solid", "solid", "22", "22")
    ) +
    ggplot2::labs(
      x = "Calendar age (cal BP)",
      y = "Unit-normalised density",
      colour = NULL,
      linetype = NULL
    ) +
    ggplot2::theme_classic(base_size = 10) +
    ggplot2::theme(
      legend.position = "bottom"
    )
}
