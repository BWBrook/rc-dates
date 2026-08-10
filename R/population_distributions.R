# Distributions used by the population simulations -------------------------

simulate_error <- function(dates, fit, unlog = TRUE) {
  mu <- stats::predict(fit, newdata = data.frame(AGE = dates))
  sigma <- summary(fit)$sigma
  error <- stats::rnorm(length(dates), mean = mu, sd = sigma)
  if (isTRUE(unlog)) error <- exp(error)
  error
}

dtexp <- function(x, rate, low, upp) {
  if (low >= upp || length(rate) != 1L || !is.finite(rate)) {
    rlang::abort("Invalid signed-exponential interval or rate", class = "rcdates_sim_error")
  }
  density <- numeric(length(x))
  valid <- x >= low & x <= upp
  if (!any(valid)) return(density)

  span <- upp - low
  if (rate == 0) {
    density[valid] <- 1 / span
  } else {
    normalizer <- -expm1(-rate * span)
    density[valid] <- rate * exp(-rate * (x[valid] - low)) / normalizer
  }
  density
}

rtexp <- function(n, rate, low, up) {
  if (low >= up || length(rate) != 1L || !is.finite(rate)) {
    rlang::abort("Invalid signed-exponential interval or rate", class = "rcdates_sim_error")
  }
  u <- stats::runif(n)
  if (rate == 0) return(low + (up - low) * u)
  low - log1p(u * expm1(-rate * (up - low))) / rate
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
  span <- up - low
  slope_limit <- 2 / span^2
  if (low >= up || length(slope) != 1L || !is.finite(slope) ||
      abs(slope) > slope_limit * (1 + 10 * .Machine$double.eps)) {
    rlang::abort("Invalid signed-linear interval or slope", class = "rcdates_sim_error")
  }
  density <- numeric(length(x))
  valid <- x >= low & x <= up
  if (any(valid)) {
    intercept <- (1 + slope * span^2 / 2) / span
    density[valid] <- intercept - slope * (x[valid] - low)
    density[valid] <- pmax(density[valid], 0)
  }
  density
}

rtlin <- function(n, slope, low, up) {
  span <- up - low
  slope_limit <- 2 / span^2
  if (low >= up || length(slope) != 1L || !is.finite(slope) ||
      abs(slope) > slope_limit * (1 + 10 * .Machine$double.eps)) {
    rlang::abort("Invalid signed-linear interval or slope", class = "rcdates_sim_error")
  }
  intercept <- (1 + slope * span^2 / 2) / span
  u <- stats::runif(n)
  discriminant <- pmax(intercept^2 - 2 * slope * u, 0)
  low + 2 * u / (intercept + sqrt(discriminant))
}
