test_that("marine contexts use the marine calibration curve", {
  environment <- c("Marine", "marine environment", "Terrestrial", NA_character_)
  curves <- choose_calibration_curves(
    environment,
    terrestrial_curve = "shcal20",
    marine_curve = "marine20"
  )

  expect_identical(curves, c("marine20", "marine20", "shcal20", "shcal20"))
})
