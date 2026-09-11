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
    ADSID = seq_len(20L),
    calibrated_median_calBP = unlist(lapply(
      seq_len(4L),
      function(site) site * 100 + seq_len(5L)
    )),
    weighted_mean_calBP = unlist(lapply(
      seq_len(4L),
      function(site) site * 100 + seq_len(5L) + 0.25
    )),
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

test_that("primary membership excludes reservoir-sensitive records and sparse sites", {
  data <- data.frame(
    ADSID = seq_len(14L),
    SITE = rep(c("A", "B"), each = 7L),
    MATERIAL = c(rep("Charcoal", 6L), "Marine_shell", rep("Charcoal", 7L)),
    TIME_SERIES_RELEVANT = c(rep("Terrestrial", 6L), "Marine", rep("Terrestrial", 7L)),
    OCCUPATION_RELATED = c(rep("Y", 7L), rep("U", 7L)),
    AGE = rep(1000, 14L),
    ERROR = rep(30, 14L),
    stringsAsFactors = FALSE
  )
  primary <- filter_manuscript_primary_reference(data)
  expect_equal(nrow(primary), 13L)
  expect_false(any(primary$MATERIAL == "Marine_shell"))

  primary$calibrated_median_calBP <- c(rep(1000, 5L), 700, rep(2000, 7L))
  primary$weighted_mean_calBP <- primary$calibrated_median_calBP
  primary$posterior_mass_in_window <- c(rep(1, 5L), 0.7, rep(1, 7L))
  common <- filter_manuscript_common_membership(
    primary,
    buffer = 100,
    mass_threshold = 0.8,
    min_dates = 5L
  )
  expect_identical(names(table(common$SITE)), c("A", "B"))
  expect_equal(as.integer(table(common$SITE)), c(5L, 7L))
})

test_that("calibrated extrema use posterior mean and stable ID tie breaks", {
  data <- data.frame(
    SITE = rep("A", 5L),
    ADSID = c(20L, 10L, 30L, 40L, 50L),
    calibrated_median_calBP = c(1000, 1000, 500, 500, 750),
    weighted_mean_calBP = c(990, 1010, 510, 510, 750),
    stringsAsFactors = FALSE
  )
  treated <- matrix(TRUE, nrow = 1L, ncol = 1L, dimnames = list("A", "iteration_1"))
  oldest <- manuscript_selection_matrix(data, "oldest", 1L, treated, 1L)
  youngest <- manuscript_selection_matrix(data, "youngest", 1L, treated, 1L)

  expect_identical(which(oldest[, 1L]), 2L)
  expect_identical(which(youngest[, 1L]), 3L)
  ties <- summarise_manuscript_extreme_ties(data)
  expect_equal(ties$posterior_median_tie_sites, c(1L, 1L))
  expect_equal(ties$posterior_mean_tie_sites, c(0L, 1L))
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

test_that("reflected Gaussian KDE preserves per-date mass at both boundaries", {
  bins <- manuscript_calendar_bins(min_age = 651, max_age = 11650, bin_width = 100)
  reflected <- manuscript_gaussian_bin_basis(
    point_ages = c(651, 700, 11650),
    bins = bins,
    bandwidth = 100,
    boundary = "reflect"
  )
  unreflected <- manuscript_gaussian_bin_basis(
    point_ages = c(651, 700, 11650),
    bins = bins,
    bandwidth = 100,
    boundary = "none"
  )

  expect_equal(dim(reflected), c(nrow(bins), 3L))
  expect_equal(colSums(reflected), rep(1, 3L), tolerance = 1e-12)
  expect_true(colSums(unreflected)[[1L]] < 0.51)
  expect_true(colSums(unreflected)[[3L]] < 0.51)
  expect_error(
    manuscript_gaussian_bin_basis(c(650, 700), bins),
    class = "rcdates_manuscript_figure_error"
  )
})

test_that("precomputed SPD basis reproduces rcarbon aggregation exactly", {
  skip_if_not_installed("rcarbon")

  data <- data.frame(
    ADSID = seq_len(4L),
    AGE = c(2000, 4000, 7000, 10000),
    ERROR = c(30, 40, 50, 60),
    TIME_SERIES_RELEVANT = rep("Terrestrial", 4L),
    stringsAsFactors = FALSE
  )
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

test_that("effective-date summaries enforce common membership", {
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
    FD = matrix(1, nrow = 2L, ncol = 3L),
    KDE = matrix(1, nrow = 2L, ncol = 3L)
  )
  counts <- summarise_manuscript_effective_counts(
    selected,
    bases,
    strategy_label = "fixture",
    proportion = 0.5
  )

  expect_equal(counts$selected_dates_mean, c(2.5, 2.5, 2.5))
  expect_equal(counts$effective_dates_mean, rep(2.5, 3L))
  expect_equal(counts$effective_dates_min, rep(2, 3L))

  bases$KDE[, 2L] <- 0
  expect_error(
    summarise_manuscript_effective_counts(
      selected,
      bases,
      strategy_label = "fixture",
      proportion = 0.5
    ),
    class = "rcdates_manuscript_figure_error"
  )
})

test_that("distance gate is conservative and directionally explicit", {
  baseline <- list(
    SPD = matrix(c(0.5, 0.5), ncol = 1L),
    FD = matrix(c(0.5, 0.5), ncol = 1L),
    KDE = matrix(c(0.5, 0.5), ncol = 1L)
  )
  curves <- list(
    SPD = matrix(c(0.2, 0.8), ncol = 1L),
    FD = matrix(c(0.21, 0.79), ncol = 1L),
    KDE = matrix(c(0.19, 0.81), ncol = 1L)
  )
  result <- summarise_manuscript_scenario_distances(
    curves,
    baseline,
    midpoints = c(100, 200),
    strategy_label = "oldest",
    proportion = 1
  )

  expect_true(result$gate$retention_larger_than_method)
  expect_identical(result$gate$temporal_direction, "older")
  expect_equal(
    result$summary$mean[
      result$summary$comparison == "minimum_retention_minus_maximum_method"
    ],
    0.27,
    tolerance = 1e-12
  )
})
