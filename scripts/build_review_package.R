#!/usr/bin/env Rscript

# Build the de-identified code/data review package outside the named GitHub repo.
# The package is intentionally code-only: no manuscript sources, reports, refs, docs,
# source-control metadata, or internal agent notes are copied.

args <- commandArgs(trailingOnly = TRUE)

default_package_parent <- function() {
  candidates <- c(
    "/Users/bwbrook/papers/de_identified_repos",
    "/home/bwbrook/papers/de_identified_repos"
  )
  existing <- candidates[dir.exists(candidates)]
  if (length(existing) > 0L) {
    return(existing[[1L]])
  }
  file.path(path.expand("~"), "papers", "de_identified_repos")
}

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
default_parent <- default_package_parent()
package_parent <- if (length(args) >= 1L) args[[1L]] else default_parent
package_parent <- normalizePath(package_parent, winslash = "/", mustWork = FALSE)
package_name <- "rc_review_package"
package_dir <- file.path(package_parent, package_name)

production_models <- c("uni", "lin", "exp")
production_props <- c("0.5", "0.75", "1")
production_rds <- unlist(lapply(production_props, function(prop) {
  sprintf(
    "results_%s_p%s_ratio10_nsim1000_seed1234.rds",
    production_models,
    prop
  )
}), use.names = FALSE)
production_files <- c(
  file.path("out", "production", production_rds),
  file.path("out", "production", paste0(production_rds, ".metadata.txt")),
  file.path("out", "production", c(
    "production_manifest.csv",
    "summary_model_accuracy.csv",
    "summary_parameter_bias.csv",
    "summary_unique_ose.csv",
    "container_image_id.txt",
    "SHA256SUMS"
  ))
)

empirical_summary_names <- c(
  "figure1_baseline_curves.csv",
  "figure2_sampling_curves.csv",
  "figure2_scenarios.csv",
  "figure1_2_effective_date_counts.csv",
  "figure1_2_metadata.txt"
)
empirical_summary_files <- file.path(
  "out",
  "empirical-sampling",
  empirical_summary_names
)
empirical_figure_sources <- file.path(
  "manuscript",
  "figures",
  c("fig_1.png", "fig_2.png")
)

sensitivity_models <- c("uni", "lin", "exp")
sensitivity_props <- c("0.5", "0.75", "1")
sensitivity_rds_names <- unlist(lapply(sensitivity_models, function(model) {
  sprintf(
    "observation_noise_%s_p%s_ratio10_nsim1000_seed1234.rds",
    model,
    sensitivity_props
  )
}), use.names = FALSE)
sensitivity_pair_names <- sub("\\.rds$", ".pairs.csv", sensitivity_rds_names)
sensitivity_metadata_names <- paste0(sensitivity_rds_names, ".metadata.txt")
sensitivity_root <- file.path("out", "sensitivity", "observation-noise")
sensitivity_summary_required_names <- c(
  "observation_noise_accuracy.csv",
  "observation_noise_ose_support.csv",
  "observation_noise_n_dropped.csv",
  "observation_noise_decision_discordance.csv",
  "observation_noise_ose_set_discordance.csv",
  "observation_noise_accuracy_advantage.csv",
  "observation_noise_drop_rate.csv",
  "observation_noise_realised_accuracy_contrasts.csv",
  "observation_noise_realised_ose_contrasts.csv",
  "observation_noise_bias.csv",
  "observation_noise_paired_bias_shift.csv",
  "observation_noise_rmse.csv",
  "observation_noise_boundary.csv",
  "observation_noise_mass_low.csv",
  "observation_noise_mass_zero.csv",
  "observation_noise_gate_report.csv",
  "observation_noise_gate_report.rds",
  "observation_noise_gate_report.json",
  "observation_noise_gate_report.md",
  "observation_noise_summary_metadata.txt"
)
sensitivity_v2_dir_name <- "estimand-aligned-v2"
sensitivity_v2_required_names <- c(
  "metrics.csv",
  "gate_report.csv",
  "gate_report.rds",
  "gate_report.json",
  "gate_report.md",
  "stability.csv",
  "v1_interpretation.md",
  "metadata.txt",
  "SHA256SUMS"
)
sensitivity_v2_root <- file.path(sensitivity_root, sensitivity_v2_dir_name)
sensitivity_v2_required_files <- file.path(
  sensitivity_v2_root,
  sensitivity_v2_required_names
)
sensitivity_gate_names <- c(
  "accuracy_difference_ci",
  "ose_support_difference_ci",
  "minimum_aic_discordance",
  "ose_set_discordance",
  "prop1_random3_random5_accuracy",
  "prop1_truth_specific_random3_random5_accuracy",
  "prop1_truth_specific_random3_random5_lower",
  "prop1_r_3_advantage_over_r1",
  "prop1_r_5_advantage_over_r1",
  "l1_l2_qualitative_consistency",
  "noisy_absolute_mean_bias",
  "paired_bias_shift",
  "rmse_relative",
  "boundary_hit_increase",
  "strict_window_drop_rate",
  "strict_window_drop_increase",
  "zero_mass_rate",
  "low_mass_arm_increase"
)
sensitivity_required_files <- c(
  file.path(
    sensitivity_root,
    c(
      sensitivity_rds_names,
      sensitivity_pair_names,
      sensitivity_metadata_names,
      "container_image_id.txt",
      "SHA256SUMS",
      file.path("summary", sensitivity_summary_required_names)
    )
  ),
  sensitivity_v2_required_files
)

required_files <- c(
  "_targets.R",
  "dependencies.R",
  ".dockerignore",
  ".gitattributes",
  ".lintr",
  "LICENSE",
  "renv.lock",
  "renv/.gitignore",
  "renv/activate.R",
  "renv/settings.json",
  "scripts/bootstrap.R",
  "scripts/run_population_simulation.R",
  "scripts/run_production_simulation_matrix.sh",
  "scripts/render_population_simulation_figures.R",
  "scripts/render_manuscript_methods_figures.R",
  "scripts/run_observation_noise_sensitivity.R",
  "scripts/run_observation_noise_sensitivity_matrix.sh",
  "scripts/summarise_observation_noise_estimand_aligned.R",
  "scripts/summarise_observation_noise_sensitivity.R",
  "docker/production-simulation.Dockerfile",
  "docker/install-production-packages.R",
  "R/manuscript_methods_figures.R",
  "R/observation_noise_estimand_aligned.R",
  "R/observation_noise_sensitivity.R",
  "R/observation_noise_summaries.R",
  "tests/testthat/test_manuscript_methods_figures.R",
  "tests/testthat/test_observation_noise_estimand_aligned.R",
  "tests/testthat/test_observation_noise_sensitivity.R",
  "tests/testthat/test_observation_noise_summaries.R",
  "data/Austarch_1-3_and_IDASQ_28Nov13-1.csv",
  "data/austarch_filtered.csv",
  empirical_summary_files,
  empirical_figure_sources,
  "provenance/observation-noise-20260726/README.md",
  "provenance/observation-noise-20260726/SHA256SUMS",
  sensitivity_required_files,
  production_files
)

required_dirs <- c(
  "R",
  "config",
  "tests",
  "inst/extdata",
  "provenance/production-20260710",
  "provenance/observation-noise-20260726"
)

missing_files <- required_files[!file.exists(file.path(repo_root, required_files))]
missing_dirs <- required_dirs[!dir.exists(file.path(repo_root, required_dirs))]

if (length(missing_files) > 0L || length(missing_dirs) > 0L) {
  stop(
    paste(
      c(
        "Cannot build review package; required paths are missing.",
        paste("Files:", paste(missing_files, collapse = ", ")),
        paste("Directories:", paste(missing_dirs, collapse = ", "))
      ),
      collapse = "\n"
    ),
    call. = FALSE
  )
}

builder_packages <- c("digest", "jsonlite", "yaml")
missing_builder_packages <- builder_packages[!vapply(
  builder_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_builder_packages) > 0L) {
  stop(
    "Missing review-package builder packages: ",
    paste(missing_builder_packages, collapse = ", "),
    call. = FALSE
  )
}

read_key_value_metadata <- function(path, label) {
  lines <- readLines(path, warn = FALSE)
  separators <- regexpr(":", lines, fixed = TRUE)
  lines <- lines[separators > 0L]
  separators <- separators[separators > 0L]
  keys <- trimws(substr(lines, 1L, separators - 1L))
  values <- trimws(substr(lines, separators + 1L, nchar(lines)))
  if (length(keys) == 0L || any(!nzchar(keys)) || anyDuplicated(keys)) {
    stop("Malformed or duplicate fields in ", label, ": ", path, call. = FALSE)
  }
  stats::setNames(values, keys)
}

read_named_inventory <- function(
  value,
  expected_names,
  value_pattern,
  label
) {
  records <- trimws(strsplit(value, ";", fixed = TRUE)[[1L]])
  parts <- strsplit(records, "=", fixed = TRUE)
  if (length(records) == 0L ||
      any(lengths(parts) != 2L) ||
      any(!nzchar(records))) {
    stop(label, " is malformed.", call. = FALSE)
  }
  keys <- vapply(parts, `[[`, character(1), 1L)
  values <- vapply(parts, `[[`, character(1), 2L)
  if (!identical(keys, expected_names) ||
      any(!grepl(value_pattern, values)) ||
      anyDuplicated(keys)) {
    stop(
      label,
      " does not match the exact ordered evidence inventory.",
      call. = FALSE
    )
  }
  stats::setNames(values, keys)
}

require_metadata_fields <- function(metadata, fields, label) {
  missing <- setdiff(fields, names(metadata))
  if (length(missing) > 0L) {
    stop(
      label,
      " is missing required fields: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

validate_md5_metadata <- function(metadata, paths, label) {
  require_metadata_fields(metadata, names(paths), label)
  recorded <- unname(metadata[names(paths)])
  actual <- unname(tools::md5sum(file.path(repo_root, unname(paths))))
  valid_recorded <- grepl("^[0-9a-f]{32}$", recorded)
  if (any(!valid_recorded) || !identical(recorded, actual)) {
    stop(label, " MD5 fingerprints do not match the supplied artefacts.", call. = FALSE)
  }
  invisible(TRUE)
}

read_sha256_manifest <- function(path, label) {
  lines <- trimws(readLines(path, warn = FALSE))
  lines <- lines[nzchar(lines)]
  matches <- regexec("^([0-9a-f]{64})[[:space:]]+[*]?(.+)$", lines)
  parts <- regmatches(lines, matches)
  if (length(parts) == 0L || any(lengths(parts) != 3L)) {
    stop("Malformed ", label, " SHA256SUMS file.", call. = FALSE)
  }
  checksums <- vapply(parts, `[[`, character(1), 2L)
  names(checksums) <- vapply(parts, `[[`, character(1), 3L)
  names(checksums) <- sub("^\\./", "", names(checksums))
  unsafe_names <- grepl(
    "(^/|^[[:alpha:]]:/|\\\\|(^|/)\\.\\.?(/|$))",
    names(checksums)
  )
  if (any(!nzchar(names(checksums))) || any(unsafe_names) ||
      anyDuplicated(names(checksums))) {
    stop(label, " SHA256SUMS contains unsafe or duplicate paths.", call. = FALSE)
  }
  checksums
}

validate_sha256_manifest <- function(base_dir, manifest_name, expected_names, label) {
  manifest_path <- file.path(base_dir, manifest_name)
  recorded <- read_sha256_manifest(manifest_path, label)
  if (!setequal(names(recorded), expected_names)) {
    missing <- setdiff(expected_names, names(recorded))
    extra <- setdiff(names(recorded), expected_names)
    stop(
      label,
      " SHA256SUMS does not match the distributable evidence boundary.",
      if (length(missing) > 0L) {
        paste0("\nMissing: ", paste(missing, collapse = ", "))
      } else {
        ""
      },
      if (length(extra) > 0L) {
        paste0("\nExtra: ", paste(extra, collapse = ", "))
      } else {
        ""
      },
      call. = FALSE
    )
  }
  actual <- vapply(names(recorded), function(relative_path) {
    digest::digest(
      file.path(base_dir, relative_path),
      algo = "sha256",
      serialize = FALSE,
      file = TRUE
    )
  }, character(1))
  if (!identical(unname(recorded), unname(actual))) {
    stop(label, " artefact SHA-256 verification failed.", call. = FALSE)
  }
  invisible(recorded)
}

production_provenance <- attr(
  readRDS(file.path(repo_root, "out", "production", production_rds[[1L]])),
  "production_provenance",
  exact = TRUE
)
if (is.null(production_provenance) ||
    !identical(production_provenance$provenance_origin, "post-run-stamp")) {
  stop("Supplied production RDS files lack the expected provenance origin.", call. = FALSE)
}
snapshot_files <- c(
  production_source_md5 = "provenance/production-20260710/R/population_simulation_production.R",
  legacy_helper_md5 = "provenance/production-20260710/R/legacy_simulation_helpers.R",
  runner_source_md5 = "provenance/production-20260710/scripts/run_population_simulation.R",
  container_recipe_md5 = "provenance/production-20260710/docker/production-simulation.Dockerfile",
  renv_lock_md5 = "renv.lock",
  input_md5 = "data/austarch_filtered.csv"
)
snapshot_md5 <- unname(tools::md5sum(file.path(repo_root, snapshot_files)))
recorded_md5 <- unname(unlist(production_provenance[names(snapshot_files)]))
if (is.null(production_provenance) || !identical(snapshot_md5, recorded_md5)) {
  stop("Production provenance does not match the retained generation snapshot.", call. = FALSE)
}
if (!identical(production_provenance$container_install_md5, "inline-in-recipe")) {
  stop("Production container-install provenance conflicts with its inline recipe.", call. = FALSE)
}
recorded_image_id <- readLines(
  file.path(repo_root, "out", "production", "container_image_id.txt"),
  warn = FALSE
)
if (!identical(recorded_image_id, production_provenance$container_image_id)) {
  stop("Production container image ID conflicts with RDS provenance.", call. = FALSE)
}
checksum_path <- file.path(repo_root, "out", "production", "SHA256SUMS")
checksum_lines <- readLines(checksum_path, warn = FALSE)
checksum_parts <- strsplit(trimws(checksum_lines), "[[:space:]]+")
valid_checksum_lines <- vapply(checksum_parts, function(parts) {
  length(parts) == 2L && grepl("^[0-9a-f]{64}$", parts[[1L]])
}, logical(1))
if (length(checksum_parts) == 0L || !all(valid_checksum_lines)) {
  stop("Malformed production SHA256SUMS file.", call. = FALSE)
}
recorded_checksums <- vapply(checksum_parts, `[[`, character(1), 1L)
names(recorded_checksums) <- vapply(checksum_parts, `[[`, character(1), 2L)
if (anyDuplicated(names(recorded_checksums))) {
  stop("Production SHA256SUMS contains duplicate filenames.", call. = FALSE)
}
expected_checksum_names <- basename(setdiff(
  production_files,
  file.path("out", "production", "SHA256SUMS")
))
if (!setequal(names(recorded_checksums), expected_checksum_names)) {
  stop("Production SHA256SUMS does not enumerate every supplied artefact.", call. = FALSE)
}
actual_checksums <- vapply(names(recorded_checksums), function(file) {
  digest::digest(
    file.path(repo_root, "out", "production", file),
    algo = "sha256",
    serialize = FALSE,
    file = TRUE
  )
}, character(1))
if (!identical(unname(recorded_checksums), unname(actual_checksums))) {
  stop("Production artefact SHA-256 verification failed.", call. = FALSE)
}

empirical_metadata <- read_key_value_metadata(
  file.path(repo_root, "out", "empirical-sampling", "figure1_2_metadata.txt"),
  "Empirical Figures 1-2 metadata"
)
require_metadata_fields(
  empirical_metadata,
  c(
    "r_version",
    "seed",
    "stochastic_iterations",
    "analysis_window_cal_bp",
    "fd_window_rule",
    "kde_window_rule"
  ),
  "Empirical Figures 1-2 metadata"
)
if (!grepl("^R version 4\\.5\\.3 ", empirical_metadata[["r_version"]]) ||
    !identical(empirical_metadata[["seed"]], "1234") ||
    !identical(empirical_metadata[["stochastic_iterations"]], "1000") ||
    !identical(empirical_metadata[["analysis_window_cal_bp"]], "651-11650 inclusive") ||
    !identical(
      empirical_metadata[["fd_window_rule"]],
      "raw weighted means filtered before legacy-anchored 100-year bins"
    ) ||
    !identical(
      empirical_metadata[["kde_window_rule"]],
      "finite weighted means filtered before Gaussian KDE"
    )) {
  stop(
    "Empirical Figures 1-2 metadata do not describe the locked repaired workflow.",
    call. = FALSE
  )
}
validate_md5_metadata(
  empirical_metadata,
  c(
    input_md5 = "data/austarch_filtered.csv",
    austarch_filter_source_md5 = "R/austarch_filters.R",
    model_fit_source_md5 = "R/model_fit.R",
    figure_source_md5 = "R/manuscript_methods_figures.R",
    runner_source_md5 = "scripts/render_manuscript_methods_figures.R",
    figure1_md5 = "manuscript/figures/fig_1.png",
    figure2_md5 = "manuscript/figures/fig_2.png",
    baseline_summary_md5 = "out/empirical-sampling/figure1_baseline_curves.csv",
    sampling_summary_md5 = "out/empirical-sampling/figure2_sampling_curves.csv",
    scenario_summary_md5 = "out/empirical-sampling/figure2_scenarios.csv",
    effective_count_summary_md5 =
      "out/empirical-sampling/figure1_2_effective_date_counts.csv"
  ),
  "Empirical Figures 1-2 metadata"
)

sensitivity_snapshot_root <- file.path(
  repo_root,
  "provenance",
  "observation-noise-20260726"
)
sensitivity_snapshot_names <- c(
  "R/legacy_simulation_helpers.R",
  "R/observation_noise_sensitivity.R",
  "R/population_simulation_production.R",
  "docker/install-production-packages.R",
  "docker/production-simulation.Dockerfile",
  "scripts/run_observation_noise_sensitivity.R",
  "scripts/run_observation_noise_sensitivity_matrix.sh"
)
sensitivity_snapshot_entries <- list.files(
  sensitivity_snapshot_root,
  all.files = TRUE,
  recursive = TRUE,
  include.dirs = TRUE,
  no.. = TRUE
)
sensitivity_snapshot_paths <- file.path(
  sensitivity_snapshot_root,
  sensitivity_snapshot_entries
)
sensitivity_snapshot_info <- file.info(sensitivity_snapshot_paths)
sensitivity_snapshot_file_names <- sensitivity_snapshot_entries[
  !sensitivity_snapshot_info$isdir
]
sensitivity_snapshot_dir_names <- sensitivity_snapshot_entries[
  sensitivity_snapshot_info$isdir
]
expected_snapshot_file_names <- c(
  "README.md",
  "SHA256SUMS",
  sensitivity_snapshot_names
)
if (!setequal(sensitivity_snapshot_file_names, expected_snapshot_file_names) ||
    !setequal(sensitivity_snapshot_dir_names, c("R", "docker", "scripts")) ||
    any(nzchar(Sys.readlink(sensitivity_snapshot_paths)))) {
  stop(
    "Frozen observation-noise provenance has missing, extra, or symlinked files.",
    call. = FALSE
  )
}
validate_sha256_manifest(
  sensitivity_snapshot_root,
  "SHA256SUMS",
  sensitivity_snapshot_names,
  "Frozen observation-noise provenance"
)

sensitivity_root_path <- file.path(repo_root, sensitivity_root)
sensitivity_root_entries <- list.files(
  sensitivity_root_path,
  all.files = TRUE,
  recursive = FALSE,
  no.. = TRUE
)
sensitivity_root_entry_paths <- file.path(
  sensitivity_root_path,
  sensitivity_root_entries
)
sensitivity_root_info <- file.info(sensitivity_root_entry_paths)
sensitivity_root_file_names <- sensitivity_root_entries[!sensitivity_root_info$isdir]
sensitivity_root_dir_names <- sensitivity_root_entries[sensitivity_root_info$isdir]
expected_sensitivity_root_file_names <- c(
  sensitivity_rds_names,
  sensitivity_pair_names,
  sensitivity_metadata_names,
  "container_image_id.txt",
  "SHA256SUMS"
)
unexpected_sensitivity_dirs <- setdiff(
  sensitivity_root_dir_names,
  c("summary", sensitivity_v2_dir_name, "logs")
)
if (!setequal(
  sensitivity_root_file_names,
  expected_sensitivity_root_file_names
) || length(unexpected_sensitivity_dirs) > 0L ||
    any(nzchar(Sys.readlink(sensitivity_root_entry_paths)))) {
  stop(
    "Observation-noise evidence root has missing, extra, or symlinked non-log paths.",
    call. = FALSE
  )
}

sensitivity_summary_root <- file.path(sensitivity_root_path, "summary")
sensitivity_summary_entries <- list.files(
  sensitivity_summary_root,
  all.files = TRUE,
  recursive = TRUE,
  include.dirs = TRUE,
  no.. = TRUE
)
sensitivity_summary_paths <- file.path(
  sensitivity_summary_root,
  sensitivity_summary_entries
)
sensitivity_summary_info <- file.info(sensitivity_summary_paths)
sensitivity_summary_file_names <- sensitivity_summary_entries[
  !sensitivity_summary_info$isdir
]
sensitivity_summary_dir_names <- sensitivity_summary_entries[
  sensitivity_summary_info$isdir
]
if (!setequal(
  sensitivity_summary_file_names,
  sensitivity_summary_required_names
) ||
    length(sensitivity_summary_dir_names) > 0L ||
    any(nzchar(Sys.readlink(sensitivity_summary_paths)))) {
  stop(
    paste(
      "Observation-noise summary evidence is incomplete or has",
      "unexpected, nested, or symlinked paths."
    ),
    call. = FALSE
  )
}
sensitivity_v2_root_path <- file.path(repo_root, sensitivity_v2_root)
sensitivity_v2_entries <- list.files(
  sensitivity_v2_root_path,
  all.files = TRUE,
  recursive = TRUE,
  include.dirs = TRUE,
  no.. = TRUE
)
sensitivity_v2_paths <- file.path(sensitivity_v2_root_path, sensitivity_v2_entries)
sensitivity_v2_info <- file.info(sensitivity_v2_paths)
sensitivity_v2_file_names <- sensitivity_v2_entries[!sensitivity_v2_info$isdir]
sensitivity_v2_dir_names <- sensitivity_v2_entries[sensitivity_v2_info$isdir]
if (!setequal(sensitivity_v2_file_names, sensitivity_v2_required_names) ||
    length(sensitivity_v2_dir_names) > 0L ||
    nzchar(Sys.readlink(sensitivity_v2_root_path)) ||
    any(nzchar(Sys.readlink(sensitivity_v2_paths)))) {
  stop(
    paste(
      "Estimand-aligned v2 evidence has missing, extra, nested,",
      "or symlinked paths."
    ),
    call. = FALSE
  )
}
validate_sha256_manifest(
  sensitivity_v2_root_path,
  "SHA256SUMS",
  setdiff(sensitivity_v2_required_names, "SHA256SUMS"),
  "Estimand-aligned v2 observation-noise"
)
sensitivity_checksum_names <- c(
  sensitivity_rds_names,
  sensitivity_pair_names,
  sensitivity_metadata_names,
  "container_image_id.txt",
  file.path("summary", sensitivity_summary_file_names),
  file.path(sensitivity_v2_dir_name, sensitivity_v2_file_names)
)
validate_sha256_manifest(
  sensitivity_root_path,
  "SHA256SUMS",
  sensitivity_checksum_names,
  "Observation-noise sensitivity"
)

sensitivity_image_id <- readLines(
  file.path(sensitivity_root_path, "container_image_id.txt"),
  warn = FALSE
)
if (length(sensitivity_image_id) != 1L ||
    !grepl("^sha256:[0-9a-f]{64}$", sensitivity_image_id)) {
  stop("Observation-noise container image ID is missing or malformed.", call. = FALSE)
}
sensitivity_snapshot_readme <- paste(
  readLines(file.path(sensitivity_snapshot_root, "README.md"), warn = FALSE),
  collapse = "\n"
)
if (!grepl(sensitivity_image_id, sensitivity_snapshot_readme, fixed = TRUE)) {
  stop(
    "Frozen observation-noise provenance records a different container image ID.",
    call. = FALSE
  )
}

sensitivity_validation_env <- new.env(parent = globalenv())
sys.source(
  file.path(repo_root, "R", "population_simulation_production.R"),
  envir = sensitivity_validation_env
)
sys.source(
  file.path(repo_root, "R", "observation_noise_sensitivity.R"),
  envir = sensitivity_validation_env
)
sensitivity_provenance_md5_paths <- c(
  input_md5 = "data/austarch_filtered.csv",
  renv_lock_md5 = "renv.lock",
  production_source_md5 =
    "provenance/observation-noise-20260726/R/population_simulation_production.R",
  sensitivity_source_md5 =
    "provenance/observation-noise-20260726/R/observation_noise_sensitivity.R",
  legacy_helper_md5 =
    "provenance/observation-noise-20260726/R/legacy_simulation_helpers.R",
  runner_source_md5 =
    "provenance/observation-noise-20260726/scripts/run_observation_noise_sensitivity.R",
  container_recipe_md5 =
    "provenance/observation-noise-20260726/docker/production-simulation.Dockerfile",
  container_install_md5 =
    "provenance/observation-noise-20260726/docker/install-production-packages.R"
)
sensitivity_provenance_required <- c(
  "schema_version",
  "sensitivity_design",
  "observation_models",
  "assay_equation",
  "calibration_curve",
  "roundyear",
  "window_exclusion_rule",
  "rng_kind",
  "stream_mapping",
  "true_model",
  "prop",
  "nsim",
  "master_seed",
  "strategies",
  names(sensitivity_provenance_md5_paths),
  "container_image_id",
  "r_version",
  "rcarbon_version"
)
sensitivity_result_columns <- c(
  "sim",
  "true",
  "prop",
  "strategy",
  "type",
  "model",
  "min",
  "ose",
  "bias",
  "n_observations",
  "n_dropped",
  "observation_model",
  "pair_id",
  "structure_hash",
  "selection_hash"
)
sensitivity_pair_columns <- c(
  "pair_id",
  "sim",
  "true",
  "prop",
  "n_sites",
  "n_dates",
  "n_treated_sites",
  "structure_hash",
  "selection_hash",
  "expectation_observation_hash",
  "realised_observation_hash",
  "expectation_low_mass_rate",
  "realised_low_mass_rate",
  "expectation_zero_mass_rate",
  "realised_zero_mass_rate"
)
sensitivity_sidecar_fields <- c(
  "schema_version",
  "generation_completed_utc",
  "r_version",
  "rcarbon_version",
  "true_model",
  "site_subsampling_proportion",
  "paired_replicates",
  "master_seed",
  "strategies",
  "sensitivity_design",
  "assay_equation",
  "window_exclusion_rule",
  "rng_kind",
  "stream_mapping",
  "input_md5",
  "renv_lock_md5",
  "production_source_md5",
  "sensitivity_source_md5",
  "legacy_helper_md5",
  "runner_source_md5",
  "container_recipe_md5",
  "container_install_md5",
  "container_image_id",
  "output_md5",
  "pair_manifest_md5",
  "packages"
)
sensitivity_sidecar_package_names <- c(
  "digest",
  "fitdistrplus",
  "rcarbon",
  "readr"
)
sensitivity_common_provenance <- NULL
sensitivity_sidecar_package_versions <- NULL

for (index in seq_along(sensitivity_rds_names)) {
  rds_name <- sensitivity_rds_names[[index]]
  pair_name <- sensitivity_pair_names[[index]]
  metadata_name <- sensitivity_metadata_names[[index]]
  expected_model <- sub(
    "^observation_noise_([^_]+)_.*$",
    "\\1",
    rds_name
  )
  expected_prop <- sub(
    "^.*_p([^_]+)_ratio.*$",
    "\\1",
    rds_name
  )
  rds_path <- file.path(sensitivity_root_path, rds_name)
  pair_path <- file.path(sensitivity_root_path, pair_name)
  metadata_path <- file.path(sensitivity_root_path, metadata_name)
  checkpoint <- readRDS(rds_path)
  if (!is.list(checkpoint) ||
      !identical(
        names(checkpoint),
        c("results", "pair_manifest", "provenance")
      )) {
    stop("Malformed observation-noise checkpoint: ", rds_name, call. = FALSE)
  }
  if (!identical(names(checkpoint$results), sensitivity_result_columns) ||
      !identical(names(checkpoint$pair_manifest), sensitivity_pair_columns)) {
    stop(
      "Observation-noise checkpoint has an unexpected data schema: ",
      rds_name,
      call. = FALSE
    )
  }
  provenance <- checkpoint$provenance
  missing_provenance <- setdiff(
    sensitivity_provenance_required,
    names(provenance)
  )
  if (length(missing_provenance) > 0L ||
      !setequal(names(provenance), sensitivity_provenance_required)) {
    stop(
      "Observation-noise checkpoint provenance is incomplete: ",
      rds_name,
      call. = FALSE
    )
  }
  provenance_md5 <- unname(unlist(
    provenance[names(sensitivity_provenance_md5_paths)]
  ))
  expected_provenance_md5 <- unname(tools::md5sum(file.path(
    repo_root,
    sensitivity_provenance_md5_paths
  )))
  valid_provenance_md5 <- grepl("^[0-9a-f]{32}$", provenance_md5)
  valid_scenario <- identical(as.character(provenance$true_model), expected_model) &&
    length(provenance$prop) == 1L &&
    isTRUE(abs(as.numeric(provenance$prop) - as.numeric(expected_prop)) <
      sqrt(.Machine$double.eps)) &&
    identical(as.integer(provenance$nsim), 1000L) &&
    identical(as.integer(provenance$master_seed), 1234L)
  valid_design <- identical(as.integer(provenance$schema_version), 1L) &&
    identical(
      as.character(provenance$sensitivity_design),
      "paired_curve_mean_vs_realised_v1"
    ) &&
    identical(
      as.character(provenance$observation_models),
      c("curve_mean", "realised")
    ) &&
    identical(
      as.character(provenance$assay_equation),
      "rCRA=round(ccCRA+Z*sqrt(ccError^2+quoted_error^2))"
    ) &&
    identical(as.character(provenance$calibration_curve), "shcal20") &&
    isTRUE(provenance$roundyear) &&
    identical(
      as.character(provenance$window_exclusion_rule),
      "drop selected observations with zero posterior mass in 651-11650"
    ) &&
    identical(as.character(provenance$rng_kind), "L'Ecuyer-CMRG") &&
    identical(
      as.character(provenance$stream_mapping),
      "structural=current; realised_assay=nextRNGStream(structural)"
    ) &&
    identical(
      as.character(provenance$strategies),
      c("r_all", "r_1", "r_3", "r_5")
    ) &&
    grepl("^R version 4\\.5\\.3 ", as.character(provenance$r_version)) &&
    identical(as.character(provenance$rcarbon_version), "1.5.2") &&
    identical(as.character(provenance$container_image_id), sensitivity_image_id)
  if (!valid_scenario || !valid_design || any(!valid_provenance_md5) ||
      !identical(provenance_md5, expected_provenance_md5)) {
    stop(
      "Observation-noise checkpoint provenance is fingerprint-inconsistent: ",
      rds_name,
      call. = FALSE
    )
  }
  common_provenance <- provenance[setdiff(
    names(provenance),
    c("true_model", "prop")
  )]
  if (is.null(sensitivity_common_provenance)) {
    sensitivity_common_provenance <- common_provenance
  } else if (!identical(common_provenance, sensitivity_common_provenance)) {
    stop(
      "Observation-noise checkpoints do not share common provenance.",
      call. = FALSE
    )
  }

  sensitivity_validation_env$validate_observation_noise_sensitivity_results(
    checkpoint$results,
    nsim = 1000L,
    strategies = c("r_all", "r_1", "r_3", "r_5")
  )
  sensitivity_validation_env$validate_observation_noise_pair_manifest(
    checkpoint$pair_manifest,
    nsim = 1000L
  )
  if (any(
    checkpoint$pair_manifest$expectation_observation_hash ==
      checkpoint$pair_manifest$realised_observation_hash
  )) {
    stop(
      "Observation-noise checkpoint contains an unchanged realised assay arm: ",
      rds_name,
      call. = FALSE
    )
  }
  result_pair_hashes <- unique(checkpoint$results[c(
    "pair_id",
    "structure_hash",
    "selection_hash"
  )])
  manifest_pair_hashes <- checkpoint$pair_manifest[c(
    "pair_id",
    "structure_hash",
    "selection_hash"
  )]
  result_pair_hashes <- result_pair_hashes[order(result_pair_hashes$pair_id), ]
  manifest_pair_hashes <- manifest_pair_hashes[order(manifest_pair_hashes$pair_id), ]
  rownames(result_pair_hashes) <- NULL
  rownames(manifest_pair_hashes) <- NULL
  if (!identical(result_pair_hashes, manifest_pair_hashes)) {
    stop(
      "Observation-noise result hashes conflict with the pair manifest: ",
      rds_name,
      call. = FALSE
    )
  }
  if (!identical(
    sort(unique(as.character(checkpoint$results$true))),
    expected_model
  ) ||
      !isTRUE(all(
        abs(unique(checkpoint$results$prop) - as.numeric(expected_prop)) <
          sqrt(.Machine$double.eps)
      )) ||
      !identical(
        sort(unique(as.character(checkpoint$results$pair_id))),
        sort(as.character(checkpoint$pair_manifest$pair_id))
      )) {
    stop(
      "Observation-noise checkpoint results conflict with scenario or pairing metadata: ",
      rds_name,
      call. = FALSE
    )
  }

  pair_csv <- utils::read.csv(
    pair_path,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  pair_rds <- as.data.frame(checkpoint$pair_manifest)
  if (!identical(names(pair_csv), names(pair_rds)) ||
      !isTRUE(all.equal(
        pair_csv,
        pair_rds,
        check.attributes = FALSE,
        tolerance = 1e-12
      ))) {
    stop(
      "Observation-noise pair CSV conflicts with its checkpoint: ",
      pair_name,
      call. = FALSE
    )
  }

  metadata_lines <- readLines(metadata_path, warn = FALSE)
  metadata <- read_key_value_metadata(
    metadata_path,
    paste("Observation-noise metadata", metadata_name)
  )
  if (length(metadata_lines) != length(sensitivity_sidecar_fields) + 1L ||
      !identical(
        metadata_lines[[1L]],
        "rc-dates paired observation-noise sensitivity"
      ) ||
      !identical(names(metadata), sensitivity_sidecar_fields) ||
      !grepl(
        "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} UTC$",
        metadata[["generation_completed_utc"]]
      )) {
    stop(
      "Observation-noise sidecar has an unexpected schema: ",
      metadata_name,
      call. = FALSE
    )
  }
  validate_md5_metadata(
    metadata,
    c(
      sensitivity_provenance_md5_paths,
      output_md5 = file.path(sensitivity_root, rds_name),
      pair_manifest_md5 = file.path(sensitivity_root, pair_name)
    ),
    paste("Observation-noise metadata", metadata_name)
  )
  provenance_character_fields <- c(
    "r_version",
    "rcarbon_version",
    "sensitivity_design",
    "assay_equation",
    "window_exclusion_rule",
    "rng_kind",
    "stream_mapping",
    "container_image_id",
    names(sensitivity_provenance_md5_paths)
  )
  recorded_provenance_values <- vapply(
    provenance[provenance_character_fields],
    as.character,
    character(1)
  )
  metadata_scenario_valid <-
    identical(metadata[["schema_version"]], "1") &&
    identical(metadata[["true_model"]], expected_model) &&
    isTRUE(abs(
      as.numeric(metadata[["site_subsampling_proportion"]]) -
        as.numeric(expected_prop)
    ) < sqrt(.Machine$double.eps)) &&
    identical(metadata[["paired_replicates"]], "1000") &&
    identical(metadata[["master_seed"]], "1234") &&
    identical(metadata[["strategies"]], "r_all,r_1,r_3,r_5")
  recorded_sidecar_packages <- read_named_inventory(
    metadata[["packages"]],
    sensitivity_sidecar_package_names,
    "^[0-9][0-9A-Za-z.+-]*$",
    paste("Observation-noise package inventory", metadata_name)
  )
  if (is.null(sensitivity_sidecar_package_versions)) {
    sensitivity_sidecar_package_versions <- recorded_sidecar_packages
  }
  if (!metadata_scenario_valid ||
      !identical(recorded_sidecar_packages[["rcarbon"]], "1.5.2") ||
      !identical(
        recorded_sidecar_packages,
        sensitivity_sidecar_package_versions
      ) ||
      !identical(
        unname(metadata[provenance_character_fields]),
        unname(recorded_provenance_values)
      )) {
    stop(
      "Observation-noise sidecar conflicts with checkpoint provenance: ",
      metadata_name,
      call. = FALSE
    )
  }
}

sensitivity_summary_metadata_fields <- c(
  "schema_version",
  "generation_completed_utc",
  "r_version",
  "rcarbon_version",
  "paired_replicates",
  "bootstrap_resamples",
  "bootstrap_seed",
  "bootstrap_interval",
  "strategies",
  "gate_status",
  "gate_names",
  "summary_source_md5",
  "summary_runner_md5",
  "frozen_snapshot_inventory_sha256",
  "input_md5",
  "renv_lock_md5",
  "container_image_id",
  "checkpoint_md5s",
  "pair_manifest_md5s",
  "metadata_md5s",
  "packages"
)
sensitivity_summary_metadata_path <- file.path(
  sensitivity_summary_root,
  "observation_noise_summary_metadata.txt"
)
sensitivity_summary_metadata_lines <- readLines(
  sensitivity_summary_metadata_path,
  warn = FALSE
)
sensitivity_summary_metadata <- read_key_value_metadata(
  sensitivity_summary_metadata_path,
  "Observation-noise summary metadata"
)
if (length(sensitivity_summary_metadata_lines) !=
      length(sensitivity_summary_metadata_fields) + 1L ||
    !identical(
      sensitivity_summary_metadata_lines[[1L]],
      "rc-dates paired observation-noise sensitivity summary"
    ) ||
    !identical(
      names(sensitivity_summary_metadata),
      sensitivity_summary_metadata_fields
    ) ||
    !grepl(
      "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} UTC$",
      sensitivity_summary_metadata[["generation_completed_utc"]]
    )) {
  stop(
    "Observation-noise summary metadata have an unexpected schema.",
    call. = FALSE
  )
}

expected_summary_md5 <- c(
  summary_source_md5 = unname(tools::md5sum(file.path(
    repo_root,
    "R",
    "observation_noise_summaries.R"
  ))),
  summary_runner_md5 = unname(tools::md5sum(file.path(
    repo_root,
    "scripts",
    "summarise_observation_noise_sensitivity.R"
  ))),
  input_md5 = unname(tools::md5sum(file.path(
    repo_root,
    "data",
    "austarch_filtered.csv"
  ))),
  renv_lock_md5 = unname(tools::md5sum(file.path(repo_root, "renv.lock")))
)
expected_frozen_inventory_sha256 <- digest::digest(
  file.path(sensitivity_snapshot_root, "SHA256SUMS"),
  algo = "sha256",
  serialize = FALSE,
  file = TRUE
)
valid_summary_metadata <- identical(
  sensitivity_summary_metadata[["schema_version"]],
  "1"
) &&
  identical(
    sensitivity_summary_metadata[["r_version"]],
    "R version 4.5.3 (2026-03-11)"
  ) &&
  identical(sensitivity_summary_metadata[["rcarbon_version"]], "1.5.2") &&
  identical(sensitivity_summary_metadata[["paired_replicates"]], "1000") &&
  identical(sensitivity_summary_metadata[["bootstrap_resamples"]], "5000") &&
  identical(sensitivity_summary_metadata[["bootstrap_seed"]], "1234") &&
  identical(
    sensitivity_summary_metadata[["bootstrap_interval"]],
    "paired_simulation_cluster_max_deviation_95"
  ) &&
  identical(
    sensitivity_summary_metadata[["strategies"]],
    "r_all,r_1,r_3,r_5"
  ) &&
  identical(
    unname(sensitivity_summary_metadata[names(expected_summary_md5)]),
    unname(expected_summary_md5)
  ) &&
  identical(
    sensitivity_summary_metadata[["frozen_snapshot_inventory_sha256"]],
    expected_frozen_inventory_sha256
  ) &&
  identical(
    sensitivity_summary_metadata[["container_image_id"]],
    sensitivity_image_id
  )
if (!valid_summary_metadata) {
  stop(
    "Observation-noise summary metadata conflict with the locked analysis.",
    call. = FALSE
  )
}

recorded_summary_checkpoint_md5 <- read_named_inventory(
  sensitivity_summary_metadata[["checkpoint_md5s"]],
  sensitivity_rds_names,
  "^[0-9a-f]{32}$",
  "Observation-noise summary checkpoint inventory"
)
recorded_summary_pair_md5 <- read_named_inventory(
  sensitivity_summary_metadata[["pair_manifest_md5s"]],
  sensitivity_pair_names,
  "^[0-9a-f]{32}$",
  "Observation-noise summary pair-manifest inventory"
)
recorded_summary_sidecar_md5 <- read_named_inventory(
  sensitivity_summary_metadata[["metadata_md5s"]],
  sensitivity_metadata_names,
  "^[0-9a-f]{32}$",
  "Observation-noise summary sidecar inventory"
)
actual_summary_checkpoint_md5 <- unname(tools::md5sum(file.path(
  sensitivity_root_path,
  sensitivity_rds_names
)))
actual_summary_pair_md5 <- unname(tools::md5sum(file.path(
  sensitivity_root_path,
  sensitivity_pair_names
)))
actual_summary_sidecar_md5 <- unname(tools::md5sum(file.path(
  sensitivity_root_path,
  sensitivity_metadata_names
)))
if (!identical(
  unname(recorded_summary_checkpoint_md5),
  actual_summary_checkpoint_md5
) ||
    !identical(
      unname(recorded_summary_pair_md5),
      actual_summary_pair_md5
    ) ||
    !identical(
      unname(recorded_summary_sidecar_md5),
      actual_summary_sidecar_md5
    )) {
  stop(
    "Observation-noise summary metadata do not inventory the supplied inputs.",
    call. = FALSE
  )
}

sensitivity_summary_package_names <- c(
  "digest",
  "jsonlite",
  "rcarbon",
  "readr"
)
recorded_summary_packages <- read_named_inventory(
  sensitivity_summary_metadata[["packages"]],
  sensitivity_summary_package_names,
  "^[0-9][0-9A-Za-z.+-]*$",
  "Observation-noise summary package inventory"
)
if (!identical(recorded_summary_packages[["rcarbon"]], "1.5.2") ||
    !identical(
      unname(recorded_summary_packages[c("digest", "rcarbon", "readr")]),
      unname(sensitivity_sidecar_package_versions[c(
        "digest",
        "rcarbon",
        "readr"
      )])
    )) {
  stop(
    "Observation-noise summary package inventory conflicts with the matrix run.",
    call. = FALSE
  )
}

sensitivity_gate_fields <- c(
  "gate",
  "pass",
  "observed",
  "threshold",
  "details",
  "recommendation"
)
sensitivity_gate_rds <- readRDS(file.path(
  sensitivity_summary_root,
  "observation_noise_gate_report.rds"
))
sensitivity_gate_csv <- utils::read.csv(
  file.path(sensitivity_summary_root, "observation_noise_gate_report.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE,
  colClasses = c(
    "character",
    "logical",
    "numeric",
    "numeric",
    "character",
    "character"
  ),
  na.strings = "NA"
)
sensitivity_gate_json <- jsonlite::fromJSON(
  file.path(sensitivity_summary_root, "observation_noise_gate_report.json"),
  simplifyDataFrame = TRUE
)
valid_gate_schema <- is.data.frame(sensitivity_gate_rds) &&
  identical(names(sensitivity_gate_rds), sensitivity_gate_fields) &&
  identical(sensitivity_gate_rds$gate, sensitivity_gate_names) &&
  is.logical(sensitivity_gate_rds$pass) &&
  is.numeric(sensitivity_gate_rds$observed) &&
  is.numeric(sensitivity_gate_rds$threshold) &&
  is.character(sensitivity_gate_rds$details) &&
  is.character(sensitivity_gate_rds$recommendation) &&
  !anyNA(sensitivity_gate_rds$pass) &&
  all(is.finite(sensitivity_gate_rds$observed)) &&
  all(is.finite(sensitivity_gate_rds$threshold))
if (!valid_gate_schema ||
    !isTRUE(all.equal(
      sensitivity_gate_csv,
      sensitivity_gate_rds,
      check.attributes = FALSE,
      tolerance = 100 * .Machine$double.eps
    )) ||
    !isTRUE(all.equal(
      sensitivity_gate_json,
      sensitivity_gate_rds,
      check.attributes = FALSE,
      tolerance = 100 * .Machine$double.eps
    ))) {
  stop(
    "Observation-noise gate-report CSV, JSON, and RDS evidence are inconsistent.",
    call. = FALSE
  )
}

expected_gate_status <- if (all(sensitivity_gate_rds$pass)) "PASS" else "FAIL"
if (!identical(
  sensitivity_summary_metadata[["gate_status"]],
  expected_gate_status
) ||
    !identical(
      sensitivity_summary_metadata[["gate_names"]],
      paste(sensitivity_gate_names, collapse = ",")
    )) {
  stop(
    "Observation-noise summary metadata conflict with the gate report.",
    call. = FALSE
  )
}

sensitivity_gate_markdown <- readLines(
  file.path(sensitivity_summary_root, "observation_noise_gate_report.md"),
  warn = FALSE
)
expected_markdown_status <- paste0("Status: **", expected_gate_status, "**")
expected_markdown_rows <- apply(sensitivity_gate_rds, 1L, function(row) {
  paste0(
    "| ",
    row[["gate"]],
    " | ",
    row[["pass"]],
    " | ",
    row[["observed"]],
    " | ",
    row[["threshold"]],
    " | ",
    row[["details"]],
    " |"
  )
})
observed_markdown_status <- grep(
  "^Status: \\*\\*(PASS|FAIL)\\*\\*$",
  sensitivity_gate_markdown,
  value = TRUE
)
observed_markdown_rows <- sensitivity_gate_markdown[grepl(
  "^\\| [a-z0-9_]+ \\|",
  sensitivity_gate_markdown
)]
if (!identical(observed_markdown_status, expected_markdown_status) ||
    !identical(observed_markdown_rows, unname(expected_markdown_rows))) {
  stop(
    "Observation-noise Markdown gate report conflicts with structured evidence.",
    call. = FALSE
  )
}

sensitivity_v2_metadata_fields <- c(
  "analysis_label",
  "schema_version",
  "generation_completed_utc",
  "r_version",
  "rcarbon_version",
  "paired_replicates",
  "bootstrap_resamples",
  "master_seed",
  "stability_master_seed",
  "accuracy_seed_offset",
  "ose_seed_offset",
  "boundary_seed_offset",
  "accuracy_ose_interval",
  "boundary_interval",
  "difference_family",
  "boundary_difference_family",
  "v2_gate_status",
  "stability_status",
  "v1_gate_status",
  "v1_gate_pass_count",
  "v1_gate_fail_count",
  "v1_failed_gates",
  "v1_fail_retained",
  "v1_summary_source_md5",
  "v1_summary_runner_md5",
  "v2_source_md5",
  "v2_runner_md5",
  "checkpoint_md5s",
  "pair_manifest_md5s",
  "v1_summary_metadata_md5",
  "packages"
)
sensitivity_v2_metadata_path <- file.path(sensitivity_v2_root_path, "metadata.txt")
sensitivity_v2_metadata_lines <- readLines(
  sensitivity_v2_metadata_path,
  warn = FALSE
)
sensitivity_v2_metadata <- read_key_value_metadata(
  sensitivity_v2_metadata_path,
  "Estimand-aligned v2 metadata"
)
if (length(sensitivity_v2_metadata_lines) !=
      length(sensitivity_v2_metadata_fields) ||
    !identical(names(sensitivity_v2_metadata), sensitivity_v2_metadata_fields) ||
    !grepl(
      "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} UTC$",
      sensitivity_v2_metadata[["generation_completed_utc"]]
    )) {
  stop("Estimand-aligned v2 metadata have an unexpected schema.", call. = FALSE)
}

sensitivity_v2_failed_v1_gates <- c(
  "accuracy_difference_ci",
  "ose_support_difference_ci",
  "boundary_hit_increase"
)
if (!identical(expected_gate_status, "FAIL") ||
    sum(sensitivity_gate_rds$pass) != 15L ||
    !identical(
      sensitivity_gate_rds$gate[!sensitivity_gate_rds$pass],
      sensitivity_v2_failed_v1_gates
    )) {
  stop(
    "The supplied v1 gate report is not the exact retained 15/18 FAIL.",
    call. = FALSE
  )
}
sensitivity_v2_expected_md5 <- c(
  v2_source_md5 = unname(tools::md5sum(file.path(
    repo_root,
    "R",
    "observation_noise_estimand_aligned.R"
  ))),
  v2_runner_md5 = unname(tools::md5sum(file.path(
    repo_root,
    "scripts",
    "summarise_observation_noise_estimand_aligned.R"
  ))),
  v1_summary_metadata_md5 = unname(tools::md5sum(
    sensitivity_summary_metadata_path
  ))
)
sensitivity_v2_metadata_valid <-
  identical(
    sensitivity_v2_metadata[["analysis_label"]],
    "post_unblinding_estimand_aligned_v2"
  ) &&
  identical(sensitivity_v2_metadata[["schema_version"]], "2") &&
  identical(
    sensitivity_v2_metadata[["r_version"]],
    "R version 4.5.3 (2026-03-11)"
  ) &&
  identical(sensitivity_v2_metadata[["rcarbon_version"]], "1.5.2") &&
  identical(sensitivity_v2_metadata[["paired_replicates"]], "1000") &&
  identical(sensitivity_v2_metadata[["bootstrap_resamples"]], "50000") &&
  identical(sensitivity_v2_metadata[["master_seed"]], "1234") &&
  identical(sensitivity_v2_metadata[["stability_master_seed"]], "5678") &&
  identical(sensitivity_v2_metadata[["accuracy_seed_offset"]], "0") &&
  identical(sensitivity_v2_metadata[["ose_seed_offset"]], "10") &&
  identical(sensitivity_v2_metadata[["boundary_seed_offset"]], "60") &&
  identical(
    sensitivity_v2_metadata[["accuracy_ose_interval"]],
    "paired_simulation_cluster_difference_max_deviation_95"
  ) &&
  identical(
    sensitivity_v2_metadata[["boundary_interval"]],
    "paired_simulation_cluster_maximum_positive_deviation_upper_95"
  ) &&
  identical(
    sensitivity_v2_metadata[["difference_family"]],
    "accuracy,ose (96 cells each)"
  ) &&
  identical(
    sensitivity_v2_metadata[["boundary_difference_family"]],
    "72 cells"
  ) &&
  sensitivity_v2_metadata[["v2_gate_status"]] %in% c("PASS", "FAIL") &&
  identical(sensitivity_v2_metadata[["stability_status"]], "AGREE") &&
  identical(
    sensitivity_v2_metadata[["v1_gate_status"]],
    expected_gate_status
  ) &&
  identical(
    sensitivity_v2_metadata[["v1_gate_pass_count"]],
    as.character(sum(sensitivity_gate_rds$pass))
  ) &&
  identical(
    sensitivity_v2_metadata[["v1_gate_fail_count"]],
    as.character(sum(!sensitivity_gate_rds$pass))
  ) &&
  identical(
    sensitivity_v2_metadata[["v1_failed_gates"]],
    paste(sensitivity_v2_failed_v1_gates, collapse = ",")
  ) &&
  identical(sensitivity_v2_metadata[["v1_fail_retained"]], "TRUE") &&
  identical(
    sensitivity_v2_metadata[["v1_summary_source_md5"]],
    sensitivity_summary_metadata[["summary_source_md5"]]
  ) &&
  identical(
    sensitivity_v2_metadata[["v1_summary_runner_md5"]],
    sensitivity_summary_metadata[["summary_runner_md5"]]
  ) &&
  identical(
    unname(sensitivity_v2_metadata[names(sensitivity_v2_expected_md5)]),
    unname(sensitivity_v2_expected_md5)
  )
if (!sensitivity_v2_metadata_valid) {
  stop(
    paste(
      "Estimand-aligned v2 metadata conflict with the locked runtime,",
      "resampling design, source fingerprints, or retained v1 FAIL."
    ),
    call. = FALSE
  )
}

sensitivity_v2_checkpoint_md5 <- read_named_inventory(
  sensitivity_v2_metadata[["checkpoint_md5s"]],
  sensitivity_rds_names,
  "^[0-9a-f]{32}$",
  "Estimand-aligned v2 checkpoint inventory"
)
sensitivity_v2_pair_md5 <- read_named_inventory(
  sensitivity_v2_metadata[["pair_manifest_md5s"]],
  sensitivity_pair_names,
  "^[0-9a-f]{32}$",
  "Estimand-aligned v2 pair-manifest inventory"
)
if (!identical(
  unname(sensitivity_v2_checkpoint_md5),
  unname(tools::md5sum(file.path(sensitivity_root_path, sensitivity_rds_names)))
) ||
    !identical(
      unname(sensitivity_v2_pair_md5),
      unname(tools::md5sum(file.path(
        sensitivity_root_path,
        sensitivity_pair_names
      )))
    )) {
  stop(
    "Estimand-aligned v2 metadata do not inventory the supplied paired inputs.",
    call. = FALSE
  )
}

sensitivity_v2_package_names <- c("digest", "jsonlite", "readr")
sensitivity_v2_packages <- read_named_inventory(
  sensitivity_v2_metadata[["packages"]],
  sensitivity_v2_package_names,
  "^[0-9][0-9A-Za-z.+-]*$",
  "Estimand-aligned v2 package inventory"
)
if (!identical(
  unname(sensitivity_v2_packages),
  unname(recorded_summary_packages[sensitivity_v2_package_names])
)) {
  stop(
    "Estimand-aligned v2 package inventory conflicts with the locked v1 run.",
    call. = FALSE
  )
}

sensitivity_v2_metric_fields <- c(
  "metric_family",
  "metric",
  "scope",
  "true",
  "prop",
  "strategy",
  "type",
  "arm",
  "estimate",
  "ci_low",
  "ci_high",
  "margin",
  "interval",
  "n_clusters"
)
sensitivity_v2_metrics <- utils::read.csv(
  file.path(sensitivity_v2_root_path, "metrics.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE,
  colClasses = c(
    "character",
    "character",
    "character",
    "character",
    "numeric",
    "character",
    "character",
    "character",
    "numeric",
    "numeric",
    "numeric",
    "numeric",
    "character",
    "numeric"
  ),
  na.strings = c("", "NA")
)
sensitivity_v2_metric_names <- c(
  accuracy = "minimum_aic_accuracy",
  ose = "unique_ose_support",
  boundary = "optimizer_boundary_hit"
)
sensitivity_v2_interval_names <- c(
  accuracy = "two_sided_max_deviation_95",
  ose = "two_sided_max_deviation_95",
  boundary = "one_sided_maximum_positive_deviation_upper_95"
)
sensitivity_v2_expected_counts <- c(
  accuracy = 96L,
  ose = 96L,
  boundary = 72L
)
sensitivity_v2_expected_cells <- do.call(rbind, lapply(
  names(sensitivity_v2_expected_counts),
  function(family) {
    scopes <- if (identical(family, "boundary")) {
      c("pooled", "lin", "exp")
    } else {
      c("pooled", "uni", "lin", "exp")
    }
    cells <- expand.grid(
      metric_family = family,
      scope = scopes,
      prop = c(0.5, 0.75, 1),
      strategy = c("r_all", "r_1", "r_3", "r_5"),
      type = c("l1", "l2"),
      KEEP.OUT.ATTRS = FALSE,
      stringsAsFactors = FALSE
    )
    cells$true <- ifelse(cells$scope == "pooled", NA_character_, cells$scope)
    cells
  }
))
sensitivity_v2_cell_key <- function(data) {
  paste(
    data$metric_family,
    data$scope,
    ifelse(is.na(data$true), "<NA>", data$true),
    sprintf("%.2f", data$prop),
    data$strategy,
    data$type,
    sep = "|"
  )
}
sensitivity_v2_actual_cell_keys <- sensitivity_v2_cell_key(
  sensitivity_v2_metrics
)
sensitivity_v2_expected_cell_keys <- sensitivity_v2_cell_key(
  sensitivity_v2_expected_cells
)
sensitivity_v2_family_counts <- vapply(
  names(sensitivity_v2_expected_counts),
  function(family) {
    sum(sensitivity_v2_metrics$metric_family == family)
  },
  integer(1)
)
sensitivity_v2_metric_schema_valid <-
  identical(names(sensitivity_v2_metrics), sensitivity_v2_metric_fields) &&
  identical(nrow(sensitivity_v2_metrics), 264L) &&
  identical(
    unname(sensitivity_v2_family_counts),
    unname(sensitivity_v2_expected_counts)
  ) &&
  !anyDuplicated(sensitivity_v2_actual_cell_keys) &&
  setequal(
    sensitivity_v2_actual_cell_keys,
    sensitivity_v2_expected_cell_keys
  ) &&
  identical(unique(sensitivity_v2_metrics$arm), "difference") &&
  all(sensitivity_v2_metrics$n_clusters == 1000) &&
  all(is.finite(sensitivity_v2_metrics$estimate)) &&
  all(is.finite(sensitivity_v2_metrics$ci_high)) &&
  all(is.finite(sensitivity_v2_metrics$margin)) &&
  all(sensitivity_v2_metrics$margin >= 0)
if (!sensitivity_v2_metric_schema_valid) {
  stop(
    paste(
      "Estimand-aligned v2 metrics do not contain the exact 264-cell",
      "difference-only family."
    ),
    call. = FALSE
  )
}
for (family in names(sensitivity_v2_expected_counts)) {
  family_rows <- sensitivity_v2_metrics[
    sensitivity_v2_metrics$metric_family == family,
    ,
    drop = FALSE
  ]
  if (!identical(unique(family_rows$metric), sensitivity_v2_metric_names[[family]]) ||
      !identical(
        unique(family_rows$interval),
        sensitivity_v2_interval_names[[family]]
      )) {
    stop(
      "Estimand-aligned v2 metric or interval label is inconsistent: ",
      family,
      call. = FALSE
    )
  }
  if (identical(family, "boundary")) {
    interval_valid <- all(is.na(family_rows$ci_low)) &&
      isTRUE(all.equal(
        family_rows$ci_high,
        family_rows$estimate + family_rows$margin,
        tolerance = 100 * .Machine$double.eps
      ))
  } else {
    interval_valid <- all(is.finite(family_rows$ci_low)) &&
      all(family_rows$ci_low <= family_rows$estimate) &&
      all(family_rows$estimate <= family_rows$ci_high) &&
      isTRUE(all.equal(
        family_rows$ci_low,
        family_rows$estimate - family_rows$margin,
        tolerance = 100 * .Machine$double.eps
      )) &&
      isTRUE(all.equal(
        family_rows$ci_high,
        family_rows$estimate + family_rows$margin,
        tolerance = 100 * .Machine$double.eps
      ))
  }
  if (!interval_valid) {
    stop(
      "Estimand-aligned v2 interval contract is inconsistent: ",
      family,
      call. = FALSE
    )
  }
}

sensitivity_v2_gate_names <- c(
  "accuracy_difference",
  "ose_difference",
  "boundary_difference"
)
sensitivity_v2_gate_fields <- c(
  "gate",
  "pass",
  "pooled_max",
  "truth_max",
  "threshold_pooled",
  "threshold_truth",
  "pooled_margin",
  "truth_margin",
  "details"
)
sensitivity_v2_gate_rds <- readRDS(
  file.path(sensitivity_v2_root_path, "gate_report.rds")
)
sensitivity_v2_gate_csv <- utils::read.csv(
  file.path(sensitivity_v2_root_path, "gate_report.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE,
  colClasses = c(
    "character",
    "logical",
    rep("numeric", 6L),
    "character"
  ),
  na.strings = "NA"
)
sensitivity_v2_gate_json <- jsonlite::fromJSON(
  file.path(sensitivity_v2_root_path, "gate_report.json"),
  simplifyDataFrame = TRUE
)
sensitivity_v2_gate_numeric_fields <- c(
  "pooled_max",
  "truth_max",
  "threshold_pooled",
  "threshold_truth",
  "pooled_margin",
  "truth_margin"
)
sensitivity_v2_gate_details <- c(
  "Two-sided max-deviation interval on paired difference estimands only.",
  "Two-sided max-deviation interval on paired difference estimands only.",
  "One-sided upper bound on maximum positive boundary difference."
)
sensitivity_v2_gate_schema_valid <-
  is.data.frame(sensitivity_v2_gate_rds) &&
  identical(names(sensitivity_v2_gate_rds), sensitivity_v2_gate_fields) &&
  identical(sensitivity_v2_gate_rds$gate, sensitivity_v2_gate_names) &&
  is.logical(sensitivity_v2_gate_rds$pass) &&
  !anyNA(sensitivity_v2_gate_rds$pass) &&
  all(vapply(
    sensitivity_v2_gate_rds[sensitivity_v2_gate_numeric_fields],
    is.numeric,
    logical(1)
  )) &&
  all(is.finite(as.matrix(
    sensitivity_v2_gate_rds[sensitivity_v2_gate_numeric_fields]
  ))) &&
  identical(sensitivity_v2_gate_rds$details, sensitivity_v2_gate_details) &&
  isTRUE(all.equal(
    sensitivity_v2_gate_csv,
    sensitivity_v2_gate_rds,
    check.attributes = FALSE,
    tolerance = 100 * .Machine$double.eps
  )) &&
  isTRUE(all.equal(
    sensitivity_v2_gate_json,
    sensitivity_v2_gate_rds,
    check.attributes = FALSE,
    tolerance = 100 * .Machine$double.eps
  ))
if (!sensitivity_v2_gate_schema_valid) {
  stop(
    "Estimand-aligned v2 gate-report CSV, JSON, and RDS evidence are inconsistent.",
    call. = FALSE
  )
}

sensitivity_v2_threshold_pooled <- c(0.03, 0.03, 0.01)
sensitivity_v2_threshold_truth <- c(0.05, 0.05, 0.01)
sensitivity_v2_metric_gate_maxima <- lapply(
  names(sensitivity_v2_expected_counts),
  function(family) {
    rows <- sensitivity_v2_metrics[
      sensitivity_v2_metrics$metric_family == family,
      ,
      drop = FALSE
    ]
    endpoint <- function(scope_rows) {
      if (identical(family, "boundary")) {
        max(scope_rows$ci_high)
      } else {
        max(abs(c(scope_rows$ci_low, scope_rows$ci_high)))
      }
    }
    c(
      pooled = endpoint(rows[rows$scope == "pooled", , drop = FALSE]),
      truth = endpoint(rows[rows$scope != "pooled", , drop = FALSE])
    )
  }
)
sensitivity_v2_metric_gate_maxima <- do.call(rbind, sensitivity_v2_metric_gate_maxima)
sensitivity_v2_expected_pass <- c(
  sensitivity_v2_gate_rds$pooled_margin[[1L]] >= 0 &&
    sensitivity_v2_gate_rds$truth_margin[[1L]] >= 0,
  sensitivity_v2_gate_rds$pooled_margin[[2L]] >= 0 &&
    sensitivity_v2_gate_rds$truth_margin[[2L]] >= 0,
  sensitivity_v2_gate_rds$pooled_margin[[3L]] > 0 &&
    sensitivity_v2_gate_rds$truth_margin[[3L]] > 0
)
sensitivity_v2_gate_values_valid <-
  isTRUE(all.equal(
    sensitivity_v2_gate_rds$threshold_pooled,
    sensitivity_v2_threshold_pooled,
    tolerance = 100 * .Machine$double.eps
  )) &&
  isTRUE(all.equal(
    sensitivity_v2_gate_rds$threshold_truth,
    sensitivity_v2_threshold_truth,
    tolerance = 100 * .Machine$double.eps
  )) &&
  isTRUE(all.equal(
    sensitivity_v2_gate_rds$pooled_max,
    sensitivity_v2_metric_gate_maxima[, "pooled"],
    tolerance = 100 * .Machine$double.eps
  )) &&
  isTRUE(all.equal(
    sensitivity_v2_gate_rds$truth_max,
    sensitivity_v2_metric_gate_maxima[, "truth"],
    tolerance = 100 * .Machine$double.eps
  )) &&
  isTRUE(all.equal(
    sensitivity_v2_gate_rds$pooled_margin,
    sensitivity_v2_gate_rds$threshold_pooled -
      sensitivity_v2_gate_rds$pooled_max,
    tolerance = 100 * .Machine$double.eps
  )) &&
  isTRUE(all.equal(
    sensitivity_v2_gate_rds$truth_margin,
    sensitivity_v2_gate_rds$threshold_truth -
      sensitivity_v2_gate_rds$truth_max,
    tolerance = 100 * .Machine$double.eps
  )) &&
  identical(sensitivity_v2_gate_rds$pass, sensitivity_v2_expected_pass)
if (!sensitivity_v2_gate_values_valid) {
  stop(
    "Estimand-aligned v2 gate values conflict with the declared metric family.",
    call. = FALSE
  )
}

sensitivity_v2_expected_gate_status <- if (all(sensitivity_v2_gate_rds$pass)) {
  "PASS"
} else {
  "FAIL"
}
if (!identical(
  sensitivity_v2_metadata[["v2_gate_status"]],
  sensitivity_v2_expected_gate_status
)) {
  stop(
    "Estimand-aligned v2 metadata conflict with the three-row gate report.",
    call. = FALSE
  )
}
sensitivity_v2_gate_markdown <- readLines(
  file.path(sensitivity_v2_root_path, "gate_report.md"),
  warn = FALSE
)
sensitivity_v2_expected_markdown_status <- paste0(
  "Status: **",
  sensitivity_v2_expected_gate_status,
  "**"
)
sensitivity_v2_expected_markdown_rows <- apply(
  sensitivity_v2_gate_rds,
  1L,
  function(row) {
    paste0(
      "| ",
      row[["gate"]],
      " | ",
      row[["pass"]],
      " | ",
      row[["pooled_max"]],
      " | ",
      row[["truth_max"]],
      " | ",
      row[["pooled_margin"]],
      " | ",
      row[["truth_margin"]],
      " |"
    )
  }
)
sensitivity_v2_observed_markdown_status <- grep(
  "^Status: \\*\\*(PASS|FAIL)\\*\\*$",
  sensitivity_v2_gate_markdown,
  value = TRUE
)
sensitivity_v2_observed_markdown_rows <- sensitivity_v2_gate_markdown[grepl(
  "^\\| (accuracy|ose|boundary)_difference \\|",
  sensitivity_v2_gate_markdown
)]
if (!identical(
  sensitivity_v2_observed_markdown_status,
  sensitivity_v2_expected_markdown_status
) ||
    !identical(
      sensitivity_v2_observed_markdown_rows,
      unname(sensitivity_v2_expected_markdown_rows)
    )) {
  stop(
    "Estimand-aligned v2 Markdown gate report conflicts with structured evidence.",
    call. = FALSE
  )
}

sensitivity_v2_stability_fields <- c(
  "gate",
  "primary_pass",
  "stability_pass",
  "status",
  "primary_width",
  "stability_width",
  "primary_pooled_max",
  "stability_pooled_max",
  "primary_truth_max",
  "stability_truth_max",
  "primary_pooled_margin",
  "stability_pooled_margin",
  "primary_truth_margin",
  "stability_truth_margin"
)
sensitivity_v2_stability <- utils::read.csv(
  file.path(sensitivity_v2_root_path, "stability.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE,
  colClasses = c(
    "character",
    "logical",
    "logical",
    "character",
    rep("numeric", 10L)
  ),
  na.strings = "NA"
)
sensitivity_v2_stability_numeric_fields <- sensitivity_v2_stability_fields[
  5:length(sensitivity_v2_stability_fields)
]
sensitivity_v2_stability_pass <- c(
  sensitivity_v2_stability$stability_pooled_margin[[1L]] >= 0 &&
    sensitivity_v2_stability$stability_truth_margin[[1L]] >= 0,
  sensitivity_v2_stability$stability_pooled_margin[[2L]] >= 0 &&
    sensitivity_v2_stability$stability_truth_margin[[2L]] >= 0,
  sensitivity_v2_stability$stability_pooled_margin[[3L]] > 0 &&
    sensitivity_v2_stability$stability_truth_margin[[3L]] > 0
)
sensitivity_v2_primary_width <- vapply(
  names(sensitivity_v2_expected_counts),
  function(family) {
    max(sensitivity_v2_metrics$margin[
      sensitivity_v2_metrics$metric_family == family
    ])
  },
  numeric(1)
)
sensitivity_v2_stability_valid <-
  identical(names(sensitivity_v2_stability), sensitivity_v2_stability_fields) &&
  identical(sensitivity_v2_stability$gate, sensitivity_v2_gate_names) &&
  all(vapply(
    sensitivity_v2_stability[sensitivity_v2_stability_numeric_fields],
    is.numeric,
    logical(1)
  )) &&
  all(is.finite(as.matrix(
    sensitivity_v2_stability[sensitivity_v2_stability_numeric_fields]
  ))) &&
  all(sensitivity_v2_stability$primary_width >= 0) &&
  all(sensitivity_v2_stability$stability_width >= 0) &&
  isTRUE(all.equal(
    sensitivity_v2_stability$primary_width,
    unname(sensitivity_v2_primary_width),
    tolerance = 100 * .Machine$double.eps
  )) &&
  identical(
    sensitivity_v2_stability$primary_pass,
    sensitivity_v2_gate_rds$pass
  ) &&
  identical(
    sensitivity_v2_stability$stability_pass,
    sensitivity_v2_stability_pass
  ) &&
  identical(
    sensitivity_v2_stability$status,
    rep("AGREE", length(sensitivity_v2_gate_names))
  ) &&
  identical(
    sensitivity_v2_stability$primary_pass,
    sensitivity_v2_stability$stability_pass
  ) &&
  isTRUE(all.equal(
    sensitivity_v2_stability$primary_pooled_max,
    sensitivity_v2_gate_rds$pooled_max,
    tolerance = 100 * .Machine$double.eps
  )) &&
  isTRUE(all.equal(
    sensitivity_v2_stability$primary_truth_max,
    sensitivity_v2_gate_rds$truth_max,
    tolerance = 100 * .Machine$double.eps
  )) &&
  isTRUE(all.equal(
    sensitivity_v2_stability$primary_pooled_margin,
    sensitivity_v2_gate_rds$pooled_margin,
    tolerance = 100 * .Machine$double.eps
  )) &&
  isTRUE(all.equal(
    sensitivity_v2_stability$primary_truth_margin,
    sensitivity_v2_gate_rds$truth_margin,
    tolerance = 100 * .Machine$double.eps
  )) &&
  isTRUE(all.equal(
    sensitivity_v2_stability$stability_pooled_margin,
    sensitivity_v2_threshold_pooled -
      sensitivity_v2_stability$stability_pooled_max,
    tolerance = 100 * .Machine$double.eps
  )) &&
  isTRUE(all.equal(
    sensitivity_v2_stability$stability_truth_margin,
    sensitivity_v2_threshold_truth -
      sensitivity_v2_stability$stability_truth_max,
    tolerance = 100 * .Machine$double.eps
  ))
if (!sensitivity_v2_stability_valid) {
  stop(
    paste(
      "Estimand-aligned v2 independent-seed stability evidence does not",
      "retain finite widths, maxima, margins, and AGREE statuses."
    ),
    call. = FALSE
  )
}

sensitivity_v2_v1_interpretation <- readLines(
  file.path(sensitivity_v2_root_path, "v1_interpretation.md"),
  warn = FALSE
)
if (sum(
  sensitivity_v2_v1_interpretation ==
    "The original v1 summary remains **FAIL (15 of 18 gates passed)**."
) != 1L ||
    !any(grepl(
      "does not replace or retroactively pass the original v1 decision",
      sensitivity_v2_v1_interpretation,
      fixed = TRUE
    ))) {
  stop(
    "Estimand-aligned v2 interpretation does not preserve the formal v1 FAIL.",
    call. = FALSE
  )
}

if (!dir.exists(package_parent)) {
  dir.create(package_parent, recursive = TRUE, showWarnings = FALSE)
}

if (basename(package_dir) != package_name) {
  stop("Refusing to remove unexpected package directory: ", package_dir, call. = FALSE)
}

if (dir.exists(package_dir)) {
  unlink(package_dir, recursive = TRUE, force = TRUE)
}
dir.create(package_dir, recursive = TRUE, showWarnings = FALSE)

copy_file <- function(from, to = from) {
  src <- file.path(repo_root, from)
  dst <- file.path(package_dir, to)
  dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
  ok <- file.copy(src, dst, overwrite = TRUE, copy.date = TRUE)
  if (!isTRUE(ok)) stop("Failed to copy file: ", from, call. = FALSE)
}

copy_dir <- function(from, to = from) {
  src <- file.path(repo_root, from)
  dst <- file.path(package_dir, to)
  dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
  if (dir.exists(dst)) unlink(dst, recursive = TRUE, force = TRUE)
  ok <- file.copy(src, dirname(dst), recursive = TRUE, copy.date = TRUE)
  if (!isTRUE(ok)) stop("Failed to copy directory: ", from, call. = FALSE)
}

write_text <- function(path, lines) {
  dst <- file.path(package_dir, path)
  dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, dst, useBytes = TRUE)
}

for (dir in required_dirs) copy_dir(dir)

for (file in c(
  "_targets.R",
  "dependencies.R",
  ".dockerignore",
  ".gitattributes",
  ".lintr",
  "LICENSE",
  "renv.lock",
  "renv/.gitignore",
  "renv/activate.R",
  "renv/settings.json",
  "scripts/bootstrap.R",
  "scripts/run_population_simulation.R",
  "scripts/run_production_simulation_matrix.sh",
  "scripts/render_population_simulation_figures.R",
  "scripts/render_manuscript_methods_figures.R",
  "scripts/run_observation_noise_sensitivity.R",
  "scripts/run_observation_noise_sensitivity_matrix.sh",
  "scripts/summarise_observation_noise_estimand_aligned.R",
  "scripts/summarise_observation_noise_sensitivity.R",
  "docker/production-simulation.Dockerfile",
  "docker/install-production-packages.R"
)) {
  copy_file(file)
}

for (file in production_files) copy_file(file)
for (file in empirical_summary_files) copy_file(file)
for (index in seq_along(empirical_figure_sources)) {
  copy_file(
    empirical_figure_sources[[index]],
    file.path("figures", basename(empirical_figure_sources[[index]]))
  )
}
for (file in file.path(sensitivity_root, sensitivity_checksum_names)) {
  copy_file(file)
}
copy_file(file.path(sensitivity_root, "SHA256SUMS"))

review_config_path <- file.path(package_dir, "config", "config.yml")
review_config <- yaml::read_yaml(review_config_path)
for (profile in intersect(c("default", "testthat"), names(review_config))) {
  review_config[[profile]]$branching$site$limit <- 12L
}
yaml::write_yaml(review_config, review_config_path)

dir.create(file.path(package_dir, "data"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(package_dir, "metadata"), recursive = TRUE, showWarnings = FALSE)

raw_path <- file.path(repo_root, "data/Austarch_1-3_and_IDASQ_28Nov13-1.csv")
raw <- utils::read.csv(raw_path, check.names = FALSE, stringsAsFactors = FALSE)

review_cols <- c(
  "ADSID",
  "LONGITUDE",
  "LATITUDE",
  "SITE",
  "SITE_TYPE",
  "LAB_CODE",
  "AGE",
  "ERROR",
  "MATERIAL",
  "METHOD",
  "Data pertinent for time-series analysis or calibration",
  "Open or Closed Site",
  "Directly Related to occupation? Yes/Unknown",
  "RECORD_SOURCE",
  "DATE_ISSUES"
)

missing_cols <- setdiff(review_cols, names(raw))
if (length(missing_cols) > 0L) {
  stop("Raw data missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
}

review_input <- raw[review_cols]
review_input$RECORD_SOURCE <- "deidentified_review_input"

utils::write.csv(
  review_input,
  file.path(package_dir, "data/austarch_input_deidentified.csv"),
  row.names = FALSE,
  na = ""
)
copy_file("data/austarch_filtered.csv", "data/austarch_filtered.csv")

write_text(
  "metadata/data_manifest.csv",
  c(
    "id,path",
    "austarch_deidentified,data/austarch_input_deidentified.csv"
  )
)
write_text(
  "metadata/example_manifest.csv",
  c(
    "id,path",
    "example,inst/extdata/austarch_example.csv"
  )
)

trim_review_targets <- function(path) {
  target_path <- file.path(package_dir, path)
  txt <- paste(readLines(target_path, warn = FALSE), collapse = "\n")
  trimmed <- sub(
    ",\n  targets::tar_target\\(\n    report_qmd,[\\s\\S]*\n  \\)\n\\)$",
    "\n)",
    txt,
    perl = TRUE
  )
  if (identical(trimmed, txt)) {
    stop("Failed to trim report targets from ", path, call. = FALSE)
  }
  writeLines(trimmed, target_path, useBytes = TRUE)
}

trim_review_targets("_targets.R")

write_text(
  "tests/testthat/test_pipeline.R",
  c(
    "test_that(\"targets pipeline declares expected analysis targets\", {",
    "  script_path <- resolve_path(\"_targets.R\")",
    "  mf <- targets::tar_manifest(script = script_path, callr_function = NULL)",
    "  expect_true(all(c(",
    "    \"cfg\", \"raw_manifest\", \"raw_files\", \"raw_tbl\", \"validated\",",
    "    \"sim_mode\", \"demo_sim_specs\", \"demo_sim_summary_files\",",
    "    \"sim_precomputed_manifest\", \"sim_manifest\", \"interim_parquet\",",
    "    \"model_fit\"",
    "  ) %in% mf$name))",
    "})"
  )
)

write_text(
  ".Rprofile",
  c(
    "if (file.exists(\"renv/activate.R\")) {",
    "  source(\"renv/activate.R\")",
    "}"
  )
)

write_text(
  ".gitignore",
  c(
    ".Rproj.user/",
    ".Rhistory",
    ".RData",
    "_targets/",
    "figs/",
    "outputs/",
    "figures/rebuilt/",
    "out/rebuilt/",
    "out/sensitivity-rerun/",
    "renv/library/",
    "renv/staging/",
    ".quarto/",
    "*.html",
    "*.log"
  )
)

write_text(
  "Makefile",
  c(
    "DEFAULT_RSCRIPT := $(firstword $(wildcard /usr/local/bin/Rscript) Rscript)",
    "RSCRIPT ?= $(DEFAULT_RSCRIPT)",
    "R_VERSION_REQUIRED ?= 4.5.3",
    "OBSERVATION_NOISE_INPUT_DIR ?= out/sensitivity/observation-noise",
    "OBSERVATION_NOISE_REBUILD_DIR ?= out/rebuilt/observation-noise",
    "OBSERVATION_NOISE_RERUN_DIR ?= $(CURDIR)/out/sensitivity-rerun/observation-noise",
    "OBSERVATION_NOISE_V2_REBUILD_ROOT ?= out/rebuilt/observation-noise-v2",
    "OBSERVATION_NOISE_IMAGE ?= rc-dates-observation-noise:r4.5.3",
    "",
    ".PHONY: help r-preflight restore test manifest pipeline check clean",
    ".PHONY: empirical-figures production-figures production-rerun",
    ".PHONY: observation-noise-summary observation-noise-rerun",
    ".PHONY: observation-noise-estimand-aligned-v2",
    "",
    "help:",
    "\t@echo \"Code review package commands:\"",
    "\t@echo \"  make r-preflight  Confirm Rscript resolves to R 4.5.3\"",
    "\t@echo \"  make restore   Restore pinned R packages with renv\"",
    "\t@echo \"  make test      Run the testthat suite\"",
    "\t@echo \"  make manifest  Print the targets manifest\"",
    "\t@echo \"  make pipeline  Run the analysis pipeline\"",
    "\t@echo \"  make empirical-figures  Rebuild Figures 1-2 from the repaired workflow\"",
    "\t@echo \"  make production-figures  Rebuild Figures 3-5 from supplied RDS files\"",
    "\t@echo \"  make production-rerun    Rerun full simulations with Docker (expensive)\"",
    "\t@echo \"  make observation-noise-summary  Rebuild paired sensitivity summaries\"",
    "\t@echo \"  make observation-noise-rerun    Rerun the focused paired sensitivity\"",
    paste(
      "\t@echo \"  make observation-noise-estimand-aligned-v2",
      "Rebuild the separate v2 diagnostic\""
    ),
    "\t@echo \"  make check     Run tests, pipeline, and the Figures 3-5 rebuild\"",
    "\t@echo \"  make clean     Remove generated targets artefacts\"",
    "",
    "r-preflight:",
    "\t@ver=\"$$(\"$(RSCRIPT)\" --version 2>&1)\"; \\",
    "\tcase \"$$ver\" in \\",
    "\t\t*\"version $(R_VERSION_REQUIRED) (\"*) echo \"Using $(RSCRIPT): $$ver\" ;; \\",
    "\t\t*) echo \"Wrong Rscript: $(RSCRIPT) reports '$$ver'\"; \\",
    "\t\t\techo \"Use R 4.5.3 for this review package.\"; exit 1 ;; \\",
    "\tesac",
    "",
    "restore: r-preflight",
    "\t\"$(RSCRIPT)\" -e 'source(\"renv/activate.R\"); renv::restore(prompt = FALSE)'",
    "",
    "test: r-preflight",
    "\t\"$(RSCRIPT)\" tests/run-tests.R",
    "",
    "manifest: r-preflight",
    "\t\"$(RSCRIPT)\" -e 'targets::tar_manifest(script = \"_targets.R\", callr_function = NULL)'",
    "",
    "pipeline: r-preflight",
    "\t\"$(RSCRIPT)\" -e 'targets::tar_make()'",
    "",
    "empirical-figures: restore",
    "\t\"$(RSCRIPT)\" scripts/render_manuscript_methods_figures.R \\",
    "\t\t--iterations=1000 --seed=1234 \\",
    "\t\t--figure-dir=figures/rebuilt \\",
    "\t\t--summary-dir=out/rebuilt/empirical-sampling",
    "",
    "production-figures: restore",
    "\t\"$(RSCRIPT)\" scripts/render_population_simulation_figures.R \\",
    "\t\t--input-dir=out/production --summary-dir=out/production \\",
    "\t\t--figure-dir=figures",
    "",
    "production-rerun:",
    "\tRC_DATES_OUTPUT_DIR=out/rerun bash scripts/run_production_simulation_matrix.sh",
    "",
    "observation-noise-summary: restore",
    "\t@set -eu; \\",
    "\tif test -e \"$(OBSERVATION_NOISE_REBUILD_DIR)\"; then \\",
    "\t\techo \"Refusing to replace existing $(OBSERVATION_NOISE_REBUILD_DIR)\"; \\",
    "\t\texit 1; \\",
    "\tfi; \\",
    "\tmkdir -p \"$(OBSERVATION_NOISE_REBUILD_DIR)\"; \\",
    "\tfor model in uni lin exp; do \\",
    "\t\tfor prop in 0.5 0.75 1; do \\",
    "\t\t\tbase=\"observation_noise_$${model}_p$${prop}_ratio10_nsim1000_seed1234.rds\"; \\",
    "\t\t\tpair=\"$${base%.rds}.pairs.csv\"; \\",
    "\t\t\tsidecar=\"$${base}.metadata.txt\"; \\",
    "\t\t\tfor name in \"$$base\" \"$$pair\" \"$$sidecar\"; do \\",
    "\t\t\t\ttest -f \"$(OBSERVATION_NOISE_INPUT_DIR)/$$name\"; \\",
    "\t\t\t\tcp \"$(OBSERVATION_NOISE_INPUT_DIR)/$$name\" \\",
    "\t\t\t\t\t\"$(OBSERVATION_NOISE_REBUILD_DIR)/$$name\"; \\",
    "\t\t\tdone; \\",
    "\t\tdone; \\",
    "\tdone; \\",
    "\ttest -f \"$(OBSERVATION_NOISE_INPUT_DIR)/container_image_id.txt\"; \\",
    "\tcp \"$(OBSERVATION_NOISE_INPUT_DIR)/container_image_id.txt\" \\",
    "\t\t\"$(OBSERVATION_NOISE_REBUILD_DIR)/container_image_id.txt\"",
    "\t\"$(RSCRIPT)\" scripts/summarise_observation_noise_sensitivity.R \\",
    "\t\t--input-dir=\"$(OBSERVATION_NOISE_REBUILD_DIR)\" \\",
    "\t\t--output-dir=\"$(OBSERVATION_NOISE_REBUILD_DIR)/summary\" \\",
    "\t\t--nsim=1000 --n-boot=5000 --seed=1234",
    "",
    "observation-noise-estimand-aligned-v2: restore",
    "\t@set -eu; \\",
    "\tif test -e \"$(OBSERVATION_NOISE_V2_REBUILD_ROOT)\"; then \\",
    paste0(
      "\t\techo \"Refusing to replace existing ",
      "$(OBSERVATION_NOISE_V2_REBUILD_ROOT)\"; \\"
    ),
    "\t\texit 1; \\",
    "\tfi; \\",
    "\tmkdir -p \"$(OBSERVATION_NOISE_V2_REBUILD_ROOT)/summary\"; \\",
    "\tfor model in uni lin exp; do \\",
    "\t\tfor prop in 0.5 0.75 1; do \\",
    "\t\t\tbase=\"observation_noise_$${model}_p$${prop}_ratio10_nsim1000_seed1234.rds\"; \\",
    "\t\t\tpair=\"$${base%.rds}.pairs.csv\"; \\",
    "\t\t\tsidecar=\"$${base}.metadata.txt\"; \\",
    "\t\t\tfor name in \"$$base\" \"$$pair\" \"$$sidecar\"; do \\",
    "\t\t\t\ttest -f \"$(OBSERVATION_NOISE_INPUT_DIR)/$$name\"; \\",
    "\t\t\t\tcp \"$(OBSERVATION_NOISE_INPUT_DIR)/$$name\" \\",
    "\t\t\t\t\t\"$(OBSERVATION_NOISE_V2_REBUILD_ROOT)/$$name\"; \\",
    "\t\t\tdone; \\",
    "\t\tdone; \\",
    "\tdone; \\",
    "\ttest -f \"$(OBSERVATION_NOISE_INPUT_DIR)/container_image_id.txt\"; \\",
    "\tcp \"$(OBSERVATION_NOISE_INPUT_DIR)/container_image_id.txt\" \\",
    "\t\t\"$(OBSERVATION_NOISE_V2_REBUILD_ROOT)/container_image_id.txt\"; \\",
    "\tcp -R \"$(OBSERVATION_NOISE_INPUT_DIR)/summary/.\" \\",
    "\t\t\"$(OBSERVATION_NOISE_V2_REBUILD_ROOT)/summary/\"",
    "\t\"$(RSCRIPT)\" scripts/summarise_observation_noise_estimand_aligned.R \\",
    "\t\t--input-dir=\"$(OBSERVATION_NOISE_V2_REBUILD_ROOT)\" \\",
    paste0(
      "\t\t--output-dir=\"$(OBSERVATION_NOISE_V2_REBUILD_ROOT)/",
      "estimand-aligned-v2\" \\"
    ),
    "\t\t--nsim=1000 --n-boot=50000 --master-seed=1234 \\",
    "\t\t--stability-seed=5678",
    "",
    "observation-noise-rerun:",
    "\t@tmp=\"$$(mktemp -d)\"; \\",
    "\ttrap 'rm -rf \"$$tmp\"' EXIT; \\",
    "\tcp -R provenance/observation-noise-20260726/. \"$$tmp/\"; \\",
    "\tmkdir -p \"$$tmp/data\"; \\",
    "\tcp data/austarch_filtered.csv \"$$tmp/data/\"; \\",
    "\tcp renv.lock \"$$tmp/\"; \\",
    "\tcp -R renv \"$$tmp/renv\"; \\",
    "\tdocker build --tag \"$(OBSERVATION_NOISE_IMAGE)\" \\",
    "\t\t--file \"$$tmp/docker/production-simulation.Dockerfile\" \"$$tmp\"; \\",
    "\tRC_DATES_SIM_IMAGE=\"$(OBSERVATION_NOISE_IMAGE)\" \\",
    "\t\tRC_DATES_SENSITIVITY_ARTIFACT_DIR=\"$(OBSERVATION_NOISE_RERUN_DIR)\" \\",
    "\t\tRC_DATES_SENSITIVITY_NSIM=1000 \\",
    "\t\tRC_DATES_SENSITIVITY_MASTER_SEED=1234 \\",
    "\t\tRC_DATES_SENSITIVITY_STRATEGIES=r_all,r_1,r_3,r_5 \\",
    "\t\tbash \"$$tmp/scripts/run_observation_noise_sensitivity_matrix.sh\"",
    "",
    "check: production-figures",
    "\t\"$(RSCRIPT)\" scripts/run_review_checks.R",
    "",
    "clean: r-preflight",
    "\t\"$(RSCRIPT)\" -e 'targets::tar_destroy(destroy = \"all\")'"
  )
)

write_text(
  "scripts/run_review_checks.R",
  c(
    "source(\"renv/activate.R\")",
    "",
    "source(\"tests/run-tests.R\")",
    "print(targets::tar_manifest(script = \"_targets.R\", callr_function = NULL))",
    "targets::tar_make()"
  )
)

write_text(
  "SIMULATION_PROVENANCE.md",
  c(
    "# Simulation and Figure Provenance",
    "",
    "## Population-model production simulations",
    "",
    "The fast reviewer path runs the same sampling and summary code in `simulate.mode: demo`.",
    "That path is intended to verify the code, data ingest, calibration, summaries,",
    "targets graph, and test suite on an ordinary reviewer machine.",
    "",
    "The high-volume production simulations used for the manuscript's model-recovery,",
    "parameter-bias, and evidential-strength displays were run outside the default",
    "reviewer pipeline. This archive supplies the nine validated 1,000-replicate RDS",
    "files under `out/production/`, together with per-file runtime metadata, a",
    "SHA-256 manifest, and three plain-text summary tables. The files cover every",
    "combination of:",
    "",
    "- generating model: uniform, linear, or exponential;",
    "- proportion of sites subjected to within-site sampling: 0.5, 0.75, or 1;",
    "- 1,000 replicates per model-proportion scenario; and",
    "- master seed 1234 with common random numbers across scenarios.",
    "",
    "Accuracy and unambiguous-support intervals use paired cluster bootstrap",
    "resampling of replicate identifiers, keeping the three generating-family",
    "outcomes together within each resampled cluster.",
    "",
    "Run `make production-figures` to validate the RDS objects, verify that the",
    "embedded provenance and metadata checksums agree, confirm that the all-dates",
    "reference is identical across sampling intensities, regenerate the three summary",
    "tables, and rebuild Figures 3-5 under `figures/`.",
    "",
    "The full runner is also supplied. It uses the exact R 4.5.3 container recipe,",
    "deterministic replicate seeds, atomic checkpoints, and a 63-worker Linux",
    "launcher. Run `make production-rerun` only when an independent expensive rerun",
    "is required; it writes to `out/rerun/` and preserves the supplied artefacts.",
    "",
    "This production implementation is method-equivalent to the archived analysis:",
    "tests compare both likelihood definitions and both growth-model optimisations",
    "against direct legacy calculations. It is not a bitwise reconstruction of the",
    "lost historical RDS files because the random-number stream and sampling order",
    "were made explicit for the reproducible rerun.",
    "",
    "The exact source files loaded by the supplied production run are retained under",
    "`provenance/production-20260710/`. Their hashes match the provenance embedded in",
    "each RDS file. The supplied files record `post-run-stamp` because the fingerprint",
    "attribute was added after completed raw RDS files had been preserved; active",
    "future-run checkpoints record `native-checkpoint`.",
    "",
    "## Empirical Figures 1-2",
    "",
    "The supplied `figures/fig_1.png` and `figures/fig_2.png` are the repaired",
    "empirical figures. Their summaries and generation metadata are under",
    "`out/empirical-sampling/`. The metadata bind both PNG files and every CSV",
    "summary to the filtered input, analysis helpers, figure module, and renderer",
    "with MD5 fingerprints. The package builder refuses inconsistent inputs.",
    "",
    "Run `make empirical-figures` under R 4.5.3 to rerun 1,000 stochastic",
    "iterations with seed 1234. Rebuilt files are written under `figures/rebuilt/`",
    "and `out/rebuilt/empirical-sampling/`, preserving the supplied evidence.",
    "",
    "## Paired realised-observation-noise sensitivity",
    "",
    "The focused sensitivity compares the curve-mean assay used by the production",
    "analysis with paired realised conventional radiocarbon-age draws. It includes",
    "only all dates, random-1, random-3, and random-5 (`r_all,r_1,r_3,r_5`). It does",
    "not evaluate oldest, youngest, bracketed, stratigraphic, or site-history",
    "sampling designs.",
    "",
    "The nine 1,000-pair checkpoints, pair manifests, runtime sidecars, container",
    "image ID, checksum manifest, and summary evidence are supplied under",
    "`out/sensitivity/observation-noise/`. Package construction verifies checkpoint",
    "completeness, exact pairing, sidecar hashes, the container ID, and the frozen",
    "source fingerprints. It also verifies that `SHA256SUMS` enumerates every",
    "distributable evidence file and no log file. This integrity validation does not",
    "assert that the sensitivity gates pass; review the supplied gate report.",
    "",
    "The separately versioned post-unblinding diagnostic is supplied under",
    "`out/sensitivity/observation-noise/estimand-aligned-v2/`. It contains only",
    "paired difference estimands, uses 50,000 resamples with primary seed 1234 and",
    "independent stability seed 5678, and retains the original v1 **FAIL (15/18)**",
    "without relabelling it. Package construction checks both decisions from their",
    "own evidence; inclusion does not presume that the three-row v2 gate report passes.",
    "",
    "Run `make observation-noise-estimand-aligned-v2` to rebuild the separate v2",
    "diagnostic from copied v1 evidence under `out/rebuilt/observation-noise-v2/`.",
    "The command preserves all supplied v1 and v2 files. A non-zero exit after outputs",
    "are written means the independent stability decisions disagree or a v2 gate fails.",
    "",
    "Run `make observation-noise-summary` to recompute the paired-bootstrap summaries",
    "from the supplied checkpoints. The command copies the exact 28 source inputs",
    "to `out/rebuilt/observation-noise/`, generates its `summary/` directory and",
    "a new checksum inventory there, and never rewrites the supplied evidence.",
    "A non-zero exit after outputs are written means at least one declared gate",
    "did not pass.",
    "",
    "The exact source loaded by the supplied matrix is frozen under",
    "`provenance/observation-noise-20260726/`. Run `make observation-noise-rerun`",
    "on a Linux Docker host for an independent focused rerun. The target builds a",
    "temporary workspace from that snapshot plus the fingerprinted input and lockfile,",
    "then writes new checkpoints under `out/sensitivity-rerun/observation-noise/`.",
    "It does not overwrite the supplied sensitivity evidence."
  )
)

write_text(
  "README.md",
  c(
    "# Analysis Code Review Package",
    "",
    "This package contains the de-identified code, data, tests, and pinned R",
    "package environment needed to review and rerun the analysis-code pipeline.",
    "It is designed to work outside GitHub and intentionally excludes manuscript",
    "sources, reports, author-identifying documentation, and repository metadata.",
    "It is not an air-gapped dependency bundle: the first `renv` restore or Docker",
    "image build requires network access to package and operating-system mirrors.",
    "",
    "## Contents",
    "",
    "- `_targets.R` - code-only `{targets}` pipeline for ingest, validation,",
    "  calibration, summaries, figures, and demo simulation outputs.",
    "- `R/` - analysis, validation, plotting, and simulation helper functions.",
    "- `figures/fig_1.png` and `figures/fig_2.png` - repaired empirical figures",
    "  bound to their source and summaries by the supplied metadata.",
    "- `out/empirical-sampling/` - source-derived data and fingerprint metadata",
    "  for Figures 1-2.",
    "- `out/production/` - nine validated production RDS files, runtime metadata,",
    "  and manuscript-display summary tables.",
    "- `out/sensitivity/observation-noise/` - paired curve-mean versus realised",
    "  observation-noise checkpoints, pair manifests, sidecars, and summaries.",
    "- `out/sensitivity/observation-noise/estimand-aligned-v2/` - separately",
    "  versioned, post-unblinding difference-only diagnostic evidence; it retains",
    "  the original v1 FAIL rather than replacing or relabelling it.",
    "- `provenance/production-20260710/` - exact de-identified source snapshot",
    "  whose hashes are embedded in the supplied production RDS files.",
    "- `provenance/observation-noise-20260726/` - exact frozen source loaded by",
    "  the supplied paired sensitivity matrix.",
    "- `scripts/render_manuscript_methods_figures.R` - rebuilds Figures 1-2",
    "  from the repaired common-window workflow.",
    "- `scripts/render_population_simulation_figures.R` - rebuilds Figures 3-5",
    "  from the supplied production artefacts.",
    "- `scripts/run_observation_noise_sensitivity.R`, its matrix launcher, and",
    "  `scripts/summarise_observation_noise_sensitivity.R` - focused paired",
    "  sensitivity generation, validation, and summary entry points.",
    "- `scripts/summarise_observation_noise_estimand_aligned.R` - rebuilds the",
    "  separate v2 diagnostic with 50,000 resamples and seeds 1234 and 5678.",
    "- `scripts/run_population_simulation.R`, the matrix launcher, and `docker/` -",
    "  resumable full-rerun path under the pinned R 4.5.3 environment.",
    "- `data/austarch_input_deidentified.csv` - de-identified input table with",
    "  only the columns used by the pipeline.",
    "- `data/austarch_filtered.csv` - locked filtered Holocene reference table",
    "  used to audit the manuscript-scale reference set.",
    "- `metadata/data_manifest.csv` - default input manifest for the de-identified",
    "  input table.",
    "- `metadata/example_manifest.csv` and `inst/extdata/` - small examples used",
    "  by tests and smoke checks.",
    "- `renv.lock`, `renv/activate.R`, and `renv/settings.json` - pinned R package",
    "  environment.",
    "- `tests/` - non-package `testthat` suite.",
    "- `REPRODUCE.md` - reviewer-facing reproduction notes.",
    "- `SIMULATION_PROVENANCE.md` - scope note for high-volume production",
    "  simulations.",
    "",
    "## Fresh Machine Setup",
    "",
    "Install R 4.5.3; the lockfile was refreshed under that exact release. Newer",
    "R releases may try to",
    "rebuild pinned source packages and fail. Then run from this directory:",
    "",
    "```sh",
    "make restore",
    "```",
    "",
    "The lockfile retains the complete pinned dependency set used to create the",
    "supplied artefacts. Because manuscript and report targets are intentionally",
    "absent, `renv::status()` may list recorded packages as unused; it should not",
    "report packages that are used but missing or unrecorded.",
    "",
    "The included Makefile runs an R 4.5.3 preflight before restore, test, and",
    "pipeline commands. Override `RSCRIPT=/path/to/Rscript` if R 4.5.3 is not",
    "the first `Rscript` on PATH.",
    "",
    "On Linux, some spatial/graphics packages may require system libraries before",
    "`renv::restore()` can complete. Typical Ubuntu packages are:",
    "",
    "```sh",
    "sudo apt-get update",
    "sudo apt-get install -y cmake gdal-bin gsfonts pandoc libcurl4-openssl-dev \\",
    "  libgdal-dev libglpk-dev libmagick++-dev libudunits2-dev libx11-dev",
    "```",
    "",
    "## Run Checks",
    "",
    "```sh",
    "make test",
    "```",
    "",
    "The targeted reproduction commands are:",
    "",
    "```sh",
    "make empirical-figures",
    "make production-figures",
    "make observation-noise-summary",
    "make observation-noise-estimand-aligned-v2",
    "```",
    "",
    "`make empirical-figures` uses R 4.5.3, 1,000 iterations, and seed 1234.",
    "The observation-noise targets cover only all-dates, random-1, random-3, and",
    "random-5 (`r_all,r_1,r_3,r_5`). For an independent rerun of that focused",
    "matrix with the frozen source and exact 1,000-pair design, use:",
    "",
    "```sh",
    "make observation-noise-rerun",
    "```",
    "",
    "These rebuild into separate output directories where needed, so supplied",
    "evidence remains unchanged. The observation-noise command reports the declared",
    "gate status; this package description does not presume either v1 or v2 status.",
    "",
    "## Run The Pipeline",
    "",
    "```sh",
    "make pipeline",
    "```",
    "",
    "Generated artefacts are written to `_targets/`, `outputs/`, and `figs/`.",
    "The reviewer profile caps optional per-site diagnostic branches at 12, matching",
    "the report display limit. Set `branching.site.limit: null` in `config/config.yml`",
    "to request the exhaustive site appendix; global analyses still use all records.",
    "",
    "For a faster test run using the tiny example data, replace",
    "`metadata/data_manifest.csv` with `metadata/example_manifest.csv` or edit",
    "`config/config.yml` so `data.manifest` points at the example manifest.",
    "",
    "See `REPRODUCE.md` before review. It explains which parts of the workflow are",
    "intended as fast code verification and how high-volume simulation artefacts",
    "are represented."
  )
)

write_text(
  "REPRODUCE.md",
  c(
    "# Reproduce and Review",
    "",
    "This is a de-identified code/data package for peer review. It contains the",
    "analysis-code workflow, input data, tests, and pinned R package environment",
    "needed to inspect and rerun the code package without GitHub.",
    "The first package restore or Docker image build requires internet access; this",
    "archive is GitHub-independent but is not an air-gapped dependency mirror.",
    "",
    "It does not contain the manuscript source, author-identifying project notes,",
    "internal reports, reference-management files, or repository metadata.",
    "",
    "## Fast Verification Path",
    "",
    "From the archive root:",
    "",
    "```sh",
    "make restore",
    "make test",
    "make manifest",
    "make pipeline",
    "```",
    "",
    "Generated files are written to `_targets/`, `outputs/`, and `figs/`.",
    "The supplied reviewer config runs 12 optional per-site diagnostic branches;",
    "remove `branching.site.limit` only if an exhaustive 1,207-site appendix is needed.",
    "",
    "Use R 4.5.3 for this path. Restoring the lockfile under a newer R release can",
    "force source rebuilds of",
    "pinned packages and is not the intended reviewer environment.",
    "The lockfile retains the complete pinned dependency set used to generate the",
    "supplied artefacts. Since manuscript and report targets are excluded,",
    "`renv::status()` may identify recorded packages as unused; this is expected",
    "and does not indicate a missing dependency.",
    "",
    "## Inputs",
    "",
    "The default manifest is `metadata/data_manifest.csv`, which points at the",
    "included de-identified input table. This table contains only the columns",
    "used by the analysis pipeline and replaces the original free-text source and",
    "notes fields with a neutral review-package provenance marker.",
    "",
    "`data/austarch_filtered.csv` is also supplied as a locked filtered reference",
    "table so reviewers can inspect the 976-row Holocene set used by the study.",
    "The tiny example manifest `metadata/example_manifest.csv` is supplied only",
    "for tests and smoke checks.",
    "",
    "## Empirical Figures 1-2",
    "",
    "The supplied empirical figures and summaries were generated by the repaired",
    "common-window workflow. Rebuild them under R 4.5.3 with the locked 1,000",
    "iterations and seed 1234:",
    "",
    "```sh",
    "make empirical-figures",
    "```",
    "",
    "The command writes `figures/rebuilt/fig_1.png`,",
    "`figures/rebuilt/fig_2.png`, and their CSV/metadata evidence under",
    "`out/rebuilt/empirical-sampling/`. Supplied files under `figures/` and",
    "`out/empirical-sampling/` are retained for comparison.",
    "",
    "## Simulation Artefacts",
    "",
    "The default configuration uses `simulate.mode: demo`. This mode runs a reduced",
    "simulation workflow with fixed seeds so that reviewers can exercise the",
    "sampling, summary, and plotting code on an ordinary machine.",
    "",
    "The high-volume population-model simulations described in the manuscript are",
    "supplied as nine validated RDS files under `out/production/`. Rebuild the three",
    "production displays and summaries without rerunning the simulations with:",
    "",
    "```sh",
    "make production-figures",
    "```",
    "",
    "This writes Figures 3-5 under `figures/` and refreshes the three CSV summaries",
    "without rerunning the expensive simulations.",
    "",
    "For an independent full rerun on a Linux host with Docker:",
    "",
    "```sh",
    "make production-rerun",
    "```",
    "",
    "The rerun uses the included R 4.5.3 image recipe and writes checkpoints to",
    "`out/rerun/`, leaving the supplied production artefacts unchanged. See",
    "`SIMULATION_PROVENANCE.md` before starting this expensive path.",
    "",
    "## Paired Observation-Noise Sensitivity",
    "",
    "The supplied focused matrix contains all-dates, random-1, random-3, and",
    "random-5 only. It does not include oldest, youngest, bracketed, stratigraphic,",
    "or site-history designs. Each latent population and site selection is paired",
    "between the curve-mean and realised-observation arms.",
    "",
    "Recompute the paired-bootstrap summaries from the supplied nine checkpoints:",
    "",
    "```sh",
    "make observation-noise-summary",
    "```",
    "",
    "The command copies the exact nine checkpoints, nine pair manifests, nine",
    "sidecars, and image ID to `out/rebuilt/observation-noise/`, then writes its",
    "`summary/` and `SHA256SUMS` there. The summary script returns status 2 after",
    "writing its report when any required gate does not pass. Inspect the report;",
    "inclusion in this package is evidence of a completed, fingerprint-consistent",
    "analysis, not an assertion of a PASS result.",
    "",
    "The separately labelled post-unblinding v2 evidence is under",
    "`out/sensitivity/observation-noise/estimand-aligned-v2/`. It contains 264",
    "difference-only metric rows, three gates, and an independent-seed stability",
    "check. It uses 50,000 resamples, seed 1234, and stability seed 5678 while",
    "retaining the original v1 **FAIL (15 of 18 gates passed)**. It does not replace",
    "or retroactively pass v1.",
    "",
    "Rebuild v2 without changing either supplied evidence family with:",
    "",
    "```sh",
    "make observation-noise-estimand-aligned-v2",
    "```",
    "",
    "The rebuild copies the required v1 inputs to",
    "`out/rebuilt/observation-noise-v2/` before generating its nested v2 directory",
    "and parent checksum. Its exit status reports the computed v2 and stability",
    "decisions; these instructions do not assume a PASS.",
    "",
    "For an independent 1,000-pair rerun of the same focused design on Linux with",
    "Docker, using the exact frozen run source:",
    "",
    "```sh",
    "make observation-noise-rerun",
    "```",
    "",
    "This builds a container from the frozen recipe and creates a temporary source",
    "workspace from `provenance/observation-noise-20260726/`, the supplied input,",
    "and `renv.lock`. Results go to",
    "`out/sensitivity-rerun/observation-noise/`; supplied checkpoints are preserved.",
    "To summarise that rerun exactly, use:",
    "",
    "```sh",
    "make observation-noise-summary \\",
    "  OBSERVATION_NOISE_INPUT_DIR=out/sensitivity-rerun/observation-noise \\",
    "  OBSERVATION_NOISE_REBUILD_DIR=out/rebuilt/observation-noise-rerun",
    "```",
    "",
    "## Anonymity Check",
    "",
    "Before repository upload, inspect this archive for author names, email",
    "addresses, ORCID identifiers, institution names, local machine paths, and",
    "internal agent notes. The review package should remain de-identified until",
    "the paper is accepted."
  )
)

package_scan_entries <- list.files(
  package_dir,
  all.files = TRUE,
  recursive = TRUE,
  no.. = TRUE
)
package_scan_paths <- file.path(package_dir, package_scan_entries)
package_scan_info <- file.info(package_scan_paths)
package_scan_entries <- package_scan_entries[!package_scan_info$isdir]
package_scan_paths <- package_scan_paths[!package_scan_info$isdir]
text_basenames <- c(
  "Makefile",
  "LICENSE",
  ".Rprofile",
  ".gitignore",
  ".gitattributes",
  ".dockerignore",
  ".lintr",
  "SHA256SUMS"
)
text_extensions <- paste0(
  "\\.(",
  paste(c("r", "rmd", "qmd", "md", "txt", "csv", "tsv", "json", "ya?ml", "sh"),
        collapse = "|"),
  ")$"
)
text_candidates <- basename(package_scan_entries) %in% text_basenames |
  grepl(text_extensions, package_scan_entries, ignore.case = TRUE)
text_candidates <- text_candidates & package_scan_entries != "renv.lock"
identity_patterns <- c(
  "(?i)bwbrook",
  "(?i)barry[[:space:]]+(w\\.?[[:space:]]+)?brook",
  "(?i)university[[:space:]]+of[[:space:]]+tasmania",
  "(?i)(^|[^[:alnum:]])utas([^[:alnum:]]|$)",
  "(?i)(^|[\"'[:space:]])/(home|users|data)/",
  "(?i)[a-z]:[/\\\\]users[/\\\\]",
  "(?i)[[:alnum:]._%+-]+@[[:alnum:].-]+\\.[[:alpha:]]{2,}",
  paste0(
    "(?i)(^|[^[:digit:]])[[:digit:]]{4}-[[:digit:]]{4}-",
    "[[:digit:]]{4}-[[:digit:]]{3}[[:digit:]x]([^[:digit:]]|$)"
  )
)
identity_hits <- vapply(
  package_scan_paths[text_candidates],
  function(path) {
    contents <- paste(readLines(path, warn = FALSE), collapse = "\n")
    any(vapply(identity_patterns, grepl, logical(1), x = contents, perl = TRUE))
  },
  logical(1)
)
identity_path_hits <- vapply(
  package_scan_entries,
  function(path) {
    any(vapply(identity_patterns, grepl, logical(1), x = path, perl = TRUE))
  },
  logical(1)
)
rejected_identity_entries <- unique(c(
  package_scan_entries[text_candidates][identity_hits],
  package_scan_entries[identity_path_hits]
))
if (length(rejected_identity_entries) > 0L) {
  stop(
    "Anonymous-package sanitizer rejected: ",
    paste(rejected_identity_entries, collapse = ", "),
    call. = FALSE
  )
}

manifest_files <- list.files(package_dir, all.files = TRUE, recursive = TRUE, no.. = TRUE)
manifest_files <- manifest_files[file.info(file.path(package_dir, manifest_files))$isdir == FALSE]
manifest_files <- sort(manifest_files)
manifest <- data.frame(
  path = manifest_files,
  bytes = file.info(file.path(package_dir, manifest_files))$size,
  stringsAsFactors = FALSE
)

utils::write.table(
  manifest,
  file.path(package_dir, "PACKAGE_MANIFEST.tsv"),
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

message("Built de-identified review package directory: ", package_dir)
