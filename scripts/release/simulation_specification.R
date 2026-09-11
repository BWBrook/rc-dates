# Scalar input adapter for the unchanged simulation engines.
# Fitted objects are deliberately not distributed: they retain source observations.

predict.rcdates_release_error_fit <- function(object, newdata, ...) {
  # predict.lm uses this matrix product for an intercept plus AGE model.
  drop(cbind(1, newdata$AGE) %*% object$coefficients)
}

summary.rcdates_release_error_fit <- function(object, ...) {
  list(sigma = object$sigma)
}

release_simulation_specification <- function(
  path = "release/inputs/simulation_parameters.csv", signed = TRUE
) {
  x <- utils::read.csv(path, check.names = FALSE)
  required <- c("schema_version", "n_sites", "lower_truncation", "nb_size", "nb_mu",
                "error_intercept", "error_slope", "error_sigma", "min_age", "max_age", "ratio")
  stopifnot(nrow(x) == 1L, all(required %in% names(x)),
            all(is.finite(as.numeric(x[1, required]))),
            x$schema_version == 1, x$n_sites == 116, x$lower_truncation == 5,
            x$nb_size > 0, x$nb_mu > 0, x$error_sigma > 0,
            x$min_age == 651, x$max_age == 11650, x$ratio == 10)
  span <- x$max_age - x$min_age
  list(
    n_sites = as.integer(x$n_sites), min_age = x$min_age, max_age = x$max_age,
    ratio = x$ratio,
    slope = 2 * (x$ratio - 1) / ((x$ratio + 1) * span^2),
    rate = log(x$ratio) / span,
    fit_n_dates = list(estimate = c(size = x$nb_size, mu = x$nb_mu)),
    fit_age_to_error = structure(
      list(coefficients = c(`(Intercept)` = x$error_intercept, AGE = x$error_slope),
           sigma = x$error_sigma), class = "rcdates_release_error_fit"
    ),
    strategies = if (signed) population_simulation_contract("signed-v1")$strategies
                 else c("r_all", "r_1", "r_3", "r_5", "r_old", "r_young", "r_bracket")
  )
}
