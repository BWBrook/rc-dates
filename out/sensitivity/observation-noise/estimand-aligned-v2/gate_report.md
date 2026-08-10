# Estimand-aligned v2 observation-noise gate report

Status: **PASS**

The v2 family is defined after unblinding and contains only paired difference estimands.
Accuracy and OSE use two-sided simultaneous max-deviation intervals; boundary uses a
one-sided simultaneous maximum-positive-deviation upper bound.

| Gate | Pass | Pooled max | Truth max | Pooled margin | Truth margin |
|---|---:|---:|---:|---:|---:|
| accuracy_difference | TRUE | 0.02033333 | 0.030 | 0.009666667 | 0.020 |
| ose_difference | TRUE | 0.02400000 | 0.038 | 0.006000000 | 0.012 |
| boundary_difference | TRUE | 0.00800000 | 0.008 | 0.002000000 | 0.002 |
