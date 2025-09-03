test_that("pipeline defines expected targets (placeholder)", {
  script_path <- resolve_path("_targets.R")
  testthat::skip_if_not(file.exists(script_path), "Pipeline not yet implemented")
  mf <- targets::tar_manifest(script = script_path, callr_function = NULL)
  expect_true(all(c(
    "cfg","raw_manifest","raw_files","raw_tbl","validated",
    "interim_parquet","model_fit","report"
  ) %in% mf$name))
})
