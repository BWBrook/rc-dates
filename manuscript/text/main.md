# Within-site date-retention rules can distort radiocarbon “dates-as-data” inference

## Abstract

Radiocarbon “dates-as-data” analyses can be distorted before any curve is drawn or model is fitted: the dates retained from each archaeological site define the regional evidence base. We quantified this dataset-formation effect using an empirical benchmark and controlled simulations. The benchmark comprised 540 terrestrial charcoal or wood determinations from 68 well-replicated AustArch sites. Summed probability distributions (SPDs), frequency distributions (FDs) and kernel density estimates (KDEs) used identical dates. We then simulated exchangeable regional ages under uniform, linear and exponential trajectories in both temporal directions, imposed eight post hoc retention rules at three site-treatment proportions, and fitted signed regional event-age-density models directly to calibrated posteriors. In the empirical benchmark, reducing every site to its oldest determination, youngest determination or both extrema produced total-variation deformation larger than the differences among the three summary methods; this ordering did not hold generally for half-site or random retention. In 1,000 simulation replicates per cell, full-site oldest retention selected a decreasing direction and full-site youngest retention an increasing direction under every generating truth. The adverse one-sided rule reversed every non-uniform truth, while either rule manufactured an exponential trend under uniform truth. Random retention preserved the direction of all strong monotonic truths, although sparse retention reduced linear-versus-exponential family recovery. Bracketed retention protected direction but not functional-family recovery. The simulation isolates post hoc selection among exchangeable dates: it does not represent prospective field sampling, occupation histories or site endpoints, and its one-sided rules were not tested under realised observation noise. Dates-as-data studies should therefore audit site contributions and retention logic, and test whether conclusions survive plausible alternative dataset-formation rules.

## Keywords

radiocarbon dating; palaeodemography; dataset formation; date retention; order statistics; model selection; simulation.

## 1. Introduction

### 1.1 Radiocarbon dates as population evidence

Archaeologists aggregate radiocarbon determinations to investigate temporal change in human activity and, by proxy, population size [@rick1987DatesDataExamination; @robinson2019SpatiotemporalDynamicsPrehistoric; @ulm1996RadiocarbonCulturalChronologies; @williams2016RadiometricDatesAre]. This “dates-as-data” logic has been applied to European Neolithic demography [@shennan2013RegionalPopulationCollapse; @timpson2014ReconstructingRegionalPopulation], Holocene Sahul [@johnson2011ReconstructingDynamicsAncient; @williams2012UseSummedRadiocarbon; @williams2013NewPopulationCurve], other regional sequences [@brown2019MaoriPopulationGrowth; @chaput2016RadiocarbonDatesEstimates; @porcic2016DemographyEarlyNeolithic] and continental syntheses [e.g., @wirtz2024MulticentennialCyclesContinental]. Common representations include summed probability distributions (SPDs), frequency distributions (FDs), kernel density estimates (KDEs) and explicit population or occupancy models [@bronkramsey2017MethodsSummarizingRadiocarbon; @brown2015FilterDarklyPopulation; @crema2022StatisticalInferencePrehistoric; @mendez-quiros2023ModelingLongtermHuman; @michczynska2007FrequencyDistributionRadiocarbon; @robinson2019SpatiotemporalDynamicsPrehistoric].

The inferential link is conditional. Differential preservation produces a “pull of the recent” [@bluhm2019ValidationGlobalModel; @surovell2009CorrectingTemporalFrequency], research effort varies through space and time, and inter-settlement sampling intensity can affect regional reconstructions [@park2026RescalingRadiocarbonData]. Calibration, binning, smoothing and model choice add further sensitivity [@carleton2021SumThingsAre; @crema2022StatisticalInferencePrehistoric]. These problems have motivated taphonomic adjustments, binning protocols, simulation tests and models that treat dated events as count or point processes rather than smoothed densities [@crema2025BayesianAlternativeAoristic; @denavascues2025AnalysisAbundanceRadiocarbon; @hanna2025SumPoissonApproach; @heaton2025NewApproachRadiocarbon; @peros2010PrehistoricDemographyNorth; @williams2015HoloceneDemographicChanges]. Yet all such methods inherit the set of determinations supplied to them.

### 1.2 Within-site retention as dataset formation

Regional databases contain unequal numbers of dates per site. This imbalance reflects budgets, preservation, research priorities and the contexts selected for dating [@codding2024CountsRadiocarbondatedArchaeological]. In legacy databases, sparse site contributions are common: the original AustArch compilation reported one determination at 53% of sites and fewer than four at 86% [@williams2014AustArchDatabase14C]. A regional compilation may also retain only selected determinations from a better-dated site. If this post hoc retention repeatedly favours older or younger dates, it can alter the regional age distribution before taphonomy, calibration or model choice is considered.

Prospective context selection and retrospective date retention are related but not equivalent. A basal dated context need not be the oldest determination after calibration; neither is the oldest retained determination necessarily an occupation onset. Site histories impose stratigraphy, duration and temporal dependence that a regional set of exchangeable dates does not contain. We therefore ask a deliberately narrower question: how strongly can named post hoc retention rules alter descriptive calendar-age densities and selection among simple regional event-age-density models?

We combine a common-membership empirical benchmark from AustArch [@williams2014AustArchDatabase14C] with simulations in which the generating trajectory is known. The empirical analysis compares retention-induced deformation with the remaining differences among SPD, FD and KDE summaries when every method receives the same dates. The simulation extends earlier one-direction tests to signed linear and exponential alternatives, so a retained sample can support an increasing or decreasing trajectory. The primary criterion is a marginal likelihood fitted directly to calibrated posteriors [@timpson2021DirectlyModellingPopulation], with an expected-log-density score as a secondary sensitivity. The goal is not to reconstruct Australian population history or prescribe a field-sampling minimum, but to identify a dataset-formation mechanism that dates-as-data studies can audit.

## 2. Methods

Detailed filters, equations and reproducibility records are given in the Supplementary Information.

### 2.1 Empirical benchmark

We began with a tracked Holocene AustArch reference containing 976 determinations from 116 sites [@williams2014AustArchDatabase14C]. For the primary empirical benchmark, we retained terrestrial charcoal or wood records coded as occupation-related (`Y`) or of uncertain occupation relation (`U`), excluding shell and human bone. All retained dates were calibrated with SHCal20 [@hogg2020SHCal20SouthernHemisphere]. We then required a full-posterior median within 751–11,550 calendar years before present (cal BP; present = AD 1950), at least 0.80 posterior mass within the 651–11,650 cal BP analysis window, and at least five eligible determinations per site. The resulting common-membership set contained 540 dates from 68 sites: 181 coded `Y` and 359 coded `U`. It is a deliberately well-replicated database benchmark, not an unbiased sample of Sahul occupation.

We constructed three unit-integral summaries on common 100-year bins. The SPD summed each calibrated posterior within the analysis window and applied a centred 100-year running mean. The FD binned posterior medians and received a two-bin running mean for display. The KDE placed Gaussian kernels of 100-year bandwidth on the same medians, reflecting kernels at both window boundaries. Every method received the same determinations in every realisation. The curves describe relative temporal shape; their normalisation removes information about the number of retained dates.

### 2.2 Empirical retention experiment

We compared all dates with five post hoc retention rules: random-1, random-5, oldest, youngest and bracketed (oldest plus youngest). A rule was applied to 50% or 100% of sites; untreated sites retained all eligible dates. Random retention and random selection of half the sites used 1,000 deterministic-seed realisations. Full-site oldest, youngest and bracketed scenarios were deterministic. Extrema were defined by calibrated posterior median, with posterior mean and then stable record identifier breaking ties.

Figure 2 plots the difference between each retained curve and that method's all-date baseline. Pointwise 2.5th–97.5th percentiles summarise conditional realisations, not uncertainty over the archive or population history. We quantified curve separation using total variation,

$$
D_{\mathrm{TV}}(p,q)=\frac{1}{2}\sum_t |p_t-q_t|.
$$

For each realisation, a conservative contrast subtracted the largest between-method distance on the retained dates from the smallest method-specific retention distance to its all-date baseline. Retention deformation was declared larger than method variation only when the contrast was positive (or its 2.5th percentile was positive for stochastic scenarios). Mean-cal-BP shifts measured temporal displacement; positive values are older. Prespecified sensitivities varied the calendar buffer, posterior-mass threshold, KDE bandwidth and boundary correction, and restricted the benchmark to `Y` records.

### 2.3 Signed simulation

The simulation used the 976-date, 116-site tracked reference—not the narrower empirical display set—to estimate a truncated negative-binomial distribution of dates per site and a regression of logged reported error on radiocarbon age. Each replicate contained 116 site labels with at least five dates per site. Calendar ages were drawn independently from one of five unit-integral regional event-age densities over 651–11,650 cal BP: uniform, linear increase, linear decrease, exponential increase or exponential decrease. Each non-uniform truth had a ten-fold end-to-end ratio. We defined the common effect

$$
\theta=\log\!\left\{\frac{f(651)}{f(11650)}\right\},
$$

so that increasing, decreasing and uniform truths had $\theta=\log(10)$, $-\log(10)$ and 0, respectively. Site identity determined only the number of dates and subsequent retention; it did not impose occupation windows, stratigraphy or within-site dependence.

The calibration-curve-mean observation model mapped each calendar age to the SHCal20 expected conventional age, simulated a reported one-sigma error from the fitted age–error relation, and recalibrated it. We imposed eight rules: all dates; random-1, random-2, random-3 and random-5; oldest; youngest; and bracketed. Extrema were selected by posterior median. Each rule treated 50%, 75% or 100% of sites, with untreated sites retaining all dates. We generated 1,000 replicates for every truth-by-proportion combination using common-random-number pairing.

We fitted signed uniform, linear and exponential families directly to the retained calibrated posteriors. For date $i$, the primary marginal log likelihood was

$$
\ell_i=\log\int f(x\mid\theta)p_i(x)\,dx,
$$

where $p_i(x)$ is the calibrated posterior. Minimum Akaike Information Criterion (AIC) selected the family [@akaike1974NewLookStatistical]. A separate $\ell^2$ analysis used the posterior expectation of the model log density; we call this an expected-log-density scoring sensitivity, not an ordinary likelihood analysis. Primary outcomes were truth-consistent signed-state selection (uniform for a uniform truth, otherwise the correct direction), generating-family selection and the fitted generating-family value of $\theta$. Figure 4 reports means and central 95% replicate ranges; triangles flag cells in which at least half of generating-family estimates reached a prespecified optimisation bound. With 1,000 replicates, the largest possible Monte Carlo standard error for a selection rate is 0.016.

A previously prespecified paired sensitivity compared calibration-curve-mean and realised conventional ages for the earlier uniform-and-increasing design and only the all-dates and random-1, random-3 and random-5 rules. It did not include signed decreasing truths or the one-sided and bracketed rules. Its original v1 gate and later post-unblinding v2 diagnostic are retained as qualifications rather than used to validate the new headline result.

### 2.4 Reproducibility

Analyses used R 4.5.3, rcarbon and a pinned package environment [@crema2021InferenceLargeSets; @rcoreteam2025LanguageEnvironmentStatistical]. Deterministic seeds, common-random-number pairing, atomic checkpoints, source fingerprints and checksum manifests bind the accepted simulation and empirical evidence to its generation code. Consequential tests cover density mathematics, retention semantics, pairing and artefact integrity. Data inclusion in the final archive remains conditional on licensing, sensitive-location review and Indigenous data-governance requirements.

## 3. Results

### 3.1 Empirical deformation

The all-date SPD, FD and KDE had similar broad temporal structure but were not identical (Fig. 1). Their pairwise total-variation distances were 0.046 for SPD–KDE, 0.088 for FD–KDE and 0.101 for SPD–FD. Because all curves use the same 540 dates and integrate to one, these values isolate construction-method differences in relative shape.

Retention deformation exceeded between-method variation only for the three deterministic full-site boundary scenarios (Fig. 2). Retaining each site's oldest date produced method-specific distances of 0.455–0.535 from the all-date baselines, versus a largest between-method distance of 0.263 on the retained dates; the conservative contrast was 0.193. Curve means shifted 3,133–3,136 years older. Youngest retention produced distances of 0.524–0.554, a largest between-method distance of 0.154 and a contrast of 0.370; curve means shifted 2,439–2,447 years younger. Bracketed retention produced distances of 0.279–0.326, a largest method distance of 0.195 and a contrast of 0.084; means shifted 344–352 years older.

The conservative contrast was not positive for either half-site extreme, either random rule at either treatment proportion, or half-site bracketed retention. Accordingly, the empirical benchmark does not support a general claim that retention matters more than curve construction. The full-site oldest and youngest results retained their distance ordering and shift direction in all nine prespecified configurations, including the 154-date, 24-site `Y`-only sensitivity.

### 3.2 Retention controls selected direction

The signed simulation exposed a simple full-treatment mechanism (Fig. 3). When every site was treated, oldest retention selected a decreasing direction and youngest retention an increasing direction in all 1,000 replicates under each of the five truths. Thus, when the one-sided rule opposed a non-uniform truth, it reversed the selected direction in every replicate. Under uniform truth, full oldest and youngest retention selected exponential decrease and increase, respectively, in every replicate.

This deterministic reversal was specific to full treatment. At 50% and 75%, the adverse one-sided rule did not select the opposite direction for any non-uniform replicate, although it increasingly selected uniform instead. A uniform truth was more sensitive: with 50% of sites treated, oldest and youngest retention selected a directional model in 97.3% and 97.9% of replicates, and from 75% treatment each imposed its exponential direction in every replicate. All four random rules preserved the correct direction for every non-uniform truth at every treatment proportion. Bracketed retention also preserved every non-uniform direction and selected uniform in 999 of 1,000 full-treatment uniform replicates.

Fitted effects show how the imposed direction arose (Fig. 4). Under all dates, mean generating-family estimates were close to the true $|\theta|=2.303$: 2.359 and -2.328 for linear increase and decrease, and 2.309 and -2.303 for exponential increase and decrease. Random-5 remained close to these values. At full treatment, adverse oldest or youngest retention reversed the sign of the fitted generating-family effect; the concordant one-sided rule drove effects to the optimisation boundary. Bracketed retention preserved sign but attenuated the mean effect to approximately $|\theta|=0.72$ under linear truth and 1.34–1.38 under exponential truth.

### 3.3 Direction can survive loss of functional family

Generating-family selection separated directional fidelity from discrimination between linear and exponential change (Fig. 5). Under all dates, selection rates were 0.974–0.976 for linear truths, 0.996–0.998 for exponential truths and 0.848 for uniform truth. Across all non-uniform truths and treatment proportions, random retention preserved direction exactly while generating-family selection ranged from 0.754 to 0.995 as dates were discarded.

Bracketed retention illustrates the distinction. At full treatment it selected the generating family in every exponential replicate and in none of the linear replicates, despite preserving the direction of every non-uniform truth. It therefore converted linear trajectories into exponential selections rather than erasing their direction. The primary marginal-likelihood and expected-log-density analyses agreed on the selected signed state in 99.75% of 120,000 paired selections, including every deterministic headline result.

In the earlier paired realised-observation-noise sensitivity, accuracy changed by -1.5 to +0.8 percentage points and support by -1.9 to +0.9 points for the all-date and random rules tested. Nevertheless, the prespecified v1 screen remains failed (15 of 18 gates passed). A separately labelled post-unblinding v2 diagnostic passed its three difference-aligned gates. Neither result evaluates realised-noise behaviour of oldest, youngest or bracketed retention.

## 4. Discussion

### 4.1 Order-statistic distortion under exchangeability

Post hoc within-site retention can determine the temporal direction selected from regional radiocarbon data. In the exchangeable-date simulation, selecting the oldest observation from every site constructed a distribution of maxima; selecting the youngest constructed a distribution of minima. The fitted regional trajectory then followed that order-statistic filter even when the generating density was uniform or changed in the opposite direction. Treating more sites did not dilute the bias: full application made it deterministic under this strong-signal design.

The empirical benchmark shows a parallel descriptive deformation without establishing the same historical mechanism. Full-site oldest and youngest retention shifted all three common-membership curves by millennia, and bracketed retention produced a smaller but still gate-passing change. These extrema were chosen after calibration from a curated database. They are not stratigraphic onset or termination estimates, and the normalised curves are not reconstructions of Sahul population history. Together, the analyses show that the regional distribution can depend on which completed determinations each site contributes; only the simulation identifies the order-statistic mechanism.

### 4.2 Consequences for dates-as-data analysis

Methods that handle calibration uncertainty more explicitly cannot recover information removed or directionally filtered during dataset formation. Fitting population densities to calibrated posteriors avoids treating an SPD, FD or KDE as the likelihood, but it does not make the retained dates representative. Conversely, the empirical comparison does not show that curve construction is unimportant. The retention-versus-method ordering held only for full-site oldest, youngest and bracketed scenarios; it failed the prespecified gate for half-site and random retention.

This dataset-formation layer complements debates about taphonomy, binning, rescaling and population models [@bronkramsey2017MethodsSummarizingRadiocarbon; @carleton2021SumThingsAre; @crema2022StatisticalInferencePrehistoric; @riris2018DatesDataRevisited; @surovell2007NoteUseTemporal; @williams2012UseSummedRadiocarbon]. Recent count-based and Bayesian approaches improve inference once a dataset is assembled [@arthur2023ProbabilisticReconstructionPaleodemographic; @crema2025BayesianAlternativeAoristic; @denavascues2025AnalysisAbundanceRadiocarbon; @hanna2025SumPoissonApproach; @heaton2025NewApproachRadiocarbon]. Our results argue for an earlier audit: analysts should report per-site contributions, identify rules that determined inclusion, and repeat key analyses under plausible alternatives. Sparse sites need not be discarded, but their material, period, region and selection history should be examined rather than assumed to average out [@bird2022P3k14cSyntheticGlobal; @loftus2019ArchaeologicalRadiocarbonDatabase; @lucarini2020MedAfriCarbonRadiocarbonDatabase; @saktura2023SahulArchGeochronologicalDatabase].

Random retention is useful here as a representative benchmark, not a field protocol. Multiple random dates preserved the direction of the strong monotonic truths, while sparse random retention progressively weakened family selection. This experiment does not compare stratified context selection, and it cannot identify a universal minimum number or optimal spacing of determinations. For new data collection, archaeological context and the study's chronological target remain primary. For compiled data, the practical recommendation is narrower: make site contribution and retention logic visible enough to test.

### 4.3 Limitations and next tests

The simulation was designed to expose a mechanism, not approximate every archaeological archive. Its non-uniform truths changed ten-fold across a fixed Holocene window; weaker, non-monotonic or spatially heterogeneous signals may behave differently. Dates were independent regional draws assigned to exchangeable site labels, with site counts and reported errors parameterised from one filtered database. There were no occupation durations, stratigraphic constraints, material offsets or context-selection processes. Retention rules changed the total number of observations, so this analysis does not separate compositional selection from sample-size loss with a matched-total-date control.

The calibration-curve-mean observation model omitted realised conventional-age variation. The earlier paired sensitivity suggests small point shifts for all-date and random rules, but its prespecified screen did not pass every gate and it did not include the one-sided rules. Calibration-curve errors were not modelled as correlated. Some fitted effects reached optimisation bounds, so their extreme magnitudes are censored. The empirical analysis is conditioned on well-replicated terrestrial charcoal or wood dates, includes uncertain occupation-relation records, normalises away sample size and selects extrema after observing calibrated posteriors.

These limits define the next scientific tests if they become decision-relevant: weaker and non-monotonic truths, matched retained counts, explicit site-duration and stratigraphic generators, and realised-noise checks for one-sided retention. The present evidence establishes only the narrower result: under exchangeability, systematic post hoc retention can manufacture, exaggerate or reverse a regional temporal trend.

### 4.4 Conclusions

Dates-as-data inference begins with dataset formation. In this study, full-site one-sided retention controlled the selected temporal direction, bracketed retention preserved direction but could replace linear with exponential change, and sparse random retention reduced family discrimination without reversing strong trends. The empirical ordering was narrower but clear for full-site extrema. Regional analyses should therefore audit per-site contributions and retention rules before interpreting a curve or fitted trajectory, and report the residual uncertainty when those rules cannot be reconstructed.

## Data availability

For peer review, supporting code, permitted data and accepted evidence will be supplied through a private repository link: [PRIVATE_REVIEW_LINK]. The associated reserved DOI is [RESERVED_DOI]. The final archive will include the pinned R environment, scientific tests, accepted simulation and empirical evidence, and provenance snapshots; source and filtered data will be included only where licensing, sensitive-location and Indigenous data-governance conditions permit. Instructions will distinguish fast verification from optional high-volume reruns. The repository record will be made public after acceptance, subject to the same conditions.

## Competing interests

None to declare.

## Declaration of generative AI and AI-assisted technologies in manuscript preparation

During preparation of this work, the authors used OpenAI ChatGPT/Codex to assist with manuscript-source conversion, citation tokenisation, reproducible-workflow checks and language-editing suggestions. The authors reviewed and edited all outputs and take full responsibility for the content of the article.

## References
