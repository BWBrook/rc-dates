# ============================================================================
# Core Functions for Radiocarbon Simulation Study
# ============================================================================
# 
# This script contains all mathematical and simulation functions needed for
# the radiocarbon sampling strategy analysis. Includes likelihood calculations
# for population models (uniform, linear, exponential), data simulation 
# routines, sampling strategy implementations, model fitting procedures, and
# performance evaluation metrics.
#
# Used by: simulation_main.R for running experiments
# ============================================================================

# simulate errors for each date based on linear model of the empirical error distribution
simulate_error <- function(dates,fit, unlog = T){
  error <- rnorm(length(dates), mean = predict(fit,newdata = data.frame(AGE = dates)), sd = summary(fit)$sigma)
  if(unlog){
    error <- exp(error)
  }
  return(error)
}

# truncated exponential distribution
dtexp <- function(x, rate, low, upp)
{
  PU <- pexp(upp, rate=rate)
  PL <- pexp(low, rate=rate)
  dexp(x, rate) / (PU-PL) * (x >= low) * (x <= upp) 
}

# truncated exponential cumulative distribution function
ptexp <- function(q, rate, low, upp)
{
  PU <- pexp(upp, rate=rate)
  PL <- pexp(low, rate=rate)
  (pexp(q, rate)-PL) / (PU-PL) * (q >= low) * (q <= upp) + 1 * (q > upp)
}

# truncated exponential random number generation
rtexp <- function(n, rate, low, up) {
  if (low >= up) stop("Upper must be greater than lower")
  u <- runif(n)
  p_low <- pexp(low, rate = rate)
  p_up <- pexp(up, rate = rate)
  adj_u <- u * (p_up - p_low) + p_low
  qexp(adj_u, rate = rate)
}

# truncated negative binomial distribution
dtnbinom <- function(x, mu, size, low){
  PL <- pnbinom(low-1, mu = mu, size=size)
  (dnbinom(x, mu = mu, size=size)/(1-PL)) * (x >= low) 
}

# truncated negative binomial cumulative distribution function
ptnbinom<- function(q, mu, size, low){
  PL <- pnbinom(low-1, mu = mu, size = size)
  (pnbinom(q, mu = mu, size = size)-PL) / (1-PL) * (q >= low) 
}

# truncated negative binomial random number generation
rtnbinom <- function(n, mu, size, low) {
  result <- numeric(n)
  for (i in 1:n) {
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
    result[i] <- x
  }
  return(result)
}

# Truncated linear distribution
dtlin <- function(x, slope, low, up) {
  if (low >= up) stop("Upper bound must be greater than lower bound")
  density <- rep(0, length(x))
  valid_x <- x >= low & x <= up
  if (any(valid_x)) {
    a <- (1 + slope * (up - low)^2 / 2) / (up - low)
    density[valid_x] <- a - slope * (x[valid_x] - low)
    if (any(density < 0)) stop("Slope too large, results in negative density values")
  }
  return(density)
}

# Truncated linear cumulative distribution function
ptlin <- function(q, slope, low, up) {
  if (low >= up) stop("Upper bound must be greater than lower bound")
  cdf <- rep(0, length(q))
  a <- (1 + slope * (up - low)^2 / 2) / (up - low) # ensure total probability = 1
  min_density <- a - slope * (up - low)
  if (min_density < 0) stop("Slope too large, results in negative density values")
  cdf[q <= low] <- 0
  cdf[q >= up] <- 1
  between <- q > low & q < up
  if (any(between)) {
    cdf[between] <- a * (q[between] - low) - slope * (q[between] - low)^2 / 2
    total_area <- a * (up - low) - slope * (up - low)^2 / 2  # Should be 1
    cdf[between] <- cdf[between] / total_area
  }
  return(cdf)
}

# Truncated linear random number generation
rtlin <- function(n, slope, low, up) {
  if (low >= up) stop("Upper bound must be greater than lower bound")
  a <- (1 + slope * (up - low)^2 / 2) / (up - low)
  min_density <- a - slope * (up - low)
  if (min_density < 0) stop("Slope too large, results in negative density values")
  u <- runif(n)
  y <- (a - sqrt(a^2 - 2*slope*u))/slope
  x <- low + y
  return(x)
}

# Calculate pointwise negative log-likelihood for linear population model
ll_lin_i <- function(slope, data, low, up, type = "l1"){
  data <- data %>% 
    filter(calBP > low & calBP < up) %>% 
    mutate(PrDens = PrDens/sum(PrDens))
  if(type == "l1"){ # log integrated likelihood
    return(log(sum(dtlin(data[,"calBP"], slope = slope, low = low, up = up)*data[,"PrDens"])))
  } else if(type == "l2"){ # integrated log likelihood
    return(sum(log(dtlin(data[,"calBP"], slope = slope, low = low, up = up))*data[,"PrDens"]))
  } 
}

# Calculate negative log-likelihood for linear population model
nll_lin <- function(slope, data, low, up, type = "l1", summed = T){
  nlli = data %>% map_dbl(~ll_lin_i(slope = slope/1e6, data = .x, low = low, up = up, type = type)) %>% {.*-1}
  if(summed){
    return(nlli %>% sum)
  } else {
    return(nlli)
  }
}

# Calculate pointwise negative log-likelihood for exponential population model
ll_exp_i <- function(rate, data, low, up, type = "l2"){
  data <- data %>% 
    filter(calBP > low & calBP < up) %>% 
    mutate(PrDens = PrDens/sum(PrDens))
  if(type == "l1"){
    return(sum(dtexp(data[,"calBP"], rate = rate, low = low, up = up)*data[,"PrDens"]) %>% log)
  } else if(type == "l2"){
    return(sum(log(dtexp(data[,"calBP"], rate = rate, low = low, up = up))*data[,"PrDens"]))
  } 
}

# Calculate negative log-likelihood for exponential population model
nll_exp <- function(rate, data, low, up, type = "l1", summed = T){
  nlli <- data %>% map_dbl(~ll_exp_i(rate = rate/1e3, data = .x, low = low, up = up, type = type)) %>% {.*-1}
  if(summed){
    return(nlli %>% sum)
  } else {
    return(nlli)
  }
}

# Return a logical vector with TRUE at the index of the first maximum value
max_one <- function(x) {
  result <- logical(length(x))
  result[which.max(x)] <- TRUE
  return(result)
}

# Return a logical vector with TRUE at the index of the minimum value
min_one <- function(x) {
  result <- logical(length(x))
  result[which.min(x)] <- TRUE
  return(result)
}

# Simulate a dataset of ages with a specified model, subsampling strategy, and error distribution
simulate_data_set <- function(n_sites, model, prop, slope = NULL, rate = NULL, 
                              min_age, max_age, sim,
                              fit_n_dates, fit_age_to_error,
                              dir_path = "") {
  sim_data_0 = 
    tibble(n_dates = rtnbinom(n_sites, 
                              mu = fit_n_dates$estimate["mu"], 
                              size = fit_n_dates$estimate["size"], 
                              low = 5),
           site = paste0("site_",1:n_sites)) %>% 
    uncount(weight = n_dates)
  
  if(model == "lin"){
    if(is.null(slope)) stop("Slope must be provided for linear model")
    sim_data_0 = 
      sim_data_0 %>% 
      mutate(age_0 = rtlin(n(), slope = slope, low = min_age, up = max_age))
  }
  if(model == "exp"){
    if(is.null(rate)) stop("Rate must be provided for exponential model")
    sim_data_0 = 
      sim_data_0 %>% 
      mutate(age_0 = rtexp(n(), rate = rate, low = min_age, up = max_age))
  }
  if(model == "uni"){
    sim_data_0 = 
      sim_data_0 %>% 
      mutate(age_0 = runif(n(), min = min_age, max = max_age))
  }
  sim_data_0 = 
    sim_data_0 %>% 
    mutate(
      age_uncal = rcarbon::uncalibrate(age_0, calCurves = "shcal20") %>% 
        {.$ccCRA},
      error = simulate_error(age_uncal, fit_age_to_error))
  
  cal = calibrate(
    x = sim_data_0$age_uncal,
    errors = sim_data_0$error,
    timeRange = c(15000,0),
    calCurves = "shcal20",
    verbose = F)
  
  sim_data = 
    sim_data_0 %>% 
    mutate(age_cal = summary(cal)[,"MedianBP"]) %>% 
    group_by(site) %>% 
    mutate(r_1 = as.numeric((1:n())==sample(1:n(),1)),
           r_3 = as.numeric((1:n()) %in% sample(1:n(),3)),
           r_5 = as.numeric((1:n()) %in% sample(1:n(),5)),
           r_old = as.numeric(max_one(age_cal)),
           r_young = as.numeric(min_one(age_cal))
    ) %>% 
    mutate(subsample = site %in% paste0("site_",sample(1:n_sites, prop*n_sites))) %>% 
    mutate(across(starts_with("r_"), ~ if_else(subsample,.x,1)),
           subsample = as.integer(subsample))
  
  sim_data %>% ungroup %>% mutate(r_all = 1, r_bracket = as.numeric(r_old | r_young), grid = cal$grids)
}

# Generate pointwise AIC table for all three models
get_aic_table <- function(est_lin, est_exp, type, data, low, up) {
  tibble(lin = 2*nll_lin(est_lin$minimum, data = data, low = low, up = up, type = type, summed = F) + 2/length(data),
         exp = 2*nll_exp(est_exp$minimum, data = data, low = low, up = up, type = type, summed = F) + 2/length(data),
         uni = -2*log(1/(up-low))) 
}


# Select models based on AIC values and standard error of the differences
select_models <- function(est_lin, est_exp, type, data, low, up) {
  
  aic_table <- get_aic_table(est_lin, est_exp, type = type, data = data, low = low, up = up)
  
  m.min <- aic_table %>% map_dbl(sum) %>% which.min %>% names
  delta_aic_table <- 
    aic_table %>% 
    mutate(across(everything(), ~ .x - .data[[m.min]]))
  
  mose_table =
    tibble(model = names(delta_aic_table),
           dim = c(uni = 0, lin = 1, exp = 1)[model],
           delta_aic = delta_aic_table %>% map_dbl(sum),
           se_delta_aic = delta_aic_table %>% map_dbl(~ sd(.x)*sqrt(length(.x))))
  
  m.ose = mose_table %>% filter(delta_aic <= se_delta_aic) %>% filter(dim == min(dim)) %>% pull(model)
  
  tibble(model = c("uni","lin","exp"),
         type = type,
         min = as.numeric(model == m.min),
         ose = as.numeric(model %in% m.ose))
}

# Fit and evaluate models based on the simulated data, true model, and subsampling strategy
evaluate_models <- function(d, true_model, strategy, prop, min_age, max_age, sim) {
  
  grids <- d %>% dplyr::filter(as.logical(.data[[strategy]])) %>% pull(grid)
  
  min_slope <- 1e-12
  max_slope <- 2 /(max_age - min_age)^2
  est_lin_1 <- optimise(nll_lin, c(min_slope,max_slope)*1e6, data = grids, low = min_age, up = max_age, type = "l1")
  est_lin_2 <- optimise(nll_lin, c(min_slope,max_slope)*1e6, data = grids, low = min_age, up = max_age, type = "l2")
  est_exp_1 <- optimise(nll_exp, c(1e-10,1e-3)*1e3, data = grids, low = min_age, up = max_age, type = "l1")
  est_exp_2 <- optimise(nll_exp, c(1e-10,1e-3)*1e3, data = grids, low = min_age, up = max_age, type = "l2")
  
  sel_1 <- select_models(est_lin_1, est_exp_1, type = "l1", data = grids, low = min_age, up = max_age)
  sel_2 <- select_models(est_lin_2, est_exp_2, type = "l2", data = grids, low = min_age, up = max_age) 
  
 
  if(true_model == "lin"){
    biases <- tibble(model = "lin",
                     type = c("l1","l2"),
                     bias = c(est_lin_1$minimum/1e6 - slope,
                              est_lin_2$minimum/1e6 - slope))
  }
  if(true_model == "exp"){
    biases <- tibble(model = "exp",
                     type = c("l1","l2"),
                     bias = c(est_exp_1$minimum/1e3 - rate,
                              est_exp_2$minimum/1e3 - rate))
  }
  if(true_model == "uni"){
    biases <- tibble(model = "uni",
                     type = c("l1","l2"),
                     bias = c(NA,NA))
  }
  
  bind_rows(sel_1,sel_2) %>% 
    left_join(biases, by = c("model", "type")) %>% 
    mutate(sim = sim,
           true = true_model,
           strategy = strategy,
           prop = prop) %>% 
    relocate(sim, true, prop, strategy, type, model, min, ose, bias) 
}

# Run a simulation with specified parameters and evaluate models
run_simulation <- function(sim, true_model, prop, 
                           n_sites, slope, rate, min_age, max_age, 
                           fit_n_dates, fit_age_to_error,
                           strategies,
                           dir_path = ""){
  d = 
    simulate_data_set(
      n_sites = n_sites,
      model = true_model,
      prop = prop,
      slope = slope,
      rate = rate,
      min_age = min_age,
      max_age = max_age,
      sim = sim,
      fit_n_dates = fit_n_dates,
      fit_age_to_error = fit_age_to_error,
      dir_path = dir_path
    )
  
  strategies %>% 
    map_dfr(~ evaluate_models(d, true_model, strategy = .x, prop, min_age, max_age, sim = sim))
  
}
