#' Fast delimited file reader
#'
#' A thin wrapper around `vroom::vroom()` that disables column type messages
#' and returns a tibble. Use this for reading medium-to-large CSV/TSV files.
#'
#' @param path Character path to a delimited text file.
#' @param ... Additional arguments passed to `vroom::vroom()`.
#' @return A tibble.
#' @examples
#' # df <- lread("data/raw/example.csv")
#' @export
lread <- function(path, ...) {
  vroom::vroom(path, show_col_types = FALSE, ...)
}
