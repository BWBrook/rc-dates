options(Ncpus = 4L)
source("renv/activate.R")
renv::restore(packages = c(
  "digest", "fitdistrplus", "rcarbon", "readr", "rlang", "tibble", "dplyr",
  "stringr", "import", "ggplot2", "scales", "withr", "jsonlite", "testthat"
), prompt = FALSE)
