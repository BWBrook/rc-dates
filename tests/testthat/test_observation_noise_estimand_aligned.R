source(file.path("..", "..", "R", "observation_noise_summaries.R"))
source(file.path("..", "..", "R", "observation_noise_estimand_aligned.R"))

make_estimand_rows <- function(nsim = 5L) {
  grid <- expand.grid(
    sim = seq_len(nsim), true = c("uni", "lin", "exp"),
    prop = c(0.5, 0.75, 1), strategy = c("r_all", "r_1", "r_3", "r_5"),
    type = c("l1", "l2"), observation_model = c("curve_mean", "realised"),
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  grid$accuracy <- as.numeric(grid$observation_model == "realised") * 0.01
  grid$ose_unique_true <- as.numeric(grid$observation_model == "realised") * 0.02
  grid$boundary_hit <- as.numeric(grid$observation_model == "realised") * 0.001
  grid
}

test_that("v2 difference families contain only their declared cells", {
  rows <- make_estimand_rows()
  accuracy <- observation_noise_estimand_aligned_bootstrap(
    rows, "accuracy", "accuracy", n_boot = 25L, seed = 1234L
  )
  boundary <- observation_noise_estimand_aligned_bootstrap(
    rows, "boundary_hit", "boundary", n_boot = 25L, seed = 1294L,
    boundary_only = TRUE, one_sided = TRUE
  )
  expect_equal(nrow(accuracy), 96L)
  expect_equal(nrow(boundary), 72L)
  expect_identical(unique(accuracy$arm), "difference")
  expect_true(all(is.na(accuracy$ci_low) == FALSE))
  expect_true(all(boundary$scope == "pooled" | boundary$true %in% c("lin", "exp")))
})

test_that("two-sided and one-sided maximum-deviation intervals differ as specified", {
  rows <- make_estimand_rows()
  two_sided <- observation_noise_estimand_aligned_bootstrap(
    rows, "accuracy", "accuracy", n_boot = 100L, seed = 7L
  )
  one_sided <- observation_noise_estimand_aligned_bootstrap(
    rows, "boundary_hit", "boundary", n_boot = 100L, seed = 67L,
    boundary_only = TRUE, one_sided = TRUE
  )
  expect_true(all(two_sided$ci_low <= two_sided$estimate))
  expect_true(all(two_sided$estimate <= two_sided$ci_high))
  expect_true(all(is.na(one_sided$ci_low)))
  expect_true(all(one_sided$estimate <= one_sided$ci_high))
  expect_match(unique(two_sided$interval), "two_sided")
  expect_match(unique(one_sided$interval), "one_sided")
})

test_that("equal-sized cells must share identical simulation identifiers", {
  rows <- make_estimand_rows()
  shifted <- rows$prop == 0.5 & rows$strategy == "r_all" & rows$type == "l1"
  rows$sim[shifted & rows$sim == 1L] <- 6L
  expect_error(
    observation_noise_estimand_aligned_bootstrap(
      rows, "accuracy", "accuracy", n_boot = 25L, seed = 1234L
    ),
    "identical ordered simulation identifiers"
  )
})

test_that("pooled and truth-specific maxima produce separate margins", {
  rows <- make_estimand_rows()
  metrics <- list(
    accuracy = observation_noise_estimand_aligned_bootstrap(
      rows, "accuracy", "accuracy", n_boot = 30L, seed = 1L
    ),
    ose = observation_noise_estimand_aligned_bootstrap(
      rows, "ose_unique_true", "ose", n_boot = 30L, seed = 11L
    ),
    boundary = observation_noise_estimand_aligned_bootstrap(
      rows, "boundary_hit", "boundary", n_boot = 30L, seed = 61L,
      boundary_only = TRUE, one_sided = TRUE
    )
  )
  gates <- observation_noise_estimand_aligned_gate_report(metrics)
  expect_equal(nrow(gates), 3L)
  expect_true(all(c("pooled_max", "truth_max", "pooled_margin", "truth_margin") %in%
                    names(gates)))
  expect_true(all(gates$pooled_margin <= gates$threshold_pooled))
  expect_true(all(gates$truth_margin <= gates$threshold_truth))
})

test_that("boundary gate retains the strict upper-bound rule", {
  rows <- make_estimand_rows()
  metric <- observation_noise_estimand_aligned_bootstrap(
    rows, "boundary_hit", "boundary", n_boot = 30L, seed = 61L,
    boundary_only = TRUE, one_sided = TRUE
  )
  metric$ci_high <- 0.01
  gates <- observation_noise_estimand_aligned_gate_report(list(
    accuracy = observation_noise_estimand_aligned_bootstrap(
      rows, "accuracy", "accuracy", n_boot = 30L, seed = 1L
    ),
    ose = observation_noise_estimand_aligned_bootstrap(
      rows, "ose_unique_true", "ose", n_boot = 30L, seed = 11L
    ),
    boundary = metric
  ))
  expect_false(gates$pass[gates$gate == "boundary_difference"])
})

test_that("fixed seeds reproduce metrics and distinct stability seeds agree", {
  rows <- make_estimand_rows()
  first <- observation_noise_estimand_aligned_bootstrap(
    rows, "accuracy", "accuracy", n_boot = 100L, seed = 1234L
  )
  second <- observation_noise_estimand_aligned_bootstrap(
    rows, "accuracy", "accuracy", n_boot = 100L, seed = 1234L
  )
  expect_identical(first, second)
  metrics <- list(
    accuracy = first,
    ose = observation_noise_estimand_aligned_bootstrap(
      rows, "ose_unique_true", "ose", n_boot = 20L, seed = 1244L
    ),
    boundary = observation_noise_estimand_aligned_bootstrap(
      rows, "boundary_hit", "boundary", n_boot = 20L, seed = 1294L,
      boundary_only = TRUE, one_sided = TRUE
    )
  )
  stability_metrics <- list(
    accuracy = observation_noise_estimand_aligned_bootstrap(
      rows, "accuracy", "accuracy", n_boot = 100L, seed = 5678L
    ),
    ose = observation_noise_estimand_aligned_bootstrap(
      rows, "ose_unique_true", "ose", n_boot = 20L, seed = 5688L
    ),
    boundary = observation_noise_estimand_aligned_bootstrap(
      rows, "boundary_hit", "boundary", n_boot = 20L, seed = 5738L,
      boundary_only = TRUE, one_sided = TRUE
    )
  )
  gates_a <- observation_noise_estimand_aligned_gate_report(metrics)
  gates_b <- observation_noise_estimand_aligned_gate_report(stability_metrics)
  stability <- ifelse(gates_a$pass == gates_b$pass, "AGREE", "DISAGREE")
  expect_identical(stability, rep("AGREE", 3L))
  stability_report <- data.frame(
    gate = gates_a$gate,
    primary_pooled_max = gates_a$pooled_max,
    stability_pooled_max = gates_b$pooled_max,
    primary_truth_margin = gates_a$truth_margin,
    stability_truth_margin = gates_b$truth_margin,
    primary_width = first$margin[[1L]],
    stability_width = stability_metrics$accuracy$margin[[1L]]
  )
  expect_true(all(vapply(stability_report[-1L], is.numeric, logical(1))))
  expect_true(all(is.finite(unlist(stability_report[-1L]))))
})
