test_that("observation-noise settings have stable names and strict validation", {
  expect_identical(
    normalize_population_observation_model("curve_mean"),
    "curve_mean"
  )
  expect_identical(
    normalize_population_observation_model("realised"),
    "realised"
  )
  expect_error(
    normalize_population_observation_model("unknown"),
    class = "rcdates_sim_spec_error"
  )

  expect_identical(
    observation_noise_sensitivity_filename(
      "exp",
      0.75,
      nsim = 1000L,
      master_seed = 1234L
    ),
    "observation_noise_exp_p0.75_ratio10_nsim1000_seed1234.rds"
  )

  parsed <- parse_observation_noise_sensitivity_args(c(
    "--model=lin",
    "--prop=0.75",
    "--nsim=25",
    "--cores=4",
    "--batch-size=8",
    "--strategies=r_all,r_1,r_3,r_5",
    "--output=out/sensitivity/test.rds"
  ))
  expect_identical(parsed$true_model, "lin")
  expect_identical(parsed$prop, 0.75)
  expect_identical(parsed$nsim, 25L)
  expect_identical(parsed$cores, 4L)
  expect_identical(parsed$batch_size, 8L)
  expect_identical(parsed$master_seed, 1234L)
  expect_identical(parsed$strategies, c("r_all", "r_1", "r_3", "r_5"))
  expect_identical(parsed$output, "out/sensitivity/test.rds")
  expect_error(
    parse_observation_noise_sensitivity_args(c(
      "--model=lin",
      "--prop=0.75",
      "--strategies=r_all,not_a_strategy"
    )),
    class = "rcdates_sim_spec_error"
  )
})

test_that("realised assays preserve structural and random-selection pairing", {
  skip_if_not_installed("rcarbon")
  skip_if_not_installed("fitdistrplus")

  data <- readr::read_csv(
    file.path("..", "..", "data", "austarch_filtered.csv"),
    show_col_types = FALSE
  )
  specification <- prepare_population_simulation(data)
  specification$n_sites <- 4L
  seed <- production_simulation_seed("lin", 0.5, sim = 1L, master_seed = 1234L)

  requireNamespace("rcarbon", quietly = TRUE)
  set.seed(seed, kind = "L'Ecuyer-CMRG")
  expectation <- simulate_population_data_set(
    "lin",
    0.5,
    specification,
    observation_model = "curve_mean"
  )
  expectation_rng_state <- .Random.seed

  set.seed(seed, kind = "L'Ecuyer-CMRG")
  realised <- simulate_population_data_set(
    "lin",
    0.5,
    specification,
    observation_model = "realised"
  )
  realised_rng_state <- .Random.seed

  shared_columns <- c(
    "site",
    "site_treated",
    "age_calendar",
    "age_uncalibrated_expected",
    "error",
    "r_1",
    "r_3",
    "r_5",
    "r_all"
  )
  expect_identical(expectation[shared_columns], realised[shared_columns])
  expect_identical(expectation_rng_state, realised_rng_state)
  expect_equal(
    expectation$age_uncalibrated,
    expectation$age_uncalibrated_expected
  )
  expect_true(any(
    realised$age_uncalibrated != realised$age_uncalibrated_expected
  ))
  expect_identical(unique(expectation$observation_model), "curve_mean")
  expect_identical(unique(realised$observation_model), "realised")
})

test_that("one paired sensitivity replicate is complete and hash-auditable", {
  skip_if_not_installed("rcarbon")
  skip_if_not_installed("fitdistrplus")
  skip_if_not_installed("digest")

  data <- readr::read_csv(
    file.path("..", "..", "data", "austarch_filtered.csv"),
    show_col_types = FALSE
  )
  specification <- prepare_population_simulation(data)
  specification$n_sites <- 4L
  strategies <- c("r_all", "r_1")

  paired <- run_observation_noise_sensitivity_replicate(
    sim = 1L,
    true_model = "uni",
    prop = 0.5,
    specification = specification,
    master_seed = 1234L,
    strategies = strategies
  )

  expect_equal(nrow(paired$results), 24L)
  expect_equal(nrow(paired$pair_manifest), 1L)
  expect_setequal(
    unique(paired$results$observation_model),
    c("curve_mean", "realised")
  )
  expect_length(unique(paired$results$pair_id), 1L)
  expect_length(unique(paired$results$structure_hash), 1L)
  expect_length(unique(paired$results$selection_hash), 1L)
  expect_match(paired$results$structure_hash[[1L]], "^[0-9a-f]{64}$")
  expect_match(paired$results$selection_hash[[1L]], "^[0-9a-f]{64}$")
  expect_invisible(validate_observation_noise_sensitivity_results(
    paired$results,
    nsim = 1L,
    strategies = strategies
  ))
  expect_invisible(validate_observation_noise_pair_manifest(
    paired$pair_manifest,
    nsim = 1L
  ))
  expect_invisible(validate_observation_noise_result_manifest_pairing(
    paired$results,
    paired$pair_manifest
  ))

  expect_error(
    validate_observation_noise_sensitivity_results(
      paired$results[-1L, ],
      nsim = 1L,
      strategies = strategies
    ),
    class = "rcdates_sim_result_error"
  )

  identical_observations <- paired$pair_manifest
  identical_observations$realised_observation_hash <-
    identical_observations$expectation_observation_hash
  expect_error(
    validate_observation_noise_pair_manifest(
      identical_observations,
      nsim = 1L
    ),
    class = "rcdates_sim_result_error"
  )

  mismatched_hash <- paired$pair_manifest
  mismatched_hash$structure_hash <- strrep("f", 64)
  expect_error(
    validate_observation_noise_result_manifest_pairing(
      paired$results,
      mismatched_hash
    ),
    class = "rcdates_sim_result_error"
  )
})

test_that("sensitivity likelihood can exclude observations with zero window overlap", {
  grids <- list(
    data.frame(calBP = c(100, 200), PrDens = c(0.4, 0.6)),
    data.frame(calBP = c(700, 800), PrDens = c(0.4, 0.6)),
    data.frame(calBP = c(900, 1000), PrDens = c(0.2, 0.8))
  )

  expect_error(
    prepare_population_likelihood_data(grids, low = 651, up = 11650),
    class = "rcdates_sim_result_error"
  )
  prepared <- prepare_population_likelihood_data(
    grids,
    low = 651,
    up = 11650,
    drop_empty = TRUE
  )

  expect_identical(prepared$n_dates, 2L)
  expect_identical(prepared$n_dropped, 1L)
  expect_equal(prepared$age, c(700, 800, 900, 1000))
  expect_equal(prepared$probability, c(0.4, 0.6, 0.2, 0.8))
})
