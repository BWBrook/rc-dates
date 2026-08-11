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

#' Prepare common-scale fitted effects for manuscript Figure 4
#' @param bias Parsed `log_ratio_bias.csv` table.
#' @param type Primary score identifier.
#' @param proportion Site-treatment proportion shown in the figure.
#' @return Validated and labelled 32-row effect summary.
prepare_manuscript_theta_panel <- function(bias, type = "l1", proportion = 1) {
  required <- c(
    "type", "true", "true_family", "true_direction", "true_log_ratio",
    "prop", "strategy", "n", "mean_estimate_log_ratio", "mean_bias_log_ratio",
    "bias_q025", "bias_q975", "boundary_rate"
  )
  if (!is.data.frame(bias) || !all(required %in% names(bias))) {
    rlang::abort(
      "The signed-model effect summary lacks required columns.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  out <- bias[
    bias$type == type & bias$prop == proportion & bias$true != "uni",
    required,
    drop = FALSE
  ]
  expected_truths <- setdiff(names(manuscript_signed_truth_labels()), "uni")
  expected <- expand.grid(
    true = expected_truths,
    strategy = names(manuscript_signed_strategy_labels()),
    stringsAsFactors = FALSE
  )
  key <- function(x) paste(x$true, x$strategy, sep = "|")
  numeric_columns <- setdiff(required, c(
    "type", "true", "true_family", "true_direction", "strategy"
  ))
  if (nrow(out) != 32L || anyDuplicated(key(out)) ||
      !setequal(key(out), key(expected)) ||
      any(!is.finite(unlist(out[numeric_columns], use.names = FALSE))) ||
      any(out$n != 1000L) || any(out$boundary_rate < 0 | out$boundary_rate > 1)) {
    rlang::abort(
      "The signed-model effect summary is incomplete or invalid.",
      class = "rcdates_manuscript_figure_error"
    )
  }
  out$estimate_low <- out$true_log_ratio + out$bias_q025
  out$estimate_high <- out$true_log_ratio + out$bias_q975
  tolerance <- 1e-12
  if (any(out$estimate_low - tolerance > out$mean_estimate_log_ratio) ||
      any(out$estimate_high + tolerance < out$mean_estimate_log_ratio)) {
    rlang::abort(
      "The signed-model effect ranges do not contain their means.",
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
  out$boundary_saturated <- out$boundary_rate >= 0.5
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
      size = 2.55,
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
    ggplot2::theme_minimal(base_size = 9) +
    ggplot2::theme(
      legend.position = "bottom",
      panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      strip.text = ggplot2::element_text(face = "plain"),
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

#' Plot common-scale fitted effects for Figure 4
#' @param data Output of [prepare_manuscript_theta_panel()].
#' @return ggplot object.
manuscript_theta_plot <- function(data) {
  references <- unique(data[c("truth_label", "true_log_ratio")])
  ggplot2::ggplot(
    data,
    ggplot2::aes(y = strategy_label, x = mean_estimate_log_ratio)
  ) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey65", linewidth = 0.35) +
    ggplot2::geom_vline(
      data = references,
      ggplot2::aes(xintercept = true_log_ratio),
      linetype = "dashed",
      linewidth = 0.45,
      inherit.aes = FALSE
    ) +
    ggplot2::geom_errorbar(
      ggplot2::aes(xmin = estimate_low, xmax = estimate_high),
      width = 0.16,
      orientation = "y",
      linewidth = 0.4
    ) +
    ggplot2::geom_point(
      ggplot2::aes(shape = boundary_saturated),
      size = 2.25,
      fill = "white",
      stroke = 0.65
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(truth_label),
      ncol = 2,
      scales = "fixed"
    ) +
    ggplot2::scale_shape_manual(
      values = c(`FALSE` = 21, `TRUE` = 24),
      labels = c("no", "yes"),
      name = "At least 50% of\nestimates at bound"
    ) +
    ggplot2::scale_x_continuous(
      limits = c(-11.5, 11.5),
      breaks = c(-10, -5, 0, 5, 10)
    ) +
    ggplot2::labs(
      x = expression("Fitted generating-family effect " * theta),
      y = "Post hoc date-retention rule"
    ) +
    ggplot2::theme_classic(base_size = 9) +
    ggplot2::theme(
      legend.position = "bottom",
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "plain")
    )
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
