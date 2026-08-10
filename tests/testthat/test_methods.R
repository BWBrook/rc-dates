test_that("spd_to_tibble returns expected columns and non-negative values", {
  df <- load_austarch_data("inst/extdata/austarch_example.csv") |>
    filter_austarch_initial() |>
    filter_austarch_material_site()
  fit <- calibrate_and_spd(df, time_range = c(100L, 20000L))
  spd_tbl <- spd_to_tibble(fit$spd)
  expect_true(all(c("calBP", "PrDens") %in% names(spd_tbl)))
  expect_true(all(spd_tbl$PrDens >= 0))
  expect_gt(nrow(spd_tbl), 0)
})

test_that("fd_from_weighted_means produces a density by bins", {
  df <- load_austarch_data("inst/extdata/austarch_example.csv") |>
    filter_austarch_initial() |>
    filter_austarch_material_site()
  fit <- calibrate_and_spd(df, time_range = c(100L, 20000L))
  wm <- filter_sites_min_calibrated_dates(df, fit$calibrated, min_dates = 1)
  fd <- fd_from_weighted_means(wm, bin_width = 200, min_age = 651, max_age = 11650)
  expect_true(all(c("bin", "value") %in% names(fd)))
  expect_gt(nrow(fd), 0)
  expect_true(all(fd$value >= 0))
})

test_that("fd_from_weighted_means filters raw ages before legacy-anchored binning", {
  ages <- tibble::tibble(
    weighted_mean_calBP = c(
      650, 650.9, 651, 699, 700,
      11649.9, 11650, 11650.1
    )
  )

  fd <- fd_from_weighted_means(
    ages,
    bin_width = 100,
    min_age = 651,
    max_age = 11650
  )

  expect_equal(fd$bin, c(600, 700, 11600))
  expect_equal(fd$value, c(2, 1, 2) / 5 / 100)
  expect_equal(sum(fd$value * 100), 1)
})

test_that("kde_from_weighted_means returns a smooth density", {
  df <- load_austarch_data("inst/extdata/austarch_example.csv") |>
    filter_austarch_initial() |>
    filter_austarch_material_site()
  fit <- calibrate_and_spd(df, time_range = c(100L, 20000L))
  wm <- filter_sites_min_calibrated_dates(df, fit$calibrated, min_dates = 1)
  kd <- kde_from_weighted_means(wm, from = 651, to = 11650, bw = 100, n = 256)
  expect_true(all(c("calBP", "density") %in% names(kd)))
  expect_gt(nrow(kd), 10)
  expect_true(all(kd$density >= 0))
})

test_that("kde_from_weighted_means uses only finite ages inside the requested window", {
  ages <- tibble::tibble(
    weighted_mean_calBP = c(
      650, 650.9, 651, 699, 700,
      11649.9, 11650, 11650.1, NA_real_, Inf
    )
  )
  valid_ages <- c(651, 699, 700, 11649.9, 11650)
  expected <- stats::density(
    valid_ages,
    from = 651,
    to = 11650,
    bw = 100,
    n = 64
  )

  observed <- kde_from_weighted_means(
    ages,
    from = 651,
    to = 11650,
    bw = 100,
    n = 64
  )

  expect_equal(observed$calBP, expected$x)
  expect_equal(observed$density, expected$y)
})

test_that("kde_from_weighted_means returns empty when fewer than two in-window ages remain", {
  ages <- tibble::tibble(weighted_mean_calBP = c(650, 651, 11650.1, NA_real_))

  observed <- kde_from_weighted_means(ages, from = 651, to = 11650)

  expect_equal(nrow(observed), 0)
  expect_equal(names(observed), c("calBP", "density"))
})
