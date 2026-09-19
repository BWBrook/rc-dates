make_endpoint_contrast_fixture <- function(nsim = 1000L) {
  truths <- c("lin_inc", "exp_inc", "lin_dec", "exp_dec")
  strategies <- names(manuscript_signed_strategy_labels())
  rows <- do.call(rbind, lapply(truths, function(truth) {
    family <- sub("_.*$", "", truth)
    direction <- if (grepl("_inc$", truth)) "increase" else "decrease"
    true_log_ratio <- if (direction == "increase") log(10) else -log(10)
    do.call(rbind, lapply(strategies, function(strategy) {
      data.frame(
        sim = seq_len(nsim), true = truth, true_family = family,
        true_direction = direction, true_log_ratio = true_log_ratio,
        prop = 1, strategy = strategy, type = "l1", model = family,
        estimate_log_ratio = rep(true_log_ratio, nsim),
        boundary = rep(FALSE, nsim),
        source_file = paste0("results_", truth, "_p1.rds"),
        stringsAsFactors = FALSE
      )
    }))
  }))
  rownames(rows) <- NULL
  rows
}

test_that("signed-state figure data preserve the accepted Stage 2 decision", {
  performance <- read.csv(file.path(
    rcdates_test_root, "out/revision/signed-models/selection_performance.csv"
  ), stringsAsFactors = FALSE)
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

test_that("endpoint contrasts transform replicates before summarising", {
  expect_equal(endpoint_contrast_from_log_ratio(c(-Inf, 0, Inf)), c(-1, 0, 1))
  q <- c(-1, -0.4, 0, 0.4, 1)
  log_ratio <- 2 * atanh(q)
  expect_equal(endpoint_contrast_from_log_ratio(log_ratio), q, tolerance = 1e-15)
  fixture <- make_endpoint_contrast_fixture()
  target <- fixture$true == "lin_inc" & fixture$strategy == "r_1"
  fixture$estimate_log_ratio[target] <- c(0, 4, rep(log(10), sum(target) - 2L))
  prepared <- prepare_manuscript_endpoint_contrast_panel(fixture)
  cell <- prepared[prepared$true == "lin_inc" & prepared$strategy == "r_1", ]
  transformed <- endpoint_contrast_from_log_ratio(fixture$estimate_log_ratio[target])
  expect_equal(cell$mean_contrast, mean(transformed), tolerance = 1e-15)
  expect_equal(
    c(cell$contrast_q025, cell$contrast_q975),
    as.numeric(stats::quantile(transformed, c(0.025, 0.975), type = 7)),
    tolerance = 1e-15
  )
  expect_equal(cell$true_contrast, 9 / 11, tolerance = 1e-15)
})

test_that("endpoint contrasts retain every boundary count and complete grid", {
  fixture <- make_endpoint_contrast_fixture()
  inc_random1 <- fixture$true == "lin_inc" & fixture$strategy == "r_1"
  dec_random1 <- fixture$true == "lin_dec" & fixture$strategy == "r_1"
  fixture$boundary[which(inc_random1)[seq_len(72L)]] <- TRUE
  fixture$boundary[which(dec_random1)[seq_len(82L)]] <- TRUE
  prepared <- prepare_manuscript_endpoint_contrast_panel(fixture)
  expect_equal(nrow(prepared), 32L)
  expect_equal(prepared$boundary_n[
    prepared$true == "lin_inc" & prepared$strategy == "r_1"
  ], 72L)
  expect_equal(prepared$boundary_n[
    prepared$true == "lin_dec" & prepared$strategy == "r_1"
  ], 82L)
  expect_equal(prepared$boundary_rate[
    prepared$true == "lin_inc" & prepared$strategy == "r_1"
  ], 0.072)
  expect_equal(prepared$boundary_rate[
    prepared$true == "lin_dec" & prepared$strategy == "r_1"
  ], 0.082)
  expect_true(all(prepared$boundary_label == "0.0%" |
    prepared$boundary_label %in% c("7.2%", "8.2%")))
})

test_that("endpoint contrast data reject incomplete or duplicated fitted rows", {
  fixture <- make_endpoint_contrast_fixture()
  bad <- fixture
  bad$sim[[2L]] <- bad$sim[[1L]]
  expect_error(prepare_manuscript_endpoint_contrast_panel(bad))
  expect_error(prepare_manuscript_endpoint_contrast_panel(fixture[-1L, ]))
})

test_that("signed-model manuscript plots build from accepted summaries", {
  performance <- prepare_manuscript_signed_performance(read.csv(file.path(
    rcdates_test_root, "out/revision/signed-models/selection_performance.csv"
  ), stringsAsFactors = FALSE))
  endpoint_contrast <- prepare_manuscript_endpoint_contrast_panel(
    make_endpoint_contrast_fixture()
  )
  plots <- list(
    manuscript_signed_state_plot(performance),
    manuscript_endpoint_contrast_plot(endpoint_contrast),
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
  expect_equal(unname(endpoint_ratio[c("lin_inc", "exp_inc")]), c(10, 10), tolerance = 1e-10)
  expect_equal(unname(endpoint_ratio[c("lin_dec", "exp_dec")]), c(0.1, 0.1), tolerance = 1e-10)
  plot <- manuscript_signed_truth_plot(curves)
  expect_s3_class(plot, "ggplot")
  expect_silent(ggplot2::ggplot_build(plot))
})
