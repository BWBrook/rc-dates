# Source the population-simulation modules in their dependency order.

population_distribution_source <- "R/population_distributions.R"
population_model_sources <- c(
  "R/population_simulation_design.R",
  "R/population_simulation_models.R",
  "R/population_simulation_run.R",
  "R/population_simulation_artifacts.R"
)
population_simulation_sources <- c(
  population_distribution_source,
  population_model_sources
)

missing_sources <- population_simulation_sources[!file.exists(population_simulation_sources)]
if (length(missing_sources) > 0L) {
  stop(
    "Run from the rc-dates repository root; missing simulation source: ",
    paste(missing_sources, collapse = ", "),
    call. = FALSE
  )
}

for (source_file in population_simulation_sources) {
  sys.source(source_file, envir = .GlobalEnv)
}

population_model_source_md5 <- function() {
  records <- paste(
    population_model_sources,
    unname(tools::md5sum(population_model_sources)),
    sep = "="
  )
  digest::digest(paste(records, collapse = "\n"), algo = "md5", serialize = FALSE)
}
