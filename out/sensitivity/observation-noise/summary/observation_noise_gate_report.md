# Paired observation-noise sensitivity gate report

Status: **FAIL**

Bootstrap: paired cluster bootstrap by simulation replicate; 5000 resamples; simultaneous 95% max-deviation intervals.

A failed gate is not silently passed: inspect the corresponding CSV and consider a focused rerun, full expansion, or precision extension.

| Gate | Pass | Observed | Threshold | Details |
|---|---:|---:|---:|---|
| accuracy_difference_ci | FALSE | 4.700000e-02 | 0.05 | Simultaneous paired arm-difference interval. |
| ose_support_difference_ci | FALSE | 6.300000e-02 | 0.05 | Simultaneous paired arm-difference interval. |
| minimum_aic_discordance | TRUE | 5.200000e-02 | 0.10 | Upper simultaneous bound for paired selected-model discordance. |
| ose_set_discordance | TRUE | 8.200000e-02 | 0.10 | Upper simultaneous bound for paired OSE-set discordance. |
| prop1_random3_random5_accuracy | TRUE | 9.123333e-01 | 0.90 |  |
| prop1_truth_specific_random3_random5_accuracy | TRUE | 8.630000e-01 | 0.85 | Truth-specific safeguard against a pooled-accuracy mask. |
| prop1_truth_specific_random3_random5_lower | TRUE | 8.310000e-01 | 0.80 | Truth-specific simultaneous lower-bound safeguard. |
| prop1_r_3_advantage_over_r1 | TRUE | 4.166667e-02 | 0.00 | Direct paired realised-arm contrast, target strategy minus random-1. |
| prop1_r_5_advantage_over_r1 | TRUE | 7.600000e-02 | 0.00 | Direct paired realised-arm contrast, target strategy minus random-1. |
| l1_l2_qualitative_consistency | TRUE | 0.000000e+00 | 0.00 | Opposite, statistically resolved L1/L2 directions are checked for observation-arm effects, realised strategy contrasts, and bias. |
| noisy_absolute_mean_bias | TRUE | 1.485085e-02 | 0.05 | Signed mean relative bias: absolute point estimate <5%; interval within +/-10%. |
| paired_bias_shift | TRUE | 1.313491e-02 | 0.10 |  |
| rmse_relative | TRUE | 1.870993e-02 | 0.15 | Entire simultaneous interval must remain within 0.85-1.15. |
| boundary_hit_increase | FALSE | 1.900000e-02 | 0.01 | Upper simultaneous bound for generating-parameter boundary hits. |
| strict_window_drop_rate | TRUE | 2.671764e-05 | 0.01 | Upper simultaneous bound for the likelihood's strict-window drop rate. |
| strict_window_drop_increase | TRUE | 2.671764e-05 | 0.01 | Upper simultaneous bound for the arm increase in strict-window drops. |
| zero_mass_rate | TRUE | 1.087015e-05 | 0.01 | Inclusive-window mass diagnostic; upper simultaneous bound. |
| low_mass_arm_increase | TRUE | 2.636422e-03 | 0.01 | Inclusive-window mass diagnostic; upper simultaneous bound. |
