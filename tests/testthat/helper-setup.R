# Helper to load project functions for non-package compendium tests

# Source all scripts in R/ so test files can call helpers like `lread()`
local({
  # Resolve project root robustly
  root <- tryCatch(here::here(), error = function(e) normalizePath("..", winslash = "/", mustWork = FALSE))
  r_dir <- file.path(root, "R")
  if (dir.exists(r_dir)) {
    r_files <- list.files(r_dir, pattern = "\\.R$", full.names = TRUE)
    for (f in r_files) sys.source(f, envir = topenv())
  }
})
