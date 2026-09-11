stopifnot(identical(as.character(getRversion()), "4.5.3"))

release_arguments <- function(defaults) {
  for (arg in commandArgs(trailingOnly = TRUE)) {
    parts <- regmatches(arg, regexec("^--([^=]+)=(.*)$", arg))[[1]]
    if (length(parts) != 3L || !parts[[2]] %in% names(defaults)) {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
    defaults[[parts[[2]]]] <- parts[[3]]
  }
  defaults
}

release_compare_rows <- function(actual, expected, keys, label) {
  stopifnot(setequal(names(actual), names(expected)))
  actual <- actual[do.call(order, unname(as.list(actual[keys]))), names(expected), drop = FALSE]
  expected <- expected[do.call(order, unname(as.list(expected[keys]))), , drop = FALSE]
  if (nrow(actual) != nrow(expected)) stop(label, ": row count differs")
  bad <- names(expected)[!vapply(names(expected), function(name) {
    isTRUE(all.equal(actual[[name]], expected[[name]], tolerance = 0,
                     check.attributes = FALSE))
  }, logical(1))]
  if (length(bad)) stop(label, ": scientific values differ in ", paste(bad, collapse = ", "))
  message(label, ": exact scientific values verified (", nrow(actual), " rows)")
  invisible(TRUE)
}

release_write_compare_csv <- function(actual, expected_path, output_path, keys) {
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  temporary <- paste0(output_path, ".tmp-", Sys.getpid())
  on.exit(unlink(temporary), add = TRUE)
  readr::write_csv(actual, temporary)
  # Compare both through the same serialization used by accepted evidence.
  observed <- readr::read_csv(temporary, show_col_types = FALSE)
  expected <- readr::read_csv(expected_path, show_col_types = FALSE)
  release_compare_rows(observed, expected, keys, basename(expected_path))
  stopifnot(file.rename(temporary, output_path))
}

release_atomic_rds <- function(object, path) {
  temporary <- paste0(path, ".tmp-", Sys.getpid())
  on.exit(unlink(temporary), add = TRUE)
  saveRDS(object, temporary, version = 3)
  stopifnot(file.rename(temporary, path))
}
