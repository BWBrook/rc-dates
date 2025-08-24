# Helper to load project functions for non-package compendium tests

# Source all scripts in R/ so test files can call helpers like `lread()`
local({
  r_dir <- "R"
  if (dir.exists(r_dir)) {
    r_files <- list.files(r_dir, pattern = "\\.R$", full.names = TRUE)
    for (f in r_files) sys.source(f, envir = topenv())
  }
})

