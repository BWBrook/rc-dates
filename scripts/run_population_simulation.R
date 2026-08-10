#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 1L && args[[1L]] %in% c("--help", "-h")) {
  writeLines(c(
    "Run one resumable Stage 2 signed-model scenario.",
    "",
    "Required:",
    "  --truth=uni|lin_inc|lin_dec|exp_inc|exp_dec",
    "  --prop=0.5|0.75|1",
    "",
    "Optional:",
    "  --ratio=10 --nsim=1000 --cores=1 --batch-size=20 --seed=1234",
    "  --output=out/revision/signed-models/results_...rds"
  ))
  quit(status = 0L)
}

required_files <- c(
  "scripts/source_population_simulation.R",
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

source("scripts/source_population_simulation.R")

settings <- parse_population_simulation_args(args)
if (.Platform$OS.type == "windows" && settings$cores > 1L) {
  warning("Multicore execution is unavailable on Windows; using one core.", call. = FALSE)
  settings$cores <- 1L
}

dir.create(dirname(settings$output), recursive = TRUE, showWarnings = FALSE)
input <- readr::read_csv("data/austarch_filtered.csv", show_col_types = FALSE)
specification <- prepare_population_simulation(input, ratio = settings$ratio)
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

provenance <- list(
  schema_version = 3L,
  truth = settings$truth,
  prop = settings$prop,
  ratio = settings$ratio,
  design = "signed-v1",
  observation_model = "curve_mean",
  nsim = settings$nsim,
  master_seed = settings$master_seed,
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
  )),
  container_image_id = Sys.getenv("RC_DATES_IMAGE_ID", unset = "not-recorded"),
  r_version = R.version.string
)

existing <- NULL
if (file.exists(settings$output)) {
  existing <- readRDS(settings$output)
  validate_population_simulation_results(existing, design = "signed-v1")
  same_scenario <- all(existing$true == settings$truth) &&
    all(abs(existing$prop - settings$prop) < sqrt(.Machine$double.eps))
  if (!same_scenario || max(existing$sim) > settings$nsim) {
    abort_population_simulation(
      "Existing checkpoint does not match the requested production scenario.",
      "rcdates_sim_result_error"
    )
  }

  validate_population_checkpoint_provenance(existing, provenance)
}

completed <- if (is.null(existing)) integer() else sort(unique(existing$sim))
remaining <- setdiff(seq_len(settings$nsim), completed)
started <- Sys.time()

message(
  sprintf(
    "[%s] %s p=%s: %s/%s replicates already complete; using %s cores",
    format(started, "%Y-%m-%d %H:%M:%S %Z"),
    settings$truth,
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
            truth = settings$truth,
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
    validate_population_simulation_results(existing, design = "signed-v1")
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
validate_population_simulation_results(
  final,
  nsim = settings$nsim,
  design = "signed-v1"
)
validate_population_checkpoint_provenance(final, provenance)
package_names <- c("digest", "fitdistrplus", "rcarbon", "readr", "rlang", "tibble")
package_versions <- vapply(package_names, function(package) {
  as.character(utils::packageVersion(package))
}, character(1))
metadata_recorded_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)
if (is.null(generation_completed_utc)) {
  generation_completed_utc <- metadata_recorded_utc
}
writeLines(c(
  "rc-dates Stage 2 signed-model simulation",
  paste("schema_version:", provenance$schema_version),
  paste("generation_completed_utc:", generation_completed_utc),
  paste("metadata_recorded_utc:", metadata_recorded_utc),
  paste("r_version:", provenance$r_version),
  paste("truth:", settings$truth),
  paste("effect_ratio:", format(settings$ratio, scientific = FALSE, trim = TRUE)),
  paste("design:", provenance$design),
  paste("observation_model:", provenance$observation_model),
  paste("site_treatment_proportion:", settings$prop),
  paste("replicates:", settings$nsim),
  paste("master_seed:", settings$master_seed),
  "seed_design: common random numbers; replicate seed = master seed + replicate number",
  paste("input_md5:", provenance$input_md5),
  paste("renv_lock_md5:", provenance$renv_lock_md5),
  paste("model_source_md5:", provenance$model_source_md5),
  paste("distribution_source_md5:", provenance$distribution_source_md5),
  paste("runner_source_md5:", provenance$runner_source_md5),
  paste("container_recipe_md5:", provenance$container_recipe_md5),
  paste("container_install_md5:", provenance$container_install_md5),
  paste("container_image_id:", provenance$container_image_id),
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
