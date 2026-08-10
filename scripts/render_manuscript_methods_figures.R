#!/usr/bin/env Rscript

parse_arguments <- function(args) {
  settings <- list(
    iterations = 1000L,
    seed = 1234L,
    figure_dir = file.path("manuscript", "figures"),
    summary_dir = file.path("out", "empirical-sampling")
  )
  key_map <- c(
    iterations = "iterations",
    seed = "seed",
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
  for (field in c("iterations", "seed")) {
    settings[[field]] <- suppressWarnings(as.integer(settings[[field]]))
    if (is.na(settings[[field]]) || settings[[field]] < 1L) {
      stop("Invalid positive integer for ", field, call. = FALSE)
    }
  }
  for (field in c("figure_dir", "summary_dir")) {
    if (length(settings[[field]]) != 1L || !nzchar(settings[[field]])) {
      stop("Invalid output directory for ", field, call. = FALSE)
    }
  }
  settings
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 1L && args[[1L]] %in% c("--help", "-h")) {
  writeLines(c(
    "Rebuild empirical manuscript Figures 1 and 2 from tracked source and data.",
    "",
    "Optional:",
    "  --iterations=1000 --seed=1234",
    "  --figure-dir=manuscript/figures",
    "  --summary-dir=out/empirical-sampling"
  ))
  quit(status = 0L)
}

required_files <- c(
  "data/austarch_filtered.csv",
  "R/manuscript_methods_figures.R",
  "R/austarch_filters.R",
  "R/model_fit.R"
)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0L) {
  stop(
    "Run from the rc-dates repository root; missing: ",
    paste(missing_files, collapse = ", "),
    call. = FALSE
  )
}

settings <- parse_arguments(args)
if (!identical(as.character(getRversion()), "4.5.3")) {
  stop(
    "Empirical manuscript figures must be rendered under R 4.5.3; found ",
    R.version.string,
    ".",
    call. = FALSE
  )
}
invisible(lapply(
  c(
    "R/austarch_filters.R",
    "R/model_fit.R",
    "R/manuscript_methods_figures.R"
  ),
  sys.source,
  envir = .GlobalEnv
))
required_packages <- c(
  "digest", "dplyr", "ggplot2", "rcarbon", "readr", "rlang", "scales", "withr"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop("Missing figure packages: ", paste(missing_packages, collapse = ", "))
}

reference <- readr::read_csv(
  "data/austarch_filtered.csv",
  show_col_types = FALSE
)
dates_per_site <- table(reference$SITE)
if (nrow(reference) != 976L || length(dates_per_site) != 116L ||
    min(dates_per_site) < 5L || anyDuplicated(reference$ADSID)) {
  stop(
    "Tracked empirical reference data do not match the manuscript's 976-date, ",
    "116-site design.",
    call. = FALSE
  )
}

curves <- choose_calibration_curves(
  reference$TIME_SERIES_RELEVANT,
  terrestrial_curve = "shcal20",
  marine_curve = "marine20"
)
calibrated <- rcarbon::calibrate(
  x = as.numeric(reference$AGE),
  errors = as.numeric(reference$ERROR),
  ids = as.character(reference$ADSID),
  calCurves = curves,
  normalised = TRUE,
  verbose = FALSE
)
calibrated <- filter_calibrated_dates_by_range(
  calibrated,
  min_calBP = 651,
  max_calBP = 11650
)
if (length(calibrated$grids) != nrow(reference) ||
    any(!as.character(reference$ADSID) %in% names(calibrated$grids))) {
  stop("Calibration-window filtering changed the locked reference membership.")
}

weighted_means <- vapply(calibrated$grids, function(grid) {
  sum(grid$calBP * grid$PrDens)
}, numeric(1))
reference$weighted_mean_calBP <- unname(
  weighted_means[as.character(reference$ADSID)]
)
if (any(!is.finite(reference$weighted_mean_calBP))) {
  stop("Recomputed weighted calibrated means contain non-finite values.")
}

bins <- manuscript_calendar_bins(
  min_age = 651,
  max_age = 11650,
  bin_width = 100
)
bases <- prepare_manuscript_curve_bases(
  data = reference,
  calibrated = calibrated,
  bins = bins,
  bandwidth = 100,
  spd_runm = 100L
)
baseline <- build_manuscript_baseline_curves(bases, n_dates = nrow(reference))
specs <- manuscript_empirical_scenarios(
  iterations = settings$iterations,
  seed = settings$seed
)
sampling <- run_manuscript_empirical_sampling(reference, bases, specs)
effective_counts <- rbind(
  summarise_manuscript_effective_counts(
    selection_matrix = matrix(TRUE, nrow = nrow(reference), ncol = 1L),
    bases = bases,
    strategy_label = "all-dates",
    proportion = 0
  ),
  attr(sampling, "effective_counts")
)
attr(sampling, "effective_counts") <- NULL

curve_groups <- interaction(
  sampling$strategy_label,
  sampling$proportion,
  sampling$method,
  drop = TRUE,
  lex.order = TRUE
)
curve_mass <- vapply(split(sampling$mean, curve_groups), sum, numeric(1))
if (any(!is.finite(unlist(sampling[c("mean", "lower", "upper")], use.names = FALSE))) ||
    any(unlist(sampling[c("mean", "lower", "upper")], use.names = FALSE) < 0) ||
    any(abs(curve_mass - 1) > 1e-10)) {
  stop("Figure 2 curve summaries failed finite, non-negative, or unit-mass gates.")
}

dir.create(settings$figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(settings$summary_dir, recursive = TRUE, showWarnings = FALSE)
figure_1_path <- file.path(settings$figure_dir, "fig_1.png")
figure_2_path <- file.path(settings$figure_dir, "fig_2.png")
figure_1_temporary <- paste0(figure_1_path, ".tmp.png")
figure_2_temporary <- paste0(figure_2_path, ".tmp.png")
on.exit(unlink(c(figure_1_temporary, figure_2_temporary)), add = TRUE)

ggplot2::ggsave(
  figure_1_temporary,
  manuscript_methods_plot(baseline),
  width = 8,
  height = 939 / 171,
  dpi = 171
)
ggplot2::ggsave(
  figure_2_temporary,
  manuscript_sampling_panel_plot(sampling),
  width = 7.5,
  height = 15,
  dpi = 320
)
if (!file.rename(figure_1_temporary, figure_1_path) ||
    !file.rename(figure_2_temporary, figure_2_path)) {
  stop("Could not atomically replace manuscript Figures 1 and 2.")
}

baseline_path <- file.path(settings$summary_dir, "figure1_baseline_curves.csv")
sampling_path <- file.path(settings$summary_dir, "figure2_sampling_curves.csv")
spec_path <- file.path(settings$summary_dir, "figure2_scenarios.csv")
effective_count_path <- file.path(
  settings$summary_dir,
  "figure1_2_effective_date_counts.csv"
)
readr::write_csv(baseline, baseline_path)
readr::write_csv(sampling, sampling_path)
readr::write_csv(specs, spec_path)
readr::write_csv(effective_counts, effective_count_path)

metadata_path <- file.path(settings$summary_dir, "figure1_2_metadata.txt")
kde_mass <- colSums(bases$KDE)
kde_mass <- kde_mass[kde_mass > 0]
package_versions <- vapply(
  required_packages,
  function(package) as.character(utils::packageVersion(package)),
  character(1)
)
writeLines(c(
  "rc-dates empirical manuscript Figures 1-2",
  paste("generation_completed_utc:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste("r_version:", R.version.string),
  paste(
    "package_versions:",
    paste(paste(names(package_versions), package_versions, sep = "="), collapse = ";")
  ),
  paste("seed:", settings$seed),
  paste("stochastic_iterations:", settings$iterations),
  "analysis_window_cal_bp: 651-11650 inclusive",
  "fd_window_rule: raw weighted means filtered before legacy-anchored 100-year bins",
  "fd_display_smoothing: two-bin centred running mean in Figures 1 and 2",
  "kde_window_rule: finite weighted means filtered before Gaussian KDE",
  "kde_boundary_rule: Gaussian kernels are not edge-corrected; aggregate mass is renormalised",
  "spd_smoothing: 100-year centred running mean with unsmoothed edge fill",
  "fd_figure1_smoothing: two-bin centred running mean with unsmoothed edge fill",
  "kde_bandwidth_years: 100",
  paste(
    "weighted_means_outside_window:",
    sum(reference$weighted_mean_calBP < 651 | reference$weighted_mean_calBP > 11650)
  ),
  paste("kde_included_kernel_mass_min:", min(kde_mass)),
  paste("kde_included_kernel_mass_mean:", mean(kde_mass)),
  paste("kde_included_kernel_mass_below_0.95:", sum(kde_mass < 0.95)),
  paste("input_md5:", unname(tools::md5sum("data/austarch_filtered.csv"))),
  paste(
    "austarch_filter_source_md5:",
    unname(tools::md5sum("R/austarch_filters.R"))
  ),
  paste(
    "model_fit_source_md5:",
    unname(tools::md5sum("R/model_fit.R"))
  ),
  paste(
    "figure_source_md5:",
    unname(tools::md5sum("R/manuscript_methods_figures.R"))
  ),
  paste("runner_source_md5:", unname(tools::md5sum(
    "scripts/render_manuscript_methods_figures.R"
  ))),
  paste("figure1_md5:", unname(tools::md5sum(figure_1_path))),
  paste("figure2_md5:", unname(tools::md5sum(figure_2_path))),
  paste("baseline_summary_md5:", unname(tools::md5sum(baseline_path))),
  paste("sampling_summary_md5:", unname(tools::md5sum(sampling_path))),
  paste("scenario_summary_md5:", unname(tools::md5sum(spec_path))),
  paste(
    "effective_count_summary_md5:",
    unname(tools::md5sum(effective_count_path))
  )
), metadata_path)

message(
  "Rendered source-controlled Figures 1-2 from ",
  nrow(reference),
  " dates at ",
  length(dates_per_site),
  " sites."
)
