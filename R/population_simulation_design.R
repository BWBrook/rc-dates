# Simulation design, CLI, RNG, and checkpoint contract ----------------------

abort_population_simulation <- function(message, class) {
  rlang::abort(message, class = class)
}

population_simulation_contract <- function(design = c("legacy", "signed-v1")) {
  design <- match.arg(design)
  if (design == "legacy") {
    return(list(
      design = design,
      truths = c("uni", "lin", "exp"),
      models = c("uni", "lin", "exp"),
      strategies = c("r_1", "r_3", "r_5", "r_old", "r_young", "r_bracket", "r_all"),
      types = c("l1", "l2"),
      rows_per_replicate = 42L
    ))
  }
  list(
    design = design,
    truths = c("uni", "lin_inc", "lin_dec", "exp_inc", "exp_dec"),
    models = c("uni", "lin", "exp"),
    strategies = c(
      "r_1", "r_2", "r_3", "r_5", "r_old", "r_young", "r_bracket", "r_all"
    ),
    types = c("l1", "l2"),
    rows_per_replicate = 48L
  )
}

population_truth_specification <- function(truth, ratio, low, up) {
  contract <- population_simulation_contract("signed-v1")
  valid_ratio <- length(ratio) == 1L && is.finite(ratio) && ratio > 1
  if (length(truth) != 1L || !truth %in% contract$truths || !valid_ratio ||
      length(low) != 1L || length(up) != 1L || !is.finite(low) || !is.finite(up) ||
      low >= up) {
    abort_population_simulation(
      "Invalid signed-model truth, effect ratio, or analysis interval.",
      "rcdates_sim_spec_error"
    )
  }

  family <- sub("_.*$", "", truth)
  direction <- if (truth == "uni") {
    "constant"
  } else if (grepl("_inc$", truth)) {
    "increase"
  } else {
    "decrease"
  }
  sign <- if (direction == "decrease") -1 else 1
  span <- up - low
  parameter <- switch(
    family,
    uni = 0,
    lin = sign * 2 * (ratio - 1) / ((ratio + 1) * span^2),
    exp = sign * log(ratio) / span
  )
  log_density_ratio <- if (direction == "constant") 0 else sign * log(ratio)

  list(
    truth = truth,
    family = family,
    direction = direction,
    parameter = parameter,
    log_density_ratio = log_density_ratio
  )
}

population_log_density_ratio <- function(model, parameter, low, up) {
  if (length(model) != 1L || !model %in% c("uni", "lin", "exp") ||
      length(parameter) != 1L || !is.finite(parameter) || low >= up) {
    abort_population_simulation(
      "Invalid model, parameter, or interval for the density ratio.",
      "rcdates_sim_spec_error"
    )
  }
  if (model == "uni") return(0)
  span <- up - low
  if (model == "exp") return(parameter * span)

  scaled_slope <- parameter * span^2 / 2
  if (abs(scaled_slope) >= 1) {
    return(sign(scaled_slope) * Inf)
  }
  log1p(scaled_slope) - log1p(-scaled_slope)
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
#' @param truth Generating truth label.
#' @param prop Proportion of sites subjected to within-site subsampling.
#' @param sim Positive simulation replicate number.
#' @param master_seed Master seed recorded for the production study.
#' @return A positive integer seed shared across scenarios for the replicate.
production_simulation_seed <- function(
  truth,
  prop,
  sim,
  master_seed = 1234L
) {
  truths <- union(
    population_simulation_contract("legacy")$truths,
    population_simulation_contract("signed-v1")$truths
  )
  proportions <- c(0.5, 0.75, 1)

  truth_index <- match(truth, truths)
  prop_index <- which(abs(as.numeric(prop) - proportions) < sqrt(.Machine$double.eps))
  valid_sim <- length(sim) == 1L && is.finite(sim) && sim >= 1 && sim == as.integer(sim)
  valid_master <- length(master_seed) == 1L && is.finite(master_seed) && master_seed >= 1

  if (length(truth_index) != 1L || is.na(truth_index) || length(prop_index) != 1L ||
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
#' @param truth Generating truth label.
#' @param prop Proportion of sites subjected to within-site subsampling.
#' @param nsim Number of simulation replicates.
#' @param master_seed Master seed recorded for the production study.
#' @param ratio Multiplicative population increase for growth models.
#' @return An RDS filename containing the complete scenario specification.
production_simulation_filename <- function(
  truth,
  prop,
  nsim = 1000L,
  master_seed = 1234L,
  ratio = 10L
) {
  production_simulation_seed(truth, prop, sim = 1L, master_seed = master_seed)
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
    truth,
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
    truth = NULL,
    prop = NULL,
    ratio = 10,
    nsim = 1000L,
    cores = 1L,
    batch_size = 20L,
    master_seed = 1234L,
    output = NULL
  )
  key_map <- c(
    truth = "truth",
    prop = "prop",
    ratio = "ratio",
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
  parsed$ratio <- suppressWarnings(as.numeric(parsed$ratio))
  for (field in c("nsim", "cores", "batch_size", "master_seed")) {
    parsed[[field]] <- suppressWarnings(as.integer(parsed[[field]]))
  }
  if (is.null(parsed$truth) || length(parsed$prop) != 1L || !is.finite(parsed$prop) ||
      length(parsed$ratio) != 1L || !is.finite(parsed$ratio) || parsed$ratio <= 1) {
    abort_population_simulation(
      "Stage 2 runner requires valid --truth, --prop, and --ratio arguments.",
      "rcdates_sim_spec_error"
    )
  }
  production_simulation_seed(
    parsed$truth,
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
        parsed$truth,
        parsed$prop,
        parsed$nsim,
        parsed$master_seed,
        parsed$ratio
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
