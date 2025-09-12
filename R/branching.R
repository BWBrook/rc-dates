## Branching helpers for selecting levels and figures via config

#' Filter character levels by include/exclude patterns and optional limit
#' @param levels Character vector of levels to filter.
#' @param include Optional character vector of regex patterns to include.
#' @param exclude Optional character vector of regex patterns to exclude.
#' @param limit Optional integer; if provided, truncate to first N after sorting.
#' @param ignore_case Logical; treat patterns case-insensitively.
#' @return Filtered character vector.
#' @export
filter_levels_by_cfg <- function(levels, include = NULL, exclude = NULL, limit = NULL, ignore_case = TRUE) {
  x <- unique(levels)
  x <- x[!is.na(x) & nzchar(x)]
  x <- sort(x)
  if (!is.null(include) && length(include) > 0) {
    keep <- Reduce(`|`, lapply(include, function(p) grepl(p, x, ignore.case = ignore_case)))
    x <- x[keep]
  }
  if (!is.null(exclude) && length(exclude) > 0) {
    drop <- Reduce(`|`, lapply(exclude, function(p) grepl(p, x, ignore.case = ignore_case)))
    x <- x[!drop]
  }
  if (!is.null(limit) && is.finite(limit) && length(x) > 0) {
    limit <- as.integer(limit)
    if (!is.na(limit) && limit > 0) x <- head(x, limit)
  }
  x
}

#' Select a subset of figure paths by basename patterns
#' @param paths Character vector of file paths
#' @param include Optional patterns applied to basenames
#' @param exclude Optional patterns applied to basenames
#' @param limit Optional integer limit
#' @return Filtered character vector of paths
#' @export
filter_paths_by_cfg <- function(paths, include = NULL, exclude = NULL, limit = NULL) {
  import::from("fs", "path_file")
  p <- as.character(paths)
  base <- path_file(p)
  keep_idx <- rep(TRUE, length(p))
  if (!is.null(include) && length(include) > 0) {
    inc <- Reduce(`|`, lapply(include, function(r) grepl(r, base, ignore.case = TRUE)))
    keep_idx <- keep_idx & inc
  }
  if (!is.null(exclude) && length(exclude) > 0) {
    exc <- Reduce(`|`, lapply(exclude, function(r) grepl(r, base, ignore.case = TRUE)))
    keep_idx <- keep_idx & !exc
  }
  out <- p[keep_idx]
  out <- out[file.exists(out)]
  out <- sort(unique(out))
  if (!is.null(limit) && is.finite(limit)) {
    limit <- as.integer(limit)
    if (!is.na(limit) && limit > 0) out <- head(out, limit)
  }
  out
}

