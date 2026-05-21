# Supplementary Information

This Supplementary Information contains the reproducibility-level methods detail, supporting simulation figures, and likelihood-sensitivity note for the main manuscript.

## Supplementary Methods

### S1. AustArch data analysis

#### S1.1 Study context and empirical reference set

Our aim was to quantify how decisions on the within-site temporal distribution of radiocarbon dates, whether deliberate or inadvertent, distort regional “dates-as-data” inference. To anchor the analysis in realistic site structures we parameterised the study from AustArch [@williams2014AustArchDatabase14C], a continental-scale compilation for Sahul (5,044 determinations from 1,748 sites). To reduce long-term taphonomic contrast while retaining a large regional dataset, we constrained the analysis to Holocene data through three phases of selection.

1. Initial screening. We retained radiocarbon determinations (both conventional and AMS) with reported ages and one-sigma errors; records flagged as erroneous or unrelated to human activity were removed. Ages were initially restricted to 100–20,000 $^{14}$C yr BP so that all possible Holocene observations lay within the SHCal20 or Marine20 calibration ranges [@heaton2020Marine20TheMarineRadiocarbon; @hogg2020SHCal20SouthernHemisphere; @ramsey2024DevelopmentINTCALDatabase; @reimer2020INTCAL20NorthernHemisphere].

2. Material and context filtering. To reduce laboratory and reservoir idiosyncrasies we accepted charcoal/wood, human bone collagen, and well-attested freshwater or marine shells from clearly anthropogenic contexts (e.g., rock shelters, middens, hearths, earth mounds). Ambiguous contexts and “unusable” designations were excluded. Duplicate laboratory codes indexing the same context/material were combined when compatible ($\chi^2$ test) using rcarbon::combine.

3. Holocene restriction and site eligibility. Dates were first calibrated and then truncated to the Holocene window 11,650-651 cal BP; the upper bound avoids near-modern boundary effects. We kept only sites contributing five or more valid Holocene determinations, yielding a final reference set of 976 determinations from 116 sites (median 7.5 dates per site). This threshold excludes sparsely dated sites, including those with fewer than three determinations, from the empirical baseline because they do not contain enough within-site chronological information to benchmark what a sampling rule has removed. Their consequences are instead assessed experimentally by down-sampling the better-dated sites into sparse-site analogues, including random-1, random-3, oldest, youngest, and bracketed scenarios. Weighted-mean calibrated ages were computed for descriptive plots only; all inference used the full calibrated posteriors.

All processing was done in R 4.5.3 [@rcoreteam2025LanguageEnvironmentStatistical], using the tidyverse for data handling and rcarbon [@crema2021InferenceLargeSets] for calibration. Random seeds were set at the start of each Monte Carlo block for reproducibility.

#### S1.2 Baseline demographic curves

The curated AustArch set defines an “all-dates” baseline (Fig. 1) for comparison with sub-sampling scenarios (Fig. 2). We constructed three familiar summaries on a common 100-yr calendar grid:

1. Summed probability distribution (SPD). Calibrated posterior grids were summed and then smoothed with a 100-yr running mean.

2. Frequency distribution (FD). Simple counts in 100-yr bins were computed using each date’s median calibrated age.

3. Kernel density estimate (KDE). A Gaussian KDE (bandwidth 100 yr) was centred on each median calibrated age.

Each curve was normalised to unit area; for joint display the SPD and KDE were re-binned to the FD grid to avoid visual aliasing. These curves provide descriptive context only and do not enter the likelihood-based inference.

#### S1.3 Within-site sub-sampling experiments

To mimic common field and budget constraints, we imposed five within-site rules on the AustArch reference set: i) random-1: one random determination per treated site; ii) random-5: five random determinations per treated site (see Fig. 2); iii) oldest: the determination with the earliest median calibrated age; iv) youngest: the determination with the latest median calibrated age; v) bracketed: the pair consisting of the oldest and youngest determinations.

Each rule was applied at two intensities: 50% of sites treated (with the remainder contributing all dates) or 100% treated; the all-dates baseline (Fig. 1) is equivalent to 0% in this framing. For stochastic rules we ran 1,000 Monte Carlo realisations per scenario. For deterministic rules, randomness enters only via the 50% site subset; we also generated 1,000 draws of that subset.

A single realisation comprised: i) sampling the treated sites (if intensity < 100%); ii) selecting date indices within treated sites according to the rule; iii) appending all dates from untreated sites; iv) calibrating determinations with SHCal20 (terrestrial) or Marine20 (shells) (for the purposes of simulation no regional marine offset, or $\Delta R$, was applied in calibrating marine dates); and v) computing SPD, FD, and KDE curves and re-normalising to unit area. For every rule × intensity combination we calculated, at each calendar bin, the mean and 2.5th/97.5th percentiles across realisations. Discrepancy from the all-dates baseline SPD was summarised using `rcarbon::compare_spds`. Figures plot the baseline together with the Monte Carlo mean and 95% interval.

These empirical experiments are used diagnostically to show how within-site rules deform regional aggregates, rather than as demographic reconstructions.

### S2. Simulation study

#### S2.1 Sample-size and age-error models based on empirical data

To ensure our simulations reflected realistic archaeological dating scenarios, we used the cleaned and filtered AustArch dataset (section 2.1) to parameterise key aspects of radiocarbon sampling. We fitted a truncated negative binomial distribution (minimum 5 dates per site) to the distribution of sample sizes across archaeological sites, capturing the typical variation in dating intensity between sites. We also performed linear regression of logged standard errors against median calibrated radiocarbon ages to model how measurement uncertainty varies with sample age.

#### S2.2 Growth models, synthetic-data generation, and sampling strategies

For the Holocene-restricted date range (11650-651 cal BP), we defined three population growth models as unit normalised, truncated probability densities: constant (uniform), linearly increasing, and exponentially increasing. Unit normalisation completely determines the uniform density, and it constrains the truncated linear and exponential distributions to one-parameter models which can be uniquely characterised by specifying the proportionate increase in population over the restricted date range.

Each synthetic radiocarbon dataset was characterised by the choice of growth model. For the linear and exponential models, we fixed their distributions by specifying a 10-fold population increase, close to the Holocene increase found by @johnson2011ReconstructingDynamicsAncient. To simulate a dataset, we drew a set of site sample sizes from the negative binomial sample-size model, and calibrated ages from the probability distribution of the specified growth model. To ensure median calibrated dates would lie in the restricted date range, we uncalibrated these ages, simulated standard errors from the age–error model, then recalibrated the dates using rcarbon.

We evaluated seven sampling strategies across three levels of bias intensity (50%, 75%, or 100% of sites). The strategies comprised: all dates (using every available radiocarbon determination), random-1, random-3, and random-5 (selecting dates randomly without replacement from each site), oldest (selecting the oldest date from each site), youngest, and bracketed (selecting both oldest and youngest dates from each site). Sites not selected for the biased sampling strategy (i.e., at the 50% and 75% intensities) contributed all their dates.

#### S2.3 Likelihood calculation, model fitting and model selection

Rather than using smoothed representations of the data such as kernel densities or regressions that do not respect unit normalisation, we fitted the normalised population growth distributions directly to the calibrated dates. Given the distributional nature of the calibrated dates, we considered two possible definitions for the pointwise log-likelihood $\ell_i$:

$$
\ell_i^1 = \log \int f(x \mid \theta)\, p_i(x)\, dx
$$

and

$$
\ell_i^2 = \int \log\!\bigl(f(x \mid \theta)\bigr)\, p_i(x)\, dx
$$

where $f(x \mid \theta)$ is the probability density of the growth model, $p_i(x)$ is the posterior probability density of the calibrated age, and $\theta$ is the distributional parameter to be estimated. The $\ell^1$ approach is more commonly used for response-error distributions, while $\ell^2$ is often used to compute information criteria [@gelman2013BayesianDataAnalysis]. In practice, the calibrated age distribution $p_i(x)$ is represented as a discrete set of values, and the integrals are replaced by finite sums. The $\ell^2$ approach is equivalent to fitting models directly to SPD curves, where each discrete probability value under the growth model is weighted by its corresponding SPD density and the total number of discrete points.

We fitted all models by maximum likelihood estimation using each definition of the log likelihood. We then computed the Akaike Information Criterion ($\mathrm{AIC} = -2\ell + 2k$), where $\ell = \sum_{i=1}^N \ell_i$ is the total log likelihood of the fitted growth model and $k$ is the number of estimated parameters [@akaike1974NewLookStatistical], and applied the modified one-standard-error (OSE) rule to identify models that have comparable AIC estimates while accounting explicitly for estimation uncertainty [@yates2021ParsimoniousModelSelection]. Specifically, the OSE rule selects models with $\Delta \mathrm{AIC} \le \mathrm{SE}(\Delta \mathrm{AIC})$, where $\Delta \mathrm{AIC}$ is the difference from the minimum AIC and $\mathrm{SE}(\Delta \mathrm{AIC})$ is the standard error of the pointwise $\Delta \mathrm{AIC}$ values across sites.

@timpson2021DirectlyModellingPopulation propose a likelihood equivalent to our $\ell^1$, although they use BIC rather than AIC for model comparison. They argue against using SPD curves as input data for models; our results show that equivalent outcomes are obtained when the contributing points are appropriately weighted (our $\ell^2$).

#### S2.4 Simulation design and performance evaluation

We generated 1,000 simulated datasets for each of the three population models (uniform, linear, exponential). Each dataset was then subsampled using all sampling strategies and bias intensities, resulting in 63,000 total analysis scenarios. For every subsampled dataset, we fitted all three candidate models using both likelihood approaches and applied both minimum AIC and OSE model selection rules.

We evaluated sampling strategy performance using three metrics: i) *accuracy* – the proportion of simulations correctly identifying the true population model, ii) *parameter bias* – the difference between estimated and true model parameters for linear and exponential models, and iii) *evidential strength* – the proportion of simulations where the OSE rule selected only the true model without ambiguity. Bootstrap resampling (1,000 iterations) was used to generate confidence intervals for accuracy estimates.

### S3. Reproducibility

All code, random seeds, and intermediate results (site subsets, index matrices, re-binned summaries, simulation outputs) are included in the submitted de-identified review package, enabling full reproducibility checks without re-running calibration. On acceptance, these materials will be made publicly available through a GitHub repository and archived on Zenodo with a DOI. High-volume simulation runs were parallelised on institutional high-performance computing.

## Supplementary Figures

### Data-generating distributions

![](../figures/SI_data_generating_distributions.png){#fig-si-s1 width=95%}

**Supplementary Figure S1.** Data-generating distributions and example simulated data used in the simulation study. Panel A shows the three unit-normalised growth models over the Holocene analysis window: uniform, linear, and exponential. Panel B shows example simulated radiocarbon-date distributions generated from those models after applying the empirical site-count, per-site sample-size, and age-error structure used in the simulations.

### Empirical dates-per-site model

![](../figures/SI_dates_per_site_in_austarch_holocene.png){#fig-si-s2 width=95%}

**Supplementary Figure S2.** Empirical and fitted distribution of radiocarbon determinations per eligible AustArch site. Points show the observed number of dates per site after Holocene filtering; the line shows the truncated negative-binomial model used to generate per-site sample sizes in the simulation study.

### Likelihood-sensitivity check

The main manuscript reports the simulation results for the $\ell^1$ likelihood because it is the more familiar response-error likelihood and gave the same qualitative conclusions as the $\ell^2$ likelihood. The $\ell^2$ runs were used as a sensitivity check for the accuracy, parameter-bias, and evidential-strength results shown in the main-text simulation figures. In each case, the same broad ranking was recovered: all-dates and span-preserving random-*n* strategies performed best; oldest, youngest, and random-1 strategies performed worst; and the bracketed rule was intermediate.

## References

<div id="refs"></div>
