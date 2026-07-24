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
  "docker/production-simulation.Dockerfile",
  "docker/install-production-packages.R",
  "data/Austarch_1-3_and_IDASQ_28Nov13-1.csv",
  "data/austarch_filtered.csv",
  production_files
)

required_dirs <- c(
  "R",
  "config",
  "tests",
  "inst/extdata",
  "provenance/production-20260710"
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

builder_packages <- c("digest", "yaml")
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
  "docker/production-simulation.Dockerfile",
  "docker/install-production-packages.R"
)) {
  copy_file(file)
}

for (file in production_files) copy_file(file)

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
    "",
    ".PHONY: help r-preflight restore test manifest pipeline check clean",
    ".PHONY: production-figures production-rerun",
    "",
    "help:",
    "\t@echo \"Code review package commands:\"",
    "\t@echo \"  make r-preflight  Confirm Rscript resolves to R 4.5.3\"",
    "\t@echo \"  make restore   Restore pinned R packages with renv\"",
    "\t@echo \"  make test      Run the testthat suite\"",
    "\t@echo \"  make manifest  Print the targets manifest\"",
    "\t@echo \"  make pipeline  Run the analysis pipeline\"",
    "\t@echo \"  make production-figures  Rebuild Figures 3-5 from supplied RDS files\"",
    "\t@echo \"  make production-rerun    Rerun full simulations with Docker (expensive)\"",
    "\t@echo \"  make check     Run restore, tests, manifest, pipeline, and figure rebuild\"",
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
    "production-figures: restore",
    "\t\"$(RSCRIPT)\" scripts/render_population_simulation_figures.R \\",
    "\t\t--input-dir=out/production --summary-dir=out/production \\",
    "\t\t--figure-dir=figures",
    "",
    "production-rerun:",
    "\tRC_DATES_OUTPUT_DIR=out/rerun bash scripts/run_production_simulation_matrix.sh",
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
    "# Production Simulation Provenance",
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
    "future-run checkpoints record `native-checkpoint`."
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
    "- `out/production/` - nine validated production RDS files, runtime metadata,",
    "  and manuscript-display summary tables.",
    "- `provenance/production-20260710/` - exact de-identified source snapshot",
    "  whose hashes are embedded in the supplied production RDS files.",
    "- `scripts/render_population_simulation_figures.R` - rebuilds Figures 3-5",
    "  from the supplied production artefacts.",
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
    "For an independent full rerun on a 64-core Linux host with Docker:",
    "",
    "```sh",
    "make production-rerun",
    "```",
    "",
    "The rerun uses the included R 4.5.3 image recipe and writes checkpoints to",
    "`out/rerun/`, leaving the supplied production artefacts unchanged. See",
    "`SIMULATION_PROVENANCE.md` before starting this expensive path.",
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
