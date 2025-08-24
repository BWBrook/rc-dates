test_that("pipeline defines expected targets", {
  mf <- targets::tar_manifest(callr_function = NULL)
  expect_true(all(c(
    "cfg","raw_manifest","raw_files","raw_tbl","validated",
    "interim_parquet","model_fit","report"
  ) %in% mf$name))
})
