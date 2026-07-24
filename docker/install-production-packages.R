options(Ncpus = 16L)
source("renv/activate.R")

renv::restore(
  packages = c(
    "cli",
    "dplyr",
    "digest",
    "fitdistrplus",
    "ggplot2",
    "import",
    "magrittr",
    "pbmcapply",
    "purrr",
    "RColorBrewer",
    "rcarbon",
    "readr",
    "rlang",
    "scales",
    "testthat",
    "tibble",
    "tidyr",
    "withr",
    "yardstick"
  ),
  prompt = FALSE
)
