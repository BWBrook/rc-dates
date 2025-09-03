test_that("plot_methods_overlay returns a ggplot object", {
  df <- load_austarch_data("inst/extdata/austarch_example.csv") |>
    filter_austarch_initial() |>
    filter_austarch_material_site()
  fit <- calibrate_and_spd(df, time_range = c(100L, 20000L))
  wm <- filter_sites_min_calibrated_dates(df, fit$calibrated, min_dates = 1)
  spd_tbl <- spd_to_tibble(fit$spd)
  fd_tbl <- fd_from_weighted_means(wm)
  kde_tbl <- kde_from_weighted_means(wm)
  p <- plot_methods_overlay(spd_tbl, fd_tbl, kde_tbl)
  expect_s3_class(p, "ggplot")
})

