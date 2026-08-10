#!/usr/bin/env Rscript

parse_summary_args <- function(args) {
  settings <- list(
    input_dir = file.path("out", "sensitivity", "observation-noise"),
    output_dir = file.path("out", "sensitivity", "observation-noise", "summary"),
    nsim = 1000L, n_boot = 5000L, seed = 1234L
  )
  key_map <- c(`input-dir` = "input_dir", `output-dir` = "output_dir",
               nsim = "nsim", `n-boot` = "n_boot", seed = "seed")
  for (argument in args) {
    parts <- regmatches(argument, regexec("^--([^=]+)=(.*)$", argument))[[1L]]
    if (length(parts) != 3L || !parts[[2L]] %in% names(key_map)) {
      stop("Unknown or malformed argument: ", argument, call. = FALSE)
    }
    settings[[key_map[[parts[[2L]]]]]] <- parts[[3L]]
  }
  for (field in c("nsim", "n_boot", "seed")) {
    settings[[field]] <- suppressWarnings(as.integer(settings[[field]]))
    if (is.na(settings[[field]]) || settings[[field]] < 1L) {
      stop("Invalid positive integer for ", field, call. = FALSE)
    }
  }
  settings
}

if (length(commandArgs(trailingOnly = TRUE)) == 1L &&
    commandArgs(trailingOnly = TRUE)[[1L]] %in% c("--help", "-h")) {
  writeLines(c(
    "Summarise paired curve-mean versus realised observation-noise checkpoints.",
    "",
    "  --input-dir=out/sensitivity/observation-noise",
    "  --output-dir=out/sensitivity/observation-noise/summary",
    "  --nsim=1000 --n-boot=5000 --seed=1234"
  ))
  quit(status = 0L)
}

required <- c("R/population_simulation_production.R", "R/observation_noise_sensitivity.R",
              "R/observation_noise_summaries.R")
missing <- required[!file.exists(required)]
if (length(missing) > 0L) stop("Run from the rc-dates repository root; missing: ",
                                paste(missing, collapse = ", "), call. = FALSE)
source(required[[1L]])
source(required[[2L]])
source(required[[3L]])
settings <- parse_summary_args(commandArgs(trailingOnly = TRUE))
if (!identical(as.character(getRversion()), "4.5.3")) {
  stop(
    "Observation-noise summaries require R 4.5.3; found ",
    R.version.string,
    ".",
    call. = FALSE
  )
}
required_packages <- c("digest", "jsonlite", "rcarbon", "readr")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop(
    "Missing observation-noise summary packages: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

models <- c("uni", "lin", "exp")
props <- c(0.5, 0.75, 1)
paths <- unlist(lapply(models, function(model) {
  file.path(settings$input_dir, vapply(props, function(prop) {
    observation_noise_sensitivity_filename(model, prop, settings$nsim, settings$seed)
  }, character(1)))
}), use.names = FALSE)
if (any(!file.exists(paths))) {
  stop("Missing observation-noise checkpoints: ", paste(paths[!file.exists(paths)], collapse = ", "),
       call. = FALSE)
}
artifacts <- lapply(paths, validate_observation_noise_artifact,
                    expected_nsim = settings$nsim,
                    expected_seed = settings$seed)
checkpoints <- lapply(artifacts, `[[`, "checkpoint")
summary <- summarise_observation_noise_sensitivity(checkpoints, n_boot = settings$n_boot,
                                                   seed = settings$seed)
dir.create(settings$output_dir, recursive = TRUE, showWarnings = FALSE)

write_summary_csv <- function(data, name) {
  if (is.null(data) || nrow(data) == 0L) return(invisible(NULL))
  path <- file.path(settings$output_dir, paste0("observation_noise_", name, ".csv"))
  readr::write_csv(data, path)
  invisible(path)
}
invisible(lapply(names(summary$metrics), function(name) write_summary_csv(summary$metrics[[name]], name)))
write_summary_csv(summary$gates, "gate_report")
saveRDS(summary$gates, file.path(settings$output_dir, "observation_noise_gate_report.rds"), version = 3)
jsonlite::write_json(summary$gates, file.path(settings$output_dir,
                                              "observation_noise_gate_report.json"),
                     auto_unbox = TRUE, pretty = TRUE, digits = NA)

status <- if (isTRUE(summary$gate_pass)) "PASS" else "FAIL"
lines <- c(
  "# Paired observation-noise sensitivity gate report", "",
  paste0("Status: **", status, "**"), "",
  paste0("Bootstrap: paired cluster bootstrap by simulation replicate; ", settings$n_boot,
         " resamples; simultaneous 95% max-deviation intervals."), "",
  "A failed gate is not silently passed: inspect the corresponding CSV and consider a focused rerun, full expansion, or precision extension.", "",
  "| Gate | Pass | Observed | Threshold | Details |", "|---|---:|---:|---:|---|"
)
if (nrow(summary$gates) > 0L) {
  lines <- c(lines, apply(summary$gates, 1L, function(x) {
    paste0("| ", x[["gate"]], " | ", x[["pass"]], " | ", x[["observed"]], " | ",
           x[["threshold"]], " | ", x[["details"]], " |")
  }))
}
writeLines(lines, file.path(settings$output_dir, "observation_noise_gate_report.md"))

format_artifact_hashes <- function(field, path_field) {
  paste(vapply(artifacts, function(artifact) {
    paste0(basename(artifact[[path_field]]), "=", artifact[[field]])
  }, character(1)), collapse = ";")
}
package_versions <- vapply(
  required_packages,
  function(package) as.character(utils::packageVersion(package)),
  character(1)
)
metadata_path <- file.path(
  settings$output_dir,
  "observation_noise_summary_metadata.txt"
)
writeLines(c(
  "rc-dates paired observation-noise sensitivity summary",
  "schema_version: 1",
  paste("generation_completed_utc:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste("r_version:", R.version.string),
  paste("rcarbon_version:", as.character(utils::packageVersion("rcarbon"))),
  paste("paired_replicates:", settings$nsim),
  paste("bootstrap_resamples:", settings$n_boot),
  paste("bootstrap_seed:", settings$seed),
  "bootstrap_interval: paired_simulation_cluster_max_deviation_95",
  "strategies: r_all,r_1,r_3,r_5",
  paste("gate_status:", status),
  paste("gate_names:", paste(summary$gates$gate, collapse = ",")),
  paste(
    "summary_source_md5:",
    unname(tools::md5sum("R/observation_noise_summaries.R"))
  ),
  paste(
    "summary_runner_md5:",
    unname(tools::md5sum("scripts/summarise_observation_noise_sensitivity.R"))
  ),
  paste(
    "frozen_snapshot_inventory_sha256:",
    artifacts[[1L]]$frozen_manifest_sha256
  ),
  paste(
    "input_md5:",
    checkpoints[[1L]]$provenance$input_md5
  ),
  paste(
    "renv_lock_md5:",
    checkpoints[[1L]]$provenance$renv_lock_md5
  ),
  paste(
    "container_image_id:",
    checkpoints[[1L]]$provenance$container_image_id
  ),
  paste("checkpoint_md5s:", format_artifact_hashes("checkpoint_md5", "path")),
  paste("pair_manifest_md5s:", format_artifact_hashes("pair_md5", "pair_path")),
  paste("metadata_md5s:", format_artifact_hashes("metadata_md5", "metadata_path")),
  paste(
    "packages:",
    paste(
      paste(names(package_versions), package_versions, sep = "="),
      collapse = ";"
    )
  )
), metadata_path)

write_observation_noise_sha256 <- function(input_dir) {
  root <- normalizePath(input_dir, winslash = "/", mustWork = TRUE)
  files <- list.files(
    root,
    recursive = TRUE,
    full.names = TRUE,
    all.files = FALSE,
    no.. = TRUE
  )
  files <- files[file.info(files)$isdir %in% FALSE]
  relative <- substring(files, nchar(root) + 2L)
  keep <- relative != "SHA256SUMS" &
    !startsWith(relative, "logs/") &
    !grepl("(^|/)[.][^/]+$", relative)
  files <- files[keep]
  relative <- relative[keep]
  ordering <- order(relative)
  files <- files[ordering]
  relative <- relative[ordering]
  hashes <- vapply(files, function(path) {
    digest::digest(file = path, algo = "sha256", serialize = FALSE)
  }, character(1))
  inventory_path <- file.path(root, "SHA256SUMS")
  temporary <- paste0(inventory_path, ".tmp-", Sys.getpid())
  on.exit(unlink(temporary), add = TRUE)
  writeLines(paste(hashes, relative, sep = "  "), temporary)
  if (file.exists(inventory_path) && !file.remove(inventory_path)) {
    stop("Could not replace observation-noise SHA256SUMS.", call. = FALSE)
  }
  if (!file.rename(temporary, inventory_path)) {
    stop("Could not atomically write observation-noise SHA256SUMS.", call. = FALSE)
  }
  invisible(inventory_path)
}
write_observation_noise_sha256(settings$input_dir)
if (!isTRUE(summary$gate_pass)) quit(status = 2L)
