#!/usr/bin/env Rscript

# Reproduce accepted Supplementary Figure S2 from an aggregate site-count
# histogram and the accepted full-precision truncated-NB fit specification.
# No archaeological record or site identifier is read by this renderer.

parse_arguments <- function(args) {
  settings <- list(
    input_dir = file.path("release", "inputs"),
    output_dir = file.path("out", "reproduced", "figures")
  )
  key_map <- c(`input-dir` = "input_dir", `output-dir` = "output_dir")
  for (argument in args) {
    parts <- regmatches(argument, regexec("^--([^=]+)=(.*)$", argument))[[1L]]
    if (length(parts) != 3L || !parts[[2L]] %in% names(key_map)) {
      stop("Unknown or malformed argument: ", argument, call. = FALSE)
    }
    settings[[key_map[[parts[[2L]]]]]] <- parts[[3L]]
  }
  for (field in names(settings)) {
    if (length(settings[[field]]) != 1L || !nzchar(settings[[field]])) {
      stop("Invalid directory for ", field, call. = FALSE)
    }
  }
  settings
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 1L && args[[1L]] %in% c("--help", "-h")) {
  writeLines(c(
    "Reproduce accepted Supplementary Figure S2 from aggregate inputs.",
    "",
    "Optional:",
    "  --input-dir=release/inputs",
    "  --output-dir=out/reproduced/figures"
  ))
  quit(status = 0L)
}

if (!identical(as.character(getRversion()), "4.5.3")) {
  stop(
    "Release figures must be rendered under R 4.5.3; found ",
    R.version.string,
    ".",
    call. = FALSE
  )
}
required_packages <- c("ggplot2")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop("Missing figure packages: ", paste(missing_packages, collapse = ", "))
}

settings <- parse_arguments(args)
histogram_path <- file.path(settings$input_dir, "site_count_histogram.csv")
parameters_path <- file.path(settings$input_dir, "simulation_parameters.csv")
all_inputs <- c(histogram_path, parameters_path)
missing_files <- all_inputs[!file.exists(all_inputs)]
if (length(missing_files) > 0L) {
  stop(
    "Missing release input: ",
    paste(missing_files, collapse = ", "),
    call. = FALSE
  )
}

histogram <- utils::read.csv(
  histogram_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
required_histogram_columns <- c("n_dates", "observed_frequency")
if (!all(required_histogram_columns %in% names(histogram)) ||
    nrow(histogram) < 2L) {
  stop("Site-count histogram has an invalid schema.", call. = FALSE)
}
histogram$n_dates <- as.numeric(histogram$n_dates)
histogram$observed_frequency <- as.numeric(histogram$observed_frequency)
if (any(!is.finite(as.matrix(histogram[required_histogram_columns]))) ||
    any(histogram$n_dates != as.integer(histogram$n_dates)) ||
    any(histogram$observed_frequency != as.integer(histogram$observed_frequency)) ||
    any(histogram$observed_frequency < 0) ||
    anyDuplicated(histogram$n_dates)) {
  stop("Site-count histogram contains invalid values.", call. = FALSE)
}

parameters <- utils::read.csv(
  parameters_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
required_parameter_columns <- c(
  "n_sites", "lower_truncation", "nb_size", "nb_mu",
  "observed_mean", "observed_median", "observed_min", "observed_max",
  "fitted_conditional_mean"
)
if (nrow(parameters) != 1L ||
    !all(required_parameter_columns %in% names(parameters))) {
  stop("Simulation parameter specification has an invalid schema.", call. = FALSE)
}
for (column in required_parameter_columns) parameters[[column]] <- as.numeric(parameters[[column]])
parameter_values <- unlist(parameters[required_parameter_columns], use.names = FALSE)
if (any(!is.finite(parameter_values)) ||
    parameters$n_sites != as.integer(parameters$n_sites) ||
    parameters$lower_truncation != as.integer(parameters$lower_truncation) ||
    parameters$n_sites < 1L || parameters$lower_truncation < 0L ||
    parameters$nb_size <= 0 || parameters$nb_mu <= 0) {
  stop("Simulation parameter specification contains invalid values.", call. = FALSE)
}

observed_sites <- sum(histogram$observed_frequency)
observed_dates <- sum(histogram$n_dates * histogram$observed_frequency)
observed_mean <- observed_dates / observed_sites
observed_values <- rep(histogram$n_dates, histogram$observed_frequency)
observed_median <- stats::median(observed_values)
if (observed_sites != parameters$n_sites ||
    abs(observed_mean - parameters$observed_mean) > 1e-10 ||
    observed_median != parameters$observed_median ||
    min(observed_values) != parameters$observed_min ||
    max(observed_values) != parameters$observed_max) {
  stop("Histogram and simulation parameter summaries do not agree.", call. = FALSE)
}
if (any(histogram$n_dates < parameters$lower_truncation)) {
  stop("Histogram contains counts below the accepted truncation.", call. = FALSE)
}

conditional_mean <- parameters$nb_mu * stats::pnbinom(
  parameters$lower_truncation - 2,
  size = parameters$nb_size + 1,
  prob = parameters$nb_size / (parameters$nb_size + parameters$nb_mu),
  lower.tail = FALSE
) / stats::pnbinom(
  parameters$lower_truncation - 1,
  size = parameters$nb_size,
  mu = parameters$nb_mu,
  lower.tail = FALSE
)
if (!is.finite(conditional_mean) ||
    abs(conditional_mean - parameters$fitted_conditional_mean) > 1e-10) {
  stop("The supplied truncated negative-binomial mean does not match its parameters.",
       call. = FALSE)
}

fit_x <- seq(
  parameters$lower_truncation,
  max(histogram$n_dates) + 2,
  by = 1
)
normalising_mass <- 1 - stats::pnbinom(
  parameters$lower_truncation - 1,
  size = parameters$nb_size,
  mu = parameters$nb_mu
)
fit <- data.frame(
  n_dates = fit_x,
  fitted_frequency = parameters$n_sites * stats::dnbinom(
    fit_x,
    size = parameters$nb_size,
    mu = parameters$nb_mu
  ) / normalising_mass
)
if (any(!is.finite(fit$fitted_frequency)) || normalising_mass <= 0) {
  stop("Truncated negative-binomial fit is not finite or normalised.", call. = FALSE)
}

plot <- ggplot2::ggplot(
  histogram,
  ggplot2::aes(x = n_dates, y = observed_frequency)
) +
  ggplot2::geom_line(
    data = fit,
    ggplot2::aes(x = n_dates, y = fitted_frequency),
    inherit.aes = FALSE,
    colour = "#6baed6",
    linewidth = 1.2
  ) +
  ggplot2::geom_point(size = 2.6, colour = "#08306b") +
  ggplot2::scale_x_continuous(
    name = "Number of dates per site",
    breaks = c(10, 20, 30)
  ) +
  ggplot2::scale_y_continuous(
    name = "Frequency",
    breaks = c(0, 10, 20, 30)
  ) +
  ggplot2::labs(
    title = "Number of dates per site",
    subtitle = "Truncated negative binomial fit to empirical data"
  ) +
  ggplot2::theme_classic(base_size = 14) +
  ggplot2::theme(
    plot.title = ggplot2::element_text(hjust = 0, size = 20),
    plot.subtitle = ggplot2::element_text(hjust = 0, size = 16)
  )

dir.create(settings$output_dir, recursive = TRUE, showWarnings = FALSE)
output <- file.path(
  settings$output_dir,
  "SI_dates_per_site_in_austarch_holocene.png"
)
temporary <- paste0(output, ".tmp.png")
on.exit(unlink(temporary), add = TRUE)
ggplot2::ggsave(
  temporary,
  plot,
  width = 971 / 100,
  height = 747 / 100,
  dpi = 100
)
if (file.exists(output)) unlink(output)
if (!file.rename(temporary, output)) {
  stop("Could not write release Supplementary Figure S2.", call. = FALSE)
}
message("Wrote ", output)
