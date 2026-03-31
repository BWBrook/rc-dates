test_that("pipeline defines expected targets (placeholder)", {
  script_path <- resolve_path("_targets.R")
  testthat::skip_if_not(file.exists(script_path), "Pipeline not yet implemented")
  mf <- targets::tar_manifest(script = script_path, callr_function = NULL)
  expect_true(all(c(
    "cfg","raw_manifest","raw_files","raw_tbl","validated",
    "report_qmd","report_quarto_yml",
    "sim_mode","demo_sim_specs","demo_sim_summary_files","sim_precomputed_manifest","sim_manifest",
    "interim_parquet","model_fit","report"
  ) %in% mf$name))
})

test_that("report reads targets directly without tar_config_set side effects", {
  qmd <- readLines(resolve_path("reports/paper.qmd"), warn = FALSE)
  expect_false(any(grepl("tar_config_set\\(", qmd, fixed = FALSE)))
})
