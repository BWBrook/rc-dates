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
  "data/austarch_filtered.csv"
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

atomic_save_rds <- function(object, path) {
  temporary <- paste0(path, ".tmp-", Sys.getpid())
  on.exit(unlink(temporary), add = TRUE)
  saveRDS(object, temporary, version = 3)
  if (!file.rename(temporary, path)) {
    stop("Could not atomically replace production checkpoint: ", path, call. = FALSE)
  }
  invisible(path)
}

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
metadata_path <- paste0(settings$output, ".metadata.txt")
package_names <- c("fitdistrplus", "rcarbon", "dplyr", "ggplot2", "testthat")
package_versions <- vapply(package_names, function(package) {
  as.character(utils::packageVersion(package))
}, character(1))
writeLines(c(
  "rc-dates production population simulation",
  paste("completed_utc:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste("r_version:", R.version.string),
  paste("true_model:", settings$true_model),
  paste("site_subsampling_proportion:", settings$prop),
  paste("replicates:", settings$nsim),
  paste("master_seed:", settings$master_seed),
  "seed_design: common random numbers; replicate seed = master seed + replicate number",
  paste("input_md5:", unname(tools::md5sum("data/austarch_filtered.csv"))),
  paste("output_md5:", unname(tools::md5sum(settings$output))),
  paste("packages:", paste(paste(names(package_versions), package_versions, sep = "="), collapse = "; "))
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
