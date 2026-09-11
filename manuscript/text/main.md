# Within-site date-retention rules can distort radiocarbon “dates-as-data” inference

## Abstract

Choosing which radiocarbon dates a site contributes can change the regional history inferred from them. We tested this effect using 540 charcoal or wood determinations from 68 AustArch sites and simulations of constant, increasing and decreasing regional dating activity. Keeping every site's oldest date shifted the empirical summed-probability curve's mean about 3,100 years older; keeping one random date per site shifted it about 100 years, with a central 95% range of −433 to +594 years. Oldest and youngest retention changed temporal shape more than differences among three summary methods across nine sensitivity configurations. In simulations, retaining only the oldest date from each site produced inferred decline, and retaining only the youngest produced growth, in all 1,000 replicates of each tested history. Either rule converted a constant history into apparent exponential change and reversed a history changing in the opposing direction. Random retention preserved the direction of the simulated ten-fold changes, although fewer dates reduced discrimination between linear and exponential trajectories. Retaining both extrema preserved direction but converted every linear trajectory to an exponential selection when applied to all sites. The simulations used independent regional dates and omitted realised measurement noise; they do not model occupation histories. Regional dates-as-data analyses should report how each site's dates were selected and test whether their conclusions survive plausible alternative retention rules.

## Keywords

radiocarbon dating; palaeodemography; dataset formation; date retention; order statistics; model selection; simulation.

## 1. Introduction

### 1.1 Radiocarbon dates as population evidence

Archaeologists aggregate radiocarbon determinations to investigate temporal change in human activity and, by proxy, population size [@rick1987DatesDataExamination; @robinson2019SpatiotemporalDynamicsPrehistoric; @ulm1996RadiocarbonCulturalChronologies; @williams2016RadiometricDatesAre]. This “dates-as-data” logic has been applied to European Neolithic demography [@shennan2013RegionalPopulationCollapse; @timpson2014ReconstructingRegionalPopulation], Holocene Sahul [@johnson2011ReconstructingDynamicsAncient; @williams2012UseSummedRadiocarbon; @williams2013NewPopulationCurve], other regional sequences [@brown2019MaoriPopulationGrowth; @chaput2016RadiocarbonDatesEstimates; @porcic2016DemographyEarlyNeolithic] and continental syntheses [e.g., @wirtz2024MulticentennialCyclesContinental]. Common representations include summed probability distributions (SPDs), frequency distributions (FDs), kernel density estimates (KDEs) and explicit population or occupancy models [@bronkramsey2017MethodsSummarizingRadiocarbon; @brown2015FilterDarklyPopulation; @crema2022StatisticalInferencePrehistoric; @mendez-quiros2023ModelingLongtermHuman; @michczynska2007FrequencyDistributionRadiocarbon; @robinson2019SpatiotemporalDynamicsPrehistoric].

The inferential link is conditional. Differential preservation produces a “pull of the recent” [@bluhm2019ValidationGlobalModel; @surovell2009CorrectingTemporalFrequency], research effort varies through space and time, and inter-settlement sampling intensity can affect regional reconstructions [@park2026RescalingRadiocarbonData]. Calibration, binning, smoothing and model choice add further sensitivity [@carleton2021SumThingsAre; @crema2022StatisticalInferencePrehistoric]. These problems have motivated taphonomic adjustments, binning protocols, simulation tests and models that treat dated events as count or point processes rather than smoothed densities [@crema2025BayesianAlternativeAoristic; @denavascues2025AnalysisAbundanceRadiocarbon; @hanna2025SumPoissonApproach; @heaton2025NewApproachRadiocarbon; @peros2010PrehistoricDemographyNorth; @williams2015HoloceneDemographicChanges]. Yet all such methods inherit the set of determinations supplied to them.

### 1.2 Within-site retention as dataset formation

Regional databases contain unequal numbers of dates per site. This imbalance reflects budgets, preservation, research priorities and the contexts selected for dating [@codding2024CountsRadiocarbondatedArchaeological]. In the original AustArch compilation, 53% of sites had one determination and 86% had fewer than four [@williams2014AustArchDatabase14C]. These counts raise a question that date totals alone cannot answer: how was a site's contribution chosen? A single determination may be the only sample dated, or it may be the only date retained from a larger set. Both selection histories matter when that contribution is used as evidence of regional activity.

Here we isolate the second process: selection among completed determinations. Repeatedly retaining a site's oldest or youngest date changes which part of its age distribution enters the regional dataset. Choosing a basal context before dating is a different process, and an extreme calibrated determination is not necessarily an occupation onset or termination. Our experiment tests post hoc date retention, providing a mechanism that can be examined separately from those archaeological decisions.

We combine an AustArch benchmark [@williams2014AustArchDataset; @williams2014AustArchDatabase14C] with simulations in which the regional trajectory is known. The empirical analysis compares oldest and youngest retention with one randomly retained date per site, and asks whether retention changes temporal shape more than choosing among SPD, FD and KDE summaries on identical dates. The simulations then test whether retention can create an apparent trend from a constant history or reverse the direction of a changing one.

## 2. Methods

Detailed filters, equations and reproducibility records are given in the Supplementary Information.

### 2.1 Empirical benchmark

We began with a tracked 976-determination, 116-site Holocene reference derived from the Archaeology Data Service AustArch file `Austarch_1-3_and_IDASQ_28Nov13-1.csv`; the project derivative and transformation history are documented in the Supplementary Information and repository [@williams2014AustArchDataset; @williams2014AustArchDatabase14C]. For the primary empirical benchmark, we retained terrestrial charcoal or wood records coded as occupation-related (`Y`) or of uncertain occupation relation (`U`), excluding shell and human bone. All retained dates were calibrated with SHCal20 [@hogg2020SHCal20SouthernHemisphere]. We then required a full-posterior median within 751–11,550 calendar years before present (cal BP; present = AD 1950), at least 0.80 posterior mass within the 651–11,650 cal BP analysis window, and at least five eligible determinations per site. The resulting common-membership set contained 540 dates from 68 sites: 181 coded `Y` and 359 coded `U`. It is a deliberately well-replicated database benchmark, not an unbiased sample of Sahul occupation.

We constructed three unit-integral summaries on common 100-year bins. The SPD summed each calibrated posterior within the analysis window and applied a centred 100-year running mean. The FD binned posterior medians and received a two-bin running mean for display. The KDE placed Gaussian kernels of 100-year bandwidth on the same medians, reflecting kernels at both window boundaries. Every method received the same determinations in every realisation. The curves describe relative temporal shape; their normalisation removes information about the number of retained dates.

### 2.2 Empirical retention experiment

We compared all dates with five post hoc retention rules: random-1, random-5, oldest, youngest and bracketed (oldest plus youngest). A rule was applied to 50% or 100% of sites; untreated sites retained all eligible dates. Random retention and random selection of half the sites used 1,000 deterministic-seed realisations. Full-site oldest, youngest and bracketed scenarios were deterministic. Extrema were defined by calibrated posterior median, with posterior mean and then stable record identifier breaking ties.

Figure 2 plots the difference between each retained curve and that method's all-date baseline. Pointwise 2.5th–97.5th percentiles summarise conditional realisations, not uncertainty over the archive or population history. We quantified curve separation using total variation,

$$
D_{\mathrm{TV}}(p,q)=\frac{1}{2}\sum_t |p_t-q_t|.
$$

Here $p_t$ and $q_t$ are the normalised probability masses in bin $t$, so $D_{\mathrm{TV}}$ ranges from zero for identical curves to one for non-overlapping curves. For each realisation, a conservative contrast subtracted the largest between-method distance on the retained dates from the smallest method-specific retention distance to its all-date baseline. Retention deformation was declared larger than method variation only when the contrast was positive (or its 2.5th percentile was positive for stochastic scenarios). Mean-cal-BP shifts measured temporal displacement; positive values are older. Prespecified sensitivities varied the calendar buffer, posterior-mass threshold, KDE bandwidth and boundary correction, and restricted the benchmark to `Y` records.

### 2.3 Simulation of constant and changing histories

The simulation used the 976-date, 116-site reference to estimate a truncated negative-binomial distribution of dates per site and a regression of logged reported error on radiocarbon age. Each replicate contained 116 site labels with at least five dates per site. Calendar ages were drawn independently from one of five unit-integral regional event-age densities over 651–11,650 cal BP: uniform, linear increase, linear decrease, exponential increase or exponential decrease. Each non-uniform truth had a ten-fold end-to-end ratio. We defined the common effect

$$
\theta=\log\!\left\{\frac{f(651)}{f(11650)}\right\}.
$$

Here increase means greater density towards the recent, low-cal-BP boundary. Increasing, decreasing and uniform truths therefore had $\theta=\log(10)$, $-\log(10)$ and 0, respectively. Site identity determined only the number of dates and subsequent retention; it did not impose occupation windows, stratigraphy or within-site dependence.

The calibration-curve-mean observation model mapped each calendar age to the SHCal20 expected conventional age, simulated a reported one-sigma error from the fitted age–error relation, and recalibrated it. We compared seven retention rules with an all-dates reference: random-1, random-2, random-3, random-5, oldest, youngest and bracketed. Extrema were selected by posterior median. Each rule treated 50%, 75% or 100% of sites, with untreated sites retaining all dates. We generated 1,000 replicates for every truth-by-proportion combination using common-random-number pairing.

We fitted three functional families—uniform, linear and exponential—directly to the retained calibrated posteriors. Both non-uniform families allowed increase or decrease. For date $i$, the primary marginal log likelihood was

$$
\ell_i=\log\int f(x\mid\theta)p_i(x)\,dx,
$$

where $p_i(x)$ is the calibrated posterior. Calibration used a uniform calendar-age prior; each posterior was restricted to the strict interior of the 651–11,650 cal BP analysis window and renormalised before fitting. Conditional on posterior mass within that window, $\ell_i$ is the observed-data marginal log likelihood up to a date-specific additive constant independent of $\theta$; these constants cancel in within-dataset AIC comparisons [@timpson2021DirectlyModellingPopulation]. Minimum Akaike Information Criterion (AIC) selected the family [@akaike1974NewLookStatistical]. This criterion treats retained dates as independent regional draws and does not model their retention probabilities. For bracketed retention, the two extrema retained from a site are dependent. The fitted product criterion treats them under working independence, so bracketed AIC and family-selection results describe the analysed workflow rather than likelihood support under a joint paired-order-statistic model. A separate $\ell^2$ analysis used the posterior expectation of the model log density; we call this an expected-log-density scoring sensitivity, not an ordinary likelihood analysis. We measured correct-direction selection (uniform for a constant history, otherwise the correct direction), selection of the generating family, and the fitted generating-family value of $\theta$. Figure 4 reports means and central 95% replicate ranges; triangles flag cells in which at least half of generating-family estimates reached a prespecified optimisation bound. With 1,000 replicates, the largest possible Monte Carlo standard error for a selection rate is 0.016.

An earlier paired sensitivity added realised conventional-age variation to constant and increasing histories for the all-dates, random-1, random-3 and random-5 rules. Its prespecified assessment and subsequent diagnostic are reported in Supplementary Section S3; oldest, youngest and bracketed retention were not included.

### 2.4 Reproducibility

Analyses used R 4.5.3, rcarbon and a pinned package environment [@crema2021InferenceLargeSets; @rcoreteam2025LanguageEnvironmentStatistical]. Deterministic seeds and common random numbers paired the simulation comparisons. Checkpoints, source fingerprints and checksum manifests link the accepted evidence to its generating code. The review archive provides code, aggregate empirical evidence and synthetic artefacts; source archaeological records are governed separately (Data availability).

OpenAI ChatGPT and Codex assisted code development, analysis review and reproducible figure pipelines, including GPT-5.6 Sol Ultra for the August 2026 revision and GPT-6 Astra for the September review. Claude Opus models (Anthropic) assisted a co-author's development and review of the analysis. The authors defined the research questions, inspected and edited the code, ran the analyses in the locked environment and verified the reported evidence.

## 3. Results

### 3.1 Empirical deformation

Retaining one date per site had very different consequences depending on how that date was chosen (Fig. 2). Keeping each site's oldest date shifted the SPD mean 3,133 years older, and keeping the youngest shifted it 2,439 years younger. Keeping one random date per site shifted the mean by +103 years across 1,000 realisations, with a central 95% range of −433 to +594 years. Each rule retained 68 dates. Their SPD total-variation distances from the 540-date baseline were 0.455 for oldest and 0.524 for youngest, compared with a random-1 mean of 0.204 (95% range 0.158–0.256). These comparisons distinguish age-based selection from retained count; the ranges describe repeated retention from this fixed benchmark.

The three all-date summaries had similar broad temporal structure (Fig. 1), with distances of 0.046 for SPD–KDE, 0.088 for FD–KDE and 0.101 for SPD–FD. When oldest or youngest retention was applied to every site, its deformation exceeded between-method differences under the prespecified conservative contrast: $C=0.193$ and $0.370$, respectively. This ordering and the direction of the mean shift held in all nine sensitivity configurations, including the 154-date, 24-site occupation-related (`Y`-only) subset.

Treating half the sites produced smaller changes. Mean distances across SPD, FD and KDE were 0.092–0.120 for oldest retention and 0.101–0.130 for youngest. The SPD mean shifts were +349 years (95% range −22 to +738) and −276 years (−673 to +137), respectively. Neither half-site rule met the retention-versus-method criterion. Nor did random retention at either treatment proportion or half-site bracketed retention.

Retaining both extrema from every site gave a smaller temporal displacement: the SPD mean shifted +352 years, within the random-1 shift range, while its distance was 0.279, above random-1's 97.5th percentile of 0.256. Displacement and shape deformation therefore tell different stories. Bracketed retention contributed 136 dates, so random-1 is not a count-matched test for this rule; the empirical experiment has no random-2 comparator. Across methods, bracketed distances were 0.279–0.326 and the conservative contrast was positive in the primary analysis ($C=0.084$), but negative in the `Y`-only sensitivity ($C=-0.054$). Its deformation exceeded method differences in eight of nine configurations.

### 3.2 Retention controls selected direction

The simulations show how retention alone can create an apparent regional trend (Fig. 3). From a constant generating history, retaining every site's oldest date selected exponential decline in all 1,000 replicates; retaining the youngest selected exponential growth in all 1,000. Across the four changing histories, these same rules always imposed decline and growth, respectively. A rule opposing the generating trend therefore reversed it in every replicate.

This complete reversal occurred when every site was treated. At 50% and 75% treatment, the opposing rule selected no reversed non-uniform trajectories, although it increasingly selected uniform instead. Constant histories were more sensitive to partial treatment: oldest and youngest retention selected a directional model in 97.3% and 97.9% of replicates at 50%, and their respective exponential directions in every replicate from 75%. All four random rules preserved the direction of every changing history at every treatment proportion. Bracketed retention also preserved those directions and selected uniform in 999 of 1,000 constant-history replicates when every site was treated.

Fitted effects show the magnitude of the distortion (Fig. 4). With all dates, mean generating-family estimates were close to the true $|\theta|=2.303$: 2.359 and -2.328 for linear increase and decrease, and 2.309 and -2.303 for exponential increase and decrease. Random-5 remained close to these values. When every site was treated, an opposing oldest or youngest rule reversed the fitted sign; a rule aligned with the generating trend drove effects to the optimisation boundary. Bracketed retention attenuated the mean effect to approximately $|\theta|=0.72$ under linear histories and 1.34–1.38 under exponential histories.

### 3.3 Correct direction does not ensure correct shape

Selecting the direction of change was easier than distinguishing linear from exponential change (Fig. 5). With all dates, generating-family selection rates were 0.974–0.976 for linear histories, 0.996–0.998 for exponential histories and 0.848 for constant histories. The last result reflects AIC's willingness to select an extra parameter for an improvement in fit; AIC does not guarantee selection of the generating model. Across the changing histories and treatment proportions, random retention preserved direction while generating-family selection ranged from 0.754 to 0.995 as dates were discarded.

Bracketed retention illustrates the distinction. Applied to every site, it selected exponential in every replicate generated from either linear or exponential histories. Thus, preserving the direction concealed complete loss of linear-family recovery. Likewise, its 999 uniform selections under a constant history cannot establish shape recovery, because the candidate set contains no U-shaped alternative. The primary marginal-likelihood and expected-log-density analyses agreed on the selected family-and-direction combination in 99.75% of 120,000 paired selections, including every all-site oldest and youngest result.

## 4. Discussion

### 4.1 Order-statistic distortion under exchangeability

The direction inferred from a regional date distribution can follow the selection rule rather than the generating history. Selecting the oldest observation from each site constructs a distribution of maxima; selecting the youngest constructs a distribution of minima. In the simulations, those filters manufactured exponential selections from constant histories and reversed trends that ran against the retained extreme.

The mechanism follows directly from order statistics. For $n$ independent, exactly observed ages with cumulative distribution $F(x)$, the oldest has cumulative distribution $F(x)^n$ and the youngest has $1-\{1-F(x)\}^n$. Pooling both extrema also changes the distribution: for uniform ages, the equally weighted density is U-shaped whenever $n\geq3$ (Supplementary Section S2.6). A uniform model can still win against monotonic alternatives. This explains why correct direction or family selection is insufficient evidence of shape recovery.

Partial treatment mixes unequal contributions. A treated site contributes one date under an oldest or youngest rule, while an untreated site contributes at least five. At 50% or 75% site treatment, filtered sites therefore supply a smaller share of retained dates than the treatment percentage suggests. The absence of reversals in those scenarios describes that mixture, rather than a general safe threshold.

The AustArch benchmark makes the size of the effect tangible. At the same retained count, oldest and youngest retention moved the mean by millennia, compared with a mean displacement of about a century under random-1. For bracketed retention, the mean shift falls within the random-1 range, whereas its SPD total variation exceeds the random-1 range. These are distinct descriptive comparisons, and a random-2 benchmark would be needed to assess bracketed retention at the same date count.

### 4.2 Consequences for dates-as-data analysis

Accounting for calibration uncertainty alone does not correct age-dependent retention. A model representing a known selection process could address this bias; the regional-density fits tested here assume that the retained observations are regional draws. Choosing a better likelihood therefore cannot substitute for examining how the dataset was assembled.

This issue complements debates about taphonomy, binning, rescaling and population models [@bronkramsey2017MethodsSummarizingRadiocarbon; @carleton2021SumThingsAre; @crema2022StatisticalInferencePrehistoric; @riris2018DatesDataRevisited; @surovell2007NoteUseTemporal; @williams2012UseSummedRadiocarbon]. Recent count-based and Bayesian approaches improve inference once a dataset is assembled [@arthur2023ProbabilisticReconstructionPaleodemographic; @crema2025BayesianAlternativeAoristic; @denavascues2025AnalysisAbundanceRadiocarbon; @hanna2025SumPoissonApproach; @heaton2025NewApproachRadiocarbon]. An earlier audit should report per-site contributions, distinguish sites with few dated samples from sites with few retained dates, and record whether inclusion depended on age. Where the selection history is unknown, analyses can test plausible alternatives and identify which conclusions depend on them.

Sparse sites can remain useful evidence. Their material, period, region and selection history should accompany their numerical contribution [@bird2022P3k14cSyntheticGlobal; @loftus2019ArchaeologicalRadiocarbonDatabase; @lucarini2020MedAfriCarbonRadiocarbonDatabase; @saktura2023SahulArchGeochronologicalDatabase]. An oldest-date summary assembled to study arrival, for example, targets a different quantity from the distribution of dated activity through time. Reusing such a summary for dates-as-data inference would carry its selection rule into the new analysis. This is a distinction between inferential targets, not a claim about how frequently such reuse occurs.

### 4.3 Limitations and next tests

The simulations isolate post hoc retention among independent regional ages. Site labels determine date counts and retention, without occupation durations, stratigraphy, spatial structure or context-selection processes. The changing histories span a ten-fold endpoint contrast; weaker or non-monotonic signals may behave differently. The observed success of random retention consequently provides neither a universal dating minimum nor an optimal allocation of a fixed dating budget. Within the simulation, oldest and youngest are count-matched to random-1 and bracketed to random-2, so their differing outcomes cannot be attributed to retained count alone.

The observation model propagates calibrated-posterior width and curve structure but omits realised conventional-age variation. An earlier sensitivity found small changes for all-date and random rules: accuracy changed by -1.5 to +0.8 percentage points and unique generating-family support by -1.9 to +0.9 points. Its prespecified assessment met 15 of 18 criteria and remains failed; a subsequent post-unblinding diagnostic met its revised criteria (Supplementary Section S3). Neither analysis tested oldest, youngest or bracketed retention. Independent, identically generated per-date noise preserves the order-statistic tilt of retained posterior medians towards the selected extreme; the unresolved test is how AIC on their full posteriors responds. Calibration-curve errors were not modelled as correlated; bracketed fits use working independence, and estimates reaching optimisation bounds have censored magnitudes.

The empirical benchmark deliberately selects well-replicated charcoal or wood dates and includes records of uncertain occupation relation. Its normalised curves describe temporal shape rather than population abundance. The retention rules diagnose what can happen to this assembled database; they do not estimate the prevalence of those practices in existing archives or supply occupation onset and termination estimates. Site-history generators and comparisons of sampling allocations would be needed to extend the results to prospective archaeological sampling.

### 4.4 Conclusions

Which dates a site contributes can determine whether a regional analysis infers growth, decline or no change. In our simulations, retaining every site's oldest or youngest date manufactured trends from constant histories and reversed opposing trends. Retaining both extrema preserved direction while turning linear histories into exponential selections. The AustArch comparison shows why retained count alone is inadequate: equally sparse datasets had sharply different temporal shapes depending on which dates were kept. Regional analyses should make site contributions and retention rules explicit, then test whether their conclusions survive plausible changes to those rules.

## Data availability

For peer review, supporting code, aggregate empirical evidence and accepted synthetic artefacts are supplied as an author-anonymized supplementary archive. The archive excludes raw and record-level AustArch data. Rebuilding the empirical curves from source records requires separately governed access to the cited AustArch dataset [@williams2014AustArchDataset]. A citable repository record containing code, synthetic artefacts and permitted aggregate evidence will be made public no later than publication; release of source or record-level archaeological data remains subject to source licensing, sensitive-location review and Indigenous data-governance requirements.

## Competing interests

None to declare.

## Declaration of generative AI and AI-assisted technologies in the manuscript preparation process

During preparation of this work, the authors used OpenAI ChatGPT and Codex, and Anthropic Claude, for manuscript-source conversion, citation tokenisation, reproducibility-workflow checks, presubmission critical review and language-editing suggestions. The September 2026 text reviews used GPT-6 Astra and GPT-5.6 Sol (OpenAI) and Claude Fable 5.1 (Anthropic). The authors independently evaluated, verified and edited all outputs and take full responsibility for the content of the article.

## References
