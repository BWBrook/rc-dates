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

