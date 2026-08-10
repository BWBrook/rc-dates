options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!nzchar(Sys.getenv("RENV_CONFIG_USE_CACHE"))) {
  Sys.setenv(RENV_CONFIG_USE_CACHE = "TRUE")
}
if (!nzchar(Sys.getenv("RENV_CONFIG_PAK_ENABLED"))) {
  Sys.setenv(RENV_CONFIG_PAK_ENABLED = "FALSE")
}

# Activate renv only under the exact analysis runtime.
rc_dates_expected_r <- identical(as.character(getRversion()), "4.5.3")
if (file.exists("renv/activate.R") && rc_dates_expected_r) {
  source("renv/activate.R")
} else if (file.exists("renv/activate.R")) {
  message(
    "Skipping renv activation for R ", as.character(getRversion()),
    "; rc-dates requires R 4.5.3. Use make r-preflight."
  )
}
