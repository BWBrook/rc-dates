# Adversarial external review and line edit

## Manuscript

**“Within-site sampling influences radiocarbon ‘dates-as-data’ demographic reconstructions”**  
Target journal: *Journal of Archaeological Science*  
Review date: 9 August 2026

---

## Overall recommendation

**Hold submission and undertake a major scientific revision.**

This is an important, potentially influential methods paper built around a real weakness in radiocarbon “dates-as-data” research: regional datasets are shaped not only by calibration, preservation and inter-site research intensity, but also by the number and identity of determinations contributed by each site. The manuscript is lucid, commendably candid about several limitations, and supported by an exceptionally well organised reproducibility archive. The direct fitting of simple calendar-age-density models to calibrated determinations, rather than to a plotted aggregate curve, is also a sound and worthwhile direction.

The present version nevertheless has three conclusion-bearing problems that cannot be repaired by prose alone:

1. **The simulation does not yet simulate archaeological within-site sampling.** Dates are independent draws from the regional age density and are assigned to otherwise exchangeable site labels. “Oldest” and “youngest” therefore operate as order-statistic filters on independent regional draws, not as sampling of site onsets, terminations, basal contexts, stratigraphic sequences or occupation episodes.
2. **The fitted model space is directionally restricted.** The candidate models allow only a constant trajectory or linear/exponential increase towards the present. Oldest-date retention induces a trajectory tending in the opposite direction, but no decreasing candidate exists. Some of the dramatic classification collapse and bound saturation is consequently imposed by the candidate-model space rather than estimated freely.
3. **The empirical cross-method comparison changes the observations as well as the summary method.** SPDs, FDs and KDEs have materially different effective memberships, particularly under youngest-date retention, and the boundary rules rank heterogeneous marine, freshwater and terrestrial determinations using uncalibrated radiocarbon ages. The claim that within-site selection visually matters more than the choice among SPD, FD and KDE is therefore not presently identified.

These are not reasons to abandon the project. They define a clear route to a much stronger paper. My preferred route is to retain the present exchangeable-date experiment as an analytically interpretable null model, add at least one hierarchical site-history simulation, fit signed growth families, introduce matched-resource controls, and repair the empirical reservoir/membership analysis. A narrower alternative is to recast the paper explicitly as a study of **post hoc within-site date-retention and order-statistic thinning**, remove claims about prospective field sampling and site onsets, and target a journal whose scope is more specifically methodological or radiocarbon-focused.

For *Journal of Archaeological Science*, I recommend the stronger route.

---

## Review scope and verification

I reviewed the anonymous manuscript, supplementary information, figures, highlights, cover letter, title page, submission checklist, repository instructions, analysis code, tests, frozen provenance sources, supplied CSV summaries, data tables and sensitivity reports.

The following checks were completed:

- The outer ZIP SHA-256 matched the supplied sidecar.
- All 200 entries in the internal SHA-256 manifest verified.
- All five main figures and two supplementary figures were rendered or inspected visually.
- The empirical input and filtered CSVs were independently audited with Python.
- The production and sensitivity summary CSVs and both the original v1 and post-unblinding v2 gate reports were inspected.
- The relevant R source was statically traced through filtering, calibration, simulation, likelihood construction, model fitting, selection and plotting.
- Citation keys, highlights and manuscript structure were checked.
- Current *Journal of Archaeological Science* intake guidance, scope and editorial information were checked against Elsevier’s official journal pages on 9 August 2026.

I could **not** independently execute the R 4.5.3 pipeline or rerun the high-volume simulations because neither R nor Docker was available in the review environment. I therefore verified archive integrity, code logic, supplied summaries and static consistency, but I do not claim an independent numerical reproduction of the RDS results. Pandoc was available: the Markdown was structurally parseable, although the supplied dependent Elsevier Harvard CSL was not self-contained for an offline build.

---

## Concise assessment

### What the manuscript gets right

The manuscript has several substantial strengths.

- **The research question is important.** Site-level dataset formation is less often interrogated than calibration, taphonomy or inter-site sampling intensity, yet it can plausibly affect every downstream summary and model.
- **The archive is exemplary.** The retained failed v1 sensitivity screen, separately versioned post-unblinding v2 diagnostic, frozen simulation sources, manifests, sidecars, tests and rebuild routes are far above ordinary publication practice.
- **The authors do not conceal idealisations.** The main text already states that sites lack occupation histories, dates are exchangeable within sites, the realised-noise analysis omits the boundary rules, and v1 remains a failure.
- **The distinction between descriptive curves and inferential models is valuable.** The primary $\ell^1$ calculation can be given a coherent marginal-likelihood interpretation under an explicit calibration prior and support contract.
- **The current results contain a useful null-model insight.** Under exchangeability, outcome-dependent retention of minima and maxima necessarily induces order-statistic deformation. That is not a trivial practical warning, even though it is not yet a field-sampling simulation.
- **The manuscript is well written at sentence level.** Most required changes are conceptual precision rather than basic prose repair.

### Why the present framing still overreaches

The manuscript repeatedly moves from “selecting the oldest or youngest observed date among independent regional draws” to “which contexts within a site are dated”, “site onsets”, “site coverage”, “adding more sites”, and field-programme advice. Those are different estimands and interventions. Transparency in the limitations section does not neutralise stronger causal and practical language in the title, abstract, results synthesis, discussion, cover letter and highlights.

Similarly, the one-sided model family makes the oldest/youngest failures look more diagnostic than they are, while the empirical comparison makes summary-method differences look smaller partly because the methods receive different dates. These features can change the interpretation of the headline findings, not merely their generality.

---

## Priority revision matrix

| Priority | Issue | Why it matters | Minimum defensible action | Preferred action for *JAS* |
|---|---|---|---|---|
| **M1** | Exchangeable site labels do not represent site histories | The central intervention is an order-statistic retention rule, not prospective archaeological context sampling | Reframe throughout as post hoc date retention; remove onset/termination and field-design claims | Add hierarchical site initiation, duration, occupation and stratigraphic/context structure; retain exchangeable model as a null case |
| **M2** | Candidate models allow only increase towards the present | Oldest-induced decline has no candidate; classification collapse and bound hits are partly forced | Fit signed linear and exponential parameters and include decreasing truths | Add signed families, multiple effect sizes, decreasing and non-monotonic histories |
| **M3** | Empirical SPD/FD/KDE membership and boundary handling differ | The method comparison is confounded by date membership and edge effects | Recompute all summaries on common memberships and remove the unquantified “selection exceeds method” claim | Add common-membership, terrestrial-only, window and edge-correction sensitivities plus quantitative curve distances |
| **M4** | Raw conventional ages rank marine, freshwater and terrestrial determinations | Reservoir effects can determine which record is labelled “oldest” or “youngest” | Make a terrestrial, non-reservoir primary analysis; use calibrated summaries consistently | Model material/reservoir processes explicitly and provide corrected/stratified sensitivity analyses |
| **M5** | Realised-noise analysis excludes the headline biased rules and v1 failed | Rank changes under noise are most relevant for oldest/youngest; v2 is post hoc | Present v1 as primary and v2 only as exploratory; narrow the abstract/highlights | Freeze a new all-seven-strategy realised-noise design and prespecified evaluation before running it |
| **M6** | Random-$n$, total sample size and site weighting are conflated | High performance of random-3/5 does not identify a per-site minimum | Add random-2 and matched-total-$N$ controls; distinguish equal-site from all-date weighting | Cross fixed site count, total assays and per-site allocation as separate design factors |
| **M7** | Only a 10-fold monotonic signal is generated | Recovery of a strong signal cannot support broad robustness claims | State the conditional scope prominently and remove generic recommendations | Add 2-, 3-, 5- and 10-fold changes, decreases, pulses/changepoints and spatial/site heterogeneity |
| **M8** | $\ell^2$ is not a likelihood; the support rule is custom | “Maximum likelihood”, “AIC” and “unambiguous support” overstate formal status | Restrict likelihood/AIC language to $\ell^1$; rename $\ell^2$ and the support metric | Compare conventional $\Delta$AIC/Akaike weights, BIC or predictive criteria alongside the custom rule |
| **M9** | Public-review archive contains identifiable sites and mixed licensing | “De-identified” is inaccurate; exact coordinates and Indigenous archaeological data require governance review | Rename as author-anonymised; remove unused names/coordinates; separate code and data licences | Document provenance, permissions, Indigenous data-governance review and any access restrictions |
| **M10** | Journal checklist says double-anonymised review | Current JAS guidance states single-anonymised review | Correct checklist and repository workflow | Simplify the submission package around the actual journal process |

---

# Major scientific comments

## M1. The current simulation is an order-statistic experiment, not a site-sampling model

### What the code actually does

For each replicate, the code draws a number of dates for each of 116 labelled sites. It then draws **all calendar ages independently from the same regional distribution**. Site identity determines only how many draws are grouped together and which rows are subsequently retained. There is no site-specific onset, duration, occupational intensity, phase structure, hiatus, stratigraphic ordering or context-selection mechanism.

If $X_{j1},\ldots,X_{jn_j}$ are independent ages at site $j$, with regional density $f(x)$ and cumulative distribution $F(x)$, then the retained “oldest” and “youngest” age densities are order statistics:

$$
g_{\max}(x\mid n_j)=n_j f(x)F(x)^{n_j-1},
$$

$$
g_{\min}(x\mid n_j)=n_j f(x)\{1-F(x)\}^{n_j-1}.
$$

With a distribution of site sample sizes, the marginal selected density is the corresponding mixture over $n_j$. The direction of deformation is therefore mathematically built into the design. The simulations add calibration and model-selection consequences, but they do not establish what happens when archaeologists select basal, terminal or stratigraphically distributed contexts from real occupation histories.

This distinction matters because the manuscript motivates the study with field programmes that date basal or terminal contexts, yet the implemented rule selects whichever **assay later turns out to have the maximum or minimum estimated age**. A field archaeologist cannot normally know that outcome before dating. Basal context, earliest occupation, oldest charcoal determination and greatest conventional radiocarbon age are not interchangeable because of residuality, old wood, redeposition, intrusion, reservoir effects, calibration multimodality and measurement error.

### Consequences for the current claims

The following statements are not established by the simulation as written:

- that the oldest rule approximates a distribution of site onsets;
- that the youngest rule approximates occupation terminations;
- that “greater site coverage” cannot compensate for a poor rule;
- that adding more sites can make bias more precise;
- that distributing three or five field dates across contexts is sufficient for reliable inference;
- that stratigraphic bracketing is inferior to random dating.

The current analysis **does** establish a narrower result: after dates have been generated, retaining within-site maxima or minima from exchangeable regional draws causes large order-statistic deformation and can change model selection. That is legitimate, but it should be named correctly.

### Two defensible revision paths

#### Path A: preferred *JAS* route—add site histories

Introduce at least one hierarchical generative model in which sites have temporal structure. For example:

1. Draw site initiation or episode centres from a regional site-formation intensity linked to the demographic trajectory.
2. Draw site duration $D_j$ from a prespecified or empirically informed distribution.
3. Draw one or more occupation episodes and within-episode context ages.
4. Generate candidate samples from those contexts, including plausible old-wood/residuality and material classes if feasible.
5. Define prospective strategies using latent archaeological information: basal context, terminal context, random context, evenly stratified contexts, phase-proportional allocation and observed-date extrema as a separate post hoc comparator.
6. Apply calibration and inference.

The current exchangeable model can then be retained as a transparent null case. Its analytic order-statistic expectation would become a strength rather than a hidden construct mismatch.

#### Path B: narrower route—reframe as date retention

Rename the intervention throughout as **within-site date retention**, **post hoc subsampling** or **order-statistic thinning**. Remove references to mimicking field constraints, site onsets, terminal occupation, prospective stratigraphic design and numbers of dates a field programme should obtain. Present the practical implication as an audit of how compiled databases may have been filtered or represented—not as a direct experiment on excavation or dating design.

### Minimum manuscript change even after reanalysis

The term “sampling” is used for at least three different processes:

- generation of archaeological events;
- selection of contexts for laboratory dating;
- post hoc retention of already dated determinations.

These must be separated explicitly. I recommend reserving **sampling design** for prospective context selection and using **retention rule** for the present operations.

---

## M2. The one-sided candidate-model space makes some failures partly inevitable

### Directional restriction

The generating and fitted linear and exponential models permit only density that increases towards the present. In the code, the linear slope is restricted to

$$
0 < s \leq \frac{2}{(U-L)^2},
$$

and the exponential rate to a positive interval. There is no corresponding decline-towards-the-present model.

Oldest-date retention shifts density towards larger cal BP values—precisely the direction that a negative slope or negative exponential rate would describe. Because no such candidate exists, the fitted model is forced towards the uniform boundary. Conversely, youngest-date retention pushes the estimate towards the strongest permitted recent increase and reaches the upper fitting bound. The observed deterministic outcomes at 100% treatment are therefore partly consequences of a constrained candidate set:

- oldest selects uniform in every replicate;
- youngest selects exponential in every replicate;
- parameter estimates saturate the fitting bounds.

The order-statistic distortion is real. The interpretation that the sampling rule “destroys model recovery”, however, is inseparable from the fact that the induced trajectory is excluded from the model space.

### Required repair

Fit signed versions of both families. With $D=U-L$, a signed linear density can be written as

$$
f_s(x)=\frac{1+sD^2/2}{D}-s(x-L),
\qquad
-\frac{2}{D^2}\leq s\leq \frac{2}{D^2}.
$$

A signed exponential tilt can be written as

$$
f_\beta(x)=
\begin{cases}
\dfrac{\beta\exp[-\beta(x-L)]}{1-\exp[-\beta D]}, & \beta\neq 0,\\[8pt]
\dfrac{1}{D}, & \beta=0,
\end{cases}
$$

where the sign of $\beta$ determines the direction of change.

Generate both increasing and decreasing truths. Then report separately:

- recovery of functional family;
- recovery of direction;
- bias in a common effect-size scale, preferably the log end-to-start density ratio;
- frequency of boundary estimates;
- confusion matrices by generating truth.

### Why this is a major rather than minor sensitivity

The strongest narrative result—the deterministic collapse of oldest and youngest rules—is exactly where the model-space restriction bites. Until signed models are fitted, the magnitude and interpretation of that collapse cannot be taken as stable.

### Figure implication

The dotted “chance accuracy = 1/3” line in Figure 3 should be removed or relabelled as a **uniform random-guess reference**. Model selection is not a three-category random guessing process, and the pooled truth mixture, nested/boundary relationships and asymmetric candidate space make $1/3$ a poor inferential benchmark.

---

## M3. The empirical comparison confounds summary method, date membership and boundary treatment

### Different effective samples

The manuscript acknowledges method-specific membership, but the size of the difference is large enough to invalidate the visual cross-method conclusion.

The supplied effective-count table shows:

| Scenario | SPD dates | FD/KDE dates |
|---|---:|---:|
| All dates | 976 | 889 |
| 100% oldest | 116 | 105 |
| 100% youngest | 116 | 72 |
| 100% bracketed | 232 | 177 |
| 100% random-1 | 116 | mean 105.1 |
| 100% random-5 | 580 | mean 525.6 |

For the headline full-youngest panel, the SPD and FD/KDE therefore differ by **44 of 116 retained determinations**. The plotted methods are not summaries of the same information.

The mechanisms also differ:

- The SPD includes posterior mass from every date whose calibrated grid overlaps the window.
- The FD and KDE exclude dates whose weighted-mean calibrated ages fall outside the window.
- KDE kernels are not edge-corrected; lost mass is then removed by renormalising the aggregate within the window.
- The SPD and KDE/FD are each normalised to unit area.

Under these conditions, visual similarity cannot identify a small method effect, and visual difference cannot be attributed to method alone.

### Boundary concentration

The full-youngest curves peak at 600–700 cal BP, essentially at the declared lower analysis boundary of 651 cal BP. This is exactly where any-overlap inclusion, point-estimate exclusion, kernel leakage, truncation and unit-area renormalisation have their greatest leverage. The statement that the youngest rule creates a strong late-Holocene edge effect may be true, but the location and magnitude of the peak require a boundary sensitivity.

The supplied metadata report:

- 87 of 976 weighted means outside the analysis window;
- minimum retained KDE kernel mass of 0.536;
- 60 kernels with less than 0.95 of their mass inside the window;
- no KDE edge correction.

### Required empirical redesign

At minimum:

1. Define a **common date membership** for every summary in a comparison panel.
2. Run a primary analysis restricted to dates whose chosen calibrated point summary and a high proportion of posterior mass lie within a buffered window.
3. Recompute KDEs with an explicit boundary correction or sufficient padding followed by comparison on the interior window.
4. Test multiple younger bounds or exclude a buffer when interpreting edge peaks.
5. Quantify curve deformation rather than relying on visual judgement. Suitable measures include total-variation distance,

   $$
   D_{\mathrm{TV}}(p,q)=\frac{1}{2}\sum_t |p_t-q_t|,
   $$

   Wasserstein distance, Jensen–Shannon distance or integrated absolute error.
6. Cross the factors explicitly: compare between-method distances on the **same retained dates**, and between-retention-rule distances within each method.

Until this is done, delete the headline claim that within-site selection has a larger effect than summary method.

---

## M4. Empirical oldest/youngest selection is confounded by reservoir effects

### Audit result

The filtered empirical table contains:

- 172 records classified as Marine;
- 56 freshwater-shell records, all routed through the non-marine calibration branch;
- 26 sites containing both marine-class and terrestrial-class determinations;
- no site-specific $\Delta R$ correction.

The oldest and youngest empirical rules rank records by **uncalibrated conventional radiocarbon age**. Under the first-occurrence tie rule used by the code:

- 21 of 116 selected oldest records are marine-class;
- a further 6 selected oldest records are freshwater shell;
- at mixed marine/terrestrial sites, 15 of 26 selected oldest records are marine-class;
- 13 selected youngest records are marine-class and 5 are freshwater shell.

Conventional ages from terrestrial charcoal, marine shell and freshwater shell are not on a common chronological scale. Marine and freshwater reservoir effects can therefore determine which determination is called “oldest” independently of its true calendar age. Calibration with Marine20 but no local $\Delta R$ does not eliminate this problem, and freshwater shells may require water-body-specific correction rather than SHCal20 alone.

### Required action

Use a **terrestrial, non-reservoir primary empirical analysis**, ideally restricted further to materials for which old-wood risk can be evaluated. Then provide broader material-inclusive analyses only as sensitivity checks.

If marine determinations remain:

- use documented site- and period-specific $\Delta R$ where available;
- stratify selection within calibration/material class rather than ranking raw ages jointly;
- state explicitly how mixed-material sites are handled.

For all empirical rules, use the same chronological definition as in the simulation—preferably a calibrated median or another prespecified posterior functional—while acknowledging that selecting an observed posterior median is still a post hoc retention rule, not a prospective field strategy.

Also define tie handling. Three sites have tied maximum conventional ages and two have tied minima; the current code silently takes the first row.

---

## M5. The realised-observation-noise evidence is incomplete and the confirmatory status is overstated

### What is commendable

The archive handles the failed sensitivity screen unusually well. The original v1 result remains visible as **FAIL: 15 of 18 gates passed**. The v2 analysis is clearly labelled post-unblinding and does not overwrite v1. This is excellent provenance practice.

### What remains unresolved

The realised-noise sensitivity covers only all-dates, random-1, random-3 and random-5. It does **not** cover oldest, youngest or bracketed retention—the rules whose behaviour drives the paper’s strongest conclusions and whose selection can change when noise alters within-site rank order.

The original v1 screen failed:

- the accuracy-equivalence interval criterion;
- the support-equivalence interval criterion;
- the directional boundary-rate criterion.

The observed paired point changes were small, but the v2 intervals were redesigned after inspecting v1 and calibrated only over the failed difference estimands. They are useful exploratory diagnostics, not confirmatory validation of the production design.

The abstract, highlights and cover letter currently make the realised-noise result sound more comprehensive than it is. “Preserved this ranking” can be read as preserving the full seven-strategy ranking, which was not tested.

### Preferred repair

Freeze a new sensitivity specification before execution and run all seven strategies. The specification should state in advance:

- which metrics are primary;
- whether selection is repeated after realised observations are generated;
- the simultaneous family over which intervals are calibrated;
- equivalence margins and why they are scientifically meaningful;
- treatment of zero in-window posterior mass;
- truth-specific safeguards;
- boundary-hit rules.

The realised arm should permit observation noise to change oldest/youngest membership. Holding selected rows fixed between arms would test only likelihood perturbation, not the full retention rule.

### Minimum prose repair if no new run is undertaken

- Call v1 the primary prespecified screen and report its failure first.
- Call v2 an exploratory, estimand-aligned diagnostic.
- Restrict the conclusion to all-date and random retention strategies.
- Replace “realised assay” with **realised observation-noise** or **realised conventional-age observation**, because the draw combines calibration-curve uncertainty and quoted laboratory error rather than representing laboratory assay error alone.

---

## M6. Random-$n$, information quantity and site weighting are not separated

### What changes under random-$n$

At 100% treatment, the strategies retain approximately:

- random-1: one date per site;
- bracketed: two dates per site;
- random-3: three dates per site;
- random-5: five dates per site;
- all dates: a variable number per site, with empirical benchmark counts from 5 to 33.

Changing from all dates to random-$n$ simultaneously changes:

1. total number of determinations;
2. per-site weighting;
3. within-site retained variance;
4. the maximum contribution of heavily dated sites.

In the exchangeable simulation, site identity carries no temporal information, so most random-$n$ performance differences are expected to be driven by total $N$. In empirical data, capping each site at $n$ also changes the estimand by moving from date-weighted towards site-weighted evidence.

### Missing controls

- random-1 is a useful sample-size-matched comparator for oldest and youngest.
- bracketed has no random-2 comparator, so its performance cannot be separated from retaining two rather than one, three or five dates.
- random-3 and random-5 have no globally random, total-$N$-matched comparator.
- the study does not vary the number of sites independently of dates per site.

### Required additions

Add:

- random-2;
- global random thinning to the same total number of dates as each per-site strategy;
- equal-site weighted all-date inference, or an explicit site-level likelihood contribution;
- fixed-cost designs that cross number of sites with dates per site;
- multiple site counts if making claims about adding sites or coverage.

Use **site-treatment proportion** rather than “site coverage”. Every simulated dataset contains the same 116 sites; the 50%, 75% and 100% levels refer to the fraction of sites subjected to a retention rule, not the proportion of sites covered by sampling.

Delete the sentence “greater site coverage cannot compensate for a poor rule” unless site count or site inclusion is actually varied.

---

## M7. The generated signal is too narrow and strong for the present general conclusions

The only non-uniform truths are a 10-fold linear increase and a 10-fold exponential increase over the analysis window. This is a deliberately strong signal. The all-date reference contains roughly the empirical number of observations, and every simulated site is conditioned to contain at least five latent dates.

High recovery under random-3 and random-5 therefore means:

> Given 116 sites, each generated with at least five exchangeable dates, and a constant or 10-fold monotonic regional signal, retaining three or five random observations per treated site often preserves discrimination among the three fitted families.

It does not mean that three or five dates per archaeological site are generally sufficient, that weaker demographic changes are preserved, or that non-monotonic histories are robust.

### Minimum revision

Move the strong-signal qualification into every headline statement. Replace “high model recovery” with “high recovery of the implemented strong monotonic signals”. Keep the explicit statement that no universal minimum follows.

### Preferred design grid

At minimum, cross:

- fold changes of 1, 2, 3, 5 and 10;
- increasing and decreasing directions;
- linear and exponential shapes;
- one pulse or boom–bust history;
- one changepoint or piecewise history;
- multiple site counts;
- at least two site-duration distributions.

For non-monotonic truths, primary performance should not rely solely on choosing among uniform, linear and exponential families. Compare estimated and true densities with trajectory-level distances and recover interpretable features such as direction, peak timing and end-to-start ratio.

---

## M8. Likelihood, score and model-support terminology needs correction

### $\ell^1$

The primary criterion is

$$
\ell_i^1=\log\int f(x\mid\theta)p_i(x)\,dx.
$$

This can be interpreted as an observed-data marginal likelihood up to a $\theta$-independent constant if $p_i(x)$ is the calibrated likelihood normalised under a uniform prior over the same support. The manuscript should state that prior/support contract explicitly. If a non-uniform calibration prior is used, $p_i(x)$ must be adjusted by that prior to recover the likelihood contribution.

The code trims each calibrated grid to the analysis window and renormalises it. The text should therefore describe the fitted criterion as conditional on age lying inside the analysis window and explain how empirical inclusion is aligned with that conditioning.

### $\ell^2$

The secondary criterion is

$$
\ell_i^2=\int \log f(x\mid\theta)p_i(x)\,dx.
$$

This is an expected log-density score or cross-entropy term. It is **not** the log likelihood of the observed radiocarbon determination. Consequently:

- fitting under $\ell^2$ should not be called maximum-likelihood estimation;
- $-2\sum_i\ell_i^2+2k$ should not be called AIC without a derivation establishing the required likelihood basis;
- the result can remain as a heuristic sensitivity score, clearly labelled as such.

A clean solution is to retain $\ell^1$ as the inferential analysis and report $\ell^2$ only as an “expected-log-density scoring sensitivity”, with a correspondingly neutral penalised-score label.

### Custom parsimony rule

The one-standard-error-style rule is transparent but non-standard. It computes a standard error of total pointwise AIC differences and then retains only the lowest-dimensional models within that threshold. Calling the resulting outcome “unambiguous support” is too strong. It is **unique generating-family selection under the prespecified parsimony rule**.

Report conventional quantities alongside it:

- $\Delta$AIC by model;
- Akaike weights;
- truth-specific confusion matrices;
- perhaps BIC or an out-of-sample predictive criterion as a sensitivity.

The manuscript’s pooled metrics should not be the only main-text results. A pooled value of $1/3$ or $2/3$ masks deterministic truth-specific failure, as the authors correctly note in the supplement. That observation belongs in the main figure or an immediately adjacent table.

---

## M9. Archive identification, licensing and Indigenous data governance require attention

This is partly an editorial issue and partly a research-governance issue.

### “De-identified” is inaccurate

The review package removes author identity, but the data retain named archaeological sites, laboratory codes and latitude/longitude. In the filtered table:

- all 116 sites retain names and coordinates;
- 352 of 976 longitude entries and 329 latitude entries are represented to four decimal places;
- 39 and 36 unique sites, respectively, reach four-decimal precision;
- 11 records are human bone collagen determinations.

The package is therefore **author-anonymised**, not de-identified in the ordinary data-governance sense.

### Licensing

The archive-level `LICENSE` is the Unlicense and expressly describes software. It does not establish rights to redistribute the AustArch-derived data under the same terms. The original data paper and deposited dataset should be traced to the exact source extract and its applicable terms. The manuscript should cite the dataset DOI as well as the data paper, identify the version/extract, and provide a separate data-licence statement.

The archived input contains 5,288 age records, including 4,828 radiocarbon determinations from 1,704 radiocarbon site labels, whereas the 2014 data paper reports 5,044 radiocarbon determinations from 1,748 sites. The supplement reports this discrepancy but does not explain the lineage of the extract. Add a provenance statement describing when, from whom and under what transformation the archived source was obtained.

### Indigenous archaeological information

A continental database of Australian archaeological sites, including precise locations and human-remains determinations, warrants an explicit review against the AIATSIS Code of Ethics and CARE Principles for Indigenous Data Governance, even where the records are secondary and previously published. This is not an allegation that the analysis is unethical. It is a request to demonstrate that reuse, redistribution, location precision and public access have been considered deliberately.

### Practical resolution

- Remove site names and coordinates from the reviewer/public analysis table unless they are analytically required.
- Replace them with stable hashed or arbitrary site identifiers.
- If location is needed, use an access-controlled or suitably coarsened representation.
- Add `LICENSE_CODE`, `LICENSE_DATA` and a provenance/permissions note.
- State whether ethics review was required or not required for this secondary-data analysis, and why.
- Record any consultation or governance process relevant to Indigenous archaeological data.

---

# Additional statistical and methodological comments

## Filtering and reference-set description

The initial archive contains 5,288 records. Static replication of the coded non-calibration filters gives the following flow:

| Step | Records retained |
|---|---:|
| Input extract | 5,288 |
| Method = radiocarbon | 4,828 |
| Occupation flag not `N` and non-missing | 4,551 |
| Conventional age 500–20,000 $^{14}$C yr BP | 3,764 |
| Positive reported error | 3,757 |
| Two specified issue classes removed | 3,703 |
| Accepted material list | 3,217 |
| Accepted site-type list | 3,134 |
| Not labelled `Unusuable` | 3,120 |
| Five-standard-error range check | 3,076 |
| Posterior-overlap and at least five eligible dates/site | 976 dates, 116 sites |

Add a formal flow diagram or table that includes the post-calibration overlap stage and the number of sites at each stage. This will make the empirical construction auditable without reading code.

The final reference set contains 604 records with occupation status `U` and 372 with `Y`. The supplement’s phrase “clearly anthropogenic contexts” is therefore inaccurate. State that records explicitly marked unrelated (`N`) were excluded, while `Y` and `U` were retained; provide a `Y`-only sensitivity if the distinction is scientifically important.

## Posterior-overlap inclusion and window conditioning

A date is retained if any calibrated-grid point overlaps the inclusive 651–11,650 cal BP window. The likelihood then uses a strict interior test, $651<x<11{,}650$, and renormalises the surviving posterior mass to one. A date with a small tail inside the window consequently receives the same total weight as a date whose posterior lies almost entirely inside it.

Add sensitivities using, for example, minimum in-window posterior masses of 0.5, 0.8 and 0.95, or derive the likelihood under the explicit observation/selection process. Harmonise strict and inclusive boundary definitions.

## Empirical error model

The simulation uses

$$
\log(\mathrm{ERROR})=\alpha+\beta\,\mathrm{AGE}+\varepsilon.
$$

An independent OLS audit of the filtered table gives approximately

$$
\widehat{\alpha}=4.0992,\qquad
\widehat{\beta}=8.56\times10^{-5},\qquad
R^2=0.170.
$$

Residual standard deviation increases across conventional-age quartiles from about 0.388 to 0.590, suggesting heteroscedasticity. Report diagnostics. Prefer empirical residual resampling within age/material bins, a heteroscedastic model, or a direct empirical conditional resampler. Propagate uncertainty in the fitted count and error models in at least one sensitivity.

The filtered reported errors range from 10 to 810 years, with median 80 and 95th percentile 210. Extreme errors and material/laboratory structure deserve explicit handling.

## Site-count model

The final empirical sites have 5–33 dates, median 7 and mean 8.41. The simulation fits a truncated negative binomial conditional on at least five dates. That is appropriate for reproducing the well-dated benchmark but not the full AustArch site-count distribution. State this conditioning every time the random-3/5 result is interpreted.

Supplementary Figure S2 needs goodness-of-fit information, parameter estimates and uncertainty, not only a line over a histogram/point distribution.

## Population proxy language

The simulated object is a normalised regional calendar-age density. Calling it a “population trajectory” embeds the dates-as-data proxy assumption inside the generative model. Use **regional event-age density** or **proxy trajectory** in methods and results, then discuss the conditions under which it reflects population.

## Normalisation

All empirical curves are separately normalised to unit area. This removes date-count and total-intensity information and turns the exercise into a comparison of relative temporal shape. State this limitation prominently. In particular, the empirical experiment cannot assess how subsampling changes estimates of absolute activity or total event intensity.

## Correlated calibration-curve uncertainty

The limitation is acknowledged, but the realised-noise draw appears to treat calibration-curve uncertainty independently across dates. Calibration-curve uncertainty has a shared component. A stronger sensitivity would draw one or more common calibration-curve realisations and condition all dates on the same realisation. This can be deferred if clearly labelled, but it should not be described as a fully realised assay process.

## Pooled intervals

The “95% intervals” around parameter bias are central replicate distributions, not confidence intervals for a mean or parameter. Label them **central 95% replicate range**. Keep bootstrap confidence intervals for aggregate proportions distinct.

---

# Claims-to-evidence audit

| Manuscript claim | Status under current analysis | Required disposition |
|---|---|---|
| Within-site date selection can deform regional summaries | **Supported conditionally** | Retain, but call the intervention post hoc retention and repair reservoir/membership confounding |
| Oldest/youngest rules induce directional bias | **Supported as an order-statistic effect; magnitude/model classification conditional** | Retain after signed-model rerun; do not equate with site onsets/terminations |
| Random-3 and random-5 preserve high recovery | **Supported only for 116 sites, minimum five latent dates and 10-fold monotonic signals** | Add effect-size/site-history grid or narrow every statement |
| Three dates are not a universal minimum | **Supported as a caution** | Retain |
| Within-site selection matters more than SPD/FD/KDE choice | **Not currently identified** | Delete pending common-membership quantitative comparison |
| Greater site coverage cannot compensate for a poor rule | **Not tested** | Delete or vary site count/inclusion |
| Adding more sites can make bias more precise | **Not tested** | Delete or add site-count simulation |
| Oldest empirical dates approximate site onsets | **Unsupported** | Replace with “within-site maxima of observed determinations” |
| Bracketing is not a general substitute for random-3/5 | **Confounded by total $N$ and absent random-2** | Add matched-$N$ control and site-history model |
| Realised assays preserve the strategy ranking | **Only tested for all/random rules; v1 failed** | Narrow and prioritise v1; rerun all strategies |
| Models are fitted by maximum likelihood under both $\ell^1$ and $\ell^2$ | **Valid for $\ell^1$ only** | Reclassify $\ell^2$ as a scoring sensitivity |
| “Unambiguous support” measures clear model support | **Overstated** | Rename as unique selection under a custom parsimony rule |
| The reference set contains clearly anthropogenic contexts | **Inaccurate** | Report 604 `U` and 372 `Y`; add sensitivity or change wording |
| The archive is de-identified | **Inaccurate** | Use “author-anonymised”; remove or govern site identifiers and coordinates |

---

# Recommended reanalysis specification

## Minimum viable scientific revision

A revision that remains close to the current architecture should include all of the following:

1. **Signed candidate families** and both increasing/decreasing truths.
2. **Random-2** plus global total-$N$-matched controls.
3. **Truth-specific confusion matrices** in the main paper.
4. **Terrestrial-only empirical primary analysis**, with reservoir-sensitive materials excluded or separately treated.
5. **Common date membership** across SPD, FD and KDE within each comparison.
6. **Window and edge sensitivities** and quantitative curve-distance metrics.
7. **All-seven-strategy realised-observation-noise rerun**, with prespecified criteria or explicitly exploratory status.
8. **Correct terminology** for date retention, $\ell^2$, the parsimony metric and treatment proportion.
9. **Removal of untested site-coverage and site-number claims.**
10. **Data provenance, licensing and governance repair.**

This would yield a defensible paper about order-statistic and sparse-retention effects under an exchangeable-date null model. It may still be judged narrow for *JAS*, but it would be scientifically coherent.

## Preferred *JAS*-level revision

Add a factorial site-history simulation. A practicable design need not be encyclopaedic. One robust implementation could cross:

| Design component | Suggested levels |
|---|---|
| Regional trajectory | uniform; 2-, 5-, 10-fold increase; matched decreases; one pulse/changepoint |
| Site histories | exchangeable null; single episode with variable duration; two-episode mixture |
| Number of sites | e.g. 50, 116, 250 |
| Assay allocation | fixed total $N$; fixed dates/site; mixed empirical counts |
| Retention/design rule | all; global random; random-1/2/3/5; basal; terminal; stratified; bracketed; observed extrema |
| Observation model | curve mean; realised independent noise; common curve-realisation sensitivity |
| Material process | terrestrial primary; optional old-wood/reservoir contamination scenarios |

Primary outputs should be:

- bias and RMSE in a common log fold-change parameter;
- trajectory distance;
- direction recovery;
- peak/changepoint recovery where relevant;
- truth-specific model-selection confusion;
- interval coverage if uncertainty intervals are produced;
- optimizer-boundary frequency;
- matched-cost differences between allocation strategies.

Freeze the design, seeds, decision criteria and primary contrasts before running the expanded matrix. The existing provenance practice is ideal for this.

## An analytically stronger framing

The exchangeable null model can be developed rather than discarded. Derive the expected retained density for random-$n$, minimum, maximum and bracketed rules conditional on the site-count distribution. Then use simulation to show how calibration and finite samples perturb the analytic expectation. This would give the paper a formal contribution beyond the intuitive statement that selecting extremes shifts a distribution.

---

# Journal fit and submission readiness

*Journal of Archaeological Science* currently emphasises major methodological advances, innovative science, broad significance and far-reaching applicability. The question has that potential, but the present implementation is more accurately a strong proof of concept than a mature archaeological sampling-design study.

My judgement is:

- **Current version:** substantial desk-rejection or major-review risk because the simulation’s construct does not match the field-sampling framing and the empirical comparison is confounded.
- **Minimum viable revision only:** publishable in principle, but *Radiocarbon*, *Journal of Archaeological Science: Reports* or another specialist methods venue may be a more natural fit.
- **Signed models + repaired empirical analysis + matched-resource controls + at least one site-history generator:** a credible and potentially strong *JAS* submission.

The current *JAS* guide states that the journal uses **single-anonymised**, not double-anonymised, review. Correct the submission checklist. An author-anonymised repository may still be used, but it is not required by the journal’s review model.

The editors named in the cover letter were current when checked. The five highlights meet the 85-character limit. The manuscript appears to be within the stated article-length guidance. Replace all repository placeholders and update the cover-letter date at submission.


---

# Detailed line edit

Line references below refer to the supplied Markdown sources and will shift after revision. Where a scientific reanalysis is recommended, the proposed wording is intentionally conservative and should be updated after new results are available.

## Global terminology and style sheet

Use the following replacements consistently.

| Current term | Preferred term | Reason |
|---|---|---|
| within-site sampling | within-site date retention / post hoc subsampling | The current implementation selects among already generated determinations |
| sampling intensity | site-treatment proportion | The number of sites represented is unchanged |
| site coverage | proportion of sites subjected to the retention rule | “Coverage” implies sites added or omitted |
| oldest/youngest sampling | oldest/youngest-date retention | Avoids implying a prospective context design |
| site onset / termination | maximum/minimum observed determination | Current data do not identify occupational endpoints |
| population trajectory | regional event-age density / proxy trajectory | Avoids assuming the proxy-population link inside the method |
| curve-expectation | calibration-curve-mean observation model | More transparent |
| realised assay | realised observation-noise arm | The draw includes curve and quoted laboratory uncertainty |
| accuracy | generating-family selection rate | More descriptive and less absolute |
| unambiguous support | unique generating-family selection under the parsimony rule | The rule is custom and does not establish general model support |
| one-sigma error | reported $1\sigma$ uncertainty / reported standard error | Use a conventional statistical label |
| de-identified archive | author-anonymised review archive | Site identities and coordinates remain |
| sub-sampling | subsampling | Standardise as one word |
| 500-20,000 | 500–20,000 | Use en dashes for ranges |
| Figures 3-5 / Figs 3-5 | Figs. 3–5 | Use one style consistently |

Additional global edits:

- Define **cal BP** at first use.
- Distinguish conventional $^{14}$C yr BP from calibrated years BP.
- Use “determination” for laboratory radiocarbon results and “date” only where the broader meaning is intended.
- Do not use “confidence interval” for pointwise Monte Carlo envelopes or central replicate ranges.
- Use “normalised to unit integral” rather than “unit area” where mathematical precision is useful.
- Avoid “robust” unless robustness has been tested across a clearly defined perturbation set.
- Remove the raw LaTeX float-placement block from the manuscript body; keep build controls in the template.

## Recommended title

### Preferred under the current exchangeable-date design

> **Within-site date-retention rules can distort radiocarbon “dates-as-data” inference**

This title is accurate without implying a prospective archaeological sampling experiment.

### Preferred after adding site-history simulations

> **Within-site sampling design influences radiocarbon “dates-as-data” demographic inference**

### Alternative, more formal title

> **Order-statistic and sparse-retention effects in radiocarbon “dates-as-data” inference**

## Interim replacement abstract

The following is a conservative abstract for the **current** design. It should not substitute for the recommended reanalysis, but it illustrates the level of precision required.

> Radiocarbon “dates-as-data” analyses are sensitive not only to calibration and model choice but also to which determinations enter regional datasets. We evaluated how post hoc within-site date-retention rules alter descriptive summaries and recovery of simple regional calendar-age-density models. A Holocene AustArch benchmark comprised 976 determinations from 116 sites with at least five eligible dates. We compared all dates with random-1, random-5, oldest, youngest and oldest-plus-youngest retention in summed probability distributions, frequency distributions and kernel density estimates. We then simulated site-labelled datasets whose dates were independent draws from uniform or strongly increasing linear or exponential regional trajectories. Site counts, date counts and reported-error structure were based on AustArch; occupation histories, stratigraphy and material-specific offsets were not modelled. Random retention of three or five dates preserved high recovery of these 10-fold monotonic signals, whereas random-1 reduced model discrimination. Selecting the oldest or youngest observed date produced large order-statistic distortions and boundary estimates. These outcomes are conditional on a candidate set containing only constant or increasing trajectories. A focused realised-observation-noise analysis of all-date and random strategies yielded cellwise point changes below two percentage points; the original simultaneous screen passed 15 of 18 criteria, whereas a later post-unblinding difference-only diagnostic passed its three criteria. The results show that non-random date retention can distort inference under an exchangeable-date design and motivate explicit audits of per-site contributions. They do not identify a universal dating minimum, simulate prospective stratigraphic sampling, or establish that date-retention effects exceed differences among summary methods.

Important: after the empirical and signed-model reruns, replace the final three sentences with the new primary findings and do not preserve obsolete caveats mechanically.

## Recommended keywords

> radiocarbon dating; palaeodemography; dataset formation; date retention; order statistics; model selection; simulation

## Interim replacement highlights

- Within-site date-retention rules can distort radiocarbon inference.
- Random retention of three or five dates preserved strong-signal recovery.
- Oldest and youngest rules produced order-statistic distortions.
- The current simulations do not represent site occupation histories.
- Realised-noise point changes were below two percentage points.

These are all within the journal’s 85-character limit. After reanalysis, replace the caveat highlight with the strongest positive site-history result.

---

## Main manuscript: paragraph-level edit ledger

### Title and front matter

| Location | Issue | Edit |
|---|---|---|
| `main.md:1` | “Sampling” implies prospective design; “reconstructions” is broader than the fitted simple densities | Replace with the preferred current-design title above, or use the stronger title only after site-history modelling |
| `main.md:3` | Source word-count note is not manuscript content and the numbers are inconsistent with the actual current source counts | Remove from the submitted manuscript; retain an automated count only in build metadata |
| `main.md:7` | Abstract combines supported results with the unsupported cross-method claim; realised-noise scope and v1/v2 status are easy to misread | Replace wholesale using the interim abstract, then update after reanalysis |
| `main.md:11` | Keywords omit dataset formation/order statistics and include a generic “likelihood-based inference” phrase | Use the replacement keywords |

### Introduction

#### `main.md:17`

The paragraph is generally strong. Make three small edits:

1. Change “The rationale is that” to “The working proxy assumption is that”.
2. Change “population size” to “relative population or activity intensity”, because the mapping is neither direct nor universally proportional.
3. End with a sentence distinguishing event-age densities from demographic processes:

> These summaries are therefore proxies whose demographic interpretation depends on preservation, discovery, sampling and the relationship between human activity and datable material.

#### `main.md:19`

The paragraph should engage more directly with prior site binning/thinning and uneven contribution work. The novelty is not that multiple dates per site can bias an SPD; that problem is already recognised in binning and rescaling practice. Replace the final two sentences with:

> Existing binning, thinning and rescaling procedures acknowledge that sites and phases contribute uneven numbers of determinations, but the inferential consequences of specific within-site retention rules remain incompletely characterised. Here we isolate one component of dataset formation: how retaining random determinations or within-site age extrema changes descriptive curves and recovery of simple regional age-density models.

Add explicit discussion of Crema and Bevan (2021), Crema (2022), Timpson et al.’s site/phase binning logic and Park et al. (2026). Define the exact new contribution relative to these studies.

#### `main.md:23`

Current wording moves too quickly from real field constraints to rules that the simulation does not represent. Replace the last two sentences with:

> A field programme may target basal, terminal or otherwise diagnostic contexts, whereas a compiled database may later retain only a subset of completed determinations. These prospective context-selection and post hoc date-retention processes are related but not equivalent. The present exchangeable-date experiment addresses the latter directly; a realistic treatment of the former requires explicit site histories and stratigraphy.

Retain the historical AustArch site-count statistic, but verify that the exact denominator and release correspond to the cited dataset version.

#### `main.md:25`

Change:

> If many sites contribute only their oldest or youngest context...

To:

> If a compiled dataset retains only the oldest or youngest observed determination from many sites...

Change:

> if one-date sites dominate, within-site temporal variance is suppressed.

To:

> if sites are represented by a single determination, within-site temporal information is lost and site weighting changes.

The latter avoids implying that a latent variance was sampled unbiasedly and then merely suppressed.

#### `main.md:27`

The sentence “The empirical reference set supplies observed site-level date counts, temporal spans, and age-error structure” is misleading because the simulations do not use observed spans. Replace the paragraph with:

> To isolate these effects, we combined a Holocene benchmark derived from AustArch [@williams2014AustArchDatabase14C] with controlled simulations. The benchmark supplies the number of eligible sites, the conditional distribution of date counts among sites with at least five determinations, and an empirical relationship between conventional age and reported uncertainty. Observed within-site temporal spans are described but are not used in the present simulations. We first examined how post hoc retention rules alter descriptive SPDs, KDEs and FDs. We then generated exchangeable site-labelled dates from known regional age-density models to measure effects on model selection and parameter estimation.

#### `main.md:29`

Three changes are needed.

- Restrict maximum-likelihood/AIC language to $\ell^1$.
- Replace “population-growth model” with “regional event-age-density model” in methods language.
- Explain the calibration-prior condition.

Suggested replacement:

> Our primary inferential analysis retains the uncertainty attached to each radiocarbon determination. Rather than fitting a model to a smoothed regional curve, we integrate each candidate event-age density over the calibrated age distribution for each determination. Under the uniform calibration prior and common support used here, this yields a marginal likelihood up to a parameter-independent constant. We compare simple candidate families with maximum likelihood and Akaike’s information criterion (AIC) [@akaike1974NewLookStatistical]. SPDs, KDEs and FDs are retained as descriptive summaries. A secondary expected-log-density score is reported only as a sensitivity and is not treated as a likelihood.

The final sentence should say the paper isolates one idealised component rather than “measures how within-site selection changes” in a general sense.

### Methods

#### `main.md:33`

Replace the repository promise with the final DOI and review link before submission. “De-identified” should become “author-anonymised”. Do not say the DOI will be supplied “before submission” in a submitted manuscript.

Suggested final form:

> Full filtering, calibration, likelihood and simulation details are given in the Supplementary Methods. An author-anonymised review archive containing the code, permitted data, frozen outputs and reproducibility instructions is available at [PRIVATE REVIEW LINK], with reserved DOI [DOI].

#### `main.md:37`

The paragraph needs a more exact filter description and a reservoir caveat. Replace “remove records flagged as erroneous or unrelated to human activity” with:

> exclude records explicitly labelled unrelated to occupation (`N`) and two specified issue classes; records labelled occupationally related (`Y`) or unknown (`U`) were retained.

Replace “materials and contexts ... suitable” with the exact accepted classes or point to a complete supplementary table. Report that 604 final records are `U` and 372 are `Y`, at least in the supplement.

The primary empirical analysis should be terrestrial/non-reservoir after revision. If the all-material analysis is retained as a sensitivity, state:

> Marine determinations were calibrated with Marine20 without site-specific $\Delta R$, and freshwater shell determinations lacked water-body-specific reservoir corrections; these records were therefore excluded from the primary boundary-selection analysis and retained only in sensitivity analyses.

Also use 11,650–651 cal BP, not `11,650-651`.

#### `main.md:39`

This paragraph currently discloses the membership mismatch but then proceeds to use the curves comparatively. After repair, write:

> For each comparison, the SPD, FD and KDE were computed from an identical prespecified set of determinations on a common grid. Curves were normalised to unit integral, so the comparison concerns temporal shape rather than total event intensity. Boundary handling and alternative analysis windows are described in the Supplementary Methods.

If the current method-specific memberships remain, remove all comparative claims among methods and state that the panels are method-specific illustrations only.

#### `main.md:43`

Change the heading to:

> **2.2 Empirical within-site date-retention experiments**

Replace “We imposed five within-site rules” with “We applied five post hoc within-site retention rules”. Do not say these mimic field constraints.

Use a common chronological ranking metric and a terrestrial primary analysis. Define tie handling. Replace “Empirical oldest and youngest rules used conventional radiocarbon ages” with the revised rule, for example:

> Oldest and youngest were defined by the greatest and least calibrated posterior median within each site; ties were resolved by [prespecified rule].

Retain the sentence that envelopes are conditional-realisation quantiles, but change “not sampling confidence” to:

> They do not represent uncertainty arising from site inclusion, archive construction, calibration-curve uncertainty or the finite archaeological record.

#### `main.md:47`

This is the most important methods paragraph and should be rewritten after the design is final. Under the current design, use:

> The exchangeable-date simulation used the filtered benchmark to set 116 site labels, a truncated distribution of determinations per site conditional on at least five, and an empirical relationship between conventional age and reported uncertainty. Conditional on a regional event-age density, all latent calendar ages were drawn independently; site labels determined only the number of dates grouped together and the subsequent retention rule. The model therefore represents post hoc selection among exchangeable regional draws and not site-specific occupation histories, phases or stratigraphy. The calibration-curve-mean production arm mapped latent calendar ages to expected SHCal20 conventional ages, added empirically modelled quoted uncertainties and recalibrated the determinations. A separate realised-observation-noise arm generated conventional-age observations stochastically before recalibration.

After signed/effect-size expansion, describe all generating families here. Do not justify a single 10-fold increase by saying it is “consistent with” a qualitative Sahul increase; it is a simulation effect size, not an estimate. State why each effect size was chosen and include weaker signals.

#### `main.md:49`

Replace “sampling strategies” with “retention strategies” for the exchangeable arm. Replace “applied to 50%, 75%, or 100% of sites” with:

> applied to randomly selected subsets comprising 50%, 75% or 100% of site labels; all site labels remained represented because untreated sites contributed every generated date.

Add random-2 and matched-total-$N$ controls. If a site-history arm is added, separate genuinely prospective context strategies from post hoc observed-date rules.

#### `main.md:51`

Replace with wording that distinguishes $\ell^1$, conventional AIC and the custom rule:

> Primary inference maximised the $\ell^1$ marginal likelihood obtained by integrating each candidate event-age density over each calibrated age distribution. Candidate families were compared with AIC. We additionally applied a prespecified parsimony heuristic: models whose total $\Delta$AIC did not exceed the estimated standard error of the pointwise AIC difference were treated as near-equivalent, after which only the lowest-dimensional models were retained. We report (i) generating-family selection by minimum AIC, (ii) parameter bias and RMSE, and (iii) unique generating-family selection under this parsimony rule. Because the third metric is rule-dependent, conventional $\Delta$AIC values and Akaike weights are also reported.

Define whether bootstrap intervals are confidence intervals for the Monte Carlo estimand and report Monte Carlo standard error if relevant.

#### `main.md:55`

Strong paragraph, but make the verification claim precise:

> The archive contains the input extract subject to its applicable data terms, analysis code, tests, workflow, pinned environment, frozen simulation outputs and provenance records. The supplied outputs were generated under R 4.5.3; independent reviewers can rebuild summaries from the frozen outputs without rerunning the full simulation matrix.

Do not imply that the final public repository can necessarily redistribute the source data until licensing/governance is resolved.

### Results

#### `main.md:61`

Delete the statement that the three method-specific curves have broadly similar shapes until they are recomputed on identical memberships. If retained after repair, report quantitative between-method distances rather than only visual adjectives.

Use:

> Because each curve is normalised separately, the panels compare relative temporal shape and do not preserve differences in the number of retained determinations or total event intensity.

#### `main.md:63`

Change “choosing the oldest determination” to “retaining the within-site maximum under the specified chronological ranking”.

Do not interpret the 600–700 cal BP youngest peak without a boundary sensitivity. A defensible current sentence is:

> Full youngest-date retention concentrates density near the younger analysis boundary; the magnitude and location of this feature are sensitive to date membership and boundary handling and are evaluated in the supplementary window analyses.

#### `main.md:65`

Delete:

> Within each scenario, SPD, KDE, and FD usually track one another despite their different boundary membership.

and

> deformation from the all-dates reference is much larger than the baseline differences among summary methods.

Replace, after common-membership analysis, with a quantitative statement such as:

> Across common-membership curves, median total-variation distance from the all-date baseline was $X$ under full oldest retention and $Y$ under full youngest retention, compared with a between-method distance of $Z$ for the all-date set.

Until those values exist, state only that retention changes the displayed curves.

#### `main.md:69`

Change “accuracy and support estimate pools” to “the displayed aggregate generating-family selection rates pool”. Add:

> Truth-specific confusion matrices are reported in [main figure/table], because pooled fractions can mask deterministic family-specific failures.

Use “Figs. 3–5”.

#### `main.md:73`

The numerical reporting is clear. Add the conditional scope in the opening sentence:

> For the 10-fold monotonic signals and 116-site exchangeable design, all-date and multi-date random retention give high pooled generating-family selection rates.

Avoid “retain high accuracy across all intensities” without that qualifier.

#### `main.md:75`

After signed-model rerun, this paragraph will change. In the current manuscript, explain that the one-sided candidate set contributes to the outcome:

> Because decreasing linear and exponential candidates were not fitted, oldest-date retention could express an induced older-age trend only by moving towards the uniform boundary. The deterministic 100% outcomes should therefore be interpreted as failures within the restricted candidate set, not as unrestricted estimates of demographic direction.

This caveat belongs in Results, not only Limitations.

#### `main.md:79`

Change “effectively unbiased” to “showed mean bias close to zero in the implemented simulations”.

Mark bound-hit estimates as censored and report bound-hit frequencies. Prefer a common effect-size scale:

> bias in log end-to-start density ratio

rather than raw slope/rate units on incomparable axes.

#### `main.md:83`

Change the heading to:

> **3.2.3 Unique selection under the parsimony rule**

Replace “unambiguous support” throughout. Clarify that the metric is not a posterior probability or conventional evidence threshold.

#### `main.md:85`

Same terminology change. Add truth-specific results rather than relying on the pooled 0.667 value.

#### `main.md:87–89`

Change the heading to:

> **3.2.4 Realised-observation-noise sensitivity**

Lead with v1:

> The prespecified v1 full-family screen failed three of 18 gates. Observed paired point changes were nevertheless small within the all-date and random-retention strategies tested: ...

Then describe v2 as exploratory:

> After inspecting v1, we defined a narrower post-unblinding diagnostic over the three failed paired-difference estimands. Those v2 diagnostics passed their stated margins, but they do not convert v1 into a pass and do not address oldest, youngest or bracketed retention.

Delete “preserved the ranking” unless the exact tested subset is named in the same sentence.

#### `main.md:93`

Replace the entire synthesis paragraph. Suggested current-design wording:

> The empirical retention experiment and exchangeable-date simulations show that post hoc within-site retention can alter descriptive curves and simple model-based inference. In the simulations, random retention of three or five dates preserved high recovery of the implemented 10-fold monotonic signals, whereas random-1 reduced discrimination. Retaining within-site maxima or minima produced strong order-statistic deformation; the resulting model-selection failures are conditional on a candidate set that excluded declining trajectories. The realised-observation-noise analysis supported small point changes for all-date and random strategies, although the prespecified v1 screen failed three gates and the boundary rules were not tested. Because site labels did not encode occupation histories and the number of sites was fixed, these results do not evaluate stratigraphic sampling or whether additional site coverage compensates for within-site bias.

### Discussion

#### `main.md:99`

The first sentence is too broad. Use:

> We evaluated how post hoc within-site retention rules propagate into regional radiocarbon summaries and recovery of simple age-density models under an exchangeable-date design.

Delete the claim that method choice has a smaller visual effect until the common-membership analysis supports it.

Change “recover the generating family reliably” to “gave high generating-family selection rates for the strong monotonic signals considered”.

End with v1 first, v2 second.

#### `main.md:101`

Replace wholesale:

> The AustArch panels illustrate the consequences of retaining within-site age extrema from an already dated benchmark. The oldest rule selects the maximum observed determination within each site; it does not directly estimate occupation onset. The youngest rule selects the corresponding minimum, bracketed retention combines both extrema, and random-1 increases variation among retained datasets. Under the exchangeable simulation, these effects have an order-statistic interpretation. A separate site-history model is required to determine how they relate to basal, terminal or stratigraphically distributed field samples.

Delete both sentences about increasing site coverage and making bias look more precise unless site count is varied.

#### `main.md:105`

Change:

> if many sites contribute only their earliest context, latest context, or a single arbitrary context, the regional evidence is compromised

To:

> if compiled datasets systematically retain age extrema or single determinations, regional inference can be distorted before a curve is drawn or model fitted.

“Can be distorted” is warranted; “is compromised” is too categorical.

#### `main.md:107`

Good conceptual paragraph, but revise the parsimony-rule sentence:

> The auxiliary parsimony rule exposes weak discrimination that minimum-AIC classification alone can conceal, although it is a study-specific heuristic rather than a general measure of model support.

Add that richer models require identifiability checks under realistic signal strengths.

#### `main.md:111`

Delete the first two sentences about large samples and adding more sites; the simulation keeps site count fixed. Replace with:

> Increasing the number of determinations does not by itself remove systematic selection bias. In the present fixed-site design, applying an outcome-dependent retention rule to a larger proportion of sites strengthened the induced distortion. Whether increasing the number or geographic coverage of sites mitigates or sharpens that bias remains to be tested directly.

Keep the caution that random-$n$ is a benchmark, not a field prescription.

#### `main.md:113`

The recommendation to exclude or down-weight one- and two-date sites is not tested directly and could create its own selection bias. Replace with:

> Regional analyses should report site-level contribution distributions and conduct prespecified sensitivity analyses that vary site weighting, sparse-site inclusion and plausible retention histories. Excluding one- or two-date sites is one possible diagnostic, not a default correction, because sparsely dated sites may carry unique spatial, temporal or site-type information.

#### `main.md:115`

“Date all eligible secure contexts where budgets allow” is reasonable professional advice but not an inference from this experiment. Soften and distinguish external practice from result:

> For new programmes, broad contextual coverage and replication are generally desirable, but the present simulations do not identify an optimal number or spacing of determinations. A future site-history analysis should compare cost-matched basal, terminal, random and stratified allocation designs directly.

Keep the repository metadata recommendation, but specify fields such as context, phase, stratigraphic relation, material, pretreatment, reservoir correction and reason for sample selection.

#### `main.md:119`

Change “audit within-site selection and coverage” to “audit per-site contributions, retention rules and site inclusion”.

Avoid a universal ordered workflow unless justified; taphonomy, research intensity and selection may need joint modelling rather than serial correction.

#### `main.md:121`

The limitations paragraph is unusually candid but must add the two most important omissions:

- the one-sided fitted model space;
- method-specific empirical membership and raw-age reservoir confounding.

Suggested replacement opening:

> The simulations isolate a restricted set of mechanisms: a fixed 116-site design, exchangeable within-site dates, constant or 10-fold increasing regional age densities, and candidate models that allow only constant or increasing trajectories. They therefore omit both archaeological site histories and the declining alternatives needed to estimate oldest-induced direction freely.

Then add:

> The empirical method comparison also used method-specific date memberships, and conventional-age ranking combined terrestrial, marine and freshwater determinations without site-specific reservoir corrections. These features must be addressed before comparing the magnitude of retention and summary-method effects.

Retain the remaining limitations, but shorten the catalogue after the key issues are explicit.

#### `main.md:125`

Replace with a conclusion that matches the current design:

> Per-site contributions should be treated as part of the data-generating process in radiocarbon “dates-as-data” analysis. Under the exchangeable-date design studied here, post hoc retention of within-site extrema produces order-statistic distortion, while sparse random retention reduces discrimination among strong simple age-density models. These results support transparent reporting and sensitivity analysis of site-level contributions, but they do not yet quantify prospective stratigraphic sampling or establish an optimal number of dates per site. Stronger guidance requires signed demographic models, matched-resource comparisons and simulations with explicit site histories.

After the recommended reanalysis, replace this with the new positive field-design conclusion.

### Statements after the main text

#### `main.md:129`

- Replace placeholders.
- Change “de-identified” to “author-anonymised”.
- Cite the original dataset DOI and exact extract provenance.
- Distinguish code licence from data licence.
- Do not promise unrestricted public release of sensitive or licence-constrained fields.

Suggested structure:

> Code, derived non-sensitive tables, frozen summaries and reproducibility materials are available at [DOI]. The source AustArch data are available under the terms of the original repository record [dataset DOI]. The public analysis archive uses author-anonymised site identifiers and excludes precise coordinates; controlled-access material, if any, is described in the repository metadata.

#### `main.md:137`

The AI statement is broadly suitable. Tighten to the publisher’s standard form and avoid implying that AI performed scientific validation:

> During preparation of this work, the authors used OpenAI ChatGPT and Codex for source-format conversion, code-workflow checks and language-editing suggestions. The authors reviewed and edited all outputs, independently verified the scientific content and take full responsibility for the article.

Check the exact current Elsevier declaration template immediately before submission.

#### `main.md:139–143`

Delete from manuscript content:

```latex
\makeatletter
\def\fps@figure{!ht}
\makeatother
```

Place float controls in the LaTeX template or Pandoc metadata. Raw placement instructions should not appear between declarations and references.

---

## Supplementary Information: detailed edits

### `supplementary.md:3`

Change “give the detail needed to reproduce” to “describe the analysis and reproduction workflow”. Full reproduction also depends on software, source-data access and the supplied frozen outputs.

### `supplementary.md:11`

Good disclosure of the source-extract mismatch, but add exact provenance:

- extraction date/version;
- person or repository from which it was obtained;
- transformations between the 2014 deposited release and the archived 5,288-record extract;
- applicable data terms.

Replace “parameterise realistic site structures” with “parameterise site counts and reported-error structure in the conditional well-dated benchmark”. The current simulation does not parameterise temporal site structure.

### `supplementary.md:13`

Replace “records flagged as erroneous or unrelated to human activity were removed” with the exact coded logic. State that `U` was retained and report final `Y/U` counts.

“Both conventional and AMS” is not a meaningful quality equivalence; report method composition if it matters or omit.

### `supplementary.md:15`

Delete “well-attested” and “clearly anthropogenic”. The final data include occupation status `U`, marine shell without $\Delta R$, freshwater shell without local reservoir correction and human bone collagen. Give the accepted material and site-type lists in a table and justify them.

Add primary/sensitivity branches:

- terrestrial charcoal/short-lived terrestrial material;
- terrestrial including wood/charcoal;
- marine/freshwater-inclusive sensitivity;
- occupation `Y` only versus `Y+U`.

### `supplementary.md:17`

The claim that 651 cal BP “avoids near-modern boundary effects” is contradicted by the full-youngest peak at the boundary and the method-specific loss of dates. Replace with a neutral rationale and show window sensitivity.

State the posterior-overlap rule precisely, including the absence of a minimum in-window mass threshold. Add a table of effective date counts by method and scenario to the SI rather than leaving it only in the repository.

Do not call random downsampling of well-dated sites “sparse-site analogues” without qualification; it reproduces a date count, not the selection history of a genuinely sparsely dated site.

### `supplementary.md:23–31`

For each descriptive method, separate:

- membership rule;
- posterior/point representation;
- smoothing;
- boundary correction;
- normalisation.

After revision, all three methods in a direct comparison should use identical date membership. State whether the SPD’s 100-year running mean is applied before or after truncation and renormalisation. A smoothed SPD is no longer the raw SPD; name it accordingly.

For the FD’s two-bin centred running mean, explain treatment of endpoints. A two-bin “centred” mean is asymmetric unless a precise alignment convention is specified.

For KDE, use boundary correction or padded evaluation and quantify remaining leakage.

### `supplementary.md:35`

Replace “To mimic field and budget constraints” with:

> To examine post hoc date-retention effects in an already dated benchmark...

Define random-2 if added. Replace raw conventional-age extrema with the revised chronological rule. Separate field-context strategies in a new site-history section.

### `supplementary.md:37`

Use “site-treatment proportion” and explicitly state that all sites remain represented. Define the site-subset randomisation and whether common random site subsets are shared across strategies for paired comparisons.

### `supplementary.md:39`

This paragraph should lead with reservoir limitations rather than place them in a subordinate clause. Add tie handling and common membership. The present phrase “according to marine-context classification” should identify the exact field and its values.

### `supplementary.md:47`

The date-count and error models need parameter estimates, diagnostics and uncertainty. Report:

- truncated-negative-binomial estimates with standard errors or bootstrap intervals;
- empirical versus fitted moments and tail probabilities;
- log-error regression coefficients, $R^2$, residual SD and heteroscedasticity diagnostics;
- whether simulated errors are rounded or bounded;
- sensitivity to empirical age-bin resampling.

### `supplementary.md:51–59`

Expand the data-generating model section after revision.

- State the age orientation clearly: larger cal BP is older.
- Show the exact density equations and normalising constants.
- Fit signed parameters.
- Explain the relationship between the chosen parameter and the end-to-start ratio.
- Include weaker and decreasing signals.
- Report the fitting bounds in natural units and why they are scientifically reasonable.

Do not describe bound-saturated bias as simply “extreme”; report the proportion of estimates at each bound and treat plotted values as censored.

### `supplementary.md:63–75`

Retain both equations but rename them:

- $\ell^1$: marginal log-likelihood under the stated calibration-prior/support assumptions;
- $S^2$: expected log-density score.

Add a derivation showing when calibrated posterior integration is proportional to the observed-data likelihood. State the default prior used by `rcarbon::calibrate()` and any per-date normalisation.

### `supplementary.md:77`

This paragraph is formally incorrect when it says “We fitted all models by maximum likelihood estimation under each likelihood definition.” Replace with:

> We maximised the $\ell^1$ marginal likelihood. Separately, we maximised the summed expected log-density score $S^2$ as a sensitivity analysis. AIC was calculated only for $\ell^1$; for $S^2$ we report a descriptively penalised score and do not invoke AIC’s likelihood-based interpretation.

Then explain the custom parsimony rule. Rename all `ose` outputs in prose, even if legacy column names remain in code.

### `supplementary.md:81–85`

Add random-2 and matched-$N$ scenarios. State the number of unique simulated datasets versus repeated strategy/intensity evaluations. The current phrase “63,000 strategy-intensity dataset combinations” may be read as 63,000 independently generated datasets, although common random numbers and repeated all-date rows are used.

Show truth-specific confusion matrices and boundary rates. Change “accuracy” and “unambiguous support” terminology as above.

### `supplementary.md:89–104`

Rename the section “Paired realised-observation-noise sensitivity”.

The equation should distinguish latent calendar age, curve-mean conventional age, curve uncertainty and quoted laboratory uncertainty. Explain whether `ccError` is treated as independent across dates and why.

After the full seven-strategy rerun, explain whether the retention rule is applied before or after realised observations. For outcome-dependent rules it must be reapplied if the estimand is the complete observed-date procedure.

Present v1 first and v2 second. Keep the exact failed gates. Move the long gate-family description to a table. Avoid making identical bootstrap critical widths from two seeds sound like independent scientific validation; it is a useful computational stability check.

### `supplementary.md:108`

Change “de-identified” to “author-anonymised”. Distinguish:

- fast static/output verification;
- full source-data pipeline;
- expensive simulation regeneration.

State which outputs a reviewer can reproduce without access to restricted source data.

### Supplementary Figure S1 (`supplementary.md:116`)

Add the fold-change ratio and direction directly to the caption. Once expanded, show multiple effect sizes or place the full design grid in a table.

Suggested current caption opening:

> **Supplementary Figure S1.** Regional event-age densities used in the exchangeable-date simulation. Linear and exponential curves increase ten-fold towards the present over 11,650–651 cal BP; the uniform density is constant.

Do not call example radiocarbon-date distributions “site structure” unless site histories are modelled.

### Supplementary Figure S2 (`supplementary.md:122`)

Add fitted parameter estimates, uncertainty and a goodness-of-fit diagnostic. Consider a rootogram or empirical/fitted cumulative distribution rather than only a long-tailed count plot.

### `supplementary.md:126`

Replace “$\ell^2$ runs recovered the same broad ranking” with a neutral sensitivity statement and avoid likelihood terminology. Report where conclusions differ, not only where they agree. The v1 $\ell^1/\ell^2$ consistency gate does not validate $\ell^2$ as a likelihood.

---

## Figure and caption edits

### Figure 1

**Scientific issue:** the methods use different memberships, and the curves are separately normalised.

**Redesign:**

- Primary panel: all three summaries from identical terrestrial/common-window dates.
- Secondary panel or SI: current method-native membership as a sensitivity.
- Annotate effective $N$ directly.
- Consider plotting unsmoothed SPD faintly and smoothed SPD prominently so smoothing is visible.
- Add quantitative between-method distances in the caption or adjacent table.

**Caption replacement skeleton:**

> **Figure 1.** Descriptive radiocarbon summaries for the common-membership AustArch benchmark. All curves use the same $N=\ldots$ terrestrial determinations and are evaluated over 11,650–651 cal BP. The SPD sums calibrated posterior mass [with stated smoothing], the FD counts prespecified point summaries in 100-year bins [with stated display smoothing], and the boundary-corrected Gaussian KDE uses bandwidth 100 years. Each curve is normalised to unit integral; the figure therefore compares temporal shape rather than total intensity. Model fitting does not use these aggregate curves.

### Figure 2

**Current presentation problem:** at 57% width, the ten panels, three curves and uncertainty bands are too dense. The all-date baseline is not overlaid, making deformation harder to judge. Boundary and membership differences dominate some panels.

**Redesign options:**

1. Plot **difference from the all-date baseline** for each method, with a horizontal zero line.
2. Put 100% treatment in the main text and 50% in the SI.
3. Use one row per method and columns for retention rules, or one figure per method.
4. Add the all-date baseline as a thin common reference.
5. Report total-variation or Wasserstein distance beside each panel.

Avoid a single common $y$ scale if it hides structure in low-amplitude panels; difference plots solve this better than free scales.

**Caption:** replace “sub-sampling” with “post hoc date retention”, list common effective $N$, and state that deterministic extrema are single realised rules rather than uncertainty-free estimates.

### Figure 3

- Replace “accuracy” with “minimum-AIC generating-family selection rate”.
- Remove or relabel the $1/3$ line.
- Add shape and line-type encoding so the figure is not colour-dependent.
- Show truth-specific facets or add a main-text confusion matrix.
- Make clear that all-date is repeated only as a visual reference.
- After signed/effect-size expansion, show direction and effect-size strata or move pooled family recovery to the SI.

### Figure 4

- Mark bound-saturated estimates with arrows, open symbols or explicit censoring marks.
- Report bound-hit frequency.
- Prefer bias in log fold change or another common effect scale, allowing linear and exponential results on the same axis.
- “Horizontal bars span the 2.5th to 97.5th percentiles” should be labelled central replicate ranges, not uncertainty in the mean.
- Remove the explanatory sentence that presumes youngest selection is a field-context process.

### Figure 5

- Rename outcome to “unique generating-family selection under the parsimony rule”.
- Add non-colour encodings.
- Show conventional model-selection quantities nearby so readers can interpret the custom metric.
- Truth-specific panels are essential because pooled 0.667 can represent deterministic failure for one family.

### Supplementary figures

- S1: add signal magnitudes, direction and common axes; expand beyond one strong signal.
- S2: add fit parameters and uncertainty; show residual or cumulative fit diagnostics.
- Add new SI figures for filter flow, common-membership/window sensitivity, reservoir/material sensitivity, truth-specific confusion, matched-$N$ comparisons and realised-noise results for all strategies.

---

## Cover letter: line edit

### `draft_cover_letter.md:1`

Update the date on the day of submission.

### Lines 8–10

Use the final title and avoid claiming the field-context problem is directly tested. Suggested replacement:

> I am pleased to submit our manuscript, *[FINAL TITLE]*, for consideration as a Research Article in the *Journal of Archaeological Science*. Radiocarbon “dates-as-data” analyses are shaped by how many determinations each site contributes and which completed determinations are retained. We quantify this dataset-formation process and, in an expanded simulation with explicit site histories, compare cost-matched within-site allocation strategies.

If site histories are not added, replace the second sentence with a narrower post hoc retention statement and reconsider journal fit.

### Line 12

“Empirically parameterised site structure” is inaccurate. Replace with:

> The AustArch benchmark supplies site count, conditional dates-per-site and reported-error distributions; the revised simulations additionally model site duration and within-site temporal structure.

If the latter is not added, say “site labels and date-count structure”, not site structure.

### Line 14

Delete the unsupported empirical cross-method comparison. Lead with signed-model and site-history results after reanalysis. Report realised-noise evidence without invoking v2 as confirmatory.

### Line 16

The scope-fit sentence should identify the general methodological advance rather than simply assert fit. For example:

> By separating site formation, assay allocation, date retention and model fitting, the study provides a general framework for diagnosing how archaeological dating design propagates into regional demographic inference.

### Line 18

Ensure the repository wording matches actual data permissions and the journal’s single-anonymised process. Use “author-anonymised review package” if appropriate.

### Suggested current-design cover-letter warning

Do not submit a cover letter claiming “which contexts within each site are selected for dating” unless the revised simulations actually model context selection.

---

## Submission checklist and title page

### `submission_checklist.md:43–45`

Correct:

> JAS currently uses double-anonymized review.

To:

> JAS currently uses single-anonymised review. Confirm the portal’s current file-separation and metadata instructions, and inspect the generated review PDF for unintended confidential information.

The present author-anonymisation workflow is optional rather than a journal requirement.

### Scientific-status section

The checklist currently treats several unresolved issues as settled. Add explicit gates for:

- signed fitted models;
- decreasing truths;
- site-history simulation;
- common-membership empirical curves;
- terrestrial/reservoir primary analysis;
- random-2 and matched-$N$ controls;
- full seven-strategy realised-noise sensitivity;
- source-data licence and Indigenous data-governance review.

Do not mark the manuscript ready while these remain open.

### Word count

Automate the count from the final rendered manuscript and use the journal’s exact exclusions. Remove the approximate source count once the submission PDF is generated.

### `title_page.md`

- Update the title.
- Verify that affiliations and funding acknowledgements are current and complete at submission.
- Add ORCIDs if requested by the portal, not necessarily in the title-page file.
- Use the publisher’s preferred CRediT formatting.
- Ensure the author contributions reflect responsibility for data governance and source-data permissions.

---

## Repository metadata and workflow edits

### `private_review_repository_metadata.md`

Change:

> de-identified input data

To:

> author-anonymised analysis data, with site identifiers and location precision handled according to the source-data terms and governance review.

Do not list “Dataset/software” under a single Unlicense unless both components can lawfully and ethically use that licence. Prefer separate code and data records or an explicit mixed-licence statement.

### `anonymised_repository_workflow.md`

The private-link workflow is careful but is built around double-blind assumptions that do not apply to current JAS review. Simplify after checking the portal. Keep the hash/download verification steps; they are excellent.

Add manual checks for:

- site names, exact coordinates and human-remains records;
- source-data licence compatibility;
- Indigenous data-governance conditions;
- hidden identifying metadata inside PDFs/RDS objects;
- whether the private-link service exposes creator names or file metadata.

### Package README

Replace “de-identified” with “author-anonymised”. State explicitly that source site identities and coordinates are either removed, coarsened or governed. Do not describe the archive-level Unlicense as applying to data.

### CSL/build

Bundle an independent CSL file or document the required parent style. The supplied Elsevier Harvard CSL depends on a remote parent and failed in an offline build. This is a minor submission issue but a reproducibility defect.


---

# Prioritised revision sequence and decision gates

The revision should be handled as a scientific redesign followed by a rewrite, not as a sequential copy-edit of the current prose. Otherwise, polished wording will repeatedly have to be discarded as the estimand and results change.

## Phase 1: freeze the construct and claims

Before generating new results, choose explicitly between the two defensible paper identities.

### Route 1: archaeological sampling-design paper for *JAS*

Adopt this route only if the analysis will add a site-history generator and prospective context-selection rules. The paper may then address how archaeological temporal structure and assay allocation interact with regional dates-as-data inference.

### Route 2: order-statistic/date-retention methods paper

Adopt this route if the current exchangeable architecture remains central. The paper should then ask how post hoc retention of within-site determinations changes regional calendar-age densities and model discrimination. This is still publishable work, but the title, motivation, claims and venue should reflect the narrower estimand.

**Gate 1:** no further prose should call the current maximum/minimum operations “basal”, “terminal”, “onset”, “termination” or prospective field sampling unless the new generator genuinely implements those objects.

## Phase 2: repair the empirical analysis

1. Define a terrestrial, non-reservoir primary set.
2. Give SPD, FD and KDE exactly the same determinations within each scenario.
3. Harmonise inclusive/strict analysis-window rules.
4. Quantify posterior mass lost at the window and test minimum in-window-mass thresholds.
5. Add an edge-aware KDE or an explicit sensitivity to edge correction and bandwidth.
6. Replace visual assertions with curve-distance estimates and uncertainty or resampling distributions.
7. Report the complete record/site flow and the composition of every final set.
8. Audit conventional-age ties and specify a deterministic, scientifically justified tie rule.
9. Decide whether `U` occupation-status records belong in the primary set; if retained, state why and provide a `Y`-only sensitivity.
10. Remove site names and precise coordinates from distributable files unless their inclusion is specifically justified and governed.

**Gate 2:** the statement that retention matters more than curve method may return only if it is supported by a common-membership quantitative comparison. Otherwise, delete it.

## Phase 3: repair the simulation and design contrasts

At minimum:

1. Fit signed linear and exponential families.
2. Generate increasing and decreasing truths.
3. Add random-2.
4. Add comparisons matched on total retained determinations.
5. Vary signal magnitude below 10-fold.
6. Run all seven retention rules under the same realised-observation-noise design.
7. Make the v1/v2 distinction explicit and freeze any new gate before inspecting the new results.

For the preferred *JAS* route:

8. Add at least one site-history model with site start, duration and within-site temporal structure.
9. Define prospective context-selection rules separately from post hoc observed-date extrema.
10. Vary the number of sites independently of dates per site and total assay count.
11. Include at least one non-monotonic regional history.

**Gate 3:** no recommendation about a minimum number of dates per site should survive unless it is stable across weaker signals, varying site histories and matched-cost designs.

## Phase 4: repair inference and reporting

1. Treat $\ell^1$ as the likelihood-based primary analysis under an explicit calibration-prior/support statement.
2. Relabel $\ell^2$ as an expected-log-density scoring sensitivity.
3. Report conventional $\Delta$AIC and Akaike weights alongside the custom parsimony rule.
4. Put truth-specific confusion matrices in the main paper.
5. Report common effect sizes, trajectory errors and boundary-hit frequencies.
6. Distinguish replicate distributions, bootstrap confidence intervals and any parameter uncertainty intervals.
7. Report Monte Carlo uncertainty for all headline simulation proportions.
8. State exactly what remains fixed versus re-estimated in each replicate.

**Gate 4:** the words “maximum likelihood”, “AIC” and “model support” must be attached only to quantities for which those labels are formally justified.

## Phase 5: rewrite from the results outward

Recommended order:

1. Results tables and figures.
2. Methods, including the estimand and simulation DAG/generative diagram.
3. Discussion and limitations.
4. Introduction.
5. Abstract, title, highlights and cover letter.
6. Supplement and repository documentation.

Do not update the abstract by editing isolated numbers into the current version. Rebuild it after the revised figures and primary contrasts are frozen.

## Phase 6: independent reproducibility and submission audit

- Rebuild from a clean checkout or container.
- Verify every generated table and figure against the manuscript.
- Recompute checksums.
- Confirm that all random seeds and package versions are recorded.
- Inspect reviewer and public archives for author identifiers, site identities, exact coordinates, human-remains records and hidden metadata.
- Verify source-data permissions and separate software/data licensing.
- Test the complete manuscript build without network access, including CSL dependencies.
- Run an independent scientific read that does not rely on this report.
- Generate the final review PDF and inspect it manually before upload.

**Submission gate:** submit to *JAS* only after M1–M9 in the priority matrix have either been resolved empirically or removed from the paper’s claims. M10 is an administrative correction but should also be fixed.

---

# Compact submission-readiness checklist

Use this as the final go/no-go list.

## Scientific identity

- [ ] The intervention is named consistently as prospective context selection or post hoc date retention, never both without distinction.
- [ ] The target estimand is stated in one sentence in the abstract and Methods.
- [ ] Claims about site onset, termination, site coverage and field design correspond to implemented variables.

## Simulation validity

- [ ] Increasing and decreasing model families are both available.
- [ ] Truth direction and effect size are varied.
- [ ] Random-2 and matched-total-$N$ controls are present.
- [ ] Site count, dates per site and total dates are not conflated.
- [ ] The realised-noise arm includes the biased retention rules or the omission is no longer used to support their ranking.
- [ ] A site-history generator is present for the *JAS* route.

## Empirical validity

- [ ] Curve methods use common memberships within each formal comparison.
- [ ] Reservoir-sensitive materials are excluded, corrected or stratified in the primary analysis.
- [ ] Boundary and KDE-edge sensitivities are reported.
- [ ] Conventional-age extrema and ties are documented.
- [ ] Record and site attrition are fully tabulated.
- [ ] Composition of `Y` and `U` records is stated.

## Statistical language

- [ ] $\ell^1$ likelihood assumptions are explicit.
- [ ] $\ell^2$ is not called a likelihood or AIC analysis without a formal derivation.
- [ ] The custom parsimony rule is named descriptively.
- [ ] Truth-specific results accompany pooled summaries.
- [ ] Monte Carlo uncertainty is reported.
- [ ] “Central 95% replicate range” is not called a confidence interval.

## Governance and reproducibility

- [ ] Author anonymisation is not described as data de-identification.
- [ ] Site names/coordinates and human-remains records have been reviewed for release.
- [ ] AustArch extract provenance and version lineage are documented.
- [ ] Code and data licences are separate and valid.
- [ ] Indigenous data-governance considerations are documented.
- [ ] A clean, offline rebuild succeeds.
- [ ] The journal’s current single-anonymised process is reflected in all files.

## Presentation

- [ ] Main figures show truth-specific outcomes and effective sample sizes.
- [ ] The abstract contains no field-design recommendation unsupported by the revised experiment.
- [ ] Highlights are each at most 85 characters.
- [ ] Cover-letter claims match the manuscript exactly.
- [ ] All placeholders and internal review notes are removed.

---

# Minor copy-edit and formatting sweep

These points are subordinate to the scientific revision but should be addressed in the final pass.

1. Use **radiocarbon determination** for a laboratory result and **calendar-age density** for the calibrated temporal object. Avoid using “date” for both without qualification.
2. Define conventional $^{14}$C yr BP, cal BP, SPD, FD and KDE at first use in both the main text and supplement where they must stand independently.
3. Use en dashes in numerical ranges and minus signs for mathematical negatives.
4. Use non-breaking or protected spacing between values and units in the rendered manuscript where supported.
5. Standardise thousands separators: `11,650`, not a mixture of `11650` and `11,650` in prose.
6. Standardise figure references as “Fig. 1”, “Figs. 3–5” and “Supplementary Fig. S1”.
7. Use **Akaike information criterion** on first mention; use AIC thereafter.
8. Avoid capitalising generic model names unless they begin a sentence.
9. Replace “robust” with the actual perturbation under which the result persisted.
10. Replace “negligible” with an estimate and uncertainty or a prespecified practical threshold.
11. Replace “clear”, “unambiguous” and “reliable” with operational quantities unless the term is explicitly defined.
12. Keep one spelling convention throughout. The manuscript currently suits Australian/British usage: `normalised`, `modelled`, `artefact` where appropriate, and `-ise` forms.
13. Use `subsampling`, not `sub-sampling`.
14. Distinguish **proportion of sites treated** from **proportion of dates retained** in labels and prose.
15. Do not call the pooled one-third line “chance” without qualification; “uniform random-guess reference” is safer.
16. Italicise statistical symbols but not function names or model labels.
17. Ensure every equation defines its support and every parameter is defined immediately after the equation.
18. Give all simulation sample sizes as replicates per truth × strategy × treatment level, not only a grand total.
19. State whether reported percentages are proportions of all replicates or conditional on successful optimiser convergence.
20. Report the number of failed fits, warnings and boundary solutions, even if zero.
21. Avoid slash constructions such as “oldest/youngest” in formal claims where the two directions have different behaviour.
22. Avoid “respectively” in sentences with more than two long lists; use a table instead.
23. In captions, describe what uncertainty bands represent and whether curves are separately normalised.
24. Captions should define line types and colours so that the figure remains interpretable in grayscale and for colour-vision deficiencies.
25. Remove software-build details from the scientific narrative where they belong in the reproducibility statement or supplement.
26. Keep repository hashes and archival identifiers in a dedicated availability section rather than the abstract, highlights or cover letter.
27. Avoid raw LaTeX float commands in the Markdown source unless the build system specifically requires them and tests them.
28. Verify that every bibliography entry cited in the supplement is included in the final reference list and vice versa.
29. Include dataset and software citations as formal references, not only inline links.
30. Use a neutral phrase such as “the analysis indicates” rather than anthropomorphic formulations such as “the model believes”.

---

# Independent archive-audit record

This section records the numerical and structural checks used in reaching the review. It is included so that the authors can distinguish review findings from interpretive recommendations.

## Integrity and package structure

- Outer ZIP SHA-256: `23eae5a71340d36ea2f2085c31973fee2c3825ba8719dea9f1e3f55275721ded`.
- The supplied sidecar matched the ZIP.
- All 200 internal manifest entries matched their recorded SHA-256 values.
- The archive retained both the failed v1 realised-noise gate and the post-unblinding v2 diagnostic rather than overwriting the former.
- Main and supplementary figure files were present and visually inspectable.
- The supplied CSL depended on an external parent style and was not self-contained in an offline Pandoc build.

## Source and filtered data

| Quantity | Audit value |
|---|---:|
| Input records | 5,288 |
| Radiocarbon records | 4,828 |
| Distinct radiocarbon site labels | 1,704 |
| Final determinations | 976 |
| Final sites | 116 |
| Dates per final site, range | 5–33 |
| Dates per final site, median | 7 |
| Dates per final site, mean | 8.41 |
| Terrestrial-classified records | 804 |
| Marine-classified records | 172 |
| Occupation status `Y` | 372 |
| Occupation status `U` | 604 |
| Human bone collagen records | 11 |
| Reported error, range | 10–810 yr |
| Reported error, median | 80 yr |
| Reported error, 95th percentile | 210 yr |

Freshwater shell materials totalled 56 records but were classified as terrestrial in the supplied table. There were 26 sites containing both marine- and terrestrial-classified determinations, comprising 209 records.

## Empirical extrema and window effects

Using the supplied conventional-age ranking and first-row tie behaviour:

- oldest-date selections included 21 marine and six freshwater-shell determinations;
- youngest-date selections included 13 marine and five freshwater-shell determinations;
- among 26 mixed marine/terrestrial sites, the oldest record was marine in 15 and the youngest was marine in seven;
- 11 selected oldest-date posterior weighted means and 44 selected youngest-date weighted means lay outside the analysis window;
- three sites had tied maximum conventional ages and two had tied minima.

The review-package metadata reported 87 filtered posterior weighted means outside the analysis window. For the window-truncated KDE kernels, retained mass ranged down to approximately 0.536, averaged approximately 0.983, and was below 0.95 for 60 determinations. These facts make membership and edge handling material rather than cosmetic.

## Effective memberships by empirical summary

| Scenario | SPD | FD/KDE |
|---|---:|---:|
| Baseline/all | 976 | 889 |
| Full oldest-date retention | 116 | 105 |
| Full youngest-date retention | 116 | 72 |
| Bracketing | 232 | 177 |
| Random-1 | 116 | mean 105.069 |
| Random-5 | 580 | mean 525.567 |

The full-youngest comparison is therefore especially unsuitable for a statement about curve-construction method alone: the SPD and FD/KDE panels differ by 44 determinations, or 37.9% of the SPD count.

## Empirical error-model check

A separate OLS fit to the filtered table gave

$$
\widehat{\log(\mathrm{ERROR})}
=4.0992+8.564\times 10^{-5}\,\mathrm{AGE},
$$

with $R^2\approx0.170$ and residual standard deviation approximately 0.472. Residual standard deviations by conventional-age quartile were approximately 0.388, 0.425, 0.460 and 0.590, indicating increasing dispersion with age that the homoscedastic log-linear simulator does not reproduce.

## Realised-observation-noise gates

The retained v1 report is a genuine failure: 15 of 18 registered checks failed, including the accuracy-equivalence, support-equivalence and boundary-increase checks. Point changes in pooled generating-family selection ranged approximately from $-0.015$ to $+0.008$, while unique-selection changes ranged approximately from $-0.019$ to $+0.009$.

The post-unblinding v2 difference-only diagnostic passed its revised thresholds:

| Metric | Pooled absolute difference | Truth-specific maximum |
|---|---:|---:|
| Generating-family selection | 0.0203 | 0.030 |
| Unique selection | 0.0240 | 0.038 |
| Boundary frequency | 0.0080 | 0.008 |

These small differences are informative, but v2 does not convert the prespecified v1 result into a pass, and neither gate included oldest, youngest or bracketed retention. The manuscript should preserve exactly that hierarchy.

## Scope of static code verification

The review traced the code implementing:

- the empirical filtering sequence;
- SHCal20 calibration in the simulations;
- the conditional site-count model;
- the log-linear reported-error model;
- exchangeable regional age generation;
- random, extrema and bracket retention;
- calibration-posterior truncation and renormalisation;
- the $\ell^1$ and $\ell^2$ objectives;
- the one-sided linear/exponential parameter bounds;
- the custom pointwise-AIC standard-error rule;
- pooled and truth-specific output summaries.

Because R and Docker were unavailable, this was a static and cross-file audit rather than an independent numerical rerun. That limitation does not affect the construct-level findings in M1–M4, which follow directly from the implemented source and supplied data, but it should be borne in mind for any exact simulation percentage not recalculated independently here.

---

# Sources checked for journal and governance context

The journal-readiness comments were checked against the current official *Journal of Archaeological Science* Guide for Authors, aims and scope, and editorial-board pages on 9 August 2026. Data-provenance comments considered the AustArch data paper and deposited dataset:

- Williams, A. N. *et al.* (2014), “A continental narrative: human settlement patterns and Australian climate change over the last 35,000 years”, *Internet Archaeology* 36, DOI: `10.11141/ia.36.6`.
- Archaeology Data Service AustArch deposit, DOI: `10.5284/1027216`.

The governance recommendation is informed by the AIATSIS Code of Ethics for Aboriginal and Torres Strait Islander Research and the CARE Principles for Indigenous Data Governance. These sources do not determine a single mandatory release decision; they support the recommendation that location precision, human-remains records, provenance, permissions and Indigenous data interests be reviewed explicitly before public dissemination.

Methodological context was also checked against recent primary literature on summed-probability and radiocarbon dates-as-data inference, including work by Crema and Bevan (2021), Crema (2022), Roalkvam (2025) and Park (2026). The manuscript should cite and distinguish the revised method from the most relevant of this literature after the analysis architecture is fixed.

---

# Final review verdict

The manuscript contains the nucleus of a strong paper: an important question, unusually transparent computational work, a coherent likelihood-based primary direction, and a striking demonstration that outcome-dependent within-site retention can deform regional temporal inference. The negative recommendation for immediate submission is therefore not a judgement that the project is unsound or unpublishable.

The problem is that the current manuscript asks the simulation to bear a broader archaeological interpretation than its generative structure supports. Exchangeable regional draws grouped under site labels cannot, by themselves, adjudicate among basal, terminal, stratified or random archaeological context-selection strategies. The missing negative-growth candidates further magnify the apparent failure of the oldest-date rule, while the empirical comparison confounds curve method with membership, edge treatment and reservoir-sensitive ranking. Those issues sit underneath the headline conclusions and must be resolved before a line-polished version is sent to review.

My recommendation is therefore:

> **Major revision before submission; potentially strong for *Journal of Archaeological Science* after construct alignment, signed-model reanalysis, empirical repair and data-governance clarification.**

The most efficient high-value revision is not to add every conceivable realism. It is to make four decisive changes: (1) distinguish prospective sampling from post hoc retention, preferably by adding one defensible site-history generator; (2) permit both temporal directions in truth and fitted models; (3) compare empirical summaries on common, reservoir-appropriate observations; and (4) separate dates per site, number of sites and total assay cost. Once those are done, the excellent provenance architecture already present should make the revised paper unusually credible and reviewable.
