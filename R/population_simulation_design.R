# Simulation design, CLI, RNG, and checkpoint contract ----------------------

abort_population_simulation <- function(message, class) {
  rlang::abort(message, class = class)
}

#' Normalize the synthetic radiocarbon observation model
#' @param observation_model Either `"curve_mean"` or `"realised"`.
#' @return A validated observation-model label.
normalize_population_observation_model <- function(observation_model) {
  observation_model <- as.character(observation_model)
  valid <- c("curve_mean", "realised")
  if (length(observation_model) != 1L || is.na(observation_model) ||
      !observation_model %in% valid) {
    abort_population_simulation(
      paste(
        "Population observation model must be one of:",
        paste(valid, collapse = ", ")
      ),
      "rcdates_sim_spec_error"
    )
  }
  observation_model
}

#' Draw realised conventional radiocarbon ages on an isolated RNG stream
#' @param calendar_age Latent calendar ages in cal BP.
#' @param errors Simulated quoted one-sigma laboratory errors.
#' @param structure_rng_state L'Ecuyer-CMRG state to preserve for sampling.
#' @return Integer realised conventional radiocarbon ages.
draw_realised_population_cra <- function(
  calendar_age,
  errors,
  structure_rng_state
) {
  if (length(structure_rng_state) != 7L) {
    abort_population_simulation(
      "Realised assays require an L'Ecuyer-CMRG structural RNG state.",
      "rcdates_sim_spec_error"
    )
  }
  assay_rng_state <- tryCatch(
    parallel::nextRNGStream(structure_rng_state),
    error = function(error) {
      abort_population_simulation(
        paste("Could not derive the realised-assay RNG stream:", conditionMessage(error)),
        "rcdates_sim_spec_error"
      )
    }
  )

  draw_on_assay_stream <- function() {
    assign(".Random.seed", assay_rng_state, envir = .GlobalEnv)
    on.exit(
      assign(".Random.seed", structure_rng_state, envir = .GlobalEnv),
      add = TRUE
    )
    rcarbon::uncalibrate(
      calendar_age,
      CRAerrors = errors,
      roundyear = TRUE,
      calCurves = "shcal20"
    )$rCRA
  }

  as.numeric(draw_on_assay_stream())
}

#' Validate the provenance fingerprint attached to a simulation checkpoint
#' @param results Checkpoint data frame.
#' @param expected Named provenance list for the requested production run.
#' @return `TRUE` invisibly when the checkpoint fingerprint matches exactly.
validate_population_checkpoint_provenance <- function(results, expected) {
  observed <- attr(results, "production_provenance", exact = TRUE)
  if (is.null(observed) || !identical(observed, expected)) {
    mismatch <- if (is.null(observed)) {
      "checkpoint is unstamped"
    } else {
      fields <- union(names(observed), names(expected))
      different <- fields[!vapply(fields, function(field) {
        identical(observed[[field]], expected[[field]])
      }, logical(1))]
      paste("mismatched fields:", paste(different, collapse = ", "))
    }
    abort_population_simulation(
      paste("Production checkpoint provenance is incompatible;", mismatch),
      "rcdates_sim_provenance_error"
    )
  }
  invisible(TRUE)
}

#' Derive a deterministic seed for one production simulation replicate
#' @param true_model One of `"uni"`, `"lin"`, or `"exp"`.
#' @param prop Proportion of sites subjected to within-site subsampling.
#' @param sim Positive simulation replicate number.
#' @param master_seed Master seed recorded for the production study.
#' @return A positive integer seed shared across scenarios for the replicate.
production_simulation_seed <- function(
  true_model,
  prop,
  sim,
  master_seed = 1234L
) {
  models <- c("uni", "lin", "exp")
  proportions <- c(0.5, 0.75, 1)

  model_index <- match(true_model, models)
  prop_index <- which(abs(as.numeric(prop) - proportions) < sqrt(.Machine$double.eps))
  valid_sim <- length(sim) == 1L && is.finite(sim) && sim >= 1 && sim == as.integer(sim)
  valid_master <- length(master_seed) == 1L && is.finite(master_seed) && master_seed >= 1

  if (length(model_index) != 1L || is.na(model_index) || length(prop_index) != 1L ||
      !valid_sim || !valid_master) {
    abort_population_simulation(
      "Invalid production simulation model, proportion, replicate, or master seed.",
      "rcdates_sim_spec_error"
    )
  }

  # The full model-by-intensity matrix uses common random numbers. This keeps
  # each replicate paired across scenarios and makes the all-dates reference exact.
  seed <- as.double(master_seed) + as.integer(sim)
  if (seed > .Machine$integer.max) {
    abort_population_simulation(
      "Derived production simulation seed exceeds the R integer limit.",
      "rcdates_sim_spec_error"
    )
  }
  as.integer(seed)
}

#' Construct the stable filename for one production simulation scenario
#' @param true_model One of `"uni"`, `"lin"`, or `"exp"`.
#' @param prop Proportion of sites subjected to within-site subsampling.
#' @param nsim Number of simulation replicates.
#' @param master_seed Master seed recorded for the production study.
#' @param ratio Multiplicative population increase for growth models.
#' @return An RDS filename containing the complete scenario specification.
production_simulation_filename <- function(
  true_model,
  prop,
  nsim = 1000L,
  master_seed = 1234L,
  ratio = 10L
) {
  production_simulation_seed(true_model, prop, sim = 1L, master_seed = master_seed)
  valid_nsim <- length(nsim) == 1L && is.finite(nsim) && nsim >= 1 &&
    nsim == as.integer(nsim)
  valid_ratio <- length(ratio) == 1L && is.finite(ratio) && ratio > 1
  if (!valid_nsim || !valid_ratio) {
    abort_population_simulation(
      "Production simulation count and growth ratio must be positive valid values.",
      "rcdates_sim_spec_error"
    )
  }
  prop_label <- format(as.numeric(prop), scientific = FALSE, trim = TRUE)
  sprintf(
    "results_%s_p%s_ratio%s_nsim%s_seed%s.rds",
    true_model,
    prop_label,
    format(ratio, scientific = FALSE, trim = TRUE),
    as.integer(nsim),
    as.integer(master_seed)
  )
}

#' Parse command-line arguments for one production simulation scenario
#' @param args Character vector from `commandArgs(trailingOnly = TRUE)`.
#' @return Validated runner settings.
parse_population_simulation_args <- function(args) {
  defaults <- list(
    true_model = NULL,
    prop = NULL,
    nsim = 1000L,
    cores = 1L,
    batch_size = 20L,
    master_seed = 1234L,
    output = NULL
  )
  key_map <- c(
    model = "true_model",
    prop = "prop",
    nsim = "nsim",
    cores = "cores",
    `batch-size` = "batch_size",
    seed = "master_seed",
    output = "output"
  )
  parsed <- defaults

  for (argument in args) {
    parts <- regmatches(argument, regexec("^--([^=]+)=(.*)$", argument))[[1L]]
    if (length(parts) != 3L || !parts[[2L]] %in% names(key_map)) {
      abort_population_simulation(
        paste("Unknown or malformed production simulation argument:", argument),
        "rcdates_sim_spec_error"
      )
    }
    parsed[[key_map[[parts[[2L]]]]]] <- parts[[3L]]
  }

  parsed$prop <- suppressWarnings(as.numeric(parsed$prop))
  for (field in c("nsim", "cores", "batch_size", "master_seed")) {
    parsed[[field]] <- suppressWarnings(as.integer(parsed[[field]]))
  }
  if (is.null(parsed$true_model) || length(parsed$prop) != 1L || !is.finite(parsed$prop)) {
    abort_population_simulation(
      "Production runner requires valid --model and --prop arguments.",
      "rcdates_sim_spec_error"
    )
  }
  production_simulation_seed(
    parsed$true_model,
    parsed$prop,
    sim = 1L,
    master_seed = parsed$master_seed
  )
  positive_integer <- vapply(
    parsed[c("nsim", "cores", "batch_size", "master_seed")],
    function(x) length(x) == 1L && !is.na(x) && x >= 1L,
    logical(1)
  )
  if (!all(positive_integer)) {
    abort_population_simulation(
      "Simulation count, cores, batch size, and seed must be positive integers.",
      "rcdates_sim_spec_error"
    )
  }

  if (is.null(parsed$output)) {
    parsed$output <- file.path(
      "out",
      "rerun",
      production_simulation_filename(
        parsed$true_model,
        parsed$prop,
        parsed$nsim,
        parsed$master_seed
      )
    )
  }
  if (length(parsed$output) != 1L || !nzchar(parsed$output)) {
    abort_population_simulation(
      "Production simulation output path must be non-empty.",
      "rcdates_sim_spec_error"
    )
  }
  parsed
}
