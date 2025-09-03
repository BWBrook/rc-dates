test_that("validate_austarch_schema passes on valid filtered data", {
  df <- load_austarch_data("inst/extdata/austarch_example.csv")
  v <- df |>
    filter_austarch_initial() |>
    filter_austarch_material_site()
  expect_s3_class(v, "tbl_df")
  expect_invisible(validate_austarch_schema(v))
})

test_that("validate_austarch_schema catches missing columns", {
  df <- load_austarch_data("inst/extdata/austarch_example.csv") |>
    dplyr::select(-AGE)
  expect_error(validate_austarch_schema(df), class = "rcdates_schema_error")
})

test_that("validate_austarch_schema catches wrong types and invalid values", {
  df <- load_austarch_data("inst/extdata/austarch_example.csv") |>
    filter_austarch_initial() |>
    filter_austarch_material_site()

  bad1 <- df
  bad1$ADSID <- as.character(bad1$ADSID)
  expect_error(validate_austarch_schema(bad1), class = "rcdates_schema_error")

  bad2 <- df
  bad2$ERROR[1] <- -1
  expect_error(validate_austarch_schema(bad2), class = "rcdates_schema_error")

  bad3 <- df
  bad3$ADSID[1] <- bad3$ADSID[2]
  expect_error(validate_austarch_schema(bad3), class = "rcdates_schema_error")
})

