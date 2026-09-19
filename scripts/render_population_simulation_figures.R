#!/usr/bin/env Rscript

parse_arguments <- function(args) {
  settings <- list(
    input_dir = file.path("out", "revision", "signed-models"),
    figure_dir = file.path("manuscript", "figures"),
    summary_dir = file.path("out", "revision", "endpoint-contrast-20260919")
  )
  key_map <- c(
    `input-dir` = "input_dir",
    `figure-dir` = "figure_dir",
    `summary-dir` = "summary_dir"
  )
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
  "R/population_simulation_models.R",
  "R/population_simulation_run.R",
  "R/population_simulation_artifacts.R",
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
  "SHA256SUMS", "VALIDATION.txt", "stage2_manifest.csv", "selection_performance.csv"
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
manifest <- readr::read_csv(
  file.path(settings$input_dir, "stage2_manifest.csv"),
  show_col_types = FALSE
)
required_manifest <- c(
  "file", "truth", "site_treatment_proportion", "replicates", "rows"
)
if (!all(required_manifest %in% names(manifest))) {
  stop("Accepted Stage 2 manifest lacks required RDS identity columns.", call. = FALSE)
}
target_truths <- c("lin_inc", "exp_inc", "lin_dec", "exp_dec")
target_manifest <- manifest[
  manifest$truth %in% target_truths &
    abs(manifest$site_treatment_proportion - 1) < sqrt(.Machine$double.eps),
  ,
  drop = FALSE
]
if (nrow(target_manifest) != length(target_truths) ||
    anyDuplicated(target_manifest$truth) ||
    any(target_manifest$replicates != 1000L) ||
    any(target_manifest$rows != 48000L)) {
  stop("Accepted Stage 2 manifest does not contain the four complete full-treatment RDS files.", call. = FALSE)
}
result_paths <- file.path(settings$input_dir, target_manifest$file)
if (any(!file.exists(result_paths))) {
  stop("Accepted Stage 2 manifest references missing RDS files.", call. = FALSE)
}
invisible(lapply(result_paths, validate_population_simulation_artifact, nsim = 1000L))
result_list <- lapply(result_paths, readRDS)
for (index in seq_along(result_list)) {
  result_list[[index]]$source_file <- basename(result_paths[[index]])
}
endpoint_results <- do.call(rbind, result_list)
rownames(endpoint_results) <- NULL
endpoint_contrast <- prepare_manuscript_endpoint_contrast_panel(endpoint_results)
truth_curves <- prepare_manuscript_signed_truth_curves()

# Render the unchanged truth-density PNG before the multi-panel PDF devices.
dir.create(settings$figure_dir, recursive = TRUE, showWarnings = FALSE)
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


plots <- list(
  fig_3 = manuscript_signed_state_plot(performance),
  fig_4 = manuscript_endpoint_contrast_plot(endpoint_contrast),
  fig_5 = manuscript_family_selection_plot(performance)
)
dimensions <- list(
  fig_3 = c(width = 8.5, height = 5.2),
  fig_4 = c(width = 8.2, height = 7.0),
  fig_5 = c(width = 8.5, height = 5.2)
)

dir.create(settings$summary_dir, recursive = TRUE, showWarnings = FALSE)
summary_temporary <- file.path(settings$summary_dir, "endpoint_contrast.tmp.csv")
summary_final <- file.path(settings$summary_dir, "endpoint_contrast.csv")
on.exit(unlink(summary_temporary), add = TRUE)
readr::write_csv(endpoint_contrast, summary_temporary)
reference_summary <- file.path(
  "out", "revision", "endpoint-contrast-20260919", "endpoint_contrast.csv"
)
if (file.exists(reference_summary)) {
  reference <- read.csv(reference_summary, stringsAsFactors = FALSE)
  rebuilt <- read.csv(summary_temporary, stringsAsFactors = FALSE)
  if (!isTRUE(all.equal(rebuilt, reference, tolerance = 1e-12))) {
    stop("Rebuilt endpoint contrasts differ from the accepted derived summary.", call. = FALSE)
  }
}
if (!file.rename(summary_temporary, summary_final)) {
  stop("Could not atomically write the endpoint-contrast summary.", call. = FALSE)
}

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


message(
  "Validated accepted Stage 2 summaries and rendered Figures 3-5 plus signed Supplementary Figure S1."
)
