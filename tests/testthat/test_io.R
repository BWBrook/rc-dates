test_that("lread reads a CSV into a tibble", {
  path <- "data/raw/example.csv"
  expect_true(file.exists(path))
  tbl <- lread(path)
  expect_s3_class(tbl, "tbl_df")
  expect_true(all(c("id","date","value") %in% names(tbl)))
  expect_gt(nrow(tbl), 0)
})
