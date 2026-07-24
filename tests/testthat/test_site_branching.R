test_that("per-SITE summaries are constructible on toy data", {
  df <- load_austarch_data("inst/extdata/austarch_example.csv") |>
    filter_austarch_initial() |>
    filter_austarch_material_site()
  s <- df$SITE[1]
  sub <- df[df$SITE == s, , drop = FALSE]
  expect_gte(nrow(sub), 1)
  fit <- calibrate_and_spd(sub)
  spd_tbl <- spd_to_tibble(fit$spd)
  expect_true(all(c("calBP", "PrDens") %in% names(spd_tbl)))
})

test_that("subset_caldates_by_adsid drops ids without calibrated grids", {
  df <- load_austarch_data("inst/extdata/austarch_example.csv") |>
    filter_austarch_initial() |>
    filter_austarch_material_site()
  fit <- calibrate_and_spd(df)
  ads <- df$ADSID[df$SITE_TYPE == "Rockshelter"]

  cds <- subset_caldates_by_adsid(fit$calibrated, ads)

  expect_false(anyNA(names(cds$grids)))
  expect_true(all(vapply(cds$grids, inherits, logical(1), what = "data.frame")))
  expect_true(all(c("calBP", "PrDens") %in% names(spd_to_tibble(spd_from_caldates(cds)))))
})

test_that("site SPD is empty when no posterior support remains in range", {
  site <- data.frame(
    ADSID = 1L,
    AGE = 750,
    ERROR = 80,
    TIME_SERIES_RELEVANT = "Marine"
  )

  fit <- calibrate_and_spd(site, time_range = c(651L, 11650L))
  summary <- spd_to_tibble(fit$spd)

  expect_identical(names(summary), c("calBP", "PrDens"))
  expect_equal(nrow(summary), 0L)
})
