#!/usr/bin/env Rscript
# Stage 6 signal-strength figure (docs/STAGE6_EFFECT_SIZE.md, "Planned display" and its display
# amendment). Writes the manuscript figure (correct state above zero, reversal below zero) and the
# prespecified correct-state-only display as an audit record in the summary directory.
# Usage: Rscript --vanilla scripts/render_stage6_effect_size_figure.R [summary_dir] [figure_stem]

args <- commandArgs(trailingOnly = TRUE)
summary_dir <- if (length(args) >= 1L) args[[1L]] else file.path("out", "revision", "effect-size-20261018")
figure_stem <- if (length(args) >= 2L) args[[2L]] else file.path("manuscript", "figures", "fig_effect_size")
prespecified_stem <- file.path(summary_dir, "fig_effect_size_prespecified")

dose <- utils::read.csv(file.path(summary_dir, "stage6_dose_response.csv"), stringsAsFactors = FALSE)
dose <- dose[dose$role %in% c("adverse", "bracketed", "random-1"), ]
dose <- unique(dose[c("family", "direction", "role", "ratio", "prop", "correct_state_rate",
                      "reversal_rate", "replicates")])
stopifnot(all(dose$replicates[dose$ratio %in% c(1, 10)] == 1000L),
          all(dose$replicates[!dose$ratio %in% c(1, 10)] == 500L))

dose$family_label <- factor(dose$family, levels = c("lin", "exp"),
                            labels = c("Linear histories", "Exponential histories"))
dose$role_label <- factor(
  dose$role,
  levels = c("adverse", "bracketed", "random-1"),
  labels = c("Opposing extreme kept", "Oldest and youngest kept", "One random date kept")
)
dose$prop_label <- factor(dose$prop, levels = c(0.5, 0.75, 1),
                          labels = c("50% of sites", "75% of sites", "100% of sites"))
dose$direction_label <- factor(dose$direction, levels = c("increase", "decrease"),
                               labels = c("Increase towards present", "Decrease towards present"))

ratio_breaks <- c(1, 1.5, 2, 3, 5, 10)
ratio_labels <- c("1\n(constant)", "1.5", "2", "3", "5", "10")
x_label <- "True end-to-end density ratio over 651–11,650 cal BP (log scale)"

rate_plot <- function(data) {
  ggplot2::ggplot(
    data,
    ggplot2::aes(x = ratio, y = value, colour = prop_label, linetype = direction_label,
                 shape = direction_label, group = series)
  ) +
    ggplot2::geom_vline(xintercept = sqrt(1.5), colour = "grey85", linewidth = 0.3, linetype = "dotted") +
    ggplot2::geom_line(data = data[data$ratio > 1, ], linewidth = 0.55) +
    ggplot2::geom_point(size = 1.7, fill = "white", stroke = 0.6) +
    ggplot2::facet_grid(rows = ggplot2::vars(family_label), cols = ggplot2::vars(role_label)) +
    ggplot2::scale_x_log10(breaks = ratio_breaks, labels = ratio_labels) +
    ggplot2::scale_colour_viridis_d(option = "C", end = 0.8, name = "Rule applied to") +
    ggplot2::scale_linetype_manual(values = c("solid", "22"), name = "True history") +
    ggplot2::scale_shape_manual(values = c(21, 24), name = "True history") +
    ggplot2::theme_classic(base_size = 10) +
    ggplot2::theme(
      legend.position = "bottom",
      legend.box = "vertical",
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "plain", size = 9),
      panel.spacing = grid::unit(10, "pt"),
      plot.caption = ggplot2::element_text(hjust = 0)
    )
}

# Manuscript display: correct state above zero, reversed direction below zero -----------------
outcomes <- rbind(
  transform(dose, outcome = "correct", value = correct_state_rate),
  transform(dose[dose$ratio > 1, ], outcome = "reversed", value = -reversal_rate)
)
outcomes$series <- interaction(outcomes$prop_label, outcomes$direction_label, outcomes$outcome)
manuscript_plot <- rate_plot(outcomes) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey55", linewidth = 0.35) +
  ggplot2::scale_y_continuous(limits = c(-1, 1), breaks = c(-1, -0.5, 0, 0.5, 1),
                              labels = c("100%", "50%", "0", "50%", "100%")) +
  ggplot2::labs(
    x = x_label,
    y = "Replicates: reversed direction (below zero) or true state (above zero)",
    caption = paste("Opposing extreme: oldest date for increasing histories, youngest for decreasing.",
                    "Above zero: AIC favours the correct direction,\nor uniform for the constant history",
                    "(ratio 1, unconnected). Below zero: AIC favours the opposite direction; the remainder",
                    "favours uniform.\nRatios 1.5–5: 500 replicates; ratios 1 and 10: 1,000.")
  )

# Prespecified display, kept as the audit record ---------------------------------------------
prespecified <- transform(dose, value = correct_state_rate)
prespecified$series <- interaction(prespecified$prop_label, prespecified$direction_label)
prespecified_plot <- rate_plot(prespecified) +
  ggplot2::geom_hline(yintercept = c(0, 1), colour = "grey85", linewidth = 0.3) +
  ggplot2::scale_y_continuous(limits = c(0, 1), breaks = c(0, 0.25, 0.5, 0.75, 1),
                              labels = function(x) paste0(round(100 * x), "%")) +
  ggplot2::labs(
    x = x_label,
    y = "Replicates in which AIC favours the true state",
    caption = paste("Opposing extreme: oldest date for increasing histories, youngest for decreasing.",
                    "True state: uniform for the constant history\n(ratio 1, unconnected), otherwise the correct",
                    "direction of change. Ratios 1.5–5: 500 replicates per point (Stage 6).\n",
                    "Ratios 1 and 10: 1,000 replicates per point (accepted evidence).")
  )

dir.create(dirname(figure_stem), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(paste0(figure_stem, ".pdf"), manuscript_plot, width = 7.4, height = 6.6,
                device = grDevices::cairo_pdf)
ggplot2::ggsave(paste0(figure_stem, ".png"), manuscript_plot, width = 7.4, height = 6.6, dpi = 300)
ggplot2::ggsave(paste0(prespecified_stem, ".pdf"), prespecified_plot, width = 7.4, height = 5.6,
                device = grDevices::cairo_pdf)
ggplot2::ggsave(paste0(prespecified_stem, ".png"), prespecified_plot, width = 7.4, height = 5.6, dpi = 300)
message("Wrote ", figure_stem, " and ", prespecified_stem, " (.pdf and .png)")
