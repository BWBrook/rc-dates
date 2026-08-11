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
  "R/manuscript_empirical_reference.R",
  "R/manuscript_empirical_distances.R",
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
    "R/manuscript_empirical_reference.R",
    "R/manuscript_empirical_distances.R",
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

locked_reference <- readr::read_csv(
  "data/austarch_filtered.csv",
  show_col_types = FALSE
)
locked_dates_per_site <- table(locked_reference$SITE)
if (nrow(locked_reference) != 976L || length(locked_dates_per_site) != 116L ||
    min(locked_dates_per_site) < 5L || anyDuplicated(locked_reference$ADSID)) {
  stop(
    "Tracked empirical reference data do not match the manuscript's 976-date, ",
    "116-site design.",
    call. = FALSE
  )
}

primary_source <- filter_manuscript_primary_reference(
  locked_reference,
  occupation_status = c("Y", "U")
)
calibrated <- rcarbon::calibrate(
  x = as.numeric(primary_source$AGE),
  errors = as.numeric(primary_source$ERROR),
  ids = as.character(primary_source$ADSID),
  calCurves = rep("shcal20", nrow(primary_source)),
  normalised = TRUE,
  verbose = FALSE
)
annotated_reference <- annotate_manuscript_calibration(
  primary_source,
  calibrated,
  min_age = 651,
  max_age = 11650
)

bins <- manuscript_calendar_bins(
  min_age = 651,
  max_age = 11650,
  bin_width = 100
)
specs <- manuscript_empirical_scenarios(
  iterations = settings$iterations,
  seed = settings$seed
)

build_configuration <- function(
  label,
  occupation_status,
  buffer,
  mass_threshold,
  bandwidth,
  kde_boundary,
  scenario_specs
) {
  candidate <- annotated_reference[
    annotated_reference$OCCUPATION_RELATED %in% occupation_status,
    ,
    drop = FALSE
  ]
  reference <- filter_manuscript_common_membership(
    candidate,
    buffer = buffer,
    mass_threshold = mass_threshold,
    min_dates = 5L,
    min_age = 651,
    max_age = 11650
  )
  bases <- prepare_manuscript_curve_bases(
    data = reference,
    calibrated = calibrated,
    bins = bins,
    bandwidth = bandwidth,
    spd_runm = 100L,
    kde_boundary = kde_boundary
  )
  list(
    label = label,
    occupation_status = paste(occupation_status, collapse = "+"),
    buffer = buffer,
    mass_threshold = mass_threshold,
    bandwidth = bandwidth,
    kde_boundary = kde_boundary,
    reference = reference,
    bases = bases,
    baseline_matrices = build_manuscript_baseline_matrices(bases, nrow(reference)),
    baseline = build_manuscript_baseline_curves(bases, nrow(reference)),
    analysis = run_manuscript_empirical_sampling(reference, bases, scenario_specs)
  )
}

primary <- build_configuration(
  label = "primary",
  occupation_status = c("Y", "U"),
  buffer = 100,
  mass_threshold = 0.8,
  bandwidth = 100,
  kde_boundary = "reflect",
  scenario_specs = specs
)
baseline <- primary$baseline
sampling <- primary$analysis$curves
deviations <- primary$analysis$deviations
effective_counts <- rbind(
  summarise_manuscript_effective_counts(
    selection_matrix = matrix(TRUE, nrow = nrow(primary$reference), ncol = 1L),
    bases = primary$bases,
    strategy_label = "all-dates",
    proportion = 0
  ),
  primary$analysis$effective_counts
)

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
if (any(!is.finite(unlist(
  deviations[c("mean", "lower", "upper")],
  use.names = FALSE
)))) {
  stop("Figure 2 deviation summaries contain non-finite values.")
}
if (!all(effective_counts$selected_dates_mean == effective_counts$effective_dates_mean) ||
    !all(effective_counts$selected_dates_min == effective_counts$effective_dates_min) ||
    !all(effective_counts$selected_dates_max == effective_counts$effective_dates_max)) {
  stop("The common-membership effective-date gate failed.")
}

baseline_pairs <- list(c("SPD", "FD"), c("SPD", "KDE"), c("FD", "KDE"))
baseline_distances <- do.call(rbind, lapply(baseline_pairs, function(pair) {
  summarise_manuscript_values(
    manuscript_between_curve_total_variation(
      primary$baseline_matrices[[pair[[1L]]]],
      primary$baseline_matrices[[pair[[2L]]]]
    ),
    comparison = "between_methods",
    strategy_label = "all-dates",
    proportion = 0,
    method_pair = paste(pair, collapse = "-")
  )
}))
distance_summaries <- rbind(
  baseline_distances,
  primary$analysis$distances
)
claim_gates <- primary$analysis$gates
tv_rows <- distance_summaries$comparison %in% c(
  "retention_vs_all", "between_methods"
)
if (any(distance_summaries$min[tv_rows] < 0) ||
    any(distance_summaries$max[tv_rows] > 1) || nrow(claim_gates) != 10L) {
  stop("Empirical distance or scenario-claim gates failed validation.")
}

calendar_eligible <- filter_manuscript_common_membership(
  annotated_reference,
  buffer = 100,
  mass_threshold = 0.8,
  min_dates = 1L,
  min_age = 651,
  max_age = 11650
)
stage_row <- function(stage, data) {
  data.frame(
    stage = stage,
    dates = nrow(data),
    sites = length(unique(data$SITE)),
    stringsAsFactors = FALSE
  )
}
reference_flow <- rbind(
  stage_row("locked_filtered_reference", locked_reference),
  stage_row("terrestrial_charcoal_or_wood", primary_source),
  stage_row("calendar_common_membership", calendar_eligible),
  stage_row("sites_with_at_least_five_eligible_dates", primary$reference)
)
material_composition <- as.data.frame(table(primary$reference$MATERIAL))
names(material_composition) <- c("material", "dates")
material_composition <- material_composition[material_composition$dates > 0L, , drop = FALSE]
material_composition <- material_composition[
  order(-material_composition$dates, material_composition$material),
  ,
  drop = FALSE
]
extreme_ties <- summarise_manuscript_extreme_ties(primary$reference)

extrema_specs <- specs[
  specs$proportion == 1 & specs$strategy %in% c("oldest", "youngest"),
  ,
  drop = FALSE
]
sensitivity_specs <- list(
  list("primary", c("Y", "U"), 100, 0.8, 100, "reflect"),
  list("buffer-0", c("Y", "U"), 0, 0.8, 100, "reflect"),
  list("buffer-200", c("Y", "U"), 200, 0.8, 100, "reflect"),
  list("mass-0.50", c("Y", "U"), 100, 0.5, 100, "reflect"),
  list("mass-0.95", c("Y", "U"), 100, 0.95, 100, "reflect"),
  list("kde-bandwidth-50", c("Y", "U"), 100, 0.8, 50, "reflect"),
  list("kde-bandwidth-200", c("Y", "U"), 100, 0.8, 200, "reflect"),
  list("kde-unreflected", c("Y", "U"), 100, 0.8, 100, "none"),
  list("occupation-Y-only", "Y", 100, 0.8, 100, "reflect")
)
sensitivity_results <- lapply(sensitivity_specs, function(specification) {
  label <- specification[[1L]]
  configuration <- if (label == "primary") {
    primary
  } else {
    build_configuration(
      label = label,
      occupation_status = specification[[2L]],
      buffer = specification[[3L]],
      mass_threshold = specification[[4L]],
      bandwidth = specification[[5L]],
      kde_boundary = specification[[6L]],
      scenario_specs = extrema_specs
    )
  }
  distances <- configuration$analysis$distances
  gates <- configuration$analysis$gates
  if (label == "primary") {
    distances <- distances[
      distances$strategy_label %in% c("oldest", "youngest") &
        distances$proportion == 1,
      ,
      drop = FALSE
    ]
    gates <- gates[
      gates$strategy_label %in% c("oldest", "youngest") & gates$proportion == 1,
      ,
      drop = FALSE
    ]
  }
  distances$configuration <- label
  gates$configuration <- label
  counts <- data.frame(
    configuration = label,
    occupation_status = configuration$occupation_status,
    buffer = configuration$buffer,
    mass_threshold = configuration$mass_threshold,
    kde_bandwidth = configuration$bandwidth,
    kde_boundary = configuration$kde_boundary,
    dates = nrow(configuration$reference),
    sites = length(unique(configuration$reference$SITE)),
    stringsAsFactors = FALSE
  )
  list(distances = distances, gates = gates, counts = counts)
})
sensitivity_distances <- do.call(rbind, lapply(sensitivity_results, `[[`, "distances"))
sensitivity_gates <- do.call(rbind, lapply(sensitivity_results, `[[`, "gates"))
sensitivity_counts <- do.call(rbind, lapply(sensitivity_results, `[[`, "counts"))

primary_sensitivity_gate <- sensitivity_gates[
  sensitivity_gates$configuration == "primary",
  c("strategy_label", "retention_larger_than_method", "temporal_direction"),
  drop = FALSE
]
sensitivity_decision <- do.call(rbind, lapply(c("oldest", "youngest"), function(strategy) {
  observed <- sensitivity_gates[sensitivity_gates$strategy_label == strategy, , drop = FALSE]
  expected_direction <- if (strategy == "oldest") "older" else "younger"
  primary_row <- primary_sensitivity_gate[
    primary_sensitivity_gate$strategy_label == strategy,
    ,
    drop = FALSE
  ]
  data.frame(
    strategy_label = strategy,
    configurations = nrow(observed),
    primary_retention_larger_than_method =
      primary_row$retention_larger_than_method[[1L]],
    primary_temporal_direction = primary_row$temporal_direction[[1L]],
    distance_gate_stable = all(
      observed$retention_larger_than_method ==
        primary_row$retention_larger_than_method[[1L]]
    ),
    direction_robust = all(observed$temporal_direction == expected_direction),
    robust = all(
      observed$retention_larger_than_method ==
        primary_row$retention_larger_than_method[[1L]]
    ) && all(observed$temporal_direction == expected_direction),
    stringsAsFactors = FALSE
  )
}))

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
  manuscript_sampling_panel_plot(deviations),
  width = 7.5,
  height = 10.5,
  dpi = 320
)
if (!file.rename(figure_1_temporary, figure_1_path) ||
    !file.rename(figure_2_temporary, figure_2_path)) {
  stop("Could not atomically replace manuscript Figures 1 and 2.")
}

baseline_path <- file.path(settings$summary_dir, "figure1_baseline_curves.csv")
sampling_path <- file.path(settings$summary_dir, "figure2_sampling_curves.csv")
deviation_path <- file.path(
  settings$summary_dir,
  "figure2_sampling_differences.csv"
)
spec_path <- file.path(settings$summary_dir, "figure2_scenarios.csv")
effective_count_path <- file.path(
  settings$summary_dir,
  "figure1_2_effective_date_counts.csv"
)
distance_path <- file.path(settings$summary_dir, "curve_distance_summaries.csv")
gate_path <- file.path(settings$summary_dir, "scenario_claim_gates.csv")
flow_path <- file.path(settings$summary_dir, "reference_flow.csv")
composition_path <- file.path(settings$summary_dir, "primary_material_composition.csv")
tie_path <- file.path(settings$summary_dir, "extreme_tie_audit.csv")
sensitivity_distance_path <- file.path(
  settings$summary_dir,
  "sensitivity_curve_distances.csv"
)
sensitivity_gate_path <- file.path(
  settings$summary_dir,
  "sensitivity_claim_gates.csv"
)
sensitivity_count_path <- file.path(
  settings$summary_dir,
  "sensitivity_reference_counts.csv"
)
sensitivity_decision_path <- file.path(
  settings$summary_dir,
  "sensitivity_decision.csv"
)
readr::write_csv(baseline, baseline_path)
readr::write_csv(sampling, sampling_path)
readr::write_csv(deviations, deviation_path)
readr::write_csv(specs, spec_path)
readr::write_csv(effective_counts, effective_count_path)
readr::write_csv(distance_summaries, distance_path)
readr::write_csv(claim_gates, gate_path)
readr::write_csv(reference_flow, flow_path)
readr::write_csv(material_composition, composition_path)
readr::write_csv(extreme_ties, tie_path)
readr::write_csv(sensitivity_distances, sensitivity_distance_path)
readr::write_csv(sensitivity_gates, sensitivity_gate_path)
readr::write_csv(sensitivity_counts, sensitivity_count_path)
readr::write_csv(sensitivity_decision, sensitivity_decision_path)

metadata_path <- file.path(settings$summary_dir, "figure1_2_metadata.txt")
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
  "primary_materials: terrestrial charcoal and wood",
  "excluded_from_primary: all shell and human bone",
  "occupation_status_primary: Y and U",
  "calibrated_point_summary: full-posterior median",
  "primary_membership: median 751-11550 cal BP and posterior mass >= 0.80 inside analysis window",
  paste("primary_dates:", nrow(primary$reference)),
  paste("primary_sites:", length(unique(primary$reference$SITE))),
  "fd_membership: identical to SPD and KDE",
  "fd_display_smoothing: two-bin centred running mean in Figures 1 and 2",
  "kde_centres: calibrated posterior medians",
  "kde_boundary_rule: reflected at both analysis-window boundaries",
  "spd_smoothing: 100-year centred running mean with unsmoothed edge fill",
  "fd_figure1_smoothing: two-bin centred running mean with unsmoothed edge fill",
  "kde_bandwidth_years: 100",
  "distance_metric: total variation",
  "direction_metric: mean cal BP shift using bin midpoints",
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
    "empirical_reference_source_md5:",
    unname(tools::md5sum("R/manuscript_empirical_reference.R"))
  ),
  paste(
    "empirical_distance_source_md5:",
    unname(tools::md5sum("R/manuscript_empirical_distances.R"))
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
  paste("design_source_md5:", unname(tools::md5sum(
    "docs/STAGE3_EMPIRICAL_REPAIR.md"
  )))
), metadata_path)

validation_path <- file.path(settings$summary_dir, "VALIDATION.txt")
writeLines(c(
  "rc-dates Stage 3 common-membership empirical evidence: ACCEPTED",
  paste("validated_utc:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste("r_version:", R.version.string),
  paste("primary_dates:", nrow(primary$reference)),
  paste("primary_sites:", length(unique(primary$reference$SITE))),
  "common_effective_membership: PASS",
  "finite_nonnegative_unit_mass_curves: PASS",
  "scenario_iteration_contracts: PASS",
  "total_variation_bounds: PASS",
  paste("scenario_claim_gates:", nrow(claim_gates)),
  paste(
    "headline_sensitivity_robustness:",
    if (all(sensitivity_decision$robust)) "PASS" else "QUALIFIED"
  )
), validation_path)

checksum_path <- file.path(settings$summary_dir, "SHA256SUMS")
evidence_files <- sort(list.files(
  settings$summary_dir,
  full.names = TRUE,
  recursive = FALSE
))
evidence_files <- evidence_files[
  basename(evidence_files) != basename(checksum_path) & file.info(evidence_files)$isdir == FALSE
]
checksums <- vapply(evidence_files, function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}, character(1))
writeLines(
  paste(checksums, basename(evidence_files)),
  checksum_path
)

message(
  "Rendered source-controlled Figures 1-2 from ",
  nrow(primary$reference),
  " dates at ",
  length(unique(primary$reference$SITE)),
  " sites; empirical evidence accepted."
)
