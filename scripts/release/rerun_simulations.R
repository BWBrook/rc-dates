#!/usr/bin/env Rscript

# Rerun the accepted simulation designs from the scalar release specification.
# The output is a release-wrapper RDS rather than the historical per-scenario
# artefact layout: its scientific rows are unchanged, with release provenance
# and (for noise) the paired-replicate manifest kept in the top-level list.

if (length(commandArgs(trailingOnly = TRUE)) == 1L &&
    commandArgs(trailingOnly = TRUE)[[1L]] %in% c("--help", "-h")) {
  writeLines(c(
    "Rerun the signed, Stage 6 or paired observation-noise simulation design.",
    "",
    "  --design=signed|noise|stage6 --nsim=1000 --cores=4 --batch-size=20",
    "  --output-dir=out/rerun/signed|out/rerun/noise",
    "Stage 6 requires --ratio=1.5|2|3|5 and --nsim=1..500.",
    "All requested replicates are compared with the accepted evidence."
  ))
  quit(status = 0L)
}

source("scripts/release/common.R")
args <- release_arguments(list(
  design = "signed",
  ratio = "10",
  nsim = "1000",
  cores = "4",
  `batch-size` = "20",
  `output-dir` = ""
))

design <- tolower(args$design)
if (!design %in% c("signed", "noise", "stage6")) {
  stop("--design must be signed, noise or stage6.", call. = FALSE)
}
signed_design <- design != "noise"
ratio <- suppressWarnings(as.numeric(args$ratio))
allowed_ratios <- if (design == "stage6") c(1.5, 2, 3, 5) else 10
if (length(ratio) != 1L || is.na(ratio) || !ratio %in% allowed_ratios) {
  stop("--ratio must be ", paste(allowed_ratios, collapse = ", "), " for ", design, ".", call. = FALSE)
}
to_positive_integer <- function(value, label) {
  parsed <- suppressWarnings(as.integer(value))
  if (length(parsed) != 1L || is.na(parsed) || parsed < 1L ||
      suppressWarnings(as.numeric(value)) != parsed) {
    stop(label, " must be a positive integer.", call. = FALSE)
  }
  parsed
}
nsim <- to_positive_integer(args$nsim, "--nsim")
cores <- to_positive_integer(args$cores, "--cores")
batch_size <- to_positive_integer(args[["batch-size"]], "--batch-size")
if (.Platform$OS.type == "windows" && cores > 1L) {
  warning("Multicore execution is unavailable on Windows; using one core.", call. = FALSE)
  cores <- 1L
}
accepted_nsim <- if (design == "stage6") 500L else 1000L
if (nsim > accepted_nsim) {
  stop("The release supports only accepted replicates 1-", accepted_nsim, " for ", design, ".")
}
if (!nzchar(args[["output-dir"]])) {
  args[["output-dir"]] <- file.path("out", "rerun", design)
  if (design == "stage6") {
    args[["output-dir"]] <- file.path(args[["output-dir"]], paste0("ratio", ratio))
  }
}
output_dir <- args[["output-dir"]]
if (length(output_dir) != 1L || !nzchar(output_dir)) {
  stop("--output-dir must be non-empty.", call. = FALSE)
}

accepted_dirs <- normalizePath(
  c("out/production", "out/revision/signed-models", "out/sensitivity/observation-noise",
    "out/revision/effect-size-20261018"),
  mustWork = FALSE
)
resolve_destination <- function(path) {
  if (file.exists(path)) return(normalizePath(path, mustWork = TRUE))
  parent <- dirname(path)
  if (identical(path, parent)) stop("Cannot resolve output path.")
  resolved_parent <- resolve_destination(parent)
  leaf <- basename(path)
  if (leaf == ".") return(resolved_parent)
  if (leaf == "..") return(dirname(resolved_parent))
  file.path(resolved_parent, leaf)
}
output_dir_abs <- resolve_destination(output_dir)
if (any(vapply(accepted_dirs, function(root) {
  identical(output_dir_abs, root) || startsWith(output_dir_abs, paste0(root, .Platform$file.sep))
}, logical(1)))) {
  stop("Refusing to write inside an accepted output directory: ", output_dir, call. = FALSE)
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

required_packages <- c("digest", "fitdistrplus", "rcarbon", "readr", "rlang", "tibble", "import", "withr")
missing_packages <- required_packages[!vapply(
  required_packages, requireNamespace, logical(1), quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop("Missing simulation packages: ", paste(missing_packages, collapse = ", "), call. = FALSE)
}

master_seed <- 1234L
proportions <- c(0.5, 0.75, 1)
spec_path <- "release/inputs/simulation_parameters.csv"
if (!file.exists(spec_path)) stop("Missing scalar simulation specification: ", spec_path, call. = FALSE)

if (signed_design) {
  source("scripts/source_population_simulation.R")
  source("scripts/release/simulation_specification.R")
  specification <- release_simulation_specification(spec_path, signed = TRUE)
  specification$ratio <- ratio
  span <- specification$max_age - specification$min_age
  specification$slope <- 2 * (ratio - 1) / ((ratio + 1) * span^2)
  specification$rate <- log(ratio) / span
  truths <- population_simulation_contract("signed-v1")$truths
  if (design == "stage6") truths <- setdiff(truths, "uni")
  strategies <- population_simulation_contract("signed-v1")$strategies
  source_paths <- c(
    "scripts/source_population_simulation.R",
    population_distribution_source,
    population_model_sources,
    "scripts/release/simulation_specification.R",
    "scripts/release/common.R",
    "scripts/release/rerun_simulations.R"
  )
  run_one <- function(sim, truth, prop) {
    run_population_simulation_replicate(
      sim = sim, truth = truth, prop = prop,
      specification = specification, master_seed = master_seed
    )
  }
} else {
  frozen_root <- "provenance/observation-noise-20260726/R"
  source(file.path(frozen_root, "legacy_simulation_helpers.R"))
  source(file.path(frozen_root, "population_simulation_production.R"))
  source(file.path(frozen_root, "observation_noise_sensitivity.R"))
  source("scripts/release/simulation_specification.R")
  specification <- release_simulation_specification(spec_path, signed = FALSE)
  truths <- c("uni", "lin", "exp")
  strategies <- c("r_all", "r_1", "r_3", "r_5")
  source_paths <- c(
    file.path(frozen_root, "legacy_simulation_helpers.R"),
    file.path(frozen_root, "population_simulation_production.R"),
    file.path(frozen_root, "observation_noise_sensitivity.R"),
    "scripts/release/simulation_specification.R",
    "scripts/release/common.R",
    "scripts/release/rerun_simulations.R"
  )
  run_one <- function(sim, truth, prop) {
    run_observation_noise_sensitivity_replicate(
      sim = sim, true_model = truth, prop = prop,
      specification = specification, master_seed = master_seed,
      strategies = strategies
    )
  }
}

source_paths <- unique(source_paths)
missing_sources <- source_paths[!file.exists(source_paths)]
if (length(missing_sources) > 0L) {
  stop("Missing rerun source: ", paste(missing_sources, collapse = ", "), call. = FALSE)
}
source_hashes <- stats::setNames(vapply(source_paths, function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}, character(1)), source_paths)
package_versions <- stats::setNames(vapply(
  required_packages, function(package) as.character(utils::packageVersion(package)), character(1)
), required_packages)
scenario_table <- expand.grid(
  truth = truths, prop = proportions, stringsAsFactors = FALSE
)
recipe_paths <- c("docker/Dockerfile", "release/templates/Dockerfile")
recipe_path <- recipe_paths[file.exists(recipe_paths)][1L]
if (is.na(recipe_path) || !file.exists("renv.lock")) {
  stop("Missing release runtime recipe or lockfile.", call. = FALSE)
}
release_provenance <- list(
  schema_version = 1L,
  renv_lock_sha256 = digest::digest(file = "renv.lock", algo = "sha256", serialize = FALSE),
  container_recipe_sha256 = digest::digest(file = recipe_path, algo = "sha256", serialize = FALSE),
  release_format = "rerun-wrapper-v1",
  design = design,
  nsim = nsim,
  master_seed = master_seed,
  ratio = ratio,
  proportions = proportions,
  scenarios = scenario_table,
  strategies = strategies,
  specification_sha256 = digest::digest(file = spec_path, algo = "sha256", serialize = FALSE),
  source_sha256 = source_hashes,
  r_version = R.version.string,
  package_versions = package_versions
)

checkpoint_path <- file.path(output_dir, paste0(design, "_checkpoint.rds"))
output_path <- file.path(output_dir, paste0(design, "_rerun.rds"))
if (file.exists(output_path)) {
  previous <- readRDS(output_path)
  if (!is.list(previous) || !identical(previous$release_provenance, release_provenance)) {
    stop("Existing final rerun output has incompatible provenance.", call. = FALSE)
  }
}

results <- NULL
pair_manifest <- NULL
if (file.exists(checkpoint_path)) {
  checkpoint <- readRDS(checkpoint_path)
  if (!is.list(checkpoint) || !identical(checkpoint$release_provenance, release_provenance)) {
    stop("Existing rerun checkpoint has incompatible design, specification, source, or runtime provenance.", call. = FALSE)
  }
  results <- checkpoint$results
  if (identical(design, "noise")) pair_manifest <- checkpoint$pair_manifest
  if (is.null(results) || !is.data.frame(results)) stop("Existing rerun checkpoint lacks result rows.", call. = FALSE)
  if (signed_design) {
    validate_population_simulation_results(results, design = "signed-v1")
  } else {
    validate_observation_noise_sensitivity_results(results, strategies = strategies)
    validate_observation_noise_pair_manifest(pair_manifest)
  }
}

scenario_rows <- function(data, truth, prop) {
  if (is.null(data)) return(NULL)
  data[data$true == truth & abs(data$prop - prop) < sqrt(.Machine$double.eps), , drop = FALSE]
}
append_rows <- function(old, new) {
  out <- if (is.null(old)) new else rbind(old, new)
  rownames(out) <- NULL
  out
}
completed_sims <- function(data, truth, prop) {
  rows <- scenario_rows(data, truth, prop)
  if (is.null(rows) || nrow(rows) == 0L) integer() else sort(unique(as.integer(rows$sim)))
}

compare_scenario <- function(truth, prop, results, pair_manifest = NULL) {
  if (signed_design) {
    expected_path <- file.path(
      if (design == "stage6") "out/revision/effect-size-20261018" else "out/revision/signed-models",
      production_simulation_filename(truth, prop, accepted_nsim, master_seed, ratio)
    )
    expected <- readRDS(expected_path)
    actual <- scenario_rows(results, truth, prop)
    expected <- expected[expected$sim <= nsim, , drop = FALSE]
    release_compare_rows(
      actual, expected, c("sim", "strategy", "type", "model"),
      paste(design, truth, prop, "ratio", ratio)
    )
  } else {
    expected_path <- file.path(
      "out/sensitivity/observation-noise",
      observation_noise_sensitivity_filename(truth, prop, 1000L, master_seed, ratio)
    )
    expected <- readRDS(expected_path)
    actual <- scenario_rows(results, truth, prop)
    expected_rows <- expected$results[expected$results$sim <= nsim, , drop = FALSE]
    release_compare_rows(
      actual, expected_rows,
      c("sim", "strategy", "type", "model", "observation_model"),
      paste("noise", truth, prop, "results")
    )
    expected_pairs <- expected$pair_manifest[expected$pair_manifest$sim <= nsim, , drop = FALSE]
    actual_pairs <- pair_manifest[pair_manifest$true == truth &
      abs(pair_manifest$prop - prop) < sqrt(.Machine$double.eps), , drop = FALSE]
    release_compare_rows(actual_pairs, expected_pairs, c("sim"), paste("noise", truth, prop, "pairs"))
  }
  invisible(NULL)
}

scenario_id <- function(truth, prop) paste(truth, format(prop, trim = TRUE), sep = "|")
scenario_key_set <- vapply(seq_len(nrow(scenario_table)), function(i) {
  scenario_id(scenario_table$truth[[i]], scenario_table$prop[[i]])
}, character(1))

for (i in seq_len(nrow(scenario_table))) {
  truth <- scenario_table$truth[[i]]
  prop <- scenario_table$prop[[i]]
  done <- completed_sims(results, truth, prop)
  remaining <- setdiff(seq_len(nsim), done)
  if (length(remaining) > 0L) {
    batches <- split(remaining, ceiling(seq_along(remaining) / batch_size))
    for (batch in batches) {
      worker <- function(sim) {
        tryCatch(
          list(ok = TRUE, sim = sim, value = run_one(sim, truth, prop)),
          error = function(error) list(ok = FALSE, sim = sim, message = conditionMessage(error))
        )
      }
      batch_results <- parallel::mclapply(
        batch, worker, mc.cores = min(cores, length(batch)),
        mc.preschedule = TRUE, mc.set.seed = FALSE
      )
      failed <- !vapply(batch_results, `[[`, logical(1), "ok")
      if (any(failed)) {
        details <- vapply(batch_results[failed], function(x) {
          paste0("replicate ", x$sim, ": ", x$message)
        }, character(1))
        stop("Simulation batch failed: ", paste(details, collapse = "; "), call. = FALSE)
      }
      if (signed_design) {
        results <- append_rows(results, do.call(rbind, lapply(batch_results, `[[`, "value")))
        validate_population_simulation_results(results, design = "signed-v1")
      } else {
        results <- append_rows(results, do.call(rbind, lapply(batch_results, function(x) x$value$results)))
        pair_manifest <- append_rows(pair_manifest, do.call(rbind, lapply(batch_results, function(x) x$value$pair_manifest)))
        validate_observation_noise_sensitivity_results(results, strategies = strategies)
        validate_observation_noise_pair_manifest(pair_manifest)
      }
      checkpoint <- list(release_provenance = release_provenance, results = results)
      if (identical(design, "noise")) checkpoint$pair_manifest <- pair_manifest
      release_atomic_rds(checkpoint, checkpoint_path)
      message("Checkpointed ", design, " ", truth, " p=", prop, " through sim ", max(batch))
    }
  }
  compare_scenario(truth, prop, results, pair_manifest)
}

present_keys <- unique(vapply(seq_len(nrow(scenario_table)), function(i) {
  key <- scenario_id(scenario_table$truth[[i]], scenario_table$prop[[i]])
  if (length(completed_sims(results, scenario_table$truth[[i]], scenario_table$prop[[i]])) != nsim) "" else key
}, character(1)))
if (!setequal(present_keys[present_keys != ""], scenario_key_set)) {
  stop("Rerun finished without all requested scenarios and replicates.", call. = FALSE)
}
if (signed_design) {
  validate_population_simulation_results(results, nsim = nsim, design = "signed-v1")
} else {
  validate_observation_noise_sensitivity_results(results, nsim = nsim, strategies = strategies)
  validate_observation_noise_pair_manifest(pair_manifest, nsim = nsim)
}
final <- list(release_provenance = release_provenance, results = results)
if (identical(design, "noise")) final$pair_manifest <- pair_manifest
release_atomic_rds(final, output_path)
message("Completed ", design, " rerun: ", nrow(results), " scientific rows in ", output_path)
