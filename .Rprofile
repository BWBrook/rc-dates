options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!nzchar(Sys.getenv("RENV_CONFIG_USE_CACHE"))) {
  Sys.setenv(RENV_CONFIG_USE_CACHE = "TRUE")
}
if (!nzchar(Sys.getenv("RENV_CONFIG_PAK_ENABLED"))) {
  Sys.setenv(RENV_CONFIG_PAK_ENABLED = "FALSE")
}

# Activate renv only under the lockfile-compatible R series. This avoids
# accidental bootstrapping under newer R minors while still keeping RStudio
# sessions convenient on the intended runtime.
rc_dates_expected_r <- startsWith(as.character(getRversion()), "4.5.")
rc_dates_allow_other_r <- identical(Sys.getenv("RC_DATES_ALLOW_NON45_RENV"), "true")
if (file.exists("renv/activate.R") && (rc_dates_expected_r || rc_dates_allow_other_r)) {
  source("renv/activate.R")
} else if (file.exists("renv/activate.R")) {
  message(
    "Skipping renv activation for R ", as.character(getRversion()),
    "; rc-dates expects R 4.5.x. Use make r-preflight or set ",
    "RC_DATES_ALLOW_NON45_RENV=true to override."
  )
}
