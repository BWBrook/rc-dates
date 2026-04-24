test_that("lread reads the austarch example CSV", {
  path <- resolve_path("inst/extdata/austarch_example.csv")
  expect_true(file.exists(path))
  tbl <- lread(path)
  expect_s3_class(tbl, "tbl_df")
  expect_true(all(c("ADSID", "AGE", "ERROR") %in% names(tbl)))
  expect_gt(nrow(tbl), 0)
})

test_that("cfg_read returns resolved paths and defaults", {
  cfg <- cfg_read(active = "testthat")
  expect_type(cfg, "list")
  expect_true(file.exists(cfg$data$example))
  expect_true(file.exists(cfg$data$manifest))
})

test_that("read_manifest resolves relative paths and validates columns", {
  mf <- read_manifest("metadata/data_manifest.csv")
  expect_true(all(c("id", "path") %in% names(mf)))
  expect_true(file.exists(mf$path[[1]]))
})

test_that("interim storage falls back to CSV on macOS", {
  expect_false(should_use_arrow_interim(TRUE, system_name = "Darwin"))
})

test_that("write_interim_validated returns a tracked file path", {
  out_dir <- tempfile("rcdates-interim-")
  tbl <- tibble::tibble(ADSID = 1L, AGE = 1000L)

  out_file <- write_interim_validated(tbl, out_dir, use_arrow = FALSE)

  expect_match(out_file, "validated_strict[.]csv$")
  expect_true(file.exists(out_file))
})
