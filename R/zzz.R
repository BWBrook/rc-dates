## Package load hooks and global project options

#' Package load-time configuration
#'
#' Sets a reproducible RNG, configures CRAN mirror, initialises logging and
#' progress handlers, and loads environment variables from `.env` if present.
#' These side effects occur when the package is loaded (either via
#' `library(RRepoGoldStd)` or `pkgload::load_all(".")`).
.onLoad <- function(libname, pkgname) {
  # RNG and seed for reproducibility (parallel-safe RNG)
  suppressWarnings({
    RNGkind("L'Ecuyer-CMRG")
  })
  if (!isTRUE(exists(".RRepoGoldStd.seed_set", envir = .GlobalEnv))) {
    set.seed(20250811L)
    assign(".RRepoGoldStd.seed_set", TRUE, envir = .GlobalEnv)
  }

  # Global options
  options(
    repos = c(CRAN = "https://packagemanager.posit.co/cran/latest"),
    readr.show_col_types = FALSE,
    scipen = 999
  )

  # Load environment variables if a .env file exists
  if (file.exists(".env")) {
    try({dotenv::load_dot_env(file = ".env", override = FALSE)}, silent = TRUE)
  }

  # Logging and progress handlers
  try({
    logger <- lgr::get_logger("diamond")
    logger$set_threshold("info")
    progressr::handlers(global = TRUE)
  }, silent = TRUE)
}
