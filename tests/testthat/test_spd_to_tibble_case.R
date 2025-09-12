test_that("spd_to_tibble maps time/density columns case-insensitively", {
  # Variant 1: CalBP/PrDens mixed case
  spd1 <- list(grid = data.frame(CalBP = 1:3, PrDens = c(0.2, 0.3, 0.5)))
  tbl1 <- spd_to_tibble(spd1)
  expect_true(all(c("calBP", "PrDens") %in% names(tbl1)))
  expect_equal(nrow(tbl1), 3)

  # Variant 2: calYearBP/density
  spd2 <- list(grid = data.frame(calYearBP = 4:6, density = c(0.1, 0.1, 0.8)))
  tbl2 <- spd_to_tibble(spd2)
  expect_true(all(c("calBP", "PrDens") %in% names(tbl2)))
  expect_equal(nrow(tbl2), 3)

  # Variant 3: generic year/value
  spd3 <- list(grid = data.frame(year = 7:9, value = c(0.3, 0.3, 0.4)))
  tbl3 <- spd_to_tibble(spd3)
  expect_true(all(c("calBP", "PrDens") %in% names(tbl3)))
  expect_equal(nrow(tbl3), 3)
})

