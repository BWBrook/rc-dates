test_that("manuscript empirical scenario matrix preserves the published design", {
  specs <- manuscript_empirical_scenarios(iterations = 1000L, seed = 1234L)

  expect_equal(nrow(specs), 10L)
  expect_identical(
    unique(specs$strategy_label),
    c("oldest", "youngest", "bracketed", "random-1", "random-5")
  )
  expect_identical(sort(unique(specs$proportion)), c(0.5, 1))
  expect_true(all(
    specs$iterations[
      specs$proportion == 1 &
        specs$strategy %in% c("oldest", "youngest", "bracketed")
    ] == 1L
  ))
  expect_true(all(
    specs$iterations[
      specs$proportion == 0.5 | specs$strategy == "random"
    ] == 1000L
  ))
})

test_that("treated-site and within-site selection matrices are deterministic", {
  data <- data.frame(
    SITE = rep(LETTERS[1:4], each = 5L),
    AGE = unlist(lapply(seq_len(4L), function(site) site * 100 + seq_len(5L))),
    stringsAsFactors = FALSE
  )
  treated <- manuscript_treated_site_matrix(
    sites = unique(data$SITE),
    proportion = 0.5,
    iterations = 3L,
    seed = 1234L
  )
  expect_equal(dim(treated), c(4L, 3L))
  expect_equal(unname(colSums(treated)), rep(2L, 3L))

  random_one <- manuscript_selection_matrix(
    data,
    strategy = "random",
    n_samples = 1L,
    treated_site_matrix = treated,
    seed = 2234L
  )
  repeated <- manuscript_selection_matrix(
    data,
    strategy = "random",
    n_samples = 1L,
    treated_site_matrix = treated,
    seed = 2234L
  )
  bracketed <- manuscript_selection_matrix(
    data,
    strategy = "bracketed",
    n_samples = 2L,
    treated_site_matrix = treated,
    seed = 3234L
  )

  expect_identical(random_one, repeated)
  expect_equal(unname(colSums(random_one)), rep(12L, 3L))
  expect_equal(unname(colSums(bracketed)), rep(14L, 3L))
})

test_that("running-mean matrix exactly matches the rcarbon edge-fill convention", {
  values <- cbind(a = seq_len(12), b = seq_len(12)^2)
  observed <- manuscript_running_mean_matrix(values, width = 4L)
  expected <- apply(values, 2L, function(x) {
    filtered <- stats::filter(x, rep(1 / 4, 4), sides = 2)
    x[!is.na(filtered)] <- filtered[!is.na(filtered)]
    x
  })

  expect_equal(observed, expected)
})

test_that("Gaussian KDE basis excludes out-of-window weighted means", {
  bins <- manuscript_calendar_bins(min_age = 651, max_age = 11650, bin_width = 100)
  basis <- manuscript_gaussian_bin_basis(
    weighted_means = c(650, 651, 700, 11650, 11651),
    bins = bins,
    bandwidth = 100
  )

  expect_equal(dim(basis), c(nrow(bins), 5L))
  expect_equal(colSums(basis)[c(1, 5)], c(0, 0))
  expect_true(all(colSums(basis)[2:4] > 0))
  expect_true(all(colSums(basis)[2:4] <= 1))
})

test_that("precomputed SPD basis reproduces rcarbon aggregation exactly", {
  skip_if_not_installed("rcarbon")

  data <- load_austarch_data(
    file.path("inst", "extdata", "austarch_example.csv")
  ) |>
    filter_austarch_initial() |>
    filter_austarch_material_site()
  fit <- calibrate_and_spd(data, time_range = c(651, 11650))
  calibrated <- fit$calibrated
  retained <- data[
    as.character(data$ADSID) %in% names(calibrated$grids),
    ,
    drop = FALSE
  ]
  bins <- manuscript_calendar_bins()
  basis <- manuscript_spd_bin_basis(
    calibrated,
    date_ids = retained$ADSID,
    bins = bins,
    runm = 100L
  )
  observed <- normalise_manuscript_curve_matrix(
    basis %*% matrix(TRUE, nrow = nrow(retained), ncol = 1L)
  )[, 1L]

  direct <- rcarbon::spd(
    calibrated,
    timeRange = c(11650, 651),
    runm = 100,
    spdnormalised = TRUE,
    verbose = FALSE
  )$grid
  direct$bin <- floor(direct$calBP / 100) * 100
  expected <- rowsum(direct$PrDens, direct$bin, reorder = TRUE)
  expected <- expected[as.character(bins$bin), 1L]
  expected <- expected / sum(expected)

  expect_equal(observed, unname(expected), tolerance = 1e-12)
})

test_that("curve summaries retain deterministic and Monte Carlo contracts", {
  curve_matrix <- matrix(
    c(
      0.1, 0.2, 0.3,
      0.2, 0.3, 0.4
    ),
    nrow = 2L,
    byrow = TRUE
  )
  summary <- summarise_manuscript_curve_matrix(
    curve_matrix,
    bins = c(600, 700),
    method = "SPD"
  )
  deterministic <- summarise_manuscript_curve_matrix(
    curve_matrix[, 1L, drop = FALSE],
    bins = c(600, 700),
    method = "SPD"
  )

  expect_equal(summary$mean, c(0.2, 0.3))
  expect_true(all(summary$lower <= summary$mean))
  expect_true(all(summary$upper >= summary$mean))
  expect_equal(deterministic$lower, deterministic$mean)
  expect_equal(deterministic$upper, deterministic$mean)
})

test_that("Figures 1 and 2 use the same FD smoothing and density units", {
  bins <- manuscript_calendar_bins(min_age = 651, max_age = 950, bin_width = 100)
  bases <- list(
    SPD = diag(4),
    FD = diag(4),
    KDE = diag(4),
    bins = bins
  )
  selected <- matrix(c(TRUE, TRUE, FALSE, FALSE), ncol = 1L)
  curves <- manuscript_curve_matrices(bases, selected, fd_smooth_width = 2L)
  expected_fd <- normalise_manuscript_curve_matrix(
    manuscript_running_mean_matrix(
      normalise_manuscript_curve_matrix(bases$FD %*% (selected * 1)),
      width = 2L
    )
  )

  expect_equal(curves$FD, expected_fd)

  summary <- do.call(rbind, lapply(names(curves), function(method) {
    summarise_manuscript_curve_matrix(curves[[method]], bins$bin, method)
  }))
  summary$strategy_label <- "random-1"
  summary$proportion <- 1
  plot <- manuscript_sampling_panel_plot(summary)
  expect_equal(plot$data$display_mean, plot$data$mean / 100)
  expect_false(plot$facet$params$free$y)
  expect_equal(as.numeric(plot$theme$panel.spacing.x), 3)
})

test_that("effective-date summaries expose method-specific membership", {
  selected <- matrix(
    c(
      TRUE, TRUE,
      TRUE, FALSE,
      TRUE, TRUE
    ),
    nrow = 3L,
    byrow = TRUE
  )
  bases <- list(
    SPD = matrix(1, nrow = 2L, ncol = 3L),
    FD = matrix(c(1, 0, 1, 0, 0, 0), nrow = 2L),
    KDE = matrix(c(1, 0, 0, 0, 0, 0), nrow = 2L)
  )
  counts <- summarise_manuscript_effective_counts(
    selected,
    bases,
    strategy_label = "fixture",
    proportion = 0.5
  )

  expect_equal(counts$selected_dates_mean, c(2.5, 2.5, 2.5))
  expect_equal(counts$effective_dates_mean, c(2.5, 1.5, 1))
  expect_equal(counts$effective_dates_min, c(2, 1, 1))
})
