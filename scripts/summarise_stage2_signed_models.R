#!/usr/bin/env Rscript

parse_stage2_summary_args <- function(args) {
  settings <- list(
    input_dir = file.path("out", "revision", "signed-models"),
    nsim = 1000L,
    ratio = 10,
    master_seed = 1234L
  )
  key_map <- c(
    `input-dir` = "input_dir",
    nsim = "nsim",
    ratio = "ratio",
    seed = "master_seed"
  )
  for (argument in args) {
    parts <- regmatches(argument, regexec("^--([^=]+)=(.*)$", argument))[[1L]]
    if (length(parts) != 3L || !parts[[2L]] %in% names(key_map)) {
      stop("Unknown or malformed Stage 2 summary argument: ", argument, call. = FALSE)
    }
    settings[[key_map[[parts[[2L]]]]]] <- parts[[3L]]
  }
  settings$nsim <- suppressWarnings(as.integer(settings$nsim))
  settings$master_seed <- suppressWarnings(as.integer(settings$master_seed))
  settings$ratio <- suppressWarnings(as.numeric(settings$ratio))
  if (length(settings$input_dir) != 1L || !nzchar(settings$input_dir) ||
      is.na(settings$nsim) || settings$nsim < 1L ||
      is.na(settings$master_seed) || settings$master_seed < 1L ||
      !is.finite(settings$ratio) || settings$ratio <= 1) {
    stop("Invalid Stage 2 summary settings.", call. = FALSE)
  }
  settings
}

if (!file.exists("scripts/source_population_simulation.R")) {
  stop("Run this script from the rc-dates repository root.", call. = FALSE)
}
source("scripts/source_population_simulation.R")
settings <- parse_stage2_summary_args(commandArgs(trailingOnly = TRUE))
contract <- population_simulation_contract("signed-v1")
proportions <- c(0.5, 0.75, 1)

result_paths <- unlist(lapply(proportions, function(prop) {
  file.path(
    settings$input_dir,
    vapply(
      contract$truths,
      production_simulation_filename,
      character(1),
      prop = prop,
      nsim = settings$nsim,
      master_seed = settings$master_seed,
      ratio = settings$ratio
    )
  )
}), use.names = FALSE)
missing_results <- result_paths[!file.exists(result_paths)]
if (length(missing_results) > 0L) {
  stop("Missing Stage 2 RDS files: ", paste(missing_results, collapse = ", "), call. = FALSE)
}

invisible(lapply(
  result_paths,
  validate_population_simulation_artifact,
  nsim = settings$nsim
))
result_list <- lapply(result_paths, readRDS)
provenance_list <- lapply(result_list, attr, which = "production_provenance", exact = TRUE)
if (!all(vapply(provenance_list, function(x) identical(x$schema_version, 3L), logical(1)))) {
  stop("Stage 2 evidence must use provenance schema 3.", call. = FALSE)
}

common_fields <- setdiff(names(provenance_list[[1L]]), c("truth", "prop"))
canonical_provenance <- provenance_list[[1L]][common_fields]
same_runtime <- vapply(provenance_list, function(provenance) {
  identical(provenance[common_fields], canonical_provenance)
}, logical(1))
if (!all(same_runtime)) {
  stop("Stage 2 artifacts were not generated under one frozen design and runtime.", call. = FALSE)
}

active_fingerprints <- c(
  input_md5 = unname(tools::md5sum("data/austarch_filtered.csv")),
  renv_lock_md5 = unname(tools::md5sum("renv.lock")),
  model_source_md5 = population_model_source_md5(),
  distribution_source_md5 = unname(tools::md5sum(population_distribution_source)),
  runner_source_md5 = unname(tools::md5sum("scripts/run_population_simulation.R")),
  container_recipe_md5 = unname(tools::md5sum(
    "docker/production-simulation.Dockerfile"
  )),
  container_install_md5 = unname(tools::md5sum(
    "docker/install-production-packages.R"
  ))
)
if (!identical(
  unname(active_fingerprints),
  unname(unlist(canonical_provenance[names(active_fingerprints)]))
)) {
  stop("Active Stage 2 sources do not match the checkpoint fingerprints.", call. = FALSE)
}
runtime_image_id <- Sys.getenv("RC_DATES_IMAGE_ID", unset = "not-recorded")
if (!identical(runtime_image_id, canonical_provenance$container_image_id)) {
  stop("The Stage 2 summariser is not running in the generation container.", call. = FALSE)
}
image_id_path <- file.path(settings$input_dir, "container_image_id.txt")
if (!file.exists(image_id_path) ||
    !identical(readLines(image_id_path, warn = FALSE), runtime_image_id)) {
  stop("The Stage 2 container-image record does not match the artifacts.", call. = FALSE)
}

results <- do.call(rbind, result_list)
rownames(results) <- NULL
validate_population_simulation_results(
  results,
  nsim = settings$nsim,
  design = "signed-v1"
)

for (truth in contract$truths) {
  all_dates <- results[results$true == truth & results$strategy == "r_all", ]
  comparison_columns <- setdiff(names(all_dates), "prop")
  canonical <- all_dates[all_dates$prop == 1, comparison_columns, drop = FALSE]
  canonical <- canonical[order(canonical$sim, canonical$type, canonical$model), ]
  rownames(canonical) <- NULL
  for (prop in c(0.5, 0.75)) {
    candidate <- all_dates[all_dates$prop == prop, comparison_columns, drop = FALSE]
    candidate <- candidate[order(candidate$sim, candidate$type, candidate$model), ]
    rownames(candidate) <- NULL
    if (!identical(candidate, canonical)) {
      stop(
        "Common-random-number all-dates check failed for ", truth, " at prop = ", prop,
        call. = FALSE
      )
    }
  }
}

confusion <- summarise_stage2_confusion(results)
selection <- summarise_stage2_selection(results)
bias <- summarise_stage2_log_ratio_bias(results)
boundaries <- summarise_stage2_boundaries(results)
paired <- summarise_stage2_paired_contrasts(results)

metadata_list <- lapply(paste0(result_paths, ".metadata.txt"), read_population_simulation_metadata)
manifest <- do.call(rbind, Map(function(path, result, metadata) {
  provenance <- attr(result, "production_provenance", exact = TRUE)
  data.frame(
    file = basename(path),
    metadata_file = basename(paste0(path, ".metadata.txt")),
    truth = unique(result$true),
    site_treatment_proportion = unique(result$prop),
    effect_ratio = provenance$ratio,
    replicates = length(unique(result$sim)),
    rows = nrow(result),
    bytes = file.info(path)$size,
    md5 = unname(tools::md5sum(path)),
    generation_completed_utc = metadata[["generation_completed_utc"]],
    container_image_id = provenance$container_image_id,
    r_version = provenance$r_version,
    stringsAsFactors = FALSE
  )
}, result_paths, result_list, metadata_list))

dir.create(settings$input_dir, recursive = TRUE, showWarnings = FALSE)
summary_paths <- c(
  manifest = file.path(settings$input_dir, "stage2_manifest.csv"),
  confusion = file.path(settings$input_dir, "truth_state_confusion.csv"),
  selection = file.path(settings$input_dir, "selection_performance.csv"),
  bias = file.path(settings$input_dir, "log_ratio_bias.csv"),
  boundaries = file.path(settings$input_dir, "boundary_frequency.csv"),
  paired = file.path(settings$input_dir, "paired_contrasts_vs_all.csv")
)
readr::write_csv(manifest, summary_paths[["manifest"]])
readr::write_csv(confusion, summary_paths[["confusion"]])
readr::write_csv(selection, summary_paths[["selection"]])
readr::write_csv(bias, summary_paths[["bias"]])
readr::write_csv(boundaries, summary_paths[["boundaries"]])
readr::write_csv(paired, summary_paths[["paired"]])

validation_path <- file.path(settings$input_dir, "VALIDATION.txt")
writeLines(c(
  "rc-dates Stage 2 signed-model evidence: ACCEPTED",
  paste("validated_utc:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  "design: signed-v1",
  paste("truths:", paste(contract$truths, collapse = ",")),
  paste("site_treatment_proportions:", paste(proportions, collapse = ",")),
  paste("effect_ratio:", format(settings$ratio, scientific = FALSE, trim = TRUE)),
  paste("replicates_per_scenario:", settings$nsim),
  paste("scenarios:", length(result_paths)),
  paste("rows:", nrow(results)),
  "all_dates_common_random_numbers: PASS",
  "artifact_and_metadata_fingerprints: PASS",
  "single_runtime_and_design: PASS",
  paste("r_version:", canonical_provenance$r_version),
  paste("container_image_id:", canonical_provenance$container_image_id)
), validation_path)

checksum_paths <- c(
  result_paths,
  paste0(result_paths, ".metadata.txt"),
  unname(summary_paths),
  validation_path,
  image_id_path
)
checksums <- vapply(checksum_paths, function(path) {
  digest::digest(path, algo = "sha256", serialize = FALSE, file = TRUE)
}, character(1))
writeLines(
  paste(checksums, basename(checksum_paths)),
  file.path(settings$input_dir, "SHA256SUMS")
)

message(
  "Accepted Stage 2 signed-model evidence: ",
  length(result_paths),
  " scenarios, ",
  nrow(results),
  " rows."
)
