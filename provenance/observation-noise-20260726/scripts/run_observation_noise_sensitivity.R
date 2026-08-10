#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 1L && args[[1L]] %in% c("--help", "-h")) {
  writeLines(c(
    "Run one resumable paired observation-noise sensitivity scenario.",
    "",
    "Required:",
    "  --model=uni|lin|exp",
    "  --prop=0.5|0.75|1",
    "",
    "Optional:",
    "  --nsim=1000 --cores=1 --batch-size=20 --seed=1234",
    "  --strategies=r_all,r_1,r_3,r_5",
    "  --output=out/sensitivity/observation-noise/observation_noise_...rds"
  ))
  quit(status = 0L)
}

required_files <- c(
  "R/legacy_simulation_helpers.R",
  "R/population_simulation_production.R",
  "R/observation_noise_sensitivity.R",
  "data/austarch_filtered.csv",
  "docker/production-simulation.Dockerfile",
  "docker/install-production-packages.R",
  "renv.lock"
)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0L) {
  stop(
    "Run from the rc-dates repository root; missing: ",
    paste(missing_files, collapse = ", "),
    call. = FALSE
  )
}

source("R/legacy_simulation_helpers.R")
source("R/population_simulation_production.R")
source("R/observation_noise_sensitivity.R")
settings <- parse_observation_noise_sensitivity_args(args)
if (.Platform$OS.type == "windows" && settings$cores > 1L) {
  warning("Multicore execution is unavailable on Windows; using one core.", call. = FALSE)
  settings$cores <- 1L
}

# Preload before installing any replicate seed. Namespace loading otherwise
# changes the process RNG state and can make fork history part of the design.
required_packages <- c("digest", "fitdistrplus", "rcarbon", "readr")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop("Missing sensitivity packages: ", paste(missing_packages, collapse = ", "))
}

dir.create(dirname(settings$output), recursive = TRUE, showWarnings = FALSE)
input <- readr::read_csv("data/austarch_filtered.csv", show_col_types = FALSE)
specification <- prepare_population_simulation(input)
metadata_path <- paste0(settings$output, ".metadata.txt")
pair_manifest_path <- sub("\\.rds$", ".pairs.csv", settings$output)
if (identical(pair_manifest_path, settings$output)) {
  pair_manifest_path <- paste0(settings$output, ".pairs.csv")
}

atomic_save_rds <- function(object, path) {
  temporary <- paste0(path, ".tmp-", Sys.getpid())
  on.exit(unlink(temporary), add = TRUE)
  saveRDS(object, temporary, version = 3)
  if (!file.rename(temporary, path)) {
    stop("Could not atomically replace sensitivity checkpoint: ", path, call. = FALSE)
  }
  invisible(path)
}

atomic_write_csv <- function(object, path) {
  temporary <- paste0(path, ".tmp-", Sys.getpid())
  on.exit(unlink(temporary), add = TRUE)
  readr::write_csv(object, temporary)
  if (!file.rename(temporary, path)) {
    stop("Could not atomically replace pair manifest: ", path, call. = FALSE)
  }
  invisible(path)
}

provenance <- list(
  schema_version = 1L,
  sensitivity_design = "paired_curve_mean_vs_realised_v1",
  observation_models = c("curve_mean", "realised"),
  assay_equation = "rCRA=round(ccCRA+Z*sqrt(ccError^2+quoted_error^2))",
  calibration_curve = "shcal20",
  roundyear = TRUE,
  window_exclusion_rule = "drop selected observations with zero posterior mass in 651-11650",
  rng_kind = "L'Ecuyer-CMRG",
  stream_mapping = "structural=current; realised_assay=nextRNGStream(structural)",
  true_model = settings$true_model,
  prop = settings$prop,
  nsim = settings$nsim,
  master_seed = settings$master_seed,
  strategies = settings$strategies,
  input_md5 = unname(tools::md5sum("data/austarch_filtered.csv")),
  renv_lock_md5 = unname(tools::md5sum("renv.lock")),
  production_source_md5 = unname(tools::md5sum(
    "R/population_simulation_production.R"
  )),
  sensitivity_source_md5 = unname(tools::md5sum(
    "R/observation_noise_sensitivity.R"
  )),
  legacy_helper_md5 = unname(tools::md5sum("R/legacy_simulation_helpers.R")),
  runner_source_md5 = unname(tools::md5sum(
    "scripts/run_observation_noise_sensitivity.R"
  )),
  container_recipe_md5 = unname(tools::md5sum(
    "docker/production-simulation.Dockerfile"
  )),
  container_install_md5 = unname(tools::md5sum(
    "docker/install-production-packages.R"
  )),
  container_image_id = Sys.getenv("RC_DATES_IMAGE_ID", unset = "not-recorded"),
  r_version = R.version.string,
  rcarbon_version = as.character(utils::packageVersion("rcarbon"))
)

existing_results <- NULL
existing_manifest <- NULL
if (file.exists(settings$output)) {
  checkpoint <- readRDS(settings$output)
  if (!is.list(checkpoint) ||
      !all(c("results", "pair_manifest", "provenance") %in% names(checkpoint)) ||
      !identical(checkpoint$provenance, provenance)) {
    abort_population_simulation(
      "Existing observation-noise checkpoint has incompatible provenance.",
      "rcdates_sim_provenance_error"
    )
  }
  existing_results <- checkpoint$results
  existing_manifest <- checkpoint$pair_manifest
  validate_observation_noise_sensitivity_results(
    existing_results,
    strategies = settings$strategies
  )
  validate_observation_noise_pair_manifest(existing_manifest)
  if (max(existing_results$sim) > settings$nsim) {
    abort_population_simulation(
      "Existing sensitivity checkpoint exceeds the requested replicate count.",
      "rcdates_sim_result_error"
    )
  }
}

completed <- if (is.null(existing_results)) {
  integer()
} else {
  sort(unique(existing_results$sim))
}
remaining <- setdiff(seq_len(settings$nsim), completed)
started <- Sys.time()
message(sprintf(
  "[%s] paired observation noise %s p=%s: %s/%s complete; using %s cores",
  format(started, "%Y-%m-%d %H:%M:%S %Z"),
  settings$true_model,
  settings$prop,
  length(completed),
  settings$nsim,
  settings$cores
))

if (length(remaining) > 0L) {
  batches <- split(remaining, ceiling(seq_along(remaining) / settings$batch_size))
  for (batch in batches) {
    worker <- function(sim) {
      tryCatch(
        list(
          ok = TRUE,
          sim = sim,
          paired = run_observation_noise_sensitivity_replicate(
            sim = sim,
            true_model = settings$true_model,
            prop = settings$prop,
            specification = specification,
            master_seed = settings$master_seed,
            strategies = settings$strategies
          )
        ),
        error = function(error) {
          list(ok = FALSE, sim = sim, message = conditionMessage(error))
        }
      )
    }

    batch_results <- parallel::mclapply(
      batch,
      worker,
      mc.cores = min(settings$cores, length(batch)),
      mc.preschedule = TRUE,
      mc.set.seed = FALSE
    )
    failed <- !vapply(batch_results, `[[`, logical(1), "ok")
    if (any(failed)) {
      details <- vapply(batch_results[failed], function(x) {
        sprintf("replicate %s: %s", x$sim, x$message)
      }, character(1))
      stop("Sensitivity batch failed: ", paste(details, collapse = "; "), call. = FALSE)
    }

    new_results <- do.call(rbind, lapply(
      batch_results,
      function(x) x$paired$results
    ))
    new_manifest <- do.call(rbind, lapply(
      batch_results,
      function(x) x$paired$pair_manifest
    ))
    existing_results <- if (is.null(existing_results)) {
      new_results
    } else {
      rbind(existing_results, new_results)
    }
    existing_manifest <- if (is.null(existing_manifest)) {
      new_manifest
    } else {
      rbind(existing_manifest, new_manifest)
    }
    existing_results <- existing_results[order(
      existing_results$sim,
      existing_results$observation_model,
      existing_results$strategy,
      existing_results$type,
      existing_results$model
    ), ]
    rownames(existing_results) <- NULL
    existing_manifest <- existing_manifest[order(existing_manifest$sim), ]
    rownames(existing_manifest) <- NULL

    validate_observation_noise_sensitivity_results(
      existing_results,
      strategies = settings$strategies
    )
    validate_observation_noise_pair_manifest(existing_manifest)
    checkpoint <- list(
      results = existing_results,
      pair_manifest = existing_manifest,
      provenance = provenance
    )
    atomic_save_rds(checkpoint, settings$output)
    atomic_write_csv(existing_manifest, pair_manifest_path)
    message(sprintf(
      "[%s] checkpointed %s/%s paired replicates",
      format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
      length(unique(existing_results$sim)),
      settings$nsim
    ))
  }
}

final <- readRDS(settings$output)
if (!identical(final$provenance, provenance)) {
  abort_population_simulation(
    "Completed sensitivity checkpoint provenance changed unexpectedly.",
    "rcdates_sim_provenance_error"
  )
}
validate_observation_noise_sensitivity_results(
  final$results,
  nsim = settings$nsim,
  strategies = settings$strategies
)
validate_observation_noise_pair_manifest(
  final$pair_manifest,
  nsim = settings$nsim
)
if (!identical(sort(unique(final$results$pair_id)), sort(final$pair_manifest$pair_id))) {
  abort_population_simulation(
    "Sensitivity results and pair manifest have different pair identifiers.",
    "rcdates_sim_result_error"
  )
}

metadata_recorded_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)
package_versions <- vapply(
  required_packages,
  function(package) as.character(utils::packageVersion(package)),
  character(1)
)
writeLines(c(
  "rc-dates paired observation-noise sensitivity",
  paste("schema_version:", provenance$schema_version),
  paste("generation_completed_utc:", metadata_recorded_utc),
  paste("r_version:", provenance$r_version),
  paste("rcarbon_version:", provenance$rcarbon_version),
  paste("true_model:", settings$true_model),
  paste("site_subsampling_proportion:", settings$prop),
  paste("paired_replicates:", settings$nsim),
  paste("master_seed:", settings$master_seed),
  paste("strategies:", paste(settings$strategies, collapse = ",")),
  paste("sensitivity_design:", provenance$sensitivity_design),
  paste("assay_equation:", provenance$assay_equation),
  paste("window_exclusion_rule:", provenance$window_exclusion_rule),
  paste("rng_kind:", provenance$rng_kind),
  paste("stream_mapping:", provenance$stream_mapping),
  paste("input_md5:", provenance$input_md5),
  paste("renv_lock_md5:", provenance$renv_lock_md5),
  paste("production_source_md5:", provenance$production_source_md5),
  paste("sensitivity_source_md5:", provenance$sensitivity_source_md5),
  paste("legacy_helper_md5:", provenance$legacy_helper_md5),
  paste("runner_source_md5:", provenance$runner_source_md5),
  paste("container_recipe_md5:", provenance$container_recipe_md5),
  paste("container_install_md5:", provenance$container_install_md5),
  paste("container_image_id:", provenance$container_image_id),
  paste("output_md5:", unname(tools::md5sum(settings$output))),
  paste("pair_manifest_md5:", unname(tools::md5sum(pair_manifest_path))),
  paste(
    "packages:",
    paste(paste(names(package_versions), package_versions, sep = "="), collapse = "; ")
  )
), metadata_path)

message(sprintf(
  "[%s] complete: %s result rows and %s pairs in %s (elapsed %.1f minutes)",
  format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
  nrow(final$results),
  nrow(final$pair_manifest),
  settings$output,
  as.numeric(difftime(Sys.time(), started, units = "mins"))
))
