#!/usr/bin/env Rscript

# Reproduce accepted empirical manuscript Figures 1 and 2 from aggregate,
# source-controlled evidence. This renderer deliberately does not read the
# archaeological record or rerun calibration, sampling, or Monte Carlo work.

parse_arguments <- function(args) {
  settings <- list(
    input_dir = file.path("out", "empirical-sampling"),
    output_dir = file.path("out", "reproduced", "figures")
  )
  key_map <- c(`input-dir` = "input_dir", `output-dir` = "output_dir")
  for (argument in args) {
    parts <- regmatches(argument, regexec("^--([^=]+)=(.*)$", argument))[[1L]]
    if (length(parts) != 3L || !parts[[2L]] %in% names(key_map)) {
      stop("Unknown or malformed argument: ", argument, call. = FALSE)
    }
    settings[[key_map[[parts[[2L]]]]]] <- parts[[3L]]
  }
  for (field in names(settings)) {
    if (length(settings[[field]]) != 1L || !nzchar(settings[[field]])) {
      stop("Invalid directory for ", field, call. = FALSE)
    }
  }
  settings
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 1L && args[[1L]] %in% c("--help", "-h")) {
  writeLines(c(
    "Reproduce accepted empirical Figures 1 and 2 from aggregate evidence.",
    "",
    "Optional:",
    "  --input-dir=out/empirical-sampling",
    "  --output-dir=out/reproduced/figures"
  ))
  quit(status = 0L)
}

if (!identical(as.character(getRversion()), "4.5.3")) {
  stop(
    "Release figures must be rendered under R 4.5.3; found ",
    R.version.string,
    ".",
    call. = FALSE
  )
}
required_packages <- c("ggplot2", "scales")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop("Missing figure packages: ", paste(missing_packages, collapse = ", "))
}

settings <- parse_arguments(args)
input_files <- c(
  baseline = file.path(settings$input_dir, "figure1_baseline_curves.csv"),
  differences = file.path(settings$input_dir, "figure2_sampling_differences.csv")
)
missing_files <- input_files[!file.exists(input_files)]
if (length(missing_files) > 0L) {
  stop(
    "Missing aggregate empirical evidence: ",
    paste(missing_files, collapse = ", "),
    call. = FALSE
  )
}

read_evidence <- function(path, required_columns) {
  data <- utils::read.csv(
    path,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  missing_columns <- setdiff(required_columns, names(data))
  if (length(missing_columns) > 0L || nrow(data) == 0L) {
    stop("Evidence file has an invalid schema: ", path, call. = FALSE)
  }
  numeric_columns <- intersect(
    c("calBP", "mean", "lower", "upper", "proportion", "iterations"),
    names(data)
  )
  for (column in numeric_columns) data[[column]] <- as.numeric(data[[column]])
  if (any(!is.finite(as.matrix(data[numeric_columns])))) {
    stop("Evidence file contains non-finite numeric values: ", path, call. = FALSE)
  }
  data
}

baseline <- read_evidence(
  input_files[["baseline"]],
  c("method", "calBP", "mean", "lower", "upper")
)
differences <- read_evidence(
  input_files[["differences"]],
  c(
    "method", "calBP", "mean", "lower", "upper", "strategy_label",
    "proportion", "iterations"
  )
)
if (!setequal(unique(baseline$method), c("SPD", "FD", "KDE"))) {
  stop("Figure 1 evidence must contain exactly SPD, FD, and KDE.", call. = FALSE)
}
if (!setequal(unique(differences$method), c("SPD", "FD", "KDE"))) {
  stop("Figure 2 evidence must contain exactly SPD, FD, and KDE.", call. = FALSE)
}
if (!setequal(
  unique(differences$strategy_label),
  c("oldest", "youngest", "bracketed", "random-1", "random-5")
) || !setequal(unique(differences$proportion), c(0.5, 1))) {
  stop("Figure 2 evidence has an unexpected scenario schema.", call. = FALSE)
}

source("R/manuscript_methods_figures.R")
figure_1 <- manuscript_methods_plot(baseline)
figure_2 <- manuscript_sampling_panel_plot(differences)

dir.create(settings$output_dir, recursive = TRUE, showWarnings = FALSE)
write_figure <- function(plot, filename, width, height, dpi) {
  output <- file.path(settings$output_dir, filename)
  temporary <- paste0(output, ".tmp.png")
  on.exit(unlink(temporary), add = TRUE)
  ggplot2::ggsave(temporary, plot, width = width, height = height, dpi = dpi)
  if (file.exists(output)) unlink(output)
  if (!file.rename(temporary, output)) {
    stop("Could not write release figure: ", output, call. = FALSE)
  }
  output
}

figure_1_path <- write_figure(
  figure_1,
  "fig_1.png",
  width = 8,
  height = 939 / 171,
  dpi = 171
)
figure_2_path <- write_figure(
  figure_2,
  "fig_2.png",
  width = 7.5,
  height = 8.5,
  dpi = 320
)

message("Wrote ", figure_1_path, " and ", figure_2_path)
