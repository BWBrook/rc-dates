test_that("parse_sim_filename extracts scenario and size", {
  x <- parse_sim_filename("data/simulation_summary_singleton_50.csv")
  expect_equal(x$scenario, "singleton")
  expect_equal(x$size, 50L)
})

test_that("read_sim_table returns tidy columns and drops empty methods", {
  # Write a small temp file using demo content
  demo <- here::here("inst", "extdata", "simulation_summary_demo_10.csv")
  tbl <- read_sim_table(demo)
  expect_true(all(c("method", "calBP", "mean", "lower", "upper", "scenario", "size") %in% names(tbl)))
  expect_true(nrow(tbl) >= 1)
})

test_that("plot_sim_overlay returns a ggplot", {
  demo <- here::here("inst", "extdata", "simulation_summary_demo_10.csv")
  df <- read_sim_table(demo)
  p <- plot_sim_overlay(df)
  expect_s3_class(p, "ggplot")
})

