#!/usr/bin/env Rscript

parse_arguments <- function(args) {
  settings <- list(
    input_dir = file.path("out", "revision", "signed-models"),
    figure_dir = file.path("manuscript", "figures")
  )
  key_map <- c(`input-dir` = "input_dir", `figure-dir` = "figure_dir")
  for (argument in args) {
    parts <- regmatches(argument, regexec("^--([^=]+)=(.*)$", argument))[[1L]]
    if (length(parts) != 3L || !parts[[2L]] %in% names(key_map)) {
      stop("Unknown or malformed argument: ", argument, call. = FALSE)
    }
    settings[[key_map[[parts[[2L]]]]]] <- parts[[3L]]
  }
  if (any(!vapply(settings, function(x) length(x) == 1L && nzchar(x), logical(1)))) {
    stop("Input and figure directories must be non-empty paths.", call. = FALSE)
  }
  settings
}

source_files <- c(
  "R/population_distributions.R",
  "R/population_simulation_design.R",
  "R/manuscript_signed_figures.R"
)
if (any(!file.exists(source_files))) {
  stop("Run from the rc-dates repository root.", call. = FALSE)
}
if (!identical(as.character(getRversion()), "4.5.3")) {
  stop(
    "Signed manuscript figures must be rendered under R 4.5.3; found ",
    R.version.string,
    ".",
    call. = FALSE
  )
}

settings <- parse_arguments(commandArgs(trailingOnly = TRUE))
required_packages <- c("ggplot2", "readr", "rlang", "scales")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop("Missing figure packages: ", paste(missing_packages, collapse = ", "))
}
invisible(lapply(source_files, sys.source, envir = .GlobalEnv))

required_files <- c(
  "SHA256SUMS", "VALIDATION.txt", "selection_performance.csv", "log_ratio_bias.csv"
)
missing_files <- required_files[
  !file.exists(file.path(settings$input_dir, required_files))
]
if (length(missing_files) > 0L) {
  stop(
    "Missing accepted Stage 2 evidence: ",
    paste(missing_files, collapse = ", "),
    call. = FALSE
  )
}
validation <- readLines(file.path(settings$input_dir, "VALIDATION.txt"), warn = FALSE)
if (!any(grepl("ACCEPTED", validation, fixed = TRUE)) ||
    !any(grepl("R version 4.5.3", validation, fixed = TRUE))) {
  stop("Stage 2 validation record is not accepted under R 4.5.3.", call. = FALSE)
}

old_working_directory <- getwd()
on.exit(setwd(old_working_directory), add = TRUE)
setwd(settings$input_dir)
checksum_output <- system2("sha256sum", c("-c", "SHA256SUMS"), stdout = TRUE, stderr = TRUE)
checksum_status <- attr(checksum_output, "status")
setwd(old_working_directory)
if (!is.null(checksum_status) && checksum_status != 0L) {
  stop(
    "Accepted Stage 2 evidence failed checksum validation:\n",
    paste(checksum_output, collapse = "\n"),
    call. = FALSE
  )
}

performance <- prepare_manuscript_signed_performance(readr::read_csv(
  file.path(settings$input_dir, "selection_performance.csv"),
  show_col_types = FALSE
))
theta <- prepare_manuscript_theta_panel(readr::read_csv(
  file.path(settings$input_dir, "log_ratio_bias.csv"),
  show_col_types = FALSE
))
truth_curves <- prepare_manuscript_signed_truth_curves()

plots <- list(
  fig_3 = manuscript_signed_state_plot(performance),
  fig_4 = manuscript_theta_plot(theta),
  fig_5 = manuscript_family_selection_plot(performance)
)
dimensions <- list(
  fig_3 = c(width = 10.5, height = 5.2),
  fig_4 = c(width = 8.2, height = 7.0),
  fig_5 = c(width = 10.5, height = 5.2)
)

dir.create(settings$figure_dir, recursive = TRUE, showWarnings = FALSE)
temporary_paths <- file.path(
  settings$figure_dir,
  paste0(names(plots), ".tmp.pdf")
)
final_paths <- file.path(settings$figure_dir, paste0(names(plots), ".pdf"))
on.exit(unlink(temporary_paths), add = TRUE)

for (name in names(plots)) {
  ggplot2::ggsave(
    filename = file.path(settings$figure_dir, paste0(name, ".tmp.pdf")),
    plot = plots[[name]],
    width = dimensions[[name]][["width"]],
    height = dimensions[[name]][["height"]],
    device = grDevices::cairo_pdf
  )
}
for (index in seq_along(final_paths)) {
  if (!file.rename(temporary_paths[[index]], final_paths[[index]])) {
    stop("Could not atomically replace ", basename(final_paths[[index]]), ".")
  }
}

si_temporary <- file.path(
  settings$figure_dir,
  "SI_data_generating_distributions.tmp.png"
)
si_final <- file.path(settings$figure_dir, "SI_data_generating_distributions.png")
on.exit(unlink(si_temporary), add = TRUE)
ggplot2::ggsave(
  filename = si_temporary,
  plot = manuscript_signed_truth_plot(truth_curves),
  width = 8,
  height = 5.2,
  dpi = 320
)
if (!file.rename(si_temporary, si_final)) {
  stop("Could not atomically replace Supplementary Figure S1.")
}

message(
  "Validated accepted Stage 2 summaries and rendered Figures 3-5 plus signed Supplementary Figure S1."
)
