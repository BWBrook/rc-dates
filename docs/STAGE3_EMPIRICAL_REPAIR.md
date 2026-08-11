# Stage 3: common-membership empirical repair

## Scientific question

After removing reservoir-sensitive materials and giving every curve method the same determinations,
how strongly do post hoc within-site retention rules deform the descriptive calendar-age distribution
relative to the remaining differences among SPD, FD and KDE summaries?

This is a descriptive benchmark, not a demographic reconstruction or a test of prospective field
sampling. All curves are normalised to unit mass, so the estimand is relative temporal shape rather
than total activity or event intensity.

## Frozen primary reference set

The tracked 976-date, 116-site AustArch reference table remains the source. The primary empirical
set is constructed as follows, in order:

1. Retain records classified as terrestrial and made from charcoal or wood:
   `Charcoal`, `Charcoal_from_hearth`, `Scattered_charcoal`, `Wood_charcoal`,
   `Carbonised_wood`, `Burnt_wood`, `Charred_wood` or `Wood`.
2. Exclude all shell and human-bone determinations. Shell requires unavailable local reservoir
   corrections; human bone can carry dietary reservoir effects and raises separate governance
   concerns.
3. Calibrate every retained determination with SHCal20 and compute its full-posterior median,
   weighted mean and posterior mass inside 651--11,650 cal BP.
4. Keep determinations whose posterior median lies inside the one-bandwidth buffered interval
   751--11,550 cal BP and whose posterior mass inside the analysis window is at least 0.80.
5. Keep sites with at least five eligible determinations, so every retained site can enter the
   random-5 comparison without replacement.

Records marked `Y` or `U` in the source occupation-relation field are retained in the primary set.
The curves are explicitly descriptions of the database benchmark, not inferred occupation events;
a `Y`-only result is reported as a strict sensitivity.

## Retention rules and stochastic design

The retained rules remain all dates, random-1, random-5, oldest, youngest and bracketed, at site-
treatment proportions 0.50 and 1.00. Treated-site subsets are paired across rules. Random rules and
half-site treatment use 1,000 deterministic realisations from master seed 1234; full-site extrema
and bracketed retention are deterministic.

Oldest and youngest are defined post hoc from the calibrated posterior median, matching the
simulation's chronological definition. Median ties are broken by the posterior weighted mean in
the same direction and then by stable ascending ADSID. The number of ties resolved at each stage is
reported.

## Common curve construction

Every method within a scenario receives exactly the same selected determinations on the same
100-year calendar bins:

- SPD: calibrated posterior mass, followed by the existing 100-year centred running mean;
- FD: calibrated posterior medians in 100-year bins, with the existing two-bin display smoothing;
- KDE: Gaussian kernels centred on calibrated posterior medians, bandwidth 100 years, reflected at
  both analysis-window boundaries.

Each curve is normalised to unit mass after construction. Figure 1 shows the common-membership
all-date curves. Figure 2 shows each method's density difference from its own all-date baseline,
which makes retention deformation visible without conflating it with the baseline difference among
methods.

## Quantitative comparison and claim gate

The primary distance is total variation,

$$
D_{\mathrm{TV}}(p,q)=\frac{1}{2}\sum_t |p_t-q_t|.
$$

For each scenario realisation:

1. the retention distance is computed separately for SPD, FD and KDE against that method's all-date
   baseline;
2. the method distance is computed for all three method pairs on the same selected dates; and
3. the conservative contrast is the smallest retention distance minus the largest between-method
   distance.

A scenario may be described as having a larger retention effect than method effect only if the
2.5th percentile of this conservative contrast is greater than zero. For a deterministic scenario,
the exact contrast must be greater than zero. Otherwise the manuscript reports the distances but
makes no ordering claim. There is no pooled visual or majority-vote gate: conclusions are attached
to named scenarios.

## Prespecified sensitivities

The full headline oldest and youngest scenarios are checked under:

- calendar buffers of 0, 100 and 200 years at posterior-mass threshold 0.80;
- posterior-mass thresholds of 0.50, 0.80 and 0.95 at the 100-year buffer;
- reflected KDE bandwidths of 50, 100 and 200 years;
- an unreflected KDE at bandwidth 100 years; and
- the occupation-related `Y`-only subset.

The primary directional conclusion is called robust only if its sign and scenario-level claim gate
are unchanged across these sensitivities. Sensitivity results are reported rather than tuned.

## Acceptance gates

Evidence is accepted only if:

- the frozen filter produces finite, uniquely identified dates and at least five dates per site;
- all three methods have exactly identical effective membership within every realisation;
- every curve is finite, non-negative and unit mass;
- treated-site counts and selected-date bounds match each scenario contract;
- deterministic scenarios reproduce exactly and stochastic scenarios contain 1,000 realisations;
- total-variation distances are finite and lie in `[0, 1]`;
- source, input, seed, runtime, package, figure and summary fingerprints are recorded; and
- a second read of the emitted summaries reproduces the named claim-gate decisions.

## Deliberately deferred

Site-history generators, matched-total-assay simulations, weaker regional signals, the all-rule
realised-observation-noise rerun, data-release governance and final repository packaging are not
part of this tranche. Manuscript-wide prose is revised only after the empirical evidence passes the
gates above.
