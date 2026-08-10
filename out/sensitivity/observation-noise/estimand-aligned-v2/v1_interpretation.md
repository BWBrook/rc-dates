# v1 interpretation retained

The original v1 summary remains **FAIL (15 of 18 gates passed)**.
Accuracy difference: pooled endpoint 0.0373333 against ±0.03; truth endpoint 0.047 against ±0.05; point range -0.015 to 0.008.
OSE difference: pooled endpoint 0.049 against ±0.03; truth endpoint 0.063 against ±0.05; point range -0.019 to 0.009.
Boundary difference: full-family upper bound 0.019 against <0.01; point range -0.005 to 0.
For each metric, v1 calibrated one full-family width over marginal curve-mean and
realised arms as well as paired differences (288 cells for accuracy and OSE; 216
for boundary). The v1 accuracy table displayed 0.05 even though pooled rows used
±0.03; its CSV and the separate endpoints above are required to interpret the FAIL.
v2 is a separately labelled post-unblinding diagnostic over difference estimands
only. It does not replace or retroactively pass the original v1 decision.
