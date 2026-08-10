# Distributions used by the population simulations -------------------------

simulate_error <- function(dates, fit, unlog = TRUE) {
  mu <- stats::predict(fit, newdata = data.frame(AGE = dates))
  sigma <- summary(fit)$sigma
  error <- stats::rnorm(length(dates), mean = mu, sd = sigma)
  if (isTRUE(unlog)) error <- exp(error)
  error
}

dtexp <- function(x, rate, low, upp) {
  p_upper <- stats::pexp(upp, rate = rate)
  p_lower <- stats::pexp(low, rate = rate)
  stats::dexp(x, rate) / (p_upper - p_lower) * (x >= low) * (x <= upp)
}

rtexp <- function(n, rate, low, up) {
  if (low >= up) {
    rlang::abort("Upper must be greater than lower", class = "rcdates_sim_error")
  }
  u <- stats::runif(n)
  p_lower <- stats::pexp(low, rate = rate)
  p_upper <- stats::pexp(up, rate = rate)
  stats::qexp(u * (p_upper - p_lower) + p_lower, rate = rate)
}

dtnbinom <- function(x, mu, size, low) {
  p_lower <- stats::pnbinom(low - 1, mu = mu, size = size)
  stats::dnbinom(x, mu = mu, size = size) / (1 - p_lower) * (x >= low)
}

rtnbinom <- function(n, mu, size, low) {
  result <- numeric(n)
  for (i in seq_len(n)) {
    u <- stats::runif(1)
    x <- low
    cdf <- dtnbinom(low, mu, size, low)
    while (cdf < u) {
      x <- x + 1
      cdf <- cdf + dtnbinom(x, mu, size, low)
    }
    result[[i]] <- x
  }
  result
}

dtlin <- function(x, slope, low, up) {
  if (low >= up) {
    rlang::abort("Upper bound must be greater than lower bound", class = "rcdates_sim_error")
  }
  density <- numeric(length(x))
  valid <- x >= low & x <= up
  if (any(valid)) {
    intercept <- (1 + slope * (up - low)^2 / 2) / (up - low)
    density[valid] <- intercept - slope * (x[valid] - low)
    if (any(density < 0)) {
      rlang::abort("Slope too large; negative density", class = "rcdates_sim_error")
    }
  }
  density
}

rtlin <- function(n, slope, low, up) {
  if (low >= up) {
    rlang::abort("Upper bound must be greater than lower bound", class = "rcdates_sim_error")
  }
  intercept <- (1 + slope * (up - low)^2 / 2) / (up - low)
  if (intercept - slope * (up - low) < 0) {
    rlang::abort("Slope too large; negative density", class = "rcdates_sim_error")
  }
  u <- stats::runif(n)
  low + (intercept - sqrt(intercept^2 - 2 * slope * u)) / slope
}
