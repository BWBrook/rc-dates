#!/usr/bin/env Rscript
source("scripts/release/common.R")
paths <- list.files("out/empirical-sampling", pattern = "[.]csv$", full.names = TRUE)
for (path in paths) {
  expected <- readr::read_csv(path, show_col_types = FALSE)
  actual <- readr::read_csv(file.path("out/reproduced/empirical-sampling", basename(path)),
                            show_col_types = FALSE)
  release_compare_rows(actual, expected, names(expected), basename(path))
}
message("All accepted empirical CSV tables reproduced exactly.")
