# ============================================================================
# Radiocarbon Sampling Strategy Simulation Study
# ============================================================================
# 
# This script runs the main simulation experiments to evaluate the performance
# of different radiocarbon sampling strategies for archaeological population 
# reconstruction. It generates synthetic data sets with known population models
# (uniform, linear, exponential growth), applies various sampling strategies 
# (all dates, random sampling, age-selective), fits models using L1/L2 
# likelihood approaches, and evaluates accuracy of model selection.
#
# Output: Performance metrics for each sampling strategy across 63,000 
# simulation scenarios, used to determine optimal dating strategies.
# ============================================================================

library(dplyr)
library(ggplot2)
library(tidyr)
library(purrr)
library(rcarbon)
library(fitdistrplus)
library(pbmcapply)

rm(list = ls())
theme_set(theme_classic())


# load data based on environment
if(interactive()){
  source("../R/legacy_simulation_helpers.R")
  data <- readr::read_csv("data/austarch_filtered.csv")
  dir_path <- ""
} else {
  source("projects/rc-dates/functions.R") # 
  data <- readr::read_csv("projects/rc-dates/data/austarch_filtered.csv")
  dir_path <- "projects/rc-dates/"
}

glimpse(data)


# Model the site sample sizes and error distributions of the empirical data set
dates_by_site <- 
  data %>% 
  group_by(SITE) %>% 
  summarise(n_dates = n())
  
n_dates_empirical <- 
  dates_by_site %>% 
  pull(n_dates) %>% 
  table %>% 
  {tibble(n = as.numeric(names(.)), freq = as.numeric(.))}

n_sites <- nrow(dates_by_site) # 116
min_n_dates <- min(dates_by_site$n_dates) # 5

# fit a truncated negative binomial distribution to the number of samples per site
fit_n_dates <- fitdist(dates_by_site$n_dates, "tnbinom", method="mle",
               start=list(size = 5, mu = 5), fix.arg=list(low=5))

# plot NB fit and empirical data
tibble(n = seq(5,35),
       freq = dtnbinom(n, 
                  size = fit_n_dates$estimate["size"], 
                  mu = fit_n_dates$estimate["mu"], 
                  low = 5)*n_sites) %>% 
  ggplot(aes(x = n, y = freq)) +
  geom_line(col = blues9[5], linewidth = 1) +
  geom_point(data = n_dates_empirical, aes(x = n, y = freq), col = blues9[9]) +
  labs(title= "Number of dates per site",
       subtitle = "Truncated negative binomial fit to empirical data",
       x = "Number of dates per site",
       y = "Frequency") 


# simulate number of dates per site
rtnbinom(n_sites, 
         mu = fit_n_dates$estimate["mu"], 
         size = fit_n_dates$estimate["size"], 
         low = 5)

# fit a linear model for the relationship between AGE and ERROR
fit_age_to_error <- lm(data = data, log(ERROR) ~ AGE) 
fit_age_to_error %>% summary # p-value <2e-16 for slope

# set age window
min_age <- 651
max_age <- 11650

# check truncated exponential distribution
ratio_exp <- 10 # set multiplicative population increase
rate <- log(ratio_exp) / (max_age - min_age)
dtexp(min_age, rate, min_age, max_age)/dtexp(max_age, rate, min_age, max_age) # YES
integrate(dtexp, min_age, max_age, rate, min_age, max_age) # 1
rtexp(1e6, rate, min_age, max_age) %>% hist(100)

# check truncated linear distribution
ratio_lin <- 10 # set multiplicative population increase
slope = 2 * (ratio_lin - 1) / ((ratio_lin + 1) * (max_age - min_age)^2)
dtlin(min_age, slope, min_age, max_age)/dtlin(max_age, slope, min_age, max_age) # YES
integrate(dtlin, min_age, max_age, slope, min_age, max_age) # 1
rtlin(1e6, slope, min_age, max_age) %>% hist(100)

# check theoretical distributions
dens_true <- 
  tibble(x = seq(min_age, max_age, 1)) %>% 
  mutate(
    uniform = dunif(x, min = min_age, max = max_age),
    linear = dtlin(x, slope = slope, low = min_age, up = max_age), 
    exponential = dtexp(x, rate = rate, low = min_age, up = max_age)) %>% 
  pivot_longer(-x) %>% 
  ggplot(aes(x = x, y = value, col = name)) +
  geom_line() +
  theme(legend.position = "none") +
  scale_color_brewer(palette = "Set1", name = "Growth model") +
  xlim(min_age, max_age) +
  scale_x_reverse(limits = c(max_age, min_age)) +
  labs(x = "Age (BP)", y = "Density")

# check simulated distributions: GOOD
dens_sim <- 
  bind_rows(
    runif(1e3, min = min_age, max = max_age) %>% density(from = min_age+300, to = max_age-300, bw = 100) %>% 
      {tibble(x = .$x, y = .$y, name = "uniform")},
    rtlin(1e3, slope, min_age, max_age) %>% density(from = min_age+300, to = max_age-300, bw = 100) %>% 
      {tibble(x = .$x, y = .$y, name = "linear")},
    rtexp(1e3, rate, min_age, max_age) %>% density(from = min_age+300, to = max_age-300, bw = 100) %>% 
      {tibble(x = .$x, y = .$y, name = "exponential")}
  ) %>% 
  ggplot(aes(x = x, y = y, col = name)) +
  geom_line() +
  scale_color_brewer(palette = "Set1", name = "Growth model") +
  scale_x_reverse(limits = c(max_age, min_age)) +
  labs(x = "Age (BP)", y = "Density")

if(interactive()){
  ggpubr::ggarrange(dens_true + labs(title = "Data-generating distributions"), 
                    dens_sim + labs(title = "Simulated data", y= " "), ncol = 2, nrow = 1,
                    labels = c("A", "B"),
                    common.legend = TRUE,
                    legend = "bottom") 
}


# main simulation study
true_model = "uni"
prop = 1
nsim = 1e3
rundate <- Sys.Date()
strategies <- c("r_1","r_3","r_5","r_old","r_young","r_bracket","r_all")
set.seed(1234)

res <- 
  1:nsim %>% 
  pbmclapply(run_simulation,
             true_model = true_model,
             prop = prop,
             n_sites = n_sites,
             slope = slope,
             rate = rate,
             min_age = min_age,
             max_age = max_age,
             fit_n_dates = fit_n_dates,
             fit_age_to_error = fit_age_to_error,
             strategies = strategies, 
             dir_path = dir_path,
             mc.cores = 10,
             ignore.interactive = T) 

#res %>% 
#  bind_rows %>% 
#  saveRDS(paste0("out/results_",true_model,"_p",prop,"_ratio",ratio_exp,"_nsim",nsim,
#                "_",rundate,".rds"))
