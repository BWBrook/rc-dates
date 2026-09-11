make_stage2_result_fixture <- function(nsim = 2L) {
  contract <- population_simulation_contract("signed-v1")
  results <- expand.grid(
    sim = seq_len(nsim),
    strategy = contract$strategies,
    type = contract$types,
    model = contract$models,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  results$true <- "lin_inc"
  results$true_family <- "lin"
  results$true_direction <- "increase"
  results$true_log_ratio <- log(10)
  results$prop <- 0.5
  selected_model <- ifelse(
    results$strategy == "r_old",
    "lin",
    ifelse(results$strategy == "r_young", "exp", "lin")
  )
  results$min <- as.integer(results$model == selected_model)
  results$ose <- results$min
  results$estimate <- ifelse(results$model == "uni", 0, 1e-4)
  results$estimate_log_ratio <- ifelse(
    results$model == "uni",
    0,
    ifelse(results$strategy == "r_old", -2, ifelse(results$model == "exp", 3, 2))
  )
  results$bias_log_ratio <- ifelse(
    results$model == "lin",
    results$estimate_log_ratio - results$true_log_ratio,
    NA_real_
  )
  results$boundary <- FALSE
  results$n_observations <- 100L
  results$n_dropped <- 0L
  results[, c(
    "sim", "true", "true_family", "true_direction", "true_log_ratio", "prop",
    "strategy", "type", "model", "min", "ose", "estimate", "estimate_log_ratio",
    "bias_log_ratio", "boundary", "n_observations", "n_dropped"
  )]
}

test_that("production simulation seeds are stable common-random-number pairs", {
  scenarios <- expand.grid(
    truth = population_simulation_contract("signed-v1")$truths,
    prop = c(0.5, 0.75, 1),
    stringsAsFactors = FALSE
  )

  seeds <- mapply(
    production_simulation_seed,
    truth = scenarios$truth,
    prop = scenarios$prop,
    MoreArgs = list(sim = 1L, master_seed = 1234L)
  )

  expect_length(unique(seeds), 1L)
  expect_identical(
    production_simulation_seed("uni", 0.5, sim = 1L, master_seed = 1234L),
    1235L
  )
  expect_identical(
    production_simulation_seed("exp_dec", 1, sim = 2L, master_seed = 1234L),
    1236L
  )
  expect_error(
    production_simulation_seed("quadratic", 0.5, sim = 1L),
    class = "rcdates_sim_spec_error"
  )
})

test_that("signed generating densities are normalised with the frozen endpoint ratios", {
  low <- 651
  up <- 11650
  grid <- seq(low, up, length.out = 20001)
  for (truth in population_simulation_contract("signed-v1")$truths) {
    specification <- population_truth_specification(truth, 10, low, up)
    density <- switch(
      specification$family,
      uni = rep(1 / (up - low), length(grid)),
      lin = dtlin(grid, specification$parameter, low, up),
      exp = dtexp(grid, specification$parameter, low, up)
    )
    integral <- sum(diff(grid) * (density[-1L] + density[-length(density)]) / 2)
    expect_equal(integral, 1, tolerance = 1e-8)
    expect_equal(
      log(density[[1L]] / density[[length(density)]]),
      specification$log_density_ratio,
      tolerance = 1e-10
    )
  }
  expect_equal(dtlin(grid, 0, low, up), rep(1 / (up - low), length(grid)))
  expect_equal(dtexp(grid, 0, low, up), rep(1 / (up - low), length(grid)))
})

test_that("positive signed densities reproduce the former positive-only formulas", {
  low <- 651
  up <- 11650
  ages <- c(700, 2000, 6000, 11000)
  slope <- 1e-8
  rate <- 2e-4
  intercept <- (1 + slope * (up - low)^2 / 2) / (up - low)
  historical_linear <- intercept - slope * (ages - low)
  historical_exponential <- stats::dexp(ages, rate) /
    (stats::pexp(up, rate) - stats::pexp(low, rate))
  expect_equal(dtlin(ages, slope, low, up), historical_linear, tolerance = 1e-14)
  expect_equal(dtexp(ages, rate, low, up), historical_exponential, tolerance = 1e-14)
})

test_that("signed random generators follow their corresponding CDFs", {
  low <- 651
  up <- 11650
  span <- up - low
  set.seed(4321)
  for (sign in c(-1, 1)) {
    slope <- sign * 1e-8
    linear_draws <- rtlin(10000L, slope, low, up)
    y_linear <- linear_draws - low
    intercept <- (1 + slope * span^2 / 2) / span
    linear_cdf <- intercept * y_linear - slope * y_linear^2 / 2
    expect_equal(mean(linear_cdf), 0.5, tolerance = 0.01)
    expect_equal(stats::var(linear_cdf), 1 / 12, tolerance = 0.005)

    rate <- sign * 2e-4
    exponential_draws <- rtexp(10000L, rate, low, up)
    y_exponential <- exponential_draws - low
    exponential_cdf <- (1 - exp(-rate * y_exponential)) /
      (1 - exp(-rate * span))
    expect_equal(mean(exponential_cdf), 0.5, tolerance = 0.01)
    expect_equal(stats::var(exponential_cdf), 1 / 12, tolerance = 0.005)
  }
})

test_that("production result validation enforces one complete 42-row block per simulation", {
  results <- expand.grid(
    sim = 1:2,
    strategy = c("r_1", "r_3", "r_5", "r_old", "r_young", "r_bracket", "r_all"),
    type = c("l1", "l2"),
    model = c("uni", "lin", "exp"),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  results$true <- "uni"
  results$prop <- 0.5
  results$min <- as.integer(results$model == "uni")
  results$ose <- results$min
  results$bias <- NA_real_

  expect_invisible(validate_population_simulation_results(results, nsim = 2L))
  expect_error(
    validate_population_simulation_results(results[-1, ], nsim = 2L),
    class = "rcdates_sim_result_error"
  )
})

test_that("Stage 2 result validation enforces complete 48-row signed blocks", {
  results <- make_stage2_result_fixture(nsim = 2L)
  expect_invisible(validate_population_simulation_results(
    results,
    nsim = 2L,
    design = "signed-v1"
  ))
  expect_error(
    validate_population_simulation_results(
      results[-1L, ],
      nsim = 2L,
      design = "signed-v1"
    ),
    class = "rcdates_sim_result_error"
  )
})

test_that("Figure 5 aggregation counts ambiguous OSE selections once per simulation", {
  results <- data.frame(
    prop = rep(0.5, 3),
    strategy = rep("r_1", 3),
    type = rep("l1", 3),
    sim = c(1L, 1L, 2L),
    true = rep("lin", 3),
    model = c("lin", "exp", "lin"),
    ose = rep(1L, 3),
    stringsAsFactors = FALSE
  )

  summary <- summarise_unique_ose(results)

  expect_equal(nrow(summary), 1L)
  expect_equal(summary$n_simulations, 2L)
  expect_equal(summary$p, 0.5)
  expect_lte(summary$ci_low, summary$p)
  expect_gte(summary$ci_high, summary$p)
})

test_that("production output filenames encode the complete scenario", {
  expect_identical(
    production_simulation_filename("exp", 0.75, nsim = 1000L, master_seed = 1234L),
    "results_exp_p0.75_ratio10_nsim1000_seed1234.rds"
  )
})

test_that("criterion selection retains equally supported models without duplicating the minimum", {
  pointwise_criterion <- data.frame(
    uni = c(10, 10),
    lin = c(9, 9),
    exp = c(9.5, 8.5)
  )

  selected <- select_population_models_from_criterion(pointwise_criterion, type = "l1")

  expect_identical(selected$model, c("uni", "lin", "exp"))
  expect_identical(selected$min, c(0L, 1L, 0L))
  expect_identical(selected$ose, c(0L, 1L, 1L))
})

test_that("one Stage 2 replicate returns a complete signed-model block", {
  skip_if_not_installed("rcarbon")
  skip_if_not_installed("fitdistrplus")

  sys.source(
    file.path(rcdates_test_root, "scripts", "release", "simulation_specification.R"),
    envir = topenv()
  )
  specification <- release_simulation_specification(
    file.path(rcdates_test_root, "release", "inputs", "simulation_parameters.csv"),
    signed = TRUE
  )
  expect_equal(specification$n_sites, 116L)

  specification$n_sites <- 4L
  result <- run_population_simulation_replicate(
    sim = 1L,
    truth = "uni",
    prop = 0.5,
    specification = specification,
    master_seed = 1234L
  )

  expect_equal(nrow(result), 48L)
  expect_invisible(validate_population_simulation_results(
    result,
    nsim = 1L,
    design = "signed-v1"
  ))
})

test_that("random-2 does not perturb the locked structural draws or RNG state", {
  skip_if_not_installed("rcarbon")
  skip_if_not_installed("fitdistrplus")
  skip_if_not_installed("import")

  sys.source(
    file.path(rcdates_test_root, "scripts", "release", "simulation_specification.R"),
    envir = topenv()
  )
  specification <- release_simulation_specification(
    file.path(rcdates_test_root, "release", "inputs", "simulation_parameters.csv"),
    signed = FALSE
  )
  specification$n_sites <- 4L
  legacy <- new.env(parent = globalenv())
  # The release omits the original production snapshot.  The frozen observation-noise
  # snapshot carries the same legacy helper byte-for-byte and its production
  # engine preserves the default curve-mean structural draw used here.
  sys.source(
    file.path(
      rcdates_test_root, "provenance", "observation-noise-20260726", "R",
      "legacy_simulation_helpers.R"
    ),
    envir = legacy
  )
  sys.source(
    file.path(
      rcdates_test_root, "provenance", "observation-noise-20260726", "R",
      "population_simulation_production.R"
    ),
    envir = legacy
  )

  set.seed(1235L, kind = "L'Ecuyer-CMRG")
  locked <- legacy$simulate_population_data_set("uni", 0.5, specification)
  locked_rng <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  set.seed(1235L, kind = "L'Ecuyer-CMRG")
  signed <- simulate_population_data_set("uni", 0.5, specification)
  signed_rng <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)

  protected_columns <- c(
    "site", "age_calendar", "age_uncalibrated", "error", "age_calibrated_median",
    "r_1", "r_3", "r_5", "r_old", "r_young", "r_bracket", "r_all"
  )
  expect_identical(signed[protected_columns], locked[protected_columns])
  expect_identical(signed$age_uncalibrated_expected, locked$age_uncalibrated)
  expect_identical(signed_rng, locked_rng)
})

test_that("production runner arguments have stable defaults and strict validation", {
  parsed <- parse_population_simulation_args(c(
    "--truth=lin_dec",
    "--prop=0.75",
    "--ratio=10",
    "--nsim=25",
    "--cores=4",
    "--batch-size=8",
    "--output=out/test.rds"
  ))

  expect_identical(parsed$truth, "lin_dec")
  expect_identical(parsed$prop, 0.75)
  expect_identical(parsed$ratio, 10)
  expect_identical(parsed$nsim, 25L)
  expect_identical(parsed$cores, 4L)
  expect_identical(parsed$batch_size, 8L)
  expect_identical(parsed$master_seed, 1234L)
  expect_identical(parsed$output, "out/test.rds")
  expect_error(
    parse_population_simulation_args(c("--truth=lin_inc", "--prop=0.6")),
    class = "rcdates_sim_spec_error"
  )
})

test_that("flattened likelihood grids preserve both historical likelihoods", {
  grids <- list(
    data.frame(calBP = c(650, 700, 800), PrDens = c(0.1, 0.6, 0.3)),
    data.frame(calBP = c(900, 1000, 1200), PrDens = c(0.2, 0.5, 0.3))
  )
  low <- 651
  up <- 11650
  prepared <- prepare_population_likelihood_data(grids, low, up)

  direct_pointwise <- function(parameter, model, type) {
    vapply(grids, function(grid) {
      keep <- grid$calBP > low & grid$calBP < up
      ages <- grid$calBP[keep]
      probability <- grid$PrDens[keep] / sum(grid$PrDens[keep])
      density <- if (model == "lin") {
        dtlin(ages, parameter, low, up)
      } else {
        dtexp(ages, parameter, low, up)
      }
      if (type == "l1") {
        -log(sum(density * probability))
      } else {
        -sum(log(density) * probability)
      }
    }, numeric(1))
  }

  cases <- expand.grid(
    model = c("lin", "exp"),
    type = c("l1", "l2"),
    stringsAsFactors = FALSE
  )
  for (index in seq_len(nrow(cases))) {
    model <- cases$model[[index]]
    type <- cases$type[[index]]
    parameter <- if (model == "lin") 1e-8 else 1e-4
    expected <- direct_pointwise(parameter, model, type)
    actual <- if (model == "lin") {
      population_nll_linear(
        parameter * 1e6,
        prepared,
        low,
        up,
        type,
        summed = FALSE
      )
    } else {
      population_nll_exponential(
        parameter * 1000,
        prepared,
        low,
        up,
        type,
        summed = FALSE
      )
    }
    expect_equal(actual, expected, tolerance = 1e-12)
  }
})

test_that("flattened optimisation matches direct signed L1 and L2 objectives", {
  grids <- list(
    data.frame(calBP = c(700, 800, 1000), PrDens = c(0.15, 0.65, 0.2)),
    data.frame(calBP = c(2000, 2500, 3000), PrDens = c(0.2, 0.5, 0.3)),
    data.frame(calBP = c(7000, 8500, 10000), PrDens = c(0.2, 0.6, 0.2))
  )
  low <- 651
  up <- 11650
  prepared <- prepare_population_likelihood_data(grids, low, up)

  direct_nll <- function(parameter, model, type) {
    sum(vapply(grids, function(grid) {
      probability <- grid$PrDens / sum(grid$PrDens)
      density <- if (model == "lin") {
        dtlin(grid$calBP, parameter / 1e6, low, up)
      } else {
        dtexp(grid$calBP, parameter / 1000, low, up)
      }
      if (type == "l1") {
        -log(sum(density * probability))
      } else {
        -sum(log(density) * probability)
      }
    }, numeric(1)))
  }

  bounds <- population_fit_bounds(low, up)
  for (type in c("l1", "l2")) {
    historical_linear <- stats::optimize(
      direct_nll,
      bounds$lin,
      model = "lin",
      type = type,
      tol = bounds$tolerance
    )
    flattened_linear <- stats::optimize(
      population_nll_linear,
      bounds$lin,
      likelihood_data = prepared,
      low = low,
      up = up,
      type = type,
      tol = bounds$tolerance
    )
    expect_equal(flattened_linear, historical_linear, tolerance = 1e-10)

    historical_exponential <- stats::optimize(
      direct_nll,
      bounds$exp,
      model = "exp",
      type = type,
      tol = bounds$tolerance
    )
    flattened_exponential <- stats::optimize(
      population_nll_exponential,
      bounds$exp,
      likelihood_data = prepared,
      low = low,
      up = up,
      type = type,
      tol = bounds$tolerance
    )
    expect_equal(flattened_exponential, historical_exponential, tolerance = 1e-10)
  }
})

test_that("production display summaries report accuracy and replicate-level bias", {
  results <- data.frame(
    prop = rep(0.5, 8),
    strategy = rep("r_all", 8),
    type = rep("l1", 8),
    sim = rep(1:4, each = 2),
    true = rep(c("lin", "exp"), 4),
    model = c("lin", "exp", "lin", "lin", "lin", "exp", "exp", "exp"),
    min = 1L,
    bias = c(1, 2, 3, 4, 5, 6, 7, 8) * 1e-5,
    stringsAsFactors = FALSE
  )

  accuracy <- summarise_population_accuracy(results, n_boot = 50L, seed = 1234L)
  bias <- summarise_population_bias(results)

  expect_equal(accuracy$accuracy, 0.75)
  expect_equal(accuracy$n_simulations, 8L)
  expect_equal(accuracy$n_clusters, 4L)
  expect_lte(accuracy$ci_low, accuracy$accuracy)
  expect_gte(accuracy$ci_high, accuracy$accuracy)
  expect_equal(nrow(bias), 2L)
  expect_equal(bias$mean_bias[bias$true == "lin"], mean(c(1, 3, 5, 7)) * 1e-5)
})

test_that("accuracy and OSE intervals bootstrap paired replicate clusters", {
  design <- expand.grid(
    sim = 1:4,
    true = c("uni", "lin", "exp"),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  correct <- design$sim <= 2L
  accuracy_results <- transform(
    design,
    prop = 0.5,
    strategy = "r_all",
    type = "l1",
    model = ifelse(correct, true, ifelse(true == "uni", "lin", "uni")),
    min = 1L
  )
  ose_results <- transform(
    accuracy_results,
    ose = 1L
  )

  accuracy <- summarise_population_accuracy(
    accuracy_results,
    n_boot = 2000L,
    seed = 1234L
  )
  ose <- summarise_unique_ose(ose_results, n_boot = 2000L, seed = 1234L)

  expect_equal(accuracy$accuracy, 0.5)
  expect_equal(accuracy$n_clusters, 4L)
  expect_gte(accuracy$ci_high - accuracy$ci_low, 0.75)
  expect_equal(ose$p, 0.5)
  expect_equal(ose$n_clusters, 4L)
  expect_gte(ose$ci_high - ose$ci_low, 0.75)
})

test_that("Stage 2 summaries separate family, direction, bias, and paired contrasts", {
  results <- make_stage2_result_fixture(nsim = 2L)
  confusion <- summarise_stage2_confusion(results)
  selection <- summarise_stage2_selection(results)
  bias <- summarise_stage2_log_ratio_bias(results)
  boundaries <- summarise_stage2_boundaries(results)
  paired <- summarise_stage2_paired_contrasts(results)

  oldest <- selection[
    selection$type == "l1" & selection$strategy == "r_old",
  ]
  youngest <- confusion[
    confusion$type == "l1" & confusion$strategy == "r_young",
  ]
  expect_equal(oldest$family_selection_rate, 1)
  expect_equal(oldest$direction_selection_rate, 0)
  expect_equal(oldest$direction_reversal_rate, 1)
  expect_identical(youngest$selected_state, "exp_inc")
  expect_true(all(is.finite(bias$mean_bias_log_ratio)))
  expect_true(all(boundaries$boundary_rate == 0))
  expect_true(any(
    paired$strategy == "r_old" &
      paired$metric == "direction_selection_rate" &
      paired$difference_from_all == -1
  ))
})

test_that("checkpoint provenance rejects unstamped or incompatible results", {
  expected <- list(
    schema_version = 1L,
    true_model = "lin",
    prop = 0.75,
    nsim = 1000L,
    master_seed = 1234L,
    input_md5 = "input",
    renv_lock_md5 = "lock",
    production_source_md5 = "production",
    legacy_helper_md5 = "legacy",
    runner_source_md5 = "runner",
    container_recipe_md5 = "container",
    container_install_md5 = "inline-in-recipe",
    container_image_id = "image",
    provenance_origin = "native-checkpoint",
    r_version = "R 4.5.3"
  )
  checkpoint <- data.frame(sim = 1L)

  expect_error(
    validate_population_checkpoint_provenance(checkpoint, expected),
    class = "rcdates_sim_provenance_error"
  )

  attr(checkpoint, "production_provenance") <- expected
  expect_invisible(validate_population_checkpoint_provenance(checkpoint, expected))

  incompatible <- expected
  incompatible$master_seed <- 999L
  expect_error(
    validate_population_checkpoint_provenance(checkpoint, incompatible),
    class = "rcdates_sim_provenance_error"
  )
})

test_that("production artifacts require matching checkpoint metadata", {
  results <- expand.grid(
    sim = 1L,
    strategy = c("r_1", "r_3", "r_5", "r_old", "r_young", "r_bracket", "r_all"),
    type = c("l1", "l2"),
    model = c("uni", "lin", "exp"),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  results$true <- "uni"
  results$prop <- 0.5
  results$min <- as.integer(results$model == "uni")
  results$ose <- results$min
  results$bias <- NA_real_
  results <- results[, c(
    "sim", "true", "prop", "strategy", "type", "model", "min", "ose", "bias"
  )]
  provenance <- list(
    schema_version = 1L,
    true_model = "uni",
    prop = 0.5,
    nsim = 1L,
    master_seed = 1234L,
    input_md5 = paste(rep("a", 32), collapse = ""),
    renv_lock_md5 = paste(rep("1", 32), collapse = ""),
    production_source_md5 = paste(rep("b", 32), collapse = ""),
    legacy_helper_md5 = paste(rep("c", 32), collapse = ""),
    runner_source_md5 = paste(rep("d", 32), collapse = ""),
    container_recipe_md5 = paste(rep("e", 32), collapse = ""),
    container_install_md5 = "inline-in-recipe",
    container_image_id = paste0("sha256:", paste(rep("f", 64), collapse = "")),
    provenance_origin = "native-checkpoint",
    r_version = "R version 4.5.3 (2026-03-11)"
  )
  attr(results, "production_provenance") <- provenance

  path <- tempfile(fileext = ".rds")
  saveRDS(results, path)
  metadata <- c(
    "rc-dates production population simulation",
    "schema_version: 1",
    "generation_completed_utc: 2026-07-10 00:00:00 UTC",
    "metadata_recorded_utc: 2026-07-10 00:01:00 UTC",
    paste("r_version:", provenance$r_version),
    "true_model: uni",
    "site_subsampling_proportion: 0.5",
    "replicates: 1",
    "master_seed: 1234",
    paste("input_md5:", provenance$input_md5),
    paste("renv_lock_md5:", provenance$renv_lock_md5),
    paste("production_source_md5:", provenance$production_source_md5),
    paste("legacy_helper_md5:", provenance$legacy_helper_md5),
    paste("runner_source_md5:", provenance$runner_source_md5),
    paste("container_recipe_md5:", provenance$container_recipe_md5),
    paste("container_install_md5:", provenance$container_install_md5),
    paste("container_image_id:", provenance$container_image_id),
    paste("provenance_origin:", provenance$provenance_origin),
    paste("output_md5:", unname(tools::md5sum(path)))
  )
  writeLines(metadata, paste0(path, ".metadata.txt"))

  expect_invisible(validate_population_simulation_artifact(path, nsim = 1L))

  v2_provenance <- provenance
  v2_provenance$schema_version <- 2L
  v2_provenance$model_source_md5 <- v2_provenance$production_source_md5
  v2_provenance$distribution_source_md5 <- v2_provenance$legacy_helper_md5
  v2_provenance$container_install_md5 <- paste(rep("2", 32), collapse = "")
  v2_provenance$production_source_md5 <- NULL
  v2_provenance$legacy_helper_md5 <- NULL
  v2_provenance$provenance_origin <- NULL
  v2_results <- results
  attr(v2_results, "production_provenance") <- v2_provenance
  saveRDS(v2_results, path)
  v2_metadata <- c(
    "rc-dates production population simulation",
    "schema_version: 2",
    "generation_completed_utc: 2026-07-10 00:00:00 UTC",
    "metadata_recorded_utc: 2026-07-10 00:01:00 UTC",
    paste("r_version:", v2_provenance$r_version),
    "true_model: uni",
    "site_subsampling_proportion: 0.5",
    "replicates: 1",
    "master_seed: 1234",
    paste("input_md5:", v2_provenance$input_md5),
    paste("renv_lock_md5:", v2_provenance$renv_lock_md5),
    paste("model_source_md5:", v2_provenance$model_source_md5),
    paste("distribution_source_md5:", v2_provenance$distribution_source_md5),
    paste("runner_source_md5:", v2_provenance$runner_source_md5),
    paste("container_recipe_md5:", v2_provenance$container_recipe_md5),
    paste("container_install_md5:", v2_provenance$container_install_md5),
    paste("container_image_id:", v2_provenance$container_image_id),
    paste("output_md5:", unname(tools::md5sum(path)))
  )
  writeLines(v2_metadata, paste0(path, ".metadata.txt"))
  expect_invisible(validate_population_simulation_artifact(path, nsim = 1L))

  saveRDS(results, path)
  metadata <- sub(
    "output_md5: .*",
    paste("output_md5:", unname(tools::md5sum(path))),
    metadata
  )
  writeLines(metadata, paste0(path, ".metadata.txt"))

  mismatched_results <- results
  mismatched_results$true <- "lin"
  saveRDS(mismatched_results, path)
  mismatched_metadata <- sub(
    "output_md5: .*",
    paste("output_md5:", unname(tools::md5sum(path))),
    metadata
  )
  writeLines(mismatched_metadata, paste0(path, ".metadata.txt"))
  expect_error(
    validate_population_simulation_artifact(path, nsim = 1L),
    class = "rcdates_sim_provenance_error"
  )

  saveRDS(results, path)
  metadata <- sub(
    "output_md5: .*",
    paste("output_md5:", unname(tools::md5sum(path))),
    metadata
  )
  writeLines(
    sub("output_md5: .*", "output_md5: tampered", metadata),
    paste0(path, ".metadata.txt")
  )
  expect_error(
    validate_population_simulation_artifact(path, nsim = 1L),
    class = "rcdates_sim_provenance_error"
  )
})
