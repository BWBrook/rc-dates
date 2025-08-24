test_that("sanity: required packages are available", {
  expect_true(requireNamespace("targets", quietly = TRUE))
  expect_true(requireNamespace("tarchetypes", quietly = TRUE))
})