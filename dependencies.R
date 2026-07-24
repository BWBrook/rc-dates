# Dependency manifest for the rc-dates compendium

# Returns a character vector of required packages for this project.
project_dependencies <- function(include_optional = FALSE) {
  pkgs <- c(
    # pipeline & IO
    "targets", "tarchetypes", "here", "yaml", "config",
    "arrow", "vroom", "fs",
    # report runtime
    "knitr", "rmarkdown",
    # wrangling & utils
    "dplyr", "readr", "purrr", "tidyr", "tibble", "stringr", "magrittr",
    "withr", "digest", "checkmate", "janitor",
    # spatial (if needed later)
    "sf", "terra",
    # modelling / methods
    "rcarbon", "fitdistrplus", "yardstick",
    # parallel & progress & logging
    "future", "future.batchtools", "pbmcapply", "progressr", "lgr",
    # viz
    "ggplot2", "RColorBrewer", "scales", "zoo", "patchwork",
    # legacy plotting helpers retained in scripts/legacy
    "ggpubr",
    # ergonomics & errors
    "cli", "rlang", "import",
    # dev
    "testthat", "lintr", "styler", "devtools", "pak", "renv", "quarto"
  )
  if (isTRUE(include_optional)) {
    pkgs <- c(pkgs, "magick")
  }
  unique(pkgs)
}

# Optional helper: install dependencies into the active project library.
# This is not run automatically. Use in RStudio if needed.
install_project_dependencies <- function(pkgs = project_dependencies()) {
  if (requireNamespace("pak", quietly = TRUE)) {
    pak::pak(unique(pkgs), ask = FALSE)
  } else {
    install.packages(unique(pkgs), dependencies = TRUE)
  }
  invisible(TRUE)
}
