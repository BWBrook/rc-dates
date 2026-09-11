#!/usr/bin/env Rscript
# Refit generating parameters from the separately reconstructed reference.
source("scripts/release/common.R")
args <- release_arguments(list(`output-dir` = "out/reproduced/inputs"))
source("scripts/source_population_simulation.R")
source("scripts/release/simulation_specification.R")
input_path <- "data/austarch_filtered.csv"
stopifnot(unname(tools::md5sum(input_path)) == "8d30b24e98088a7808c234d6b77ac382")
input <- readr::read_csv(input_path, show_col_types = FALSE)
spec <- prepare_population_simulation(input)
counts <- as.numeric(table(input$SITE))
nb <- spec$fit_n_dates$estimate
conditional_mean <- nb[["mu"]] * stats::pnbinom(
  3, size = nb[["size"]] + 1, prob = nb[["size"]] / sum(nb), lower.tail = FALSE
) / stats::pnbinom(4, size = nb[["size"]], mu = nb[["mu"]], lower.tail = FALSE)
values <- c(schema_version = 1, n_sites = spec$n_sites, lower_truncation = 5,
            nb_size = nb[["size"]], nb_mu = nb[["mu"]],
            error_intercept = unname(stats::coef(spec$fit_age_to_error)[[1]]),
            error_slope = unname(stats::coef(spec$fit_age_to_error)[[2]]),
            error_sigma = summary(spec$fit_age_to_error)$sigma,
            error_r_squared = summary(spec$fit_age_to_error)$r.squared,
            error_residual_df = stats::df.residual(spec$fit_age_to_error),
            min_age = spec$min_age, max_age = spec$max_age, ratio = spec$ratio,
            observed_mean = mean(counts), observed_median = stats::median(counts),
            observed_min = min(counts), observed_max = max(counts),
            fitted_conditional_mean = conditional_mean)
dir.create(args[["output-dir"]], recursive = TRUE, showWarnings = FALSE)
path <- file.path(args[["output-dir"]], "simulation_parameters.csv")
writeLines(c(paste(names(values), collapse = ","),
             paste(sprintf("%.17g", values), collapse = ",")), path)
restored <- release_simulation_specification(path)
stopifnot(identical(unname(restored$fit_n_dates$estimate), unname(nb)))
test_ages <- seq(0, 15000, by = 0.5)
stopifnot(identical(unname(stats::predict(spec$fit_age_to_error, data.frame(AGE = test_ages))),
                    unname(stats::predict(restored$fit_age_to_error, data.frame(AGE = test_ages)))))
set.seed(2411)
original <- simulate_error(test_ages, spec$fit_age_to_error)
original_rng <- .Random.seed
set.seed(2411)
reconstructed <- simulate_error(test_ages, restored$fit_age_to_error)
stopifnot(identical(original, reconstructed), identical(original_rng, .Random.seed))
message("Exported scalar specification; exact coefficients, predictions, error draws and RNG verified.")

if (normalizePath(path) != normalizePath("release/inputs/simulation_parameters.csv")) {
  release_compare_rows(readr::read_csv(path, show_col_types = FALSE),
                       readr::read_csv("release/inputs/simulation_parameters.csv", show_col_types = FALSE),
                       "schema_version", "Refitted generating parameters")
}
histogram <- as.data.frame(table(counts), stringsAsFactors = FALSE)
names(histogram) <- c("n_dates", "observed_frequency")
histogram$n_dates <- as.numeric(histogram$n_dates)
release_compare_rows(histogram,
                     readr::read_csv("release/inputs/site_count_histogram.csv", show_col_types = FALSE),
                     "n_dates", "Refitted site-count histogram")
