#!/usr/bin/env Rscript

# Build the de-identified code/data review package outside the named GitHub repo.
# The package is intentionally code-only: no manuscript sources, reports, refs, docs,
# source-control metadata, or internal agent notes are copied.

args <- commandArgs(trailingOnly = TRUE)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
default_parent <- "/home/bwbrook/papers/de_identified_repos"
package_parent <- if (length(args) >= 1L) args[[1L]] else default_parent
package_parent <- normalizePath(package_parent, winslash = "/", mustWork = FALSE)
package_name <- "rc_review_package"
package_dir <- file.path(package_parent, package_name)

required_files <- c(
  "_targets.R",
  "dependencies.R",
  ".gitattributes",
  ".lintr",
  "LICENSE",
  "renv.lock",
  "renv/.gitignore",
  "renv/activate.R",
  "renv/settings.json",
  "scripts/bootstrap.R",
  "data/Austarch_1-3_and_IDASQ_28Nov13-1.csv",
  "data/austarch_filtered.csv"
)

required_dirs <- c("R", "config", "tests", "inst/extdata")

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
  ".gitattributes",
  ".lintr",
  "LICENSE",
  "renv.lock",
  "renv/.gitignore",
  "renv/activate.R",
  "renv/settings.json",
  "scripts/bootstrap.R"
)) {
  copy_file(file)
}

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
    ".PHONY: help restore test manifest pipeline check clean",
    "",
    "help:",
    "\t@echo \"Code review package commands:\"",
    "\t@echo \"  make restore   Restore pinned R packages with renv\"",
    "\t@echo \"  make test      Run the testthat suite\"",
    "\t@echo \"  make manifest  Print the targets manifest\"",
    "\t@echo \"  make pipeline  Run the analysis pipeline\"",
    "\t@echo \"  make check     Run restore, tests, manifest, and pipeline\"",
    "\t@echo \"  make clean     Remove generated targets artefacts\"",
    "",
    "restore:",
    "\tRscript -e 'source(\"renv/activate.R\"); renv::restore(prompt = FALSE)'",
    "",
    "test:",
    "\tRscript tests/run-tests.R",
    "",
    "manifest:",
    "\tRscript -e 'targets::tar_manifest(script = \"_targets.R\", callr_function = NULL)'",
    "",
    "pipeline:",
    "\tRscript -e 'targets::tar_make()'",
    "",
    "check:",
    "\tRscript scripts/run_review_checks.R",
    "",
    "clean:",
    "\tRscript -e 'targets::tar_destroy(destroy = \"all\")'"
  )
)

write_text(
  "scripts/run_review_checks.R",
  c(
    "source(\"renv/activate.R\")",
    "renv::restore(prompt = FALSE)",
    "",
    "source(\"tests/run-tests.R\")",
    "print(targets::tar_manifest(script = \"_targets.R\", callr_function = NULL))",
    "targets::tar_make()"
  )
)

write_text(
  "SIMULATION_PROVENANCE.md",
  c(
    "# Production Simulation Provenance",
    "",
    "The fast reviewer path runs the same sampling and summary code in `simulate.mode: demo`.",
    "That path is intended to verify the code, data ingest, calibration, summaries,",
    "targets graph, and test suite on an ordinary reviewer machine.",
    "",
    "The high-volume production simulations used for the manuscript's model-recovery,",
    "parameter-bias, and evidential-strength displays were run outside the default",
    "reviewer pipeline. The original legacy result reader expected these locked RDS",
    "files:",
    "",
    "- `out/results_exp_p0.5_ratio10_nsim1000_2025-05-21.rds`",
    "- `out/results_lin_p0.5_ratio10_nsim1000_2025-05-21.rds`",
    "- `out/results_uni_p0.5_ratio10_nsim1000_2025-05-21.rds`",
    "- `out/results_exp_p0.75_ratio10_nsim1000_2025-05-22.rds`",
    "- `out/results_lin_p0.75_ratio10_nsim1000_2025-05-22.rds`",
    "- `out/results_uni_p0.75_ratio10_nsim1000_2025-05-22.rds`",
    "- `out/results_exp_p1_ratio10_nsim1000_2025-05-20.rds`",
    "- `out/results_lin_p1_ratio10_nsim1000_2025-05-20.rds`",
    "- `out/results_uni_p1_ratio10_nsim1000_2025-05-20.rds`",
    "",
    "Those RDS files are not included in this de-identified code-review package.",
    "If exact numerical reruns of the high-volume simulations are required before",
    "upload, add converted `data/simulation_summary_*.csv` files and switch",
    "`config/config.yml` to `simulate.mode: precomputed` before rebuilding the zip."
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
    "",
    "## Contents",
    "",
    "- `_targets.R` - code-only `{targets}` pipeline for ingest, validation,",
    "  calibration, summaries, figures, and demo simulation outputs.",
    "- `R/` - analysis, validation, plotting, and simulation helper functions.",
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
    "Install R 4.5.x; the lockfile was refreshed under R 4.5.3 and should be",
    "restored with the same R minor series. Newer R minor releases may try to",
    "rebuild pinned source packages and fail. Then run from this directory:",
    "",
    "```sh",
    "Rscript -e 'source(\"renv/activate.R\"); renv::restore(prompt = FALSE)'",
    "```",
    "",
    "On Linux, some spatial/graphics packages may require system libraries before",
    "`renv::restore()` can complete. Typical Ubuntu packages are:",
    "",
    "```sh",
    "sudo apt-get update",
    "sudo apt-get install -y cmake gdal-bin gsfonts libcurl4-openssl-dev libgdal-dev libglpk-dev libmagick++-dev libudunits2-dev libx11-dev",
    "```",
    "",
    "## Run Checks",
    "",
    "```sh",
    "Rscript tests/run-tests.R",
    "```",
    "",
    "or:",
    "",
    "```sh",
    "make test",
    "```",
    "",
    "## Run The Pipeline",
    "",
    "```sh",
    "Rscript -e 'targets::tar_make()'",
    "```",
    "",
    "or:",
    "",
    "```sh",
    "make pipeline",
    "```",
    "",
    "Generated artefacts are written to `_targets/`, `outputs/`, and `figs/`.",
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
    "",
    "It does not contain the manuscript source, author-identifying project notes,",
    "internal reports, reference-management files, or repository metadata.",
    "",
    "## Fast Verification Path",
    "",
    "From the archive root:",
    "",
    "```sh",
    "Rscript -e 'source(\"renv/activate.R\"); renv::restore(prompt = FALSE)'",
    "Rscript tests/run-tests.R",
    "Rscript -e 'targets::tar_manifest(script = \"_targets.R\", callr_function = NULL)'",
    "Rscript -e 'targets::tar_make()'",
    "```",
    "",
    "The same path is available as:",
    "",
    "```sh",
    "make restore",
    "make test",
    "make manifest",
    "make pipeline",
    "```",
    "",
    "Generated files are written to `_targets/`, `outputs/`, and `figs/`.",
    "",
    "Use R 4.5.x for this path. The lockfile was refreshed under R 4.5.3;",
    "restoring it under a newer R minor series can force source rebuilds of",
    "pinned packages and is not the intended reviewer environment.",
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
    "## Simulation Artefacts",
    "",
    "The default configuration uses `simulate.mode: demo`. This mode runs a reduced",
    "simulation workflow with fixed seeds so that reviewers can exercise the",
    "sampling, summary, and plotting code on an ordinary machine.",
    "",
    "The high-volume population-model simulations described in the manuscript are",
    "not rerun by the fast reviewer path. See `SIMULATION_PROVENANCE.md` for the",
    "scope note and the production-output filenames expected by the legacy result",
    "reader.",
    "",
    "If production summaries are added later, include them as",
    "`data/simulation_summary_*.csv` files and set `config/config.yml` to:",
    "",
    "```yaml",
    "simulate:",
    "  mode: precomputed",
    "  precomputed:",
    "    dir: data",
    "    pattern: ^simulation_summary_.*\\.csv$",
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
