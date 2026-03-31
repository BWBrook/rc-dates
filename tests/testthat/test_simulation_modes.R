test_that("cfg_read defaults to demo simulation mode", {
  cfg <- cfg_read(active = "testthat")
  expect_identical(cfg$simulate$mode, "demo")
  expect_equal(cfg$simulate$demo$iterations, 10L)
  expect_equal(cfg$simulate$demo$multiton_n, 3L)
})

test_that("build_demo_sim_specs yields the full legacy-style demo matrix", {
  cfg <- cfg_read(active = "testthat")
  specs <- build_demo_sim_specs(cfg)

  expect_equal(nrow(specs), 10)
  expect_equal(sort(unique(specs$scenario)), c("bracketed", "multiton", "oldest", "singleton", "youngest"))
  expect_equal(sort(unique(specs$size)), c(50L, 100L))
  expect_true(all(!grepl("/", specs$filename, fixed = TRUE)))
  expect_true(all(grepl("^simulation_summary_.*\\.csv$", specs$filename)))
})

test_that("demo simulation generation is deterministic and non-empty", {
  cfg <- cfg_read(active = "testthat")
  cfg$outputs$dir <- file.path(tempdir(), "rc-dates-demo-test")
  cfg$simulate$demo$iterations <- 1L

  df <- load_austarch_data(cfg$data$example) |>
    filter_austarch_initial() |>
    filter_austarch_material_site()
  specs <- build_demo_sim_specs(cfg)

  paths <- write_demo_simulation_summaries(df, cfg, specs)
  manifest <- build_sim_manifest_from_paths(paths, origin = "demo")

  expect_equal(length(paths), 10)
  expect_equal(nrow(manifest), 10)
  expect_true(all(file.exists(paths)))

  spec <- specs[specs$scenario == "singleton" & specs$size == 50L, , drop = FALSE]
  out1 <- run_demo_sampling_workflow(df, cfg, spec)
  out2 <- run_demo_sampling_workflow(df, cfg, spec)
  expect_equal(out1, out2)
})

test_that("precomputed and none modes resolve cleanly", {
  cfg_pre <- cfg_read(active = "testthat")
  cfg_pre$simulate$mode <- "precomputed"
  cfg_pre$simulate$precomputed$dir <- here::here("inst", "extdata")
  mf_pre <- read_sim_manifest(
    cfg_pre$simulate$precomputed$dir,
    cfg_pre$simulate$precomputed$pattern,
    origin = "precomputed"
  )
  expect_identical(cfg_pre$simulate$mode, "precomputed")
  expect_gte(nrow(mf_pre), 1)
  expect_true(all(mf_pre$origin == "precomputed"))

  cfg_none <- cfg_read(active = "testthat")
  cfg_none$simulate$mode <- "none"
  expect_identical(cfg_none$simulate$mode, "none")
  expect_equal(nrow(empty_sim_manifest()), 0)
})
