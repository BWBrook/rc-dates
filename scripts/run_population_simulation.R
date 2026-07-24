#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 1L && args[[1L]] %in% c("--help", "-h")) {
  writeLines(c(
    "Run one resumable production population-simulation scenario.",
    "",
    "Required:",
    "  --model=uni|lin|exp",
    "  --prop=0.5|0.75|1",
    "",
    "Optional:",
    "  --nsim=1000 --cores=1 --batch-size=20 --seed=1234",
    "  --output=out/production/results_...rds"
  ))
  quit(status = 0L)
}

required_files <- c(
  "R/legacy_simulation_helpers.R",
  "R/population_simulation_production.R",
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

settings <- parse_population_simulation_args(args)
if (.Platform$OS.type == "windows" && settings$cores > 1L) {
  warning("Multicore execution is unavailable on Windows; using one core.", call. = FALSE)
  settings$cores <- 1L
}

dir.create(dirname(settings$output), recursive = TRUE, showWarnings = FALSE)
input <- readr::read_csv("data/austarch_filtered.csv", show_col_types = FALSE)
specification <- prepare_population_simulation(input)
metadata_path <- paste0(settings$output, ".metadata.txt")
generation_completed_utc <- NULL
if (file.exists(metadata_path)) {
  metadata_lines <- readLines(metadata_path, warn = FALSE)
  completion_lines <- grep(
    "^(generation_completed_utc|completed_utc):[[:space:]]*",
    metadata_lines,
    value = TRUE
  )
  preferred <- grep("^generation_completed_utc:", completion_lines, value = TRUE)
  completion_line <- if (length(preferred) == 1L) preferred else completion_lines
  if (length(completion_line) == 1L) {
    generation_completed_utc <- sub("^[^:]+:[[:space:]]*", "", completion_line)
  }
}

atomic_save_rds <- function(object, path) {
  temporary <- paste0(path, ".tmp-", Sys.getpid())
  on.exit(unlink(temporary), add = TRUE)
  saveRDS(object, temporary, version = 3)
  if (!file.rename(temporary, path)) {
    stop("Could not atomically replace production checkpoint: ", path, call. = FALSE)
  }
  invisible(path)
}

allow_unstamped_complete <- identical(
  tolower(Sys.getenv("RC_DATES_ALLOW_UNSTAMPED_COMPLETE", unset = "false")),
  "true"
)
provenance_md5 <- function(path, override_name) {
  override <- Sys.getenv(override_name, unset = "")
  if (allow_unstamped_complete && nzchar(override)) override else unname(tools::md5sum(path))
}
provenance_origin <- Sys.getenv(
  "RC_DATES_PROVENANCE_ORIGIN",
  unset = "native-checkpoint"
)
if (!provenance_origin %in% c("native-checkpoint", "post-run-stamp") ||
    (provenance_origin == "post-run-stamp" && !allow_unstamped_complete)) {
  abort_population_simulation(
    "Invalid production provenance origin or migration settings.",
    "rcdates_sim_provenance_error"
  )
}
provenance <- list(
  schema_version = 1L,
  true_model = settings$true_model,
  prop = settings$prop,
  nsim = settings$nsim,
  master_seed = settings$master_seed,
  input_md5 = provenance_md5(
    "data/austarch_filtered.csv",
    "RC_DATES_PROVENANCE_INPUT_MD5"
  ),
  renv_lock_md5 = provenance_md5(
    "renv.lock",
    "RC_DATES_PROVENANCE_RENV_LOCK_MD5"
  ),
  production_source_md5 = provenance_md5(
    "R/population_simulation_production.R",
    "RC_DATES_PROVENANCE_PRODUCTION_SOURCE_MD5"
  ),
  legacy_helper_md5 = provenance_md5(
    "R/legacy_simulation_helpers.R",
    "RC_DATES_PROVENANCE_LEGACY_HELPER_MD5"
  ),
  runner_source_md5 = provenance_md5(
    "scripts/run_population_simulation.R",
    "RC_DATES_PROVENANCE_RUNNER_SOURCE_MD5"
  ),
  container_recipe_md5 = provenance_md5(
    "docker/production-simulation.Dockerfile",
    "RC_DATES_PROVENANCE_CONTAINER_RECIPE_MD5"
  ),
  container_install_md5 = provenance_md5(
    "docker/install-production-packages.R",
    "RC_DATES_PROVENANCE_CONTAINER_INSTALL_MD5"
  ),
  container_image_id = Sys.getenv("RC_DATES_IMAGE_ID", unset = "not-recorded"),
  provenance_origin = provenance_origin,
  r_version = R.version.string
)

existing <- NULL
if (file.exists(settings$output)) {
  existing <- readRDS(settings$output)
  validate_population_simulation_results(existing)
  same_scenario <- all(existing$true == settings$true_model) &&
    all(abs(existing$prop - settings$prop) < sqrt(.Machine$double.eps))
  if (!same_scenario || max(existing$sim) > settings$nsim) {
    abort_population_simulation(
      "Existing checkpoint does not match the requested production scenario.",
      "rcdates_sim_result_error"
    )
  }

  observed_provenance <- attr(existing, "production_provenance", exact = TRUE)
  complete_checkpoint <- identical(
    sort(unique(existing$sim)),
    seq_len(settings$nsim)
  )
  if (is.null(observed_provenance) && allow_unstamped_complete && complete_checkpoint) {
    attr(existing, "production_provenance") <- provenance
    atomic_save_rds(existing, settings$output)
    message("Stamped a complete legacy checkpoint with its recorded generation provenance.")
  } else {
    validate_population_checkpoint_provenance(existing, provenance)
  }
}

completed <- if (is.null(existing)) integer() else sort(unique(existing$sim))
remaining <- setdiff(seq_len(settings$nsim), completed)
started <- Sys.time()

message(
  sprintf(
    "[%s] %s p=%s: %s/%s replicates already complete; using %s cores",
    format(started, "%Y-%m-%d %H:%M:%S %Z"),
    settings$true_model,
    settings$prop,
    length(completed),
    settings$nsim,
    settings$cores
  )
)

if (length(remaining) > 0L) {
  batches <- split(remaining, ceiling(seq_along(remaining) / settings$batch_size))
  for (batch in batches) {
    worker <- function(sim) {
      tryCatch(
        list(
          ok = TRUE,
          sim = sim,
          result = run_population_simulation_replicate(
            sim = sim,
            true_model = settings$true_model,
            prop = settings$prop,
            specification = specification,
            master_seed = settings$master_seed
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
      stop("Production simulation batch failed: ", paste(details, collapse = "; "), call. = FALSE)
    }

    new_rows <- do.call(rbind, lapply(batch_results, `[[`, "result"))
    existing <- if (is.null(existing)) new_rows else rbind(existing, new_rows)
    existing <- existing[order(existing$sim, existing$strategy, existing$type, existing$model), ]
    rownames(existing) <- NULL
    validate_population_simulation_results(existing)
    attr(existing, "production_provenance") <- provenance
    atomic_save_rds(existing, settings$output)
    message(
      sprintf(
        "[%s] checkpointed %s/%s replicates",
        format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
        length(unique(existing$sim)),
        settings$nsim
      )
    )
  }
}

final <- readRDS(settings$output)
validate_population_simulation_results(final, nsim = settings$nsim)
validate_population_checkpoint_provenance(final, provenance)
package_names <- c("fitdistrplus", "rcarbon", "dplyr", "ggplot2", "testthat")
package_versions <- vapply(package_names, function(package) {
  as.character(utils::packageVersion(package))
}, character(1))
metadata_recorded_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)
if (is.null(generation_completed_utc)) {
  generation_completed_utc <- metadata_recorded_utc
}
writeLines(c(
  "rc-dates production population simulation",
  paste("schema_version:", provenance$schema_version),
  paste("generation_completed_utc:", generation_completed_utc),
  paste("metadata_recorded_utc:", metadata_recorded_utc),
  paste("r_version:", provenance$r_version),
  paste("true_model:", settings$true_model),
  paste("site_subsampling_proportion:", settings$prop),
  paste("replicates:", settings$nsim),
  paste("master_seed:", settings$master_seed),
  "seed_design: common random numbers; replicate seed = master seed + replicate number",
  paste("input_md5:", provenance$input_md5),
  paste("renv_lock_md5:", provenance$renv_lock_md5),
  paste("production_source_md5:", provenance$production_source_md5),
  paste("legacy_helper_md5:", provenance$legacy_helper_md5),
  paste("runner_source_md5:", provenance$runner_source_md5),
  paste("container_recipe_md5:", provenance$container_recipe_md5),
  paste("container_install_md5:", provenance$container_install_md5),
  paste("container_image_id:", provenance$container_image_id),
  paste("provenance_origin:", provenance$provenance_origin),
  paste("output_md5:", unname(tools::md5sum(settings$output))),
  paste(
    "packages:",
    paste(paste(names(package_versions), package_versions, sep = "="), collapse = "; ")
  )
), metadata_path)

message(
  sprintf(
    "[%s] complete: %s rows in %s (elapsed %.1f minutes)",
    format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    nrow(final),
    settings$output,
    as.numeric(difftime(Sys.time(), started, units = "mins"))
  )
)
