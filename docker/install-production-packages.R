options(Ncpus = 16L)
source("renv/activate.R")

renv::restore(
  packages = c(
    "digest",
    "fitdistrplus",
    "rcarbon",
    "readr",
    "rlang",
    "tibble"
  ),
  prompt = FALSE
)
