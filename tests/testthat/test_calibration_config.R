test_that("choose_calibration_curves maps env to curves as expected", {
  env <- c("Marine", "marine environment", "Terrestrial", NA_character_)
  curves <- choose_calibration_curves(env, terrestrial_curve = "shcal20", marine_curve = "marine20")
  expect_identical(curves, c("marine20", "marine20", "shcal20", "shcal20"))
})

test_that("calibrate_and_spd respects configured time_range bounds", {
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
  spd_tbl <- spd_to_tibble(fit$spd)
  tr_min <- min(cfg$calibration$time_range)
  tr_max <- max(cfg$calibration$time_range)
  expect_gte(min(spd_tbl$calBP, na.rm = TRUE), tr_min)
  expect_lte(max(spd_tbl$calBP, na.rm = TRUE), tr_max)
})

