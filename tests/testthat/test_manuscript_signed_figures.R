test_that("signed-state figure data preserve the accepted Stage 2 decision", {
  performance <- read.csv(
    file.path(
      rcdates_test_root,
      "out/revision/signed-models/selection_performance.csv"
    ),
    stringsAsFactors = FALSE
  )
  prepared <- prepare_manuscript_signed_performance(performance)

  expect_equal(nrow(prepared), 120L)
  expect_setequal(unique(as.character(prepared$truth_label)), c(
    "uniform", "linear increase", "linear decrease",
    "exponential increase", "exponential decrease"
  ))
  expect_setequal(unique(as.character(prepared$strategy_label)), c(
    "all dates", "random-1", "random-2", "random-3", "random-5",
    "bracketed", "oldest", "youngest"
  ))

  full <- prepared[prepared$prop == 1, , drop = FALSE]
  oldest <- full[full$strategy == "r_old", , drop = FALSE]
  youngest <- full[full$strategy == "r_young", , drop = FALSE]
  nonuniform <- full$true != "uni"

  expect_equal(oldest$state_rate[oldest$true == "uni"], 0)
  expect_equal(youngest$state_rate[youngest$true == "uni"], 0)
  expect_true(all(oldest$mean_selected_log_ratio < 0))
  expect_true(all(youngest$mean_selected_log_ratio > 0))
  expect_equal(
    full$direction_reversal_rate[
      nonuniform & full$strategy %in% c("r_old", "r_young") &
        sign(full$mean_selected_log_ratio) != sign(full$true_log_ratio)
    ],
    rep(1, 4L)
  )
})

test_that("common-effect figure data expose reversals and boundary saturation", {
  bias <- read.csv(
    file.path(rcdates_test_root, "out/revision/signed-models/log_ratio_bias.csv"),
    stringsAsFactors = FALSE
  )
  prepared <- prepare_manuscript_theta_panel(bias)

  expect_equal(nrow(prepared), 32L)
  expect_true(all(prepared$estimate_low - 1e-12 <= prepared$mean_estimate_log_ratio))
  expect_true(all(prepared$estimate_high + 1e-12 >= prepared$mean_estimate_log_ratio))
  expect_true(all(is.finite(unlist(prepared[c(
    "mean_estimate_log_ratio", "estimate_low", "estimate_high", "boundary_rate"
  )]))))

  estimate <- function(truth, strategy) {
    prepared$mean_estimate_log_ratio[
      prepared$true == truth & prepared$strategy == strategy
    ]
  }
  expect_lt(estimate("lin_inc", "r_old"), 0)
  expect_lt(estimate("exp_inc", "r_old"), 0)
  expect_gt(estimate("lin_dec", "r_young"), 0)
  expect_gt(estimate("exp_dec", "r_young"), 0)
  expect_true(all(prepared$boundary_saturated[
    prepared$true %in% c("lin_inc", "lin_dec") &
      prepared$strategy %in% c("r_old", "r_young")
  ]))
})

test_that("signed-model manuscript plots build from accepted summaries", {
  performance <- prepare_manuscript_signed_performance(read.csv(
    file.path(
      rcdates_test_root,
      "out/revision/signed-models/selection_performance.csv"
    ),
    stringsAsFactors = FALSE
  ))
  theta <- prepare_manuscript_theta_panel(read.csv(
    file.path(rcdates_test_root, "out/revision/signed-models/log_ratio_bias.csv"),
    stringsAsFactors = FALSE
  ))

  plots <- list(
    manuscript_signed_state_plot(performance),
    manuscript_theta_plot(theta),
    manuscript_family_selection_plot(performance)
  )
  expect_true(all(vapply(plots, inherits, logical(1), what = "ggplot")))
  expect_silent(lapply(plots, ggplot2::ggplot_build))
})

test_that("supplementary truth curves reproduce the frozen signed design", {
  curves <- prepare_manuscript_signed_truth_curves()

  expect_equal(nrow(curves), 5005L)
  expect_setequal(unique(curves$truth), c(
    "uni", "lin_inc", "lin_dec", "exp_inc", "exp_dec"
  ))
  expect_true(all(is.finite(curves$density) & curves$density > 0))

  endpoint_ratio <- vapply(split(curves, curves$truth), function(rows) {
    rows$density[rows$cal_bp == 651] / rows$density[rows$cal_bp == 11650]
  }, numeric(1))
  expect_equal(endpoint_ratio[["uni"]], 1, tolerance = 1e-12)
  expect_equal(
    unname(endpoint_ratio[c("lin_inc", "exp_inc")]),
    c(10, 10),
    tolerance = 1e-10
  )
  expect_equal(
    unname(endpoint_ratio[c("lin_dec", "exp_dec")]),
    c(0.1, 0.1),
    tolerance = 1e-10
  )

  plot <- manuscript_signed_truth_plot(curves)
  expect_s3_class(plot, "ggplot")
  expect_silent(ggplot2::ggplot_build(plot))
})
