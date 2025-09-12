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

