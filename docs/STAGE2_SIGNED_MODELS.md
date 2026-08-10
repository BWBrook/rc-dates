# Stage 2: signed-model headline audit

## Scientific question

Does the apparent loss of model recovery under oldest- and youngest-date retention persist when the
fitted model space can represent change in either temporal direction?

This is a bounded reanalysis of **post hoc date retention among exchangeable regional-age draws**.
It does not represent prospective context selection, occupation histories, site onset or site
termination.

## Frozen design

- Analysis window: 651–11,650 cal BP.
- Observation model: calibration-curve-mean conventional ages with simulated reported uncertainty.
- Generating truths: uniform, linear increase, linear decrease, exponential increase and exponential
  decrease.
- Effect magnitude: a 10-fold end-to-end density ratio for every non-uniform truth.
- Direction convention: increase means greater density at the recent, low-cal-BP bound; decrease
  means greater density at the old, high-cal-BP bound.
- Fitted families: uniform, signed linear and signed exponential.
- Retention rules: all dates, random-1, random-2, random-3, random-5, oldest, youngest and bracketed.
- Site-treatment proportions: 0.50, 0.75 and 1.00; untreated sites retain all dates.
- Replicates: 1,000 per truth-by-proportion scenario.
- Seed: replicate `i` uses `1234 + i` under `L'Ecuyer-CMRG`. The same replicate seed is used across
  all truths and treatment proportions.
- Primary inference: the marginal likelihood labelled `l1` in the implementation.
- Secondary sensitivity: the expected-log-density score labelled `l2`; it is not described as an
  ordinary likelihood or AIC analysis.

The common effect scale is

$$
\theta = \log\left\{\frac{f(651)}{f(11650)}\right\}.
$$

Thus $\theta=\log(10)$ for increasing truths, $\theta=-\log(10)$ for decreasing truths and
$\theta=0$ for the uniform truth. Linear and exponential parameter bias can therefore be compared
without mixing their native units.

Random-2 is drawn on an isolated deterministic RNG state after the original structural draws. It
cannot change the generated dates, quoted errors, treated sites or any of the seven previously
implemented retention rules.

## Evidence reported regardless of outcome

1. Truth-specific confusion matrices over the five selected states: uniform, linear increase,
   linear decrease, exponential increase and exponential decrease.
2. Generating-family and direction selection rates.
3. Direction-reversal rates for non-uniform truths.
4. Bias in $\theta$ for the fitted generating family.
5. Optimiser-boundary frequencies for both signed fitted families.
6. Paired contrasts against the all-dates result using common replicate identifiers.
7. Results for both `l1` and `l2`, with `l1` primary.

## Acceptance and decision gates

The production evidence is accepted only if all of the following hold before interpretation:

- signed densities are non-negative, integrate to one and attain the specified endpoint ratios;
- zero-valued signed parameters reproduce the uniform density;
- positive-valued density and score calculations reproduce the former positive-only formulas within
  numerical tolerance;
- every scenario contains exactly 1,000 complete result blocks;
- checkpoints, metadata, source hashes, input hash, lockfile hash, container image and R 4.5.3 agree;
- all-dates results are exactly identical across the three treatment-proportion files within each
  truth;
- all 15 scenarios were generated from the frozen design in one inspected runtime.

Claims are then calibrated to the emitted evidence:

- “deterministic” is used only for an observed selection rate of exactly 1.000 across all 1,000
  replicates;
- “directional reversal” is used only for non-uniform truths selected in the opposite direction, and
  its truth-specific rate is reported;
- loss of family recovery is described only where the paired contrast against all dates is negative;
- if signed alternatives replace the former uniform/boundary collapse with coherent opposite-direction
  fits, the result is reframed as retention-induced directional distortion rather than destruction of
  model recovery;
- if the headline pattern attenuates materially or varies by family or direction, the manuscript is
  narrowed before any broader simulation expansion.

## Deliberately deferred

Weaker signals, globally matched-total-date controls, site-history generators, the all-strategy
realised-observation-noise rerun, empirical-data repair and final manuscript figures are outside this
tranche. They proceed only after this headline audit fixes the interpretation of the central result.
