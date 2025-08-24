## Dependency helpers (no installs here)
##
## Centralise the list of core packages used by this compendium. Use
## these helpers to attach packages interactively if needed. Installation
## is handled via `scripts/bootstrap.R` and `renv`.

#' Vector of core runtime packages
#' @keywords internal
core_packages <- function() {
  c(
    "targets","tarchetypes","arrow","duckdb","vroom","dplyr",
    "readr","purrr","tidyr","sf","terra","yaml","config","qs",
    "lgr","progressr"
  )
}

#' Attach core packages quietly for interactive work
#' @keywords internal
attach_core <- function() {
  op <- options(stringsAsFactors = FALSE)
  on.exit(options(op), add = TRUE)
  suppressPackageStartupMessages({
    for (pkg in core_packages()) require(pkg, character.only = TRUE)
  })
  invisible(TRUE)
}
