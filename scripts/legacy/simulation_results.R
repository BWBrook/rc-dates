# ============================================================================
# Results Analysis and Visualization
# ============================================================================
# 
# This script processes simulation results to generate performance comparisons
# between radiocarbon sampling strategies. Creates figures showing accuracy
# rates, parameter bias, and model selection performance across different
# site inclusion levels and likelihood approaches.
#
# Input: Simulation results from simulations.R
# Output: Publication-ready figures and summary statistics
# ============================================================================

library(dplyr)
library(ggplot2)
library(tidyr)
library(purrr)
library(yardstick)
library(RColorBrewer)

rm(list = ls())

theme_set(theme_classic())

# load results
res_50 <- list()
res_50[["exp"]] <- readRDS("out/results_exp_p0.5_ratio10_nsim1000_2025-05-21.rds")
res_50[["lin"]] <- readRDS("out/results_lin_p0.5_ratio10_nsim1000_2025-05-21.rds")
res_50[["uni"]] <- readRDS("out/results_uni_p0.5_ratio10_nsim1000_2025-05-21.rds")

res_75 <- list()
res_75[["exp"]] <- readRDS("out/results_exp_p0.75_ratio10_nsim1000_2025-05-22.rds")
res_75[["lin"]] <- readRDS("out/results_lin_p0.75_ratio10_nsim1000_2025-05-22.rds")
res_75[["uni"]] <- readRDS("out/results_uni_p0.75_ratio10_nsim1000_2025-05-22.rds")

res_100 <- list()
res_100[["exp"]] <- readRDS("out/results_exp_p1_ratio10_nsim1000_2025-05-20.rds")
res_100[["lin"]] <- readRDS("out/results_lin_p1_ratio10_nsim1000_2025-05-20.rds")
res_100[["uni"]] <- readRDS("out/results_uni_p1_ratio10_nsim1000_2025-05-20.rds")

res <- c(res_50, res_75, res_100) %>% 
  bind_rows() %>% 
  mutate(truth = factor(true, levels = c("lin","exp","uni")),
         predicted = factor(model, levels = c("lin","exp","uni")))

# strategy names
strategies <- c(r_all = "all",r_1 = "random-1", r_3 = "random-3", r_5 = "random-5", 
  r_bracket = "bracketed", r_old = "oldest", r_young = "youngest")

res_min <- res %>% filter(min ==1) 

class_metrics <- metric_set(accuracy, mcc, kap, precision,sensitivity, specificity, f_meas)

# calculate metrics with bootstrapping
res_boot <- 
  pbmcapply::pbmclapply(1:1000, function(i) {
    res_min %>% 
      filter(type == "l1") %>% 
      group_by(strategy, type, prop) %>% 
      slice_sample(n = 3000, replace= TRUE) %>% 
      class_metrics(truth = truth, estimate = predicted) %>% 
      mutate(sim = i)
  }, mc.cores = 15) %>% 
    bind_rows()


res_boot %>% 
  group_by(strategy, type, prop,.metric) %>% 
  filter(.metric == "accuracy") %>% 
  summarise(
    .se = sd(.estimate),
    .lo = quantile(.estimate, 0.025),
    .hi = quantile(.estimate, 0.975),
    .estimate = mean(.estimate),
    .groups = "drop"
  ) %>% 
  mutate(strategy_name = strategies[strategy] %>% factor(levels = strategies)) %>% 
  ggplot(aes(x = prop, y = .estimate, col = strategy_name)) +
  geom_point() +
  geom_line() +
  #geom_linerange(aes(ymin = .estimate - 1.96 * .se, ymax = .estimate + 1.96 * .se), alpha = 0.4) +
  geom_linerange(aes(ymin = .lo, ymax = .hi), alpha = 0.4) +
  #facet_wrap(~.metric) +
  labs(title = "Accuracy of sampling stategies",
       x = "Proportion of sites subsampled",
       y = "Accuracy",
       col = "Strategy") +
  scale_x_continuous(breaks = c(0.5, 0.75, 1)) +
  scale_y_continuous(breaks = seq(0,1,0.1)) +
  scale_color_brewer(palette = "Dark2") +
  theme(plot.title = element_text(hjust = 0.5))

#ggsave("figures/accuracy_2025_05_30_2.pdf", width = 6, height = 5)



# bias
pad = 0.15
res %>% 
  filter(!is.na(bias) & type == "l1") %>% 
  group_by(strategy, type, prop, true) %>%
  summarise(
    mean_bias = mean(bias),
    sd_bias = sd(bias),
    lo = quantile(bias, 0.025),
    hi = quantile(bias, 0.975),
  ) %>% 
  mutate(strategy = strategies[strategy] %>% factor(levels = rev(strategies))) %>% 
  ggplot(aes(y = strategy, x = mean_bias, col = factor(prop))) +
  #geom_point() +
  geom_point(position = position_nudge(y = pad), data = ~ .x %>% filter(prop == 0.5)) +
  geom_point(position = position_nudge(y = 0), data = ~ .x %>% filter(prop == 0.75)) +
  geom_point(position = position_nudge(y = -pad), data = ~ .x %>% filter(prop == 1)) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), 
                 position = position_nudge(y = pad),
                 height = 0.1, data = ~ .x %>% filter(prop == 0.5),alpha = 0.5) +

  geom_errorbarh(aes(xmin = lo, xmax = hi), 
                 position = position_nudge(y = 0),
                 height = 0.1, data = ~ .x %>% filter(prop == 0.75),alpha = 0.5) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), 
                 position = position_nudge(y = -pad),
                 height = 0.1, data = ~ .x %>% filter(prop == 1),alpha = 0.5) +
  #geom_errorbarh(aes(xmin = mean_bias - 1*sd_bias, xmax = mean_bias + 1*sd_bias), height = 0.1) +
  facet_wrap(~true, scales = "free", labeller = as_labeller(c(exp = "exponential", lin = "linear"))) +
  geom_vline(xintercept = 0, lty = "dashed") +
  labs(x = "Bias in distributional parameter (rate or slope)",
       y = "Strategy",
       col = "Proportion of sites subsampled") +
  theme(legend.position = "bottom") +
  scale_color_brewer(palette = "Set1") +
  scale_x_continuous(
    labels = function(x) format(x, scientific = TRUE, digits = 2)
  )+
  theme(
    plot.title = element_text(hjust = 0.5),
    panel.spacing = unit(1, "cm"),
    strip.background = element_rect(
      colour = NA,           # Remove border
      fill = NA     # Custom background color
    ),
    strip.text = element_text(
      colour = "black",      # Text color
      face = "plain" ,
      size = 12
    )
  ) 
  # scale_x_continuous(
  #   labels = function(x) x * 10e4,
  #   name = expression("Values (" %*% 10^-4 * ")")
  # )

#ggsave("figures/bias_2025_05_30_2.pdf", width = 7, height = 5)


#--- unambiguous
res %>% 
  filter(ose == 1) %>% 
  group_by(prop,strategy,type,sim,truth) %>%
  mutate(p_unique_ose = !any(predicted != truth[1])) %>% 
  group_by(type,prop,strategy) %>% 
  summarise(p = mean(p_unique_ose),
            se = sqrt(p*(1-p)/n())) %>% 
  filter(type == "l1") %>% 
  mutate(strategy = strategies[strategy] %>% factor(levels = (strategies))) %>% 
  ggplot(aes(x = prop, y = p, col = strategy)) +
  geom_point() +
  geom_line() +
  geom_errorbar(aes(ymin = p - 1.96 * se, ymax = p + 1.96 * se), width = 0.01, alpha = 0.4) +
  scale_x_continuous(breaks = c(0.5, 0.75, 1)) +
  labs(title = "Unambiguous selection of growth model",
       x = "Proportion of sites subsampled",
       y = "Proportion of simulations") +
  scale_color_brewer(palette = "Dark2") +
  scale_y_continuous(breaks = seq(0,1,0.1)) +
  theme(plot.title = element_text(hjust = 0.5))

#ggsave("figures/unambiguous_2025_05_30_2.pdf", width = 6, height = 5)



