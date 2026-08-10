#!/usr/bin/env Rscript

parse_estimand_aligned_args <- function(args) {
  settings <- list(
    input_dir = file.path("out", "sensitivity", "observation-noise"),
    output_dir = file.path(
      "out", "sensitivity", "observation-noise", "estimand-aligned-v2"
    ),
    nsim = 1000L, n_boot = 50000L, master_seed = 1234L,
    stability_seed = 5678L
  )
  key_map <- c(
    `input-dir` = "input_dir", `output-dir` = "output_dir", nsim = "nsim",
    `n-boot` = "n_boot", `master-seed` = "master_seed",
    `stability-seed` = "stability_seed"
  )
  for (argument in args) {
    parts <- regmatches(argument, regexec("^--([^=]+)=(.*)$", argument))[[1L]]
    if (length(parts) != 3L || !parts[[2L]] %in% names(key_map)) {
      stop("Unknown or malformed argument: ", argument, call. = FALSE)
    }
    settings[[key_map[[parts[[2L]]]]]] <- parts[[3L]]
  }
  for (field in c("nsim", "n_boot", "master_seed", "stability_seed")) {
    settings[[field]] <- suppressWarnings(as.integer(settings[[field]]))
    if (is.na(settings[[field]]) || settings[[field]] < 1L) {
      stop("Invalid positive integer for ", field, call. = FALSE)
    }
  }
  settings
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 1L && args[[1L]] %in% c("--help", "-h")) {
  writeLines(c(
    "Summarise frozen paired observation-noise checkpoints with estimand-aligned v2 gates.",
    "",
    "  --input-dir=out/sensitivity/observation-noise",
    "  --output-dir=out/sensitivity/observation-noise/estimand-aligned-v2",
    "  --nsim=1000 --n-boot=50000 --master-seed=1234 --stability-seed=5678"
  ))
  quit(status = 0L)
}
settings <- parse_estimand_aligned_args(args)
if (!identical(as.character(getRversion()), "4.5.3")) {
  stop("Estimand-aligned summaries require R 4.5.3; found ", R.version.string, ".",
       call. = FALSE)
}
if (!identical(settings$nsim, 1000L) || !identical(settings$master_seed, 1234L)) {
  stop("The v2 path is fixed to the nine frozen 1,000-pair checkpoints and seed 1234.",
       call. = FALSE)
}
required <- c(
  "R/population_simulation_production.R", "R/observation_noise_sensitivity.R",
  "R/observation_noise_summaries.R", "R/observation_noise_estimand_aligned.R"
)
missing <- required[!file.exists(required)]
if (length(missing) > 0L) {
  stop("Run from the rc-dates repository root; missing: ", paste(missing, collapse = ", "),
       call. = FALSE)
}
invisible(lapply(required, source))
required_packages <- c("digest", "jsonlite", "readr")
missing_packages <- required_packages[!vapply(
  required_packages, requireNamespace, logical(1), quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop("Missing summary packages: ", paste(missing_packages, collapse = ", "), call. = FALSE)
}

models <- c("uni", "lin", "exp")
props <- c(0.5, 0.75, 1)
paths <- unlist(lapply(models, function(model) {
  file.path(settings$input_dir, vapply(props, function(prop) {
    observation_noise_sensitivity_filename(model, prop, settings$nsim, settings$master_seed)
  }, character(1)))
}), use.names = FALSE)
if (length(paths) != 9L || any(!file.exists(paths))) {
  stop("Exactly nine frozen observation-noise checkpoints are required; missing: ",
       paste(paths[!file.exists(paths)], collapse = ", "), call. = FALSE)
}
artifacts <- lapply(paths, validate_observation_noise_artifact,
                    expected_nsim = settings$nsim, expected_seed = settings$master_seed)
checkpoints <- lapply(artifacts, `[[`, "checkpoint")
validated <- validate_observation_noise_summary_inputs(checkpoints)
summary <- observation_noise_estimand_aligned_summary(
  validated, n_boot = settings$n_boot, master_seed = settings$master_seed,
  stability_seed = settings$stability_seed
)

dir.create(settings$output_dir, recursive = TRUE, showWarnings = FALSE)
atomic_write <- function(path, writer) {
  temporary <- paste0(path, ".tmp-", Sys.getpid())
  on.exit(unlink(temporary), add = TRUE)
  writer(temporary)
  if (file.exists(path) && !file.remove(path)) stop("Could not replace ", path, call. = FALSE)
  if (!file.rename(temporary, path)) stop("Could not atomically write ", path, call. = FALSE)
  invisible(path)
}
write_csv_atomic <- function(data, path) {
  atomic_write(path, function(temporary) readr::write_csv(data, temporary, na = ""))
}
write_rds_atomic <- function(data, path) {
  atomic_write(path, function(temporary) saveRDS(data, temporary, version = 3))
}
write_json_atomic <- function(data, path) {
  atomic_write(path, function(temporary) jsonlite::write_json(
    data, temporary, auto_unbox = TRUE, pretty = TRUE, digits = NA
  ))
}

metrics <- do.call(rbind, lapply(names(summary$metrics), function(name) {
  data <- summary$metrics[[name]]
  data$metric_family <- name
  data
}))
metrics <- metrics[c(
  "metric_family", "metric", "scope", "true", "prop", "strategy", "type", "arm",
  "estimate", "ci_low", "ci_high", "margin", "interval", "n_clusters"
)]
write_csv_atomic(metrics, file.path(settings$output_dir, "metrics.csv"))
write_csv_atomic(summary$gates, file.path(settings$output_dir, "gate_report.csv"))
write_rds_atomic(summary$gates, file.path(settings$output_dir, "gate_report.rds"))
write_json_atomic(summary$gates, file.path(settings$output_dir, "gate_report.json"))
gate_status <- if (isTRUE(summary$gate_pass)) "PASS" else "FAIL"
markdown <- c(
  "# Estimand-aligned v2 observation-noise gate report", "",
  paste0("Status: **", gate_status, "**"), "",
  "The v2 family is defined after unblinding and contains only paired difference estimands.",
  "Accuracy and OSE use two-sided simultaneous max-deviation intervals; boundary uses a",
  "one-sided simultaneous maximum-positive-deviation upper bound.", "",
  "| Gate | Pass | Pooled max | Truth max | Pooled margin | Truth margin |",
  "|---|---:|---:|---:|---:|---:|",
  apply(summary$gates, 1L, function(row) paste0(
    "| ", row[["gate"]], " | ", row[["pass"]], " | ", row[["pooled_max"]], " | ",
    row[["truth_max"]], " | ", row[["pooled_margin"]], " | ", row[["truth_margin"]], " |"
  ))
)
atomic_write(
  file.path(settings$output_dir, "gate_report.md"),
  function(temporary) writeLines(markdown, temporary)
)
write_csv_atomic(summary$stability, file.path(settings$output_dir, "stability.csv"))

v1_metadata <- file.path(settings$input_dir, "summary", "observation_noise_summary_metadata.txt")
if (!file.exists(v1_metadata)) {
  stop("Missing v1 summary metadata; cannot retain v1 interpretation.", call. = FALSE)
}
v1_lines <- readLines(v1_metadata, warn = FALSE)
v1_value <- function(key, fallback = "") {
  hit <- grep(paste0("^", key, ":"), v1_lines, value = TRUE)
  if (length(hit) != 1L) fallback else sub(paste0("^", key, ":[[:space:]]*"), "", hit)
}
v1_status <- v1_value("gate_status", "FAIL")
if (!identical(v1_status, "FAIL")) {
  stop("The v1 formal FAIL status is required and must be retained.", call. = FALSE)
}
v1_gate_path <- file.path(
  settings$input_dir,
  "summary",
  "observation_noise_gate_report.csv"
)
if (!file.exists(v1_gate_path)) {
  stop("Missing v1 gate report; cannot retain the original decision.", call. = FALSE)
}
v1_gates <- utils::read.csv(
  v1_gate_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
v1_pass_count <- sum(v1_gates$pass %in% TRUE)
v1_fail_names <- v1_gates$gate[!(v1_gates$pass %in% TRUE)]
if (nrow(v1_gates) != 18L || v1_pass_count != 15L ||
    !setequal(
      v1_fail_names,
      c(
        "accuracy_difference_ci",
        "ose_support_difference_ci",
        "boundary_hit_increase"
      )
    )) {
  stop("The retained v1 gate report is not the expected 15/18 FAIL.", call. = FALSE)
}
v1_metric_endpoints <- function(name, one_sided = FALSE) {
  path <- file.path(settings$input_dir, "summary", paste0("observation_noise_", name, ".csv"))
  if (!file.exists(path)) stop("Missing v1 metric evidence: ", path, call. = FALSE)
  metric <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  metric <- metric[metric$arm == "difference", , drop = FALSE]
  if (nrow(metric) == 0L) stop("Missing v1 difference rows in: ", path, call. = FALSE)
  endpoint <- function(rows) {
    if (one_sided) max(rows$ci_high, na.rm = TRUE) else {
      max(abs(c(rows$ci_low, rows$ci_high)), na.rm = TRUE)
    }
  }
  pooled <- endpoint(metric[metric$scope == "pooled", , drop = FALSE])
  truth <- endpoint(metric[metric$scope != "pooled", , drop = FALSE])
  point <- range(metric$estimate, na.rm = TRUE)
  full <- if (one_sided) max(metric$ci_high, na.rm = TRUE) else endpoint(metric)
  list(pooled = pooled, truth = truth, full = full, point = point)
}
v1_accuracy <- v1_metric_endpoints("accuracy")
v1_ose <- v1_metric_endpoints("ose_support")
v1_boundary <- v1_metric_endpoints("boundary", one_sided = TRUE)
atomic_write(
  file.path(settings$output_dir, "v1_interpretation.md"),
  function(temporary) writeLines(c(
    "# v1 interpretation retained", "",
    "The original v1 summary remains **FAIL (15 of 18 gates passed)**.",
    paste0("Accuracy difference: pooled endpoint ", signif(v1_accuracy$pooled, 6),
           " against ±0.03; truth endpoint ", signif(v1_accuracy$truth, 6),
           " against ±0.05",
           "; point range ", paste(signif(v1_accuracy$point, 6), collapse = " to "), "."),
    paste0("OSE difference: pooled endpoint ", signif(v1_ose$pooled, 6),
           " against ±0.03; truth endpoint ", signif(v1_ose$truth, 6),
           " against ±0.05",
           "; point range ", paste(signif(v1_ose$point, 6), collapse = " to "), "."),
    paste0("Boundary difference: full-family upper bound ", signif(v1_boundary$full, 6),
           " against <0.01; point range ",
           paste(signif(v1_boundary$point, 6), collapse = " to "), "."),
    "For each metric, v1 calibrated one full-family width over marginal curve-mean and",
    "realised arms as well as paired differences (288 cells for accuracy and OSE; 216",
    "for boundary). The v1 accuracy table displayed 0.05 even though pooled rows used",
    "±0.03; its CSV and the separate endpoints above are required to interpret the FAIL.",
    "v2 is a separately labelled post-unblinding diagnostic over difference estimands",
    "only. It does not replace or retroactively pass the original v1 decision."
  ), temporary)
)

metadata <- c(
  "analysis_label: post_unblinding_estimand_aligned_v2",
  "schema_version: 2",
  paste("generation_completed_utc:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste("r_version:", R.version.string),
  paste("rcarbon_version:", as.character(utils::packageVersion("rcarbon"))),
  paste("paired_replicates:", settings$nsim),
  paste("bootstrap_resamples:", settings$n_boot),
  paste("master_seed:", settings$master_seed),
  paste("stability_master_seed:", settings$stability_seed),
  "accuracy_seed_offset: 0", "ose_seed_offset: 10", "boundary_seed_offset: 60",
  "accuracy_ose_interval: paired_simulation_cluster_difference_max_deviation_95",
  "boundary_interval: paired_simulation_cluster_maximum_positive_deviation_upper_95",
  "difference_family: accuracy,ose (96 cells each)",
  "boundary_difference_family: 72 cells",
  paste("v2_gate_status:", gate_status),
  paste("stability_status:", if (summary$stability_agree) "AGREE" else "DISAGREE"),
  paste("v1_gate_status:", v1_status),
  paste("v1_gate_pass_count:", v1_pass_count),
  paste("v1_gate_fail_count:", length(v1_fail_names)),
  paste("v1_failed_gates:", paste(v1_fail_names, collapse = ",")),
  paste("v1_fail_retained:", identical(v1_status, "FAIL")),
  paste("v1_summary_source_md5:", v1_value("summary_source_md5")),
  paste("v1_summary_runner_md5:", v1_value("summary_runner_md5")),
  paste("v2_source_md5:", unname(tools::md5sum("R/observation_noise_estimand_aligned.R"))),
  paste(
    "v2_runner_md5:",
    unname(tools::md5sum("scripts/summarise_observation_noise_estimand_aligned.R"))
  ),
  paste(
    "checkpoint_md5s:",
    paste(
      paste0(
        basename(paths),
        "=",
        vapply(artifacts, `[[`, character(1), "checkpoint_md5")
      ),
      collapse = ";"
    )
  ),
  paste(
    "pair_manifest_md5s:",
    paste(
      paste0(
        sub("\\.rds$", ".pairs.csv", basename(paths)),
        "=",
        vapply(artifacts, `[[`, character(1), "pair_md5")
      ),
      collapse = ";"
    )
  ),
  paste("v1_summary_metadata_md5:", unname(tools::md5sum(v1_metadata))),
  paste(
    "packages:",
    paste(
      paste0(
        required_packages,
        "=",
        vapply(
          required_packages,
          function(package) as.character(utils::packageVersion(package)),
          character(1)
        )
      ),
      collapse = ";"
    )
  )
)
atomic_write(
  file.path(settings$output_dir, "metadata.txt"),
  function(temporary) writeLines(metadata, temporary)
)

write_sha256 <- function(root, filename, exclude_nested_manifests = TRUE) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  files <- list.files(root, recursive = TRUE, full.names = TRUE, all.files = FALSE, no.. = TRUE)
  files <- files[!file.info(files)$isdir]
  relative <- substring(files, nchar(root) + 2L)
  keep <- (if (isTRUE(exclude_nested_manifests)) {
    !grepl("(^|/)SHA256SUMS$", relative)
  } else {
    relative != filename
  }) &
    !grepl("(^|/)logs/", relative) & !grepl("(^|/)[.]", relative)
  files <- files[keep]
  relative <- relative[keep]
  ordering <- order(relative)
  hashes <- vapply(files[ordering], function(path) {
    digest::digest(file = path, algo = "sha256", serialize = FALSE)
  }, character(1))
  atomic_write(file.path(root, filename), function(temporary) {
    writeLines(paste(hashes, relative[ordering], sep = "  "), temporary)
  })
}
write_sha256(settings$output_dir, "SHA256SUMS")
write_sha256(settings$input_dir, "SHA256SUMS", exclude_nested_manifests = FALSE)
if (!isTRUE(summary$stability_agree)) quit(status = 1L)
if (!isTRUE(summary$gate_pass)) quit(status = 2L)
