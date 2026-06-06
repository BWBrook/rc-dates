## Dependency helpers (no installs here)
##
## Centralise the list of core packages used by this compendium. Use
## these helpers to attach packages interactively if needed. Installation
## is handled via `scripts/bootstrap.R` and `renv`.

#' Vector of core runtime packages
#' @keywords internal
core_packages <- function() {
  c(
    "targets","tarchetypes","here","arrow","vroom","dplyr",
    "readr","purrr","tidyr","sf","terra","yaml","config",
    "lgr","progressr"
  )
}

#' Check core packages quietly for interactive work
#' @keywords internal
attach_core <- function() {
  pkgs <- core_packages()
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0L) {
    rlang::abort(
      paste0("Missing core packages: ", paste(missing, collapse = ", ")),
      class = "rcdates_dependency_error"
    )
  }
  invisible(TRUE)
}
