test_that("example dataset retains expected legacy-style counts", {
  cfg <- cfg_read(active = "testthat")
  df <- load_austarch_data(cfg$data$example) |>
    filter_austarch_initial() |>
    filter_austarch_material_site()

  expect_equal(nrow(df), 20)
  expect_equal(dplyr::n_distinct(df$SITE), 6)
  expect_equal(dplyr::n_distinct(df$ADSID), 20)
  expect_equal(
    sort(unique(df$SITE_TYPE)),
    c("Hearth", "Midden", "Open_site", "Rockshelter", "Shell_midden", "Shell_mound")
  )

  by_type <- dplyr::count(df, SITE_TYPE)
  expect_equal(by_type$n[match("Rockshelter", by_type$SITE_TYPE)], 7)
  expect_equal(by_type$n[match("Midden", by_type$SITE_TYPE)], 4)
})

test_that("example dataset produces non-empty calibrated summaries", {
  cfg <- cfg_read(active = "testthat")
  df <- load_austarch_data(cfg$data$example) |>
    filter_austarch_initial() |>
    filter_austarch_material_site()

  fit <- calibrate_and_spd(
    df,
    time_range = cfg$calibration$time_range,
    terrestrial_curve = cfg$calibration$terrestrial_curve,
    marine_curve = cfg$calibration$marine_curve
  )
  wm <- filter_sites_min_calibrated_dates(df, fit$calibrated, min_dates = 1)

  expect_gt(nrow(spd_to_tibble(fit$spd)), 0)
  expect_gt(nrow(fd_from_weighted_means(wm)), 0)
  expect_gt(nrow(kde_from_weighted_means(wm)), 0)
  expect_equal(dplyr::n_distinct(wm$SITE), 6)
})
