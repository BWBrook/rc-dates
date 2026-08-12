# Supplementary Information

## S1. Common-membership AustArch benchmark

### S1.1 Source data and filtering

AustArch is a continental radiocarbon and luminescence-age compilation for Australia [@williams2014AustArchDataset; @williams2014AustArchDatabase14C]. The source object is the Archaeology Data Service (ADS) collection 1661, DOI `10.5284/1027216`, file `Austarch_1-3_and_IDASQ_28Nov13-1.csv`. A fresh ADS download on 12 August 2026 contained 5,522 rows: 5,044 labelled `Radiocarbon` and 478 assigned to other dating methods. This reconciles the published count of 5,044 radiocarbon determinations with the larger deposited multi-method table.

The project began from a working derivative of the same-named ADS file, introduced to the repository on 2 April 2025 and edited on 3 April 2025. It has SHA-256 `7e8e053389830e8ec56657feb1bbbfdd5dba5f9ed8bc13d7f0634f1aa66d28cb` and 5,288 rows after the header, of which 17 are blank; the 5,271 nonblank records include 4,828 radiocarbon determinations from 1,704 named radiocarbon sites. Relative to the current ADS file, this derivative omits 251 record identifiers and changes fields in 239 retained records, principally depth and coordinate fields. The historical rationale for every pre-analysis edit is not recoverable, so the derivative is not described as a pristine deposited release. This provenance issue does not alter the analysed reference: every one of its 976 record identifiers occurs in the ADS download, with matching conventional ages, errors, methods, laboratory codes and analysis-status fields; site, site-type and material labels differ only by replacement of spaces with underscores. The tracked 976-row reference has SHA-256 `2f1b5ccc40038f9e30bce643d57191c545c98448266fcaab3b11c9a33059c70a`.

Initial screening retained conventional or accelerator-mass-spectrometry radiocarbon determinations with reported ages and one-sigma errors, removed records flagged as erroneous or unrelated to human activity, and restricted conventional ages to 500–20,000 14C yr BP. The resulting tracked reference contains 976 determinations from 116 sites, each with at least five dates.

The primary empirical display analysis then applied a narrower, prespecified common-membership filter. We retained records classified as terrestrial whose material was `Charcoal`, `Charcoal_from_hearth`, `Scattered_charcoal`, `Wood_charcoal`, `Carbonised_wood`, `Burnt_wood`, `Charred_wood` or `Wood`. Shell determinations were excluded because appropriate local reservoir corrections were unavailable, and human bone was excluded because dietary reservoir effects and data-governance considerations require separate treatment. Records coded `Y` (occupation-related) or `U` (uncertain) were retained. All were calibrated with SHCal20 [@hogg2020SHCal20SouthernHemisphere].

For each posterior, we recorded its median, weighted mean and probability mass within 651–11,650 cal BP. A determination was calendar-eligible when its median lay within the one-bandwidth-buffered interval 751–11,550 cal BP and at least 0.80 of its posterior mass lay inside the analysis window. Sites then required at least five eligible dates. The flow was:

| Filter stage | Dates | Sites |
|---|---:|---:|
| Tracked filtered reference | 976 | 116 |
| Terrestrial charcoal or wood | 737 | 106 |
| Common calendar membership | 645 | 106 |
| At least five eligible dates per site | 540 | 68 |

The final 540 dates comprised 497 `Charcoal`, 28 `Charcoal_from_hearth`, 10 `Scattered_charcoal`, four `Wood_charcoal` and one `Charred_wood` record. Occupation-relation codes were `Y` for 181 dates and `U` for 359. The benchmark is deliberately conditioned on well-replicated sites and is not an unbiased sample of Sahul occupation.

### S1.2 Curve construction

Every curve method received exactly the same selected determinations on the same 100-year bins. The summed probability distribution (SPD) used posterior probability mass within the analysis window, followed by a centred 100-year running mean with unsmoothed edge cells. The frequency distribution (FD) assigned each posterior median to a 100-year bin and applied a centred two-bin running mean for display. The kernel density estimate (KDE) placed Gaussian kernels of 100-year bandwidth on the same posterior medians and reflected them at 651 and 11,650 cal BP. Each resulting curve was normalised to unit integral. Thus, the estimand is relative temporal shape, not total date abundance.

The all-date pairwise total-variation distances were 0.0459 for SPD–KDE, 0.0884 for FD–KDE and 0.1015 for SPD–FD. These values compare construction methods on identical dates; they are not sampling-error estimates.

### S1.3 Retention rules and realisations

We compared all dates with random-1, random-5, oldest, youngest and bracketed (oldest plus youngest) retention. A rule treated either 34 of 68 sites (50%) or all 68 sites (100%); untreated sites retained every eligible date. Treated-site subsets were paired across rules. Random retention and half-site treatment used 1,000 realisations from master seed 1234. Full-site oldest, youngest and bracketed retention were deterministic.

Oldest and youngest refer to the greatest and least calibrated posterior median within a site. Median ties were resolved by the posterior weighted mean in the same direction and then by ascending AustArch record identifier. No site had an oldest-median tie. Two sites had youngest ties at both the median and mean stages, so the stable identifier supplied the final decision. These extrema were defined after calibration and should not be interpreted as site onsets or terminations.

For each method and realisation, we calculated total variation from its all-date baseline,

$$
D_{\mathrm{TV}}(p,q)=\frac{1}{2}\sum_t |p_t-q_t|,
$$

and all three between-method distances on the retained dates. The conservative ordering contrast was

$$
C=\min_m D_{\mathrm{TV}}(p_{m,\mathrm{retained}},p_{m,\mathrm{all}})
-\max_{m\ne m'}D_{\mathrm{TV}}(p_{m,\mathrm{retained}},p_{m',\mathrm{retained}}).
$$

A deterministic scenario passed the retention-versus-method gate when $C>0$; a stochastic scenario required the 2.5th percentile of $C$ to exceed zero. Temporal displacement was the change in mean cal BP, using bin midpoints. An older result required positive shifts for all methods (positive 2.5th percentiles when stochastic); a younger result required negative shifts (negative 97.5th percentiles).

Only the three deterministic full-site boundary scenarios passed the ordering gate:

| Rule | Retention $D_{\mathrm{TV}}$ across methods | Largest method $D_{\mathrm{TV}}$ | $C$ | Mean-cal-BP shift across methods |
|---|---:|---:|---:|---:|
| Oldest | 0.455–0.535 | 0.263 | +0.193 | +3,133 to +3,136 yr |
| Youngest | 0.524–0.554 | 0.154 | +0.370 | -2,447 to -2,439 yr |
| Bracketed | 0.279–0.326 | 0.195 | +0.084 | +344 to +352 yr |

Neither half-site extremum, either random rule at either proportion, nor half-site bracketed retention passed. Pointwise 2.5th–97.5th percentile envelopes in Figure 2 therefore describe conditional retention realisations only; they are not confidence intervals over sites, archive inclusion, calibration uncertainty or population history.

### S1.4 Frozen sensitivity suite

The nine configurations were prespecified for oldest and youngest retention. Before the bracketed extension was run, the same configurations and all-nine decision gate were frozen for that rule. The suite comprised calendar buffers of 0, 100 and 200 years; posterior-mass thresholds of 0.50, 0.80 and 0.95; reflected KDE bandwidths of 50, 100 and 200 years; an unreflected 100-year KDE; and the occupation-related `Y`-only subset. The configurations retained 496–576 dates from 62–73 sites, except the `Y`-only set, which retained 154 dates from 24 sites. Every configuration preserved a positive ordering contrast and older shift for oldest retention, and a positive contrast and younger shift for youngest retention. Bracketed retention shifted older in all nine configurations and had a positive ordering contrast in eight, ranging from +0.060 to +0.089; the `Y`-only contrast was -0.054. Oldest and youngest are therefore sensitivity-robust within this suite, whereas bracketed retention is reported as a primary-specification result.

## S2. Signed simulation study

### S2.1 Empirical site-count and reported-error models

Simulation parameterisation used the tracked 976-date, 116-site reference rather than the narrower display benchmark. The empirical number of dates per site had mean 8.414, median 7 and range 5–33. A negative-binomial distribution left-truncated at five dates was fitted by maximum likelihood. In the `fitdistrplus` parameterisation before conditioning, the estimates were `size = 0.0002577` and `mu = 0.001448`; after conditioning at five, the fitted mean was 8.412 (Supplementary Fig. S2). Each synthetic replicate drew 116 site counts from this distribution.

Reported uncertainty was modelled as

$$
\log(\sigma_{\mathrm{quoted}})=4.0992+8.5643\times10^{-5}\,\mathrm{CRA}+\varepsilon,
$$

with residual standard deviation 0.4719 and $R^2=0.170$. This regression reproduces the broad age–error relation; it is not a laboratory-performance model.

### S2.2 Generating truths and observation model

Five unit-integral regional event-age densities were defined over 651–11,650 cal BP: uniform, linear increase, linear decrease, exponential increase and exponential decrease (Supplementary Fig. S1). “Increase” means greater density at the recent, low-cal-BP boundary. Every non-uniform truth had a ten-fold endpoint ratio, summarised on the common scale

$$
\theta=\log\!\left\{\frac{f(651)}{f(11650)}\right\}.
$$

Thus $\theta=\log(10)$ for increasing truths, $-\log(10)$ for decreasing truths and 0 for uniform truth. Linear slopes and exponential rates were signed, so both fitted families could represent either temporal direction.

For each replicate, all calendar ages were independent draws from the regional truth. Site labels determined only how many dates were grouped together and which observations were subsequently retained. They did not impose occupation windows, durations, stratigraphic order or within-site dependence.

The primary observation model mapped each calendar age to the central conventional radiocarbon age expected from SHCal20 (`ccCRA` from `rcarbon::uncalibrate()`), drew a quoted one-sigma error from the empirical regression and recalibrated the central age. It therefore propagated posterior width and calibration-curve structure but conditioned on the calibration-curve-mean conventional age.

### S2.3 Retention design and stochastic control

Eight rules were evaluated: all dates; random-1, random-2, random-3 and random-5 without replacement; oldest and youngest by calibrated posterior median; and bracketed retention of both extrema. Each rule treated 50%, 75% or 100% of the 116 sites, with untreated sites retaining all dates. All counts were at least five, so every random rule was feasible. We generated 1,000 replicates for each of five truths at each of three proportions. Replicate $i$ used deterministic seed $1234+i$ under `L'Ecuyer-CMRG`, with common random numbers preserving paired comparisons. Random-2 was drawn on an isolated RNG state so that adding it could not change dates, errors, treated sites or any previously implemented rule.

The accepted matrix comprises 15 scenario files, 15,000 complete data-generating replicates and 720,000 fitted-result rows. The all-dates result for a truth is exactly identical across the three treatment files.

### S2.4 Model fitting and selection

The fitted regional density $f(x\mid\theta)$ was evaluated against each calibrated posterior $p_i(x)$. The primary marginal log likelihood was

$$
\ell_i^1=\log\int f(x\mid\theta)p_i(x)\,dx.
$$

The secondary score was

$$
\ell_i^2=\int\log\!\{f(x\mid\theta)\}p_i(x)\,dx.
$$

Calibration used a uniform calendar-age prior. Each calibrated posterior was restricted to the strict interior of the 651–11,650 cal BP analysis window and renormalised before fitting. Conditional on posterior mass within this window, the first criterion is the observed-data marginal log likelihood up to a date-specific additive constant independent of $\theta$; these constants cancel in within-dataset AIC comparisons [@akaike1974NewLookStatistical; @timpson2021DirectlyModellingPopulation]. The second is the posterior expected log density; we applied the same parameter penalty as a scoring sensitivity but do not describe it as a marginal likelihood or its criterion as AIC. Integrals were finite sums on the calibrated calendar grids.

Signed uniform, linear and exponential candidates were fitted by bounded numerical optimisation. Minimum AIC under $\ell^1$ supplied the primary selected family. For bracketed retention, the oldest and youngest observations retained from a site are dependent; the product criterion treats their posteriors under working independence. Bracketed AIC and family-selection results therefore describe this analysis workflow rather than likelihood support under a joint paired-order-statistic model. We recorded the signed state, generating-family selection, direction reversal, fitted generating-family $\theta$ and boundary frequency. Truth-consistent state means uniform selection under uniform truth and the correct direction under a non-uniform truth, irrespective of functional family. Central 95% ranges in Figure 4 are empirical replicate quantiles, not confidence intervals for a historical parameter.

### S2.5 Primary signed results

The full-site results below report “family; state” percentages under the primary marginal likelihood. For uniform truth, state is uniform; for non-uniform truth, state is the correct direction. An adverse one-sided rule is oldest for increasing truths and youngest for decreasing truths.

| Truth | All dates | Oldest | Youngest | Bracketed |
|---|---:|---:|---:|---:|
| Uniform | 84.8; 84.8 | 0.0; 0.0 | 0.0; 0.0 | 99.9; 99.9 |
| Linear increase | 97.6; 100 | 19.5; 0.0 | 0.0; 100 | 0.0; 100 |
| Exponential increase | 99.6; 100 | 41.6; 0.0 | 100; 100 | 100; 100 |
| Linear decrease | 97.4; 100 | 0.0; 100 | 16.8; 0.0 | 0.0; 100 |
| Exponential decrease | 99.8; 100 | 100; 100 | 43.3; 0.0 | 100; 100 |

Full oldest retention selected a decreasing signed state and full youngest retention an increasing state in every replicate under every truth. When the rule opposed a non-uniform truth, the directional-reversal rate was 1.000. Under uniform truth, oldest and youngest selected the corresponding exponential direction in all replicates. Concordant one-sided retention frequently drove fitted effects to their bounds. Under the working-independence criterion, bracketed retention preserved direction but selected exponential in every full-treatment linear-truth replicate.

The full-treatment reversal should not be extrapolated to partial treatment. At proportions 0.50 and 0.75, no non-uniform replicate selected the opposite direction under the adverse rule; at 0.75, uniform was instead selected in 18.1% of linear-increase and 21.2% of linear-decrease replicates. Uniform truth was affected sooner: half-site oldest and youngest retention selected a directional model in 97.3% and 97.9% of replicates.

Across random-1, random-2, random-3 and random-5, all four non-uniform truths and all three treatment proportions, direction selection was 1.000. Generating-family selection ranged from 0.754 to 0.995 as information was discarded. The $\ell^1$ and $\ell^2$ analyses agreed on the selected signed state in 99.75% of 120,000 paired selections, including all deterministic headline cells.

## S3. Earlier realised-observation-noise sensitivity

The signed revision retained, but did not extend, an earlier paired sensitivity based on uniform, linear-increase and exponential-increase truths. It covered all dates, random-1, random-3 and random-5 at the three treatment proportions, with 1,000 pairs per truth-by-proportion cell. Each pair shared the latent ages, site treatment, retained observations and structural random-number state. In the realised arm,

$$
r_{\mathrm{CRA}}=\operatorname{round}\!\left[
ccCRA+Z\sqrt{ccError^2+\sigma_{\mathrm{quoted}}^2}
\right],\qquad Z\sim N(0,1),
$$

where `ccError` is SHCal20 curve error and $\sigma_{\mathrm{quoted}}$ is the simulated laboratory error. Realised ages were recalibrated. Observations with zero posterior mass inside the strict likelihood window were dropped and recorded. Oldest, youngest and bracketed retention were not included.

This earlier analysis also recorded unique generating-family selection under a prespecified parsimony rule. Models whose total criterion difference from the minimum did not exceed the estimated standard error of their pointwise differences were treated as similarly supported, after which only the lowest-dimensional supported model or models were retained. A replicate counted as unique support only when the generating family alone remained. This outcome is retained for audit continuity but is not used for the signed headline.

The prespecified v1 screen used 5,000 paired cluster-bootstrap resamples and simultaneous 95% max-deviation intervals over marginal arms and paired differences. It passed 15 of 18 gates and therefore remains **FAIL**. Observed accuracy differences ranged from -0.015 to +0.008 and unique-support differences from -0.019 to +0.009. The pooled v1 maximum absolute endpoints were 0.0373 for accuracy and 0.049 for support against 0.03 margins; truth-specific endpoints were 0.047 and 0.063 against 0.05 margins. None of 72 realised-minus-mean boundary-rate differences was positive, but the symmetric simultaneous upper endpoint was 0.019 against a threshold below 0.01.

After v1 was inspected, an explicitly post-unblinding v2 diagnostic recalibrated intervals over only the paired-difference estimands implicated by those failures. Its pooled/truth-specific endpoints were 0.0203/0.030 for accuracy, 0.024/0.038 for unique support and 0.008/0.008 for the one-sided boundary metric, within the respective 0.03, 0.05 and 0.01 margins. Two independent 50,000-resample seeds gave identical critical widths, endpoints and decisions. v2 supports describing the tested point shifts as small; it neither replaces the v1 failure nor validates the untested one-sided rules. No 2,000-pair extension was run.

## S4. Reproducibility and archive status

All accepted empirical and signed-simulation evidence was generated under R 4.5.3 in one digest-recorded container image. The signed simulation has one metadata record per scenario, exact common-random-number checks, and SHA-256 manifests covering raw checkpoints and machine-readable summaries. The empirical evidence similarly records filters, effective counts, curve distances, tie resolution, sensitivity decisions, figures, source fingerprints and checksums. Fast verification separates execution from artefact integrity: `make test` runs the consequential scientific tests, while each evidence directory's `SHA256SUMS` file is checked separately with `sha256sum --check --strict SHA256SUMS`. Optional high-volume reruns use the documented container and resumable atomic checkpoints.

The author-anonymized supplementary review archive contains the active code, pinned environment, focused tests, synthetic simulation artefacts, aggregate empirical evidence and provenance snapshots. It excludes raw and record-level AustArch data, including source site identities, coordinates, laboratory identifiers and human-remains records. A citable repository record containing code, synthetic artefacts and permitted aggregate evidence will be made public no later than publication. Any release of source or record-level archaeological data remains conditional on licensing, sensitive-location review and Indigenous data-governance requirements.

## Supplementary Figures

### Signed data-generating densities

![](../figures/SI_data_generating_distributions.png){#fig-si-s1 width=95%}

**Supplementary Figure S1.** The five unit-normalised regional event-age densities used in the signed simulation. Increasing trajectories have greater density at the recent (low-cal-BP) boundary; decreasing trajectories have greater density at the old boundary. Each non-uniform trajectory has a ten-fold end-to-end ratio, $|\theta|=\log(10)$, over 651–11,650 cal BP. Colour and line type jointly identify the truth.

### Empirical dates-per-site model

![](../figures/SI_dates_per_site_in_austarch_holocene.png){#fig-si-s2 width=75%}

**Supplementary Figure S2.** Empirical and fitted distribution of radiocarbon determinations per site in the tracked 976-date, 116-site reference. Points show the observed frequency; the line is the fitted negative-binomial distribution left-truncated at five dates. The empirical and fitted conditional means are 8.414 and 8.412 dates per site, respectively; the empirical range is 5–33.

## References

<div id="refs"></div>
