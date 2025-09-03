## IO helpers

#' Fast delimited file reader (project-root aware)
#'
#' Thin wrapper around `vroom::vroom()` that resolves `path` relative to the
#' project root via `here::here()`, disables column type messages, and returns
#' a tibble.
#'
#' @param path Character path to a delimited text file.
#' @param ... Additional arguments passed to `vroom::vroom()`.
#' @return A tibble.
#' @examples
#' # df <- lread("inst/extdata/austarch_example.csv")
#' @export
lread <- function(path, ...) {
  import::from("vroom", "vroom")
  import::from("rlang", "abort")
  import::from("checkmate", "assert_file_exists")

  path_abs <- resolve_path(path)
  assert_file_exists(path_abs)
  tryCatch(
    vroom(path_abs, show_col_types = FALSE, ...),
    error = function(e) abort(paste0("Failed to read file: ", path_abs), class = "rcdates_io_error")
  )
}

#' Read a simple CSV manifest of input files
#'
#' Expects a CSV with columns `id` and `path`. Returns a tibble with columns
#' `id` and `path` (absolute, resolved via `here()`).
#' @param manifest_path Path to the manifest CSV.
#' @return A tibble with `id` and absolute `path`.
#' @export
read_manifest <- function(manifest_path) {
  import::from("vroom", "vroom")
  import::from("rlang", "abort")
  import::from("checkmate", "assert_file_exists")
  import::from("dplyr", "%>%", "mutate")

  mp <- resolve_path(manifest_path)
  assert_file_exists(mp)
  mf <- tryCatch(
    vroom(mp, show_col_types = FALSE),
    error = function(e) abort(paste0("Failed to read manifest: ", mp), class = "rcdates_io_error")
  )
  required <- c("id", "path")
  missing <- setdiff(required, names(mf))
  if (length(missing) > 0) {
    abort(paste0("Manifest missing required columns: ", paste(missing, collapse = ", ")), class = "rcdates_io_error")
  }
  mf %>% mutate(path = vapply(path, resolve_path, character(1)))
}

#' Ensure a data frame contains required columns
#' @param x A data.frame or tibble.
#' @param cols Character vector of required columns.
#' @param class Error class to use on failure (default: "rcdates_validation_error").
#' @return Invisibly `TRUE` if validation passes; otherwise aborts.
#' @export
require_columns <- function(x, cols, class = "rcdates_validation_error") {
  import::from("rlang", "abort")
  nms <- names(x)
  missing <- setdiff(cols, nms)
  if (length(missing) > 0) {
    abort(
      paste0("Input missing required columns: ", paste(missing, collapse = ", ")),
      class = class
    )
  }
  invisible(TRUE)
}
