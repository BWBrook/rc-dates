## Legacy simulation helpers (ported as pure functions; heavy sims disabled)

# The legacy simulation study code from `src/simulation_*.R` has been migrated
# into pure helpers to preserve function signatures and enable reuse. Heavy
# simulation runners remain disabled in this compendium; prefer the
# precomputed summaries integrated via the `simulate` config and
# `{targets}` branch.

#' Simulate measurement error from a linear model of AGE -> log(ERROR)
#' @param dates numeric vector of CRA ages
#' @param fit stats::lm fit on log(ERROR) ~ AGE
#' @param unlog logical; exp() the simulated errors
#' @return numeric vector of errors
#' @export
simulate_error <- function(dates, fit, unlog = TRUE) {
  import::from("stats", "predict", "rnorm")
  mu <- predict(fit, newdata = data.frame(AGE = dates))
  sigma <- summary(fit)$sigma
  err <- rnorm(length(dates), mean = mu, sd = sigma)
  if (isTRUE(unlog)) err <- exp(err)
  err
}

# Truncated exponential -----------------------------------------------------

#' @export
dtexp <- function(x, rate, low, upp) {
  import::from("stats", "pexp", "dexp")
  PU <- pexp(upp, rate = rate)
  PL <- pexp(low, rate = rate)
  dexp(x, rate) / (PU - PL) * (x >= low) * (x <= upp)
}

#' @export
ptexp <- function(q, rate, low, upp) {
  import::from("stats", "pexp")
  PU <- pexp(upp, rate = rate)
  PL <- pexp(low, rate = rate)
  (pexp(q, rate) - PL) / (PU - PL) * (q >= low) * (q <= upp) + 1 * (q > upp)
}

#' @export
rtexp <- function(n, rate, low, up) {
  import::from("stats", "pexp", "qexp", "runif")
  if (low >= up) rlang::abort("Upper must be greater than lower", class = "rcdates_sim_error")
  u <- runif(n)
  p_low <- pexp(low, rate = rate)
  p_up <- pexp(up, rate = rate)
  adj_u <- u * (p_up - p_low) + p_low
  qexp(adj_u, rate = rate)
}

# Truncated negative binomial ----------------------------------------------

#' @export
dtnbinom <- function(x, mu, size, low) {
  import::from("stats", "pnbinom", "dnbinom")
  PL <- pnbinom(low - 1, mu = mu, size = size)
  (dnbinom(x, mu = mu, size = size) / (1 - PL)) * (x >= low)
}

#' @export
ptnbinom <- function(q, mu, size, low) {
  import::from("stats", "pnbinom")
  PL <- pnbinom(low - 1, mu = mu, size = size)
  (pnbinom(q, mu = mu, size = size) - PL) / (1 - PL) * (q >= low)
}

#' @export
rtnbinom <- function(n, mu, size, low) {
  import::from("stats", "runif")
  res <- numeric(n)
  for (i in seq_len(n)) {
    u <- runif(1)
    x <- low
    cdf <- 0
    prob <- dtnbinom(low, mu, size, low)
    cdf <- cdf + prob
    while (cdf < u) {
      x <- x + 1
      prob <- dtnbinom(x, mu, size, low)
      cdf <- cdf + prob
    }
    res[i] <- x
  }
  res
}

# Truncated linear ----------------------------------------------------------

#' @export
dtlin <- function(x, slope, low, up) {
  if (low >= up) rlang::abort("Upper bound must be greater than lower bound", class = "rcdates_sim_error")
  density <- numeric(length(x))
  valid <- x >= low & x <= up
  if (any(valid)) {
    a <- (1 + slope * (up - low)^2 / 2) / (up - low)
    density[valid] <- a - slope * (x[valid] - low)
    if (any(density < 0)) rlang::abort("Slope too large; negative density", class = "rcdates_sim_error")
  }
  density
}

#' @export
ptlin <- function(q, slope, low, up) {
  if (low >= up) rlang::abort("Upper bound must be greater than lower bound", class = "rcdates_sim_error")
  cdf <- numeric(length(q))
  a <- (1 + slope * (up - low)^2 / 2) / (up - low)
  if ((a - slope * (up - low)) < 0) rlang::abort("Slope too large; negative density", class = "rcdates_sim_error")
  cdf[q <= low] <- 0
  cdf[q >= up] <- 1
  between <- q > low & q < up
  if (any(between)) {
    cdf[between] <- a * (q[between] - low) - slope * (q[between] - low)^2 / 2
    total <- a * (up - low) - slope * (up - low)^2 / 2
    cdf[between] <- cdf[between] / total
  }
  cdf
}

#' @export
rtlin <- function(n, slope, low, up) {
  import::from("stats", "runif")
  if (low >= up) rlang::abort("Upper bound must be greater than lower bound", class = "rcdates_sim_error")
  a <- (1 + slope * (up - low)^2 / 2) / (up - low)
  if ((a - slope * (up - low)) < 0) rlang::abort("Slope too large; negative density", class = "rcdates_sim_error")
  u <- runif(n)
  y <- (a - sqrt(a^2 - 2 * slope * u)) / slope
  low + y
}

# Small utilities -----------------------------------------------------------

#' @export
max_one <- function(x) {
  out <- logical(length(x))
  out[which.max(x)] <- TRUE
  out
}

#' @export
min_one <- function(x) {
  out <- logical(length(x))
  out[which.min(x)] <- TRUE
  out
}

# Disabled heavy runners ----------------------------------------------------

#' Run full simulation (disabled in compendium)
#' @export
run_simulation <- function(...) {
  import::from("rlang", "abort")
  abort("Heavy simulation is disabled in this compendium. Use precomputed summaries via cfg$simulate.", class = "rcdates_sim_disabled")
}

