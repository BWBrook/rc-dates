source(file.path("..", "..", "R", "population_simulation_production.R"))
source(file.path("..", "..", "R", "observation_noise_sensitivity.R"))
source(file.path("..", "..", "R", "observation_noise_summaries.R"))

make_noise_summary_checkpoint <- function(true_model, prop, nsim = 3L) {
  strategies <- c("r_all", "r_1", "r_3", "r_5")
  models <- c("uni", "lin", "exp")
  rows <- do.call(rbind, lapply(seq_len(nsim), function(sim) {
    do.call(rbind, lapply(c("curve_mean", "realised"), function(arm) {
      do.call(rbind, lapply(strategies, function(strategy) {
        do.call(rbind, lapply(c("l1", "l2"), function(type) {
          data.frame(
            sim = sim, true = true_model, prop = prop, strategy = strategy,
            type = type, model = models, min = as.integer(models == true_model),
            ose = as.integer(models == true_model),
            bias = ifelse(models == true_model & true_model != "uni",
                          if (arm == "realised") -0.01 else 0.01, NA_real_),
            n_observations = 10L, n_dropped = 0L, observation_model = arm,
            pair_id = sprintf("%s_%s_%s", true_model, prop, sim),
            structure_hash = strrep("a", 64), selection_hash = strrep(if (prop == 0.5) "b" else "e", 64),
            stringsAsFactors = FALSE
          )
        }))
      }))
    }))
  }))
  manifest <- do.call(rbind, lapply(seq_len(nsim), function(sim) {
    data.frame(
      pair_id = sprintf("%s_%s_%s", true_model, prop, sim), sim = sim,
      true = true_model, prop = prop, n_sites = 10L, n_dates = 100L,
      n_treated_sites = as.integer(round(prop * 10)), structure_hash = strrep("a", 64),
      selection_hash = strrep(if (prop == 0.5) "b" else "e", 64), expectation_observation_hash = strrep("c", 64),
      realised_observation_hash = strrep("d", 64), expectation_low_mass_rate = 0,
      realised_low_mass_rate = 0, expectation_zero_mass_rate = 0,
      realised_zero_mass_rate = 0, stringsAsFactors = FALSE
    )
  }))
  provenance <- list(
    schema_version = 1L, sensitivity_design = "paired_curve_mean_vs_realised_v1",
    observation_models = c("curve_mean", "realised"), assay_equation = "synthetic",
    calibration_curve = "shcal20", roundyear = TRUE, window_exclusion_rule = "synthetic",
    rng_kind = "L'Ecuyer-CMRG", stream_mapping = "synthetic", true_model = true_model,
    prop = prop, nsim = nsim, master_seed = 1234L, strategies = strategies,
    input_md5 = "input", renv_lock_md5 = "lock", production_source_md5 = "production",
    sensitivity_source_md5 = "sensitivity", legacy_helper_md5 = "legacy", runner_source_md5 = "runner",
    container_recipe_md5 = "container", container_install_md5 = "install",
    container_image_id = "image", r_version = "R 4.5.3"
  )
  list(results = rows, pair_manifest = manifest, provenance = provenance)
}

write_noise_summary_artifact_fixture <- function(directory) {
  checkpoint <- make_noise_summary_checkpoint("uni", 0.5, nsim = 3L)
  provenance_dir <- file.path(
    "..",
    "..",
    "provenance",
    "observation-noise-20260726"
  )
  input_path <- file.path("..", "..", "data", "austarch_filtered.csv")
  lock_path <- file.path("..", "..", "renv.lock")
  image_id <- paste0("sha256:", strrep("1", 64))
  checkpoint$provenance <- list(
    schema_version = 1L,
    sensitivity_design = "paired_curve_mean_vs_realised_v1",
    observation_models = c("curve_mean", "realised"),
    assay_equation = "rCRA=round(ccCRA+Z*sqrt(ccError^2+quoted_error^2))",
    calibration_curve = "shcal20",
    roundyear = TRUE,
    window_exclusion_rule =
      "drop selected observations with zero posterior mass in 651-11650",
    rng_kind = "L'Ecuyer-CMRG",
    stream_mapping = "structural=current; realised_assay=nextRNGStream(structural)",
    true_model = "uni",
    prop = 0.5,
    nsim = 3L,
    master_seed = 1234L,
    strategies = c("r_all", "r_1", "r_3", "r_5"),
    input_md5 = unname(tools::md5sum(input_path)),
    renv_lock_md5 = unname(tools::md5sum(lock_path)),
    production_source_md5 = unname(tools::md5sum(file.path(
      provenance_dir, "R", "population_simulation_production.R"
    ))),
    sensitivity_source_md5 = unname(tools::md5sum(file.path(
      provenance_dir, "R", "observation_noise_sensitivity.R"
    ))),
    legacy_helper_md5 = unname(tools::md5sum(file.path(
      provenance_dir, "R", "legacy_simulation_helpers.R"
    ))),
    runner_source_md5 = unname(tools::md5sum(file.path(
      provenance_dir, "scripts", "run_observation_noise_sensitivity.R"
    ))),
    container_recipe_md5 = unname(tools::md5sum(file.path(
      provenance_dir, "docker", "production-simulation.Dockerfile"
    ))),
    container_install_md5 = unname(tools::md5sum(file.path(
      provenance_dir, "docker", "install-production-packages.R"
    ))),
    container_image_id = image_id,
    r_version = "R version 4.5.3 (2026-03-11)",
    rcarbon_version = "1.5.2"
  )
  path <- file.path(directory, "observation_noise_uni_p0.5_fixture.rds")
  pair_path <- sub("\\.rds$", ".pairs.csv", path)
  metadata_path <- paste0(path, ".metadata.txt")
  image_id_path <- file.path(directory, "container_image_id.txt")
  saveRDS(checkpoint, path, version = 3)
  readr::write_csv(checkpoint$pair_manifest, pair_path)
  writeLines(image_id, image_id_path)
  provenance <- checkpoint$provenance
  writeLines(c(
    "rc-dates paired observation-noise sensitivity",
    paste("schema_version:", provenance$schema_version),
    "generation_completed_utc: 2026-07-26 00:00:00 UTC",
    paste("r_version:", provenance$r_version),
    paste("rcarbon_version:", provenance$rcarbon_version),
    paste("true_model:", provenance$true_model),
    paste("site_subsampling_proportion:", provenance$prop),
    paste("paired_replicates:", provenance$nsim),
    paste("master_seed:", provenance$master_seed),
    paste("strategies:", paste(provenance$strategies, collapse = ",")),
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
    paste("output_md5:", unname(tools::md5sum(path))),
    paste("pair_manifest_md5:", unname(tools::md5sum(pair_path))),
    "packages: synthetic=1"
  ), metadata_path)
  list(
    path = path,
    provenance_dir = provenance_dir,
    input_path = input_path,
    lock_path = lock_path,
    image_id_path = image_id_path
  )
}

test_that("paired summary validates nine scenarios and emits simultaneous contrasts", {
  checkpoints <- lapply(c("uni", "lin", "exp"), function(model) {
    lapply(c(0.5, 0.75, 1), make_noise_summary_checkpoint, true_model = model)
  })
  checkpoints <- unlist(checkpoints, recursive = FALSE)
  summary <- summarise_observation_noise_sensitivity(checkpoints, n_boot = 30L, seed = 1L)
  expect_true(is.list(summary$metrics))
  expect_true(all(c("pooled", "lin", "exp", "uni") %in% summary$metrics$accuracy$scope))
  expect_true(all(summary$metrics$accuracy$ci_low <= summary$metrics$accuracy$estimate))
  expect_true(all(summary$metrics$accuracy$estimate <= summary$metrics$accuracy$ci_high))
  expect_true(is.data.frame(summary$gates))
  expect_length(unique(summary$metrics$accuracy$ci_high - summary$metrics$accuracy$estimate), 1L)
  signed_realised <- summary$metrics$bias[summary$metrics$bias$arm == "realised", ]
  expect_true(all(signed_realised$estimate < 0))
  summary_again <- summarise_observation_noise_sensitivity(checkpoints, n_boot = 30L, seed = 1L)
  expect_identical(summary$metrics$accuracy, summary_again$metrics$accuracy)
})

test_that("artifact validation binds checkpoints to frozen provenance", {
  skip_if_not_installed("digest")
  skip_if_not_installed("readr")
  directory <- withr::local_tempdir()
  fixture <- write_noise_summary_artifact_fixture(directory)
  validated <- validate_observation_noise_artifact(
    fixture$path,
    provenance_dir = fixture$provenance_dir,
    input_path = fixture$input_path,
    lock_path = fixture$lock_path,
    image_id_path = fixture$image_id_path,
    expected_nsim = 3L
  )
  expect_identical(validated$checkpoint$provenance$true_model, "uni")

  tampered <- readRDS(fixture$path)
  tampered$provenance$sensitivity_source_md5 <- strrep("0", 32)
  saveRDS(tampered, fixture$path, version = 3)
  expect_error(
    validate_observation_noise_artifact(
      fixture$path,
      provenance_dir = fixture$provenance_dir,
      input_path = fixture$input_path,
      lock_path = fixture$lock_path,
      image_id_path = fixture$image_id_path,
      expected_nsim = 3L
    ),
    class = "rcdates_sim_result_error"
  )
})

test_that("partial checkpoints fail against provenance nsim", {
  checkpoint <- make_noise_summary_checkpoint("uni", 0.5, nsim = 3L)
  checkpoint$provenance$nsim <- 4L
  expect_error(
    summarise_observation_noise_sensitivity(
      list(checkpoint), n_boot = 10L, require_complete_scenarios = FALSE
    ),
    class = "rcdates_sim_result_error"
  )
})

test_that("duplicate pair identifiers fail closed", {
  a <- make_noise_summary_checkpoint("uni", 0.5)
  b <- make_noise_summary_checkpoint("lin", 0.5)
  b$pair_manifest$pair_id <- a$pair_manifest$pair_id
  expect_error(
    summarise_observation_noise_sensitivity(
      c(list(a), list(b)), n_boot = 10L, require_complete_scenarios = FALSE
    ),
    class = "rcdates_sim_result_error"
  )
})

test_that("true slope and exponential rate use the declared window", {
  pars <- observation_noise_true_parameters()
  expect_equal(unname(pars[["lin"]]), 18 / (11 * (11650 - 651)^2))
  expect_equal(unname(pars[["exp"]]), log(10) / (11650 - 651))
})

test_that("RMSE uses the ratio of pooled squared errors, not mean ratios", {
  rows <- do.call(rbind, lapply(seq_len(2L), function(sim) {
    data.frame(
      sim = sim, true = "lin", prop = 1, strategy = "r_1", type = "l1",
      observation_model = c("curve_mean", "realised"), parameter = 1,
      bias = if (sim == 1L) c(1, 2) else c(3, 2), stringsAsFactors = FALSE
    )
  }))
  rmse <- observation_noise_rmse_summary(rows, n_boot = 200L, seed = 7L)
  expect_equal(rmse$estimate[rmse$scope == "lin"], sqrt(8 / 10), tolerance = 1e-12)
})

test_that("optimizer-boundary detection follows scaled optimize resolution", {
  specifications <- list(
    lin = list(bounds = c(1e-12, 2 / (11650 - 651)^2), scale = 1e6),
    exp = list(bounds = c(1e-10, 1e-3), scale = 1e3)
  )
  for (model in names(specifications)) {
    specification <- specifications[[model]]
    interval <- specification$bounds * specification$scale
    lower <- stats::optimize(function(x) x, interval = interval)$minimum /
      specification$scale
    upper <- stats::optimize(function(x) -x, interval = interval)$minimum /
      specification$scale
    middle <- mean(specification$bounds)
    expect_true(observation_noise_optimizer_boundary_hit(model, lower))
    expect_true(observation_noise_optimizer_boundary_hit(model, upper))
    expect_false(observation_noise_optimizer_boundary_hit(model, middle))
  }
})

test_that("accuracy advantages are direct paired realised-arm contrasts", {
  rows <- do.call(rbind, lapply(seq_len(4L), function(sim) {
    expand <- expand.grid(
      true = c("lin", "exp"), strategy = c("r_1", "r_3", "r_5"),
      type = c("l1", "l2"), KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
    )
    transform(expand, sim = sim, prop = 1, observation_model = "realised",
              accuracy = as.numeric(strategy != "r_1"))
  }))
  advantages <- observation_noise_accuracy_advantage(rows, n_boot = 200L, seed = 8L)
  expect_equal(advantages$estimate, rep(1, 4))
})

test_that("truth-specific accuracy safeguard prevents a pooled mask", {
  truth_rows <- expand.grid(
    scope = c("uni", "lin", "exp"),
    strategy = c("r_3", "r_5"),
    type = c("l1", "l2"),
    stringsAsFactors = FALSE
  )
  truth_rows$true <- truth_rows$scope
  truth_rows$metric <- "minimum_aic_accuracy"
  truth_rows$prop <- 1
  truth_rows$arm <- "realised"
  truth_rows$estimate <- ifelse(truth_rows$true == "uni", 0.75, 1)
  truth_rows$ci_low <- truth_rows$estimate - 0.03
  truth_rows$ci_high <- truth_rows$estimate + 0.03
  truth_rows$n_clusters <- 1000L
  pooled <- expand.grid(
    strategy = c("r_3", "r_5"),
    type = c("l1", "l2"),
    stringsAsFactors = FALSE
  )
  pooled$scope <- "pooled"
  pooled$true <- NA_character_
  pooled$metric <- "minimum_aic_accuracy"
  pooled$prop <- 1
  pooled$arm <- "realised"
  pooled$estimate <- (0.75 + 1 + 1) / 3
  pooled$ci_low <- 0.889
  pooled$ci_high <- 0.944
  pooled$n_clusters <- 1000L
  accuracy <- rbind(truth_rows, pooled)

  contrast <- expand.grid(
    strategy = c("r_3", "r_5"),
    type = c("l1", "l2"),
    stringsAsFactors = FALSE
  )
  contrast$metric <- "realised_accuracy_contrast_vs_r1"
  contrast$scope <- "pooled"
  contrast$true <- NA_character_
  contrast$prop <- 1
  contrast$reference_strategy <- "r_1"
  contrast$arm <- "difference"
  contrast$estimate <- 0.1
  contrast$ci_low <- 0.05
  contrast$ci_high <- 0.15
  contrast$n_clusters <- 1000L

  empty <- data.frame()
  metrics <- list(
    accuracy = accuracy,
    ose_support = empty,
    decision_discordance = data.frame(estimate = 0, ci_high = 0),
    ose_set_discordance = data.frame(estimate = 0, ci_high = 0),
    realised_accuracy_contrasts = contrast,
    realised_ose_contrasts = empty,
    bias = empty,
    paired_bias_shift = empty,
    rmse = empty,
    boundary = empty,
    drop_rate = empty,
    mass_zero = empty,
    mass_low = empty
  )
  gates <- observation_noise_gate_report(metrics)
  pooled_gate <- gates$pass[gates$gate == "prop1_random3_random5_accuracy"]
  truth_gate <- gates$pass[
    gates$gate == "prop1_truth_specific_random3_random5_accuracy"
  ]
  expect_true(pooled_gate)
  expect_false(truth_gate)
})

test_that("L1/L2 consistency flags only opposite resolved directions", {
  one <- expand.grid(
    prop = .5, strategy = "r_3", scope = "pooled", true = NA_character_,
    type = c("l1", "l2"), stringsAsFactors = FALSE
  )
  one$arm <- "difference"
  one$estimate <- c(.2, -.2)
  one$ci_low <- c(.1, -.3)
  one$ci_high <- c(.3, -.1)
  one$metric <- "x"
  metrics <- list(
    accuracy = one,
    ose_support = transform(one, estimate = c(.1, .1), ci_low = c(-.1, -.1), ci_high = c(.3, .3))
  )
  consistency <- observation_noise_likelihood_consistency(metrics)
  expect_false(consistency$pass)
  expect_equal(consistency$conflicts, 1L)
})

test_that("L1/L2 consistency checks realised strategy rankings", {
  contrast <- expand.grid(
    prop = 1,
    strategy = "r_3",
    reference_strategy = "r_1",
    scope = "pooled",
    true = NA_character_,
    type = c("l1", "l2"),
    stringsAsFactors = FALSE
  )
  contrast$arm <- "difference"
  contrast$estimate <- c(0.2, -0.2)
  contrast$ci_low <- c(0.1, -0.3)
  contrast$ci_high <- c(0.3, -0.1)
  metrics <- list(
    accuracy = data.frame(),
    ose_support = data.frame(),
    realised_accuracy_contrasts = contrast,
    realised_ose_contrasts = data.frame(),
    bias = data.frame(),
    paired_bias_shift = data.frame()
  )
  consistency <- observation_noise_likelihood_consistency(metrics)
  expect_false(consistency$pass)
  expect_equal(consistency$strategy_conflicts, 1L)
})

test_that("rate gates use simultaneous upper bounds", {
  empty <- data.frame()
  accuracy <- data.frame(
    arm = "curve_mean",
    true = NA_character_,
    prop = 0.5,
    type = "l1",
    strategy = "r_1",
    estimate = 1,
    ci_low = 1,
    ci_high = 1
  )
  metrics <- list(
    accuracy = accuracy,
    ose_support = empty,
    decision_discordance = data.frame(estimate = 0.09, ci_high = 0.14),
    ose_set_discordance = data.frame(estimate = 0.09, ci_high = 0.14),
    realised_accuracy_contrasts = empty,
    realised_ose_contrasts = empty,
    bias = empty,
    paired_bias_shift = empty,
    rmse = empty,
    boundary = empty,
    drop_rate = empty,
    mass_zero = empty,
    mass_low = empty
  )
  gates <- observation_noise_gate_report(metrics)
  expect_false(gates$pass[gates$gate == "minimum_aic_discordance"])
  expect_false(gates$pass[gates$gate == "ose_set_discordance"])
})
