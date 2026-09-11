#!/usr/bin/env Rscript

# Rebuild the accepted observation-noise aggregate evidence from the nine
# frozen paired checkpoints.  The transformation order follows the original
# runners at commit 1ba8eb0:
#   scripts/summarise_observation_noise_sensitivity.R
#   scripts/summarise_observation_noise_estimand_aligned.R
# Only aggregate CSVs are emitted; accepted evidence is never overwritten.

source("scripts/release/common.R")

frozen_dir <- file.path("provenance", "observation-noise-20260726")
frozen_sources <- c(
  file.path(frozen_dir, "R", "legacy_simulation_helpers.R"),
  file.path(frozen_dir, "R", "population_simulation_production.R"),
  file.path(frozen_dir, "R", "observation_noise_sensitivity.R")
)
invisible(lapply(frozen_sources, source))
source("release/historical/observation_noise_summaries.R")
source("release/historical/observation_noise_estimand_aligned.R")

settings <- release_arguments(list(
  `input-dir` = file.path("out", "sensitivity", "observation-noise"),
  `output-dir` = file.path("out", "reproduced", "noise"),
  `n-boot` = 5000L,
  `seed` = 1234L,
  `v2-n-boot` = 50000L,
  `v2-seed` = 1234L,
  `v2-stability-seed` = 5678L
))
for (field in c("n-boot", "seed", "v2-n-boot", "v2-seed", "v2-stability-seed")) {
  settings[[field]] <- suppressWarnings(as.integer(settings[[field]]))
  if (is.na(settings[[field]]) || settings[[field]] < 1L) {
    stop("Invalid positive integer for --", field, ".", call. = FALSE)
  }
}
fixed_settings <- c(
  `n-boot` = 5000L,
  seed = 1234L,
  `v2-n-boot` = 50000L,
  `v2-seed` = 1234L,
  `v2-stability-seed` = 5678L
)
for (field in names(fixed_settings)) {
  if (!identical(settings[[field]], fixed_settings[[field]])) {
    stop("The accepted observation-noise rebuild requires --", field, "=",
         fixed_settings[[field]], ".", call. = FALSE)
  }
}
if (!identical(as.character(getRversion()), "4.5.3")) {
  stop("Observation-noise summary rebuild requires R 4.5.3; found ",
       R.version.string, ".", call. = FALSE)
}
required_packages <- c("digest", "jsonlite", "rcarbon", "readr")
missing_packages <- required_packages[!vapply(
  required_packages, requireNamespace, logical(1), quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop("Missing observation-noise summary packages: ",
       paste(missing_packages, collapse = ", "), call. = FALSE)
}

abort <- function(message) stop(message, call. = FALSE)

validate_release_artifact <- function(
  path,
  provenance_dir = frozen_dir,
  input_path = file.path("data", "austarch_filtered.csv"),
  lock_path = "renv.lock",
  image_id_path = file.path(dirname(path), "container_image_id.txt"),
  expected_nsim = 1000L,
  expected_seed = 1234L,
  expected_strategies = c("r_all", "r_1", "r_3", "r_5")
) {
  pair_path <- sub("\\.rds$", ".pairs.csv", path)
  metadata_path <- paste0(path, ".metadata.txt")
  required_files <- c(path, pair_path, metadata_path, image_id_path)
  if (any(!file.exists(required_files))) {
    abort(paste("Missing observation-noise artifact files:",
                paste(required_files[!file.exists(required_files)], collapse = ", ")))
  }

  # This validates the complete frozen inventory and its source snapshots.
  snapshot <- validate_observation_noise_frozen_snapshot(provenance_dir)
  checkpoint <- readRDS(path)
  required_checkpoint <- c("results", "pair_manifest", "provenance")
  if (!is.list(checkpoint) ||
      !identical(sort(names(checkpoint)), sort(required_checkpoint))) {
    abort("Observation-noise checkpoint schema is not the frozen schema.")
  }
  provenance <- checkpoint$provenance
  required_provenance <- c(
    "schema_version", "sensitivity_design", "observation_models",
    "assay_equation", "calibration_curve", "roundyear",
    "window_exclusion_rule", "rng_kind", "stream_mapping", "true_model",
    "prop", "nsim", "master_seed", "strategies", "input_md5",
    "renv_lock_md5", "production_source_md5", "sensitivity_source_md5",
    "legacy_helper_md5", "runner_source_md5", "container_recipe_md5",
    "container_install_md5", "container_image_id", "r_version",
    "rcarbon_version"
  )
  if (!is.list(provenance) ||
      !identical(sort(names(provenance)), sort(required_provenance))) {
    abort("Observation-noise checkpoint provenance schema is incomplete.")
  }

  image_id <- trimws(readLines(image_id_path, warn = FALSE))
  frozen_md5 <- observation_noise_frozen_md5(provenance_dir)
  observed_md5 <- unlist(provenance[names(frozen_md5)], use.names = TRUE)
  valid_header <- identical(provenance$schema_version, 1L) &&
    identical(provenance$sensitivity_design, "paired_curve_mean_vs_realised_v1") &&
    identical(provenance$observation_models, c("curve_mean", "realised")) &&
    identical(provenance$assay_equation,
              "rCRA=round(ccCRA+Z*sqrt(ccError^2+quoted_error^2))") &&
    identical(provenance$calibration_curve, "shcal20") &&
    isTRUE(provenance$roundyear) &&
    identical(provenance$window_exclusion_rule,
              "drop selected observations with zero posterior mass in 651-11650") &&
    identical(provenance$rng_kind, "L'Ecuyer-CMRG") &&
    identical(provenance$stream_mapping,
              "structural=current; realised_assay=nextRNGStream(structural)") &&
    identical(as.integer(provenance$nsim), as.integer(expected_nsim)) &&
    identical(as.integer(provenance$master_seed), as.integer(expected_seed)) &&
    identical(as.character(provenance$strategies), expected_strategies) &&
    identical(provenance$r_version, "R version 4.5.3 (2026-03-11)") &&
    identical(provenance$rcarbon_version, "1.5.2") &&
    length(image_id) == 1L && grepl("^sha256:[0-9a-f]{64}$", image_id) &&
    identical(provenance$container_image_id, image_id)
  if (!valid_header || !identical(unname(observed_md5), unname(frozen_md5))) {
    abort("Observation-noise checkpoint does not match frozen source provenance.")
  }

  # The governed raw CSV is deliberately optional in a release checkout. If
  # present, verify its fingerprint; otherwise retain the recorded fingerprint
  # as provenance without requiring the restricted record-level input.
  if (file.exists(input_path) &&
      !identical(provenance$input_md5, unname(tools::md5sum(input_path)))) {
    abort("Observation-noise raw-input fingerprint differs from provenance.")
  }
  if (file.exists(lock_path) &&
      !identical(provenance$renv_lock_md5, unname(tools::md5sum(lock_path)))) {
    abort("Observation-noise renv.lock fingerprint differs from provenance.")
  }
  if (!grepl("^[0-9a-f]{32}$", provenance$input_md5) ||
      !grepl("^[0-9a-f]{32}$", provenance$renv_lock_md5)) {
    abort("Recorded observation-noise input fingerprints are malformed.")
  }

  validate_observation_noise_sensitivity_results(
    checkpoint$results, nsim = as.integer(expected_nsim),
    strategies = expected_strategies
  )
  validate_observation_noise_pair_manifest(
    checkpoint$pair_manifest, nsim = as.integer(expected_nsim)
  )
  observation_noise_manifest_matches_csv(checkpoint$pair_manifest, pair_path)

  metadata <- read_observation_noise_metadata(metadata_path)
  metadata_map <- c(
    schema_version = "schema_version", r_version = "r_version",
    rcarbon_version = "rcarbon_version", true_model = "true_model",
    site_subsampling_proportion = "prop", paired_replicates = "nsim",
    master_seed = "master_seed", sensitivity_design = "sensitivity_design",
    assay_equation = "assay_equation", window_exclusion_rule = "window_exclusion_rule",
    rng_kind = "rng_kind", stream_mapping = "stream_mapping",
    input_md5 = "input_md5", renv_lock_md5 = "renv_lock_md5",
    production_source_md5 = "production_source_md5",
    sensitivity_source_md5 = "sensitivity_source_md5",
    legacy_helper_md5 = "legacy_helper_md5", runner_source_md5 = "runner_source_md5",
    container_recipe_md5 = "container_recipe_md5",
    container_install_md5 = "container_install_md5", container_image_id = "container_image_id"
  )
  required_metadata <- c(names(metadata_map), "generation_completed_utc",
                         "strategies", "output_md5", "pair_manifest_md5", "packages")
  if (!all(required_metadata %in% names(metadata))) {
    abort("Observation-noise metadata sidecar is incomplete.")
  }
  metadata_matches <- vapply(names(metadata_map), function(key) {
    identical(metadata[[key]], as.character(provenance[[metadata_map[[key]]]]))
  }, logical(1))
  valid_metadata <- all(metadata_matches) &&
    identical(metadata[["strategies"]], paste(expected_strategies, collapse = ",")) &&
    identical(metadata[["output_md5"]], unname(tools::md5sum(path))) &&
    identical(metadata[["pair_manifest_md5"]], unname(tools::md5sum(pair_path))) &&
    grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} UTC$",
          metadata[["generation_completed_utc"]])
  if (!valid_metadata) abort("Observation-noise sidecar fingerprints do not agree.")
  list(
    checkpoint = checkpoint, path = path, pair_path = pair_path,
    metadata_path = metadata_path, checkpoint_md5 = unname(tools::md5sum(path)),
    pair_md5 = unname(tools::md5sum(pair_path)), metadata_md5 = unname(tools::md5sum(metadata_path)),
    frozen_manifest_sha256 = snapshot$manifest_sha256
  )
}

models <- c("uni", "lin", "exp")
props <- c(0.5, 0.75, 1)
paths <- unlist(lapply(models, function(model) {
  file.path(settings[["input-dir"]], vapply(props, function(prop) {
    observation_noise_sensitivity_filename(model, prop, 1000L, settings[["seed"]])
  }, character(1)))
}), use.names = FALSE)
if (length(paths) != 9L || any(!file.exists(paths))) {
  abort(paste("Exactly nine frozen observation-noise checkpoints are required; missing:",
              paste(paths[!file.exists(paths)], collapse = ", ")))
}
artifacts <- lapply(paths, validate_release_artifact, expected_nsim = 1000L,
                    expected_seed = settings[["seed"]])
checkpoints <- lapply(artifacts, `[[`, "checkpoint")
validated <- validate_observation_noise_summary_inputs(checkpoints)

key_columns <- function(data) {
  candidates <- c("metric_family", "gate", "metric", "scope", "true", "prop",
                  "strategy", "reference_strategy", "type", "arm")
  keys <- intersect(candidates, names(data))
  if (length(keys) == 0L) stop("No stable key columns found for aggregate table.", call. = FALSE)
  keys
}
write_compare <- function(data, accepted_path, reproduced_path) {
  release_write_compare_csv(data, accepted_path, reproduced_path, key_columns(data))
}

v1 <- summarise_observation_noise_sensitivity(
  checkpoints, n_boot = settings[["n-boot"]], seed = settings[["seed"]]
)
v1_gate <- v1$gates
if (nrow(v1_gate) != 18L || sum(v1_gate$pass %in% TRUE) != 15L ||
    !setequal(v1_gate$gate[!(v1_gate$pass %in% TRUE)],
              c("accuracy_difference_ci", "ose_support_difference_ci", "boundary_hit_increase"))) {
  abort("Rebuilt v1 summary does not retain the prespecified 15/18 FAIL decision.")
}
v1_output <- file.path(settings[["output-dir"]], "summary")
for (name in names(v1$metrics)) {
  write_compare(
    v1$metrics[[name]],
    file.path(settings[["input-dir"]], "summary", paste0("observation_noise_", name, ".csv")),
    file.path(v1_output, paste0("observation_noise_", name, ".csv"))
  )
}
write_compare(v1_gate,
              file.path(settings[["input-dir"]], "summary", "observation_noise_gate_report.csv"),
              file.path(v1_output, "observation_noise_gate_report.csv"))

v2 <- observation_noise_estimand_aligned_summary(
  validated, n_boot = settings[["v2-n-boot"]],
  master_seed = settings[["v2-seed"]], stability_seed = settings[["v2-stability-seed"]]
)
if (!isTRUE(v2$gate_pass) || !isTRUE(v2$stability_agree)) {
  abort("Rebuilt v2 summary does not retain PASS/AGREE decisions.")
}
v2_metrics <- do.call(rbind, lapply(names(v2$metrics), function(name) {
  data <- v2$metrics[[name]]
  data$metric_family <- name
  data
}))
v2_metrics <- v2_metrics[c(
  "metric_family", "metric", "scope", "true", "prop", "strategy", "type", "arm",
  "estimate", "ci_low", "ci_high", "margin", "interval", "n_clusters"
)]
v2_output <- file.path(settings[["output-dir"]], "estimand-aligned-v2")
write_compare(v2_metrics,
              file.path(settings[["input-dir"]], "estimand-aligned-v2", "metrics.csv"),
              file.path(v2_output, "metrics.csv"))
write_compare(v2$gates,
              file.path(settings[["input-dir"]], "estimand-aligned-v2", "gate_report.csv"),
              file.path(v2_output, "gate_report.csv"))
write_compare(v2$stability,
              file.path(settings[["input-dir"]], "estimand-aligned-v2", "stability.csv"),
              file.path(v2_output, "stability.csv"))

message("Frozen observation-noise v1 and v2 aggregate CSVs reproduced and compared.")
