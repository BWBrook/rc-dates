## Global options and reproducibility settings
##
## These are applied automatically in `.onLoad()` (see R/zzz.R). The function
## below is provided for interactive re-application if needed.

#' (Re)apply project-wide options and RNG
#' @keywords internal
set_project_options <- function() {
  suppressWarnings({
    RNGkind("L'Ecuyer-CMRG")
  })
  set.seed(20250811L)
  options(
    repos = c(CRAN = "https://packagemanager.posit.co/cran/latest"),
    readr.show_col_types = FALSE,
    scipen = 999
  )
  logger <- lgr::get_logger("diamond")
  logger$set_threshold("info")
  progressr::handlers(global = TRUE)
  invisible(TRUE)
}
