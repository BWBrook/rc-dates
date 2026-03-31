# Helper to load project functions for non-package compendium tests

# Source all scripts in R/ so test files can call helpers like `lread()`
local({
  find_project_root <- function() {
    candidates <- c(".", "..", "../..")
    for (candidate in candidates) {
      root <- normalizePath(candidate, winslash = "/", mustWork = FALSE)
      if (dir.exists(file.path(root, "R")) && file.exists(file.path(root, "_targets.R"))) {
        return(root)
      }
    }
    normalizePath(".", winslash = "/", mustWork = FALSE)
  }

  root <- find_project_root()
  invisible(lapply(
    c("parallel", "grid", "splines", "stats", "graphics", "grDevices", "targets", "tarchetypes"),
    requireNamespace,
    quietly = TRUE
  ))
  r_dir <- file.path(root, "R")
  if (dir.exists(r_dir)) {
    r_files <- list.files(r_dir, pattern = "\\.R$", full.names = TRUE)
    for (f in r_files) sys.source(f, envir = topenv())
  }
})
