# Load the paper's active scientific functions for non-package tests.

local({
  find_project_root <- function() {
    for (candidate in c(".", "..", "../..")) {
      root <- normalizePath(candidate, winslash = "/", mustWork = FALSE)
      if (file.exists(file.path(root, "Makefile")) &&
          file.exists(file.path(root, "R", "population_simulation_design.R"))) {
        return(root)
      }
    }
    stop("Could not find the rc-dates repository root.", call. = FALSE)
  }

  root <- find_project_root()
  source_files <- c(
    "R/austarch_filters.R",
    "R/model_fit.R",
    "R/manuscript_empirical_reference.R",
    "R/manuscript_empirical_distances.R",
    "R/manuscript_methods_figures.R",
    "R/population_distributions.R",
    "R/population_simulation_design.R",
    "R/population_simulation_models.R",
    "R/population_simulation_run.R",
    "R/population_simulation_artifacts.R"
  )
  for (source_file in source_files) {
    sys.source(file.path(root, source_file), envir = topenv())
  }
})
