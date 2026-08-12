# Second-round Pro adequacy review and submission-readiness audit

## Manuscript

**Within-site date-retention rules can distort radiocarbon “dates-as-data” inference**

**Target journal:** *Journal of Archaeological Science*  
**Review date:** 11 August 2026  
**Review stage:** second-round independent adequacy review after major presubmission revision  
**Recommendation:** **minor targeted revision**

---

## Editorial recommendation

The revised manuscript is now scientifically defensible, archaeologically useful and appropriately bounded for submission to the *Journal of Archaeological Science*. The two first-round defects most capable of determining the result—the one-direction candidate-model space and the non-common empirical memberships—have been repaired analytically rather than rhetorically. The revised signed simulations support the claimed full-treatment direction-forcing mechanism, and the common-membership empirical benchmark supports robust oldest- and youngest-retention effects across the prespecified sensitivity suite. I do **not** consider a hierarchical site-history generator, a weaker-signal factorial experiment, a matched-total-date experiment or a new realised-noise run mandatory for this paper, because the manuscript now identifies its estimand as post hoc retention among exchangeable dates and avoids field-design or universal-minimum claims. I nevertheless recommend one short revision round before submission. The principal scientific fix is to either extend the existing nine-configuration empirical sensitivity suite to full-site bracketed retention or demote bracketed retention explicitly to a **primary-specification-only** empirical result. A small set of technical and submission fixes is also required: qualify the posterior-based marginal likelihood and analysis-window conditioning; disclose working independence for paired bracketed extrema; insert the exact ten-fold qualifier into the abstract, conclusion and highlights; strengthen AustArch source-data provenance; correct the journal’s review model to **single anonymized**; reduce the abstract below 250 words; resolve archive placeholders; repair the title-page superscript and radiocarbon glyphs; and reconcile the AI declaration with the authors’ actual use. These are targeted corrections, not grounds for another major revision.

---

# 1. Review scope and independent verification

## 1.1 Material reviewed

I reviewed the following as an integrated submission and evidence package:

- the revised anonymous manuscript in PDF, DOCX and source Markdown;
- the Supplementary Information in PDF, DOCX and source Markdown;
- all five main figures and the two supplementary figures;
- the title page, cover letter, highlights and submission checklist;
- the first external review and the Stage 4 response crosswalk;
- the author-anonymized code/evidence repository, including active R source, tests, frozen designs, accepted summaries, validation records, manifests, provenance snapshots and licensing documentation.

I first assessed the revised manuscript on its own terms, then compared it against the first-round criticisms and finally audited the consequential claims against the repository.

## 1.2 Archive integrity

The delivered archive passed the following independent checks:

| Check | Result |
|---|---:|
| Reported ZIP size | 18,102,648 bytes |
| Observed ZIP size | 18,102,648 bytes |
| Reported SHA-256 | `3d5b591afbdf0e7e064ee36973a61fd75ee4d1d659bf5d458253ac97d19c8670` |
| Observed SHA-256 | exact match |
| ZIP structural test | no compressed-data errors |
| Package manifest | 227 of 227 entries verified |
| `make verify-evidence` | all supplied evidence manifests verified |

The signed-model validation record identifies 15 accepted scenarios, 1,000 replicates per scenario and 720,000 fitted-result rows under R 4.5.3, with common-random-number, fingerprint and single-runtime/design checks marked PASS. The empirical validation record identifies 540 dates and 68 sites and marks common membership, finite non-negative unit-mass curves, iteration contracts, total-variation bounds and headline oldest/youngest sensitivity robustness as PASS.

## 1.3 Important verification limit

`Rscript` was not available in the review environment. I therefore could not independently execute the R 4.5.3 test suite, regenerate Figures 3–5 or repeat the high-volume simulations. I **did** verify all supplied SHA-256 manifests, inspect the active code and tests, reconcile machine-readable summaries with the manuscript, and inspect the frozen validation and provenance records. Accordingly, this is a strong static and artefact-level audit, not a claim that the numerical analysis was independently recomputed from source.

This distinction also exposes a small wording error in Supplementary Information line 153: `make verify-evidence` validates checksums; it does not run the scientific tests. The repository README and Makefile describe this correctly, but the SI currently merges the two operations.

## 1.4 Display and document audit

The manuscript PDF is 13 A4 pages and the SI is 7 pages. The figures are legible at ordinary review magnification, captions are generally self-contained, and I found no obvious clipping or missing display item. The anonymous manuscript PDF contains no author metadata. The DOCX files contain no tracked insertions or deletions; the comments parts are present but empty.

Two production defects require correction:

1. the title-page PDF prints `Barry W. Brook^a,*^` literally rather than rendering the corresponding-author superscript; and
2. several reference-list occurrences of `¹⁴C` are rendered as `¹�C` in the manuscript PDF.

---

# 2. Direct answers to the ten adequacy questions

## 2.1 Is the exchangeable-date retention result sufficiently consequential and archaeologically useful for *JAS* without a site-history generator?

**Yes.** The revised paper no longer claims to model prospective archaeological sampling, occupation histories, onset, termination, stratigraphic selection or a universal field protocol. It now isolates a real and consequential database-formation mechanism: after dates have been produced, systematic within-site retention can transform the regional distribution passed to any downstream dates-as-data method. That is a legitimate methodological contribution for *JAS*, particularly because regional radiocarbon compilations often combine unequal and incompletely documented site contributions.

The empirical exercise does not establish how often oldest-, youngest- or bracketed-retention rules occur in actual databases. It need not do so for the present mechanism paper, provided this absence is made explicit. I recommend adding one sentence:

> The one-sided and bracketed rules are diagnostic stress tests; this study does not estimate their prevalence in existing radiocarbon compilations.

A site-history generator would support a different and broader paper. It is not required to validate the present, narrowed estimand.

## 2.2 Has the signed-model repair removed the direction-forcing defect, and do the direction and family-recovery claims match the evidence?

**Yes.** The candidate space now includes uniform, signed linear and signed exponential models, while the generating design includes uniform, linear increase, linear decrease, exponential increase and exponential decrease. This removes the first-round confounding in which a one-direction model space made some apparent failures inevitable.

The accepted primary summaries support the revised claims:

- under full treatment, oldest retention selects a decreasing state and youngest retention an increasing state in every one of 1,000 replicates under each of the five truths;
- the opposing one-sided rule reverses the selected direction in every full-treatment non-uniform replicate;
- under uniform truth, full oldest and full youngest retention select the corresponding exponential direction in every replicate;
- at 50% and 75% treatment, the adverse rule does not reverse the non-uniform direction but increasingly favours uniform;
- all four random rules preserve direction in all simulated non-uniform cells, while family recovery falls as information is discarded;
- full bracketed retention preserves non-uniform direction but changes all simulated linear truths into exponential family selections.

The manuscript now distinguishes signed-state recovery from generating-family recovery, which is essential. The remaining edits are qualification edits: say **full treatment** wherever reversal/manufacture is summarized, and say **simulated ten-fold monotonic truths** rather than merely “strong truths” or “strong trends.”

## 2.3 Does the common-membership empirical analysis support the ordering claimed for oldest, youngest and bracketed retention? Is bracketed retention overgeneralized?

**Oldest and youngest are strongly supported; bracketed is supported only under the primary empirical specification and is currently given slightly too much headline parity.**

Under the primary specification, all three deterministic full-site boundary rules pass the conservative retention-versus-method gate:

| Full-site rule | Conservative contrast, $C$ | Direction of mean-age shift | Status |
|---|---:|---|---|
| Oldest | 0.1925 | older | passes primary and all nine sensitivities |
| Youngest | 0.3703 | younger | passes primary and all nine sensitivities |
| Bracketed | 0.0837 | older | passes primary only; not sensitivity-tested |

The bracketed result is not false, and its smaller margin is still positive. The problem is evidential symmetry: the abstract, cover letter and conclusion place it alongside oldest and youngest without immediately saying that only the one-sided rules were taken through the nine-configuration sensitivity suite. The main Results eventually make the distinction, but the high-level wording invites a reader to infer common robustness.

The smallest defensible repair is an either/or decision:

1. **Preferred:** run full-site bracketed retention through the existing nine configurations and report the result; or
2. **No-new-analysis route:** label it everywhere as a primary-specification result and remove it from any sentence implying the same robustness as oldest and youngest.

Either route is sufficient. The second route does not weaken the central paper, because the primary headline is one-sided directional distortion.

## 2.4 Does omission of realised observation noise for the headline one-sided rules require one final analysis?

**No, not for the present bounded paper.** The manuscript is now transparent that the calibration-curve-mean observation model propagates posterior width and calibration structure but omits realised conventional-age variation, and that the earlier v1 screen did not include oldest, youngest or bracketed retention. It also preserves the v1 FAIL decision and labels v2 as post-unblinding rather than using it as confirmatory evidence.

A realised-noise extension would be worthwhile future work, but it is not needed to establish the mathematical order-statistic mechanism under the stated observation model. The authors must continue to resist wording such as “noise robust,” “observation-model invariant” or “universal.” The replacement abstract below keeps this boundary visible.

## 2.5 Are the ten-fold signal and simplifying assumptions qualified sufficiently?

**Substantively yes, but the most visible text should be more exact.** The Methods and limitations identify the ten-fold endpoint contrast, exchangeable dates, absence of site histories, fixed Holocene window, single empirical site-count/error parameterization, changing retained sample size and omitted realised noise. Those are adequate boundaries.

The abstract currently says “all strong monotonic truths,” the conclusion says “strong trends,” and the highlights omit the effect size. Those phrases are too easy to detach from the Methods. Replace them with “the simulated ten-fold monotonic truths.” This is a wording fix, not a request for weaker or pulsed simulations.

## 2.6 Are likelihood, AIC, scoring-rule and effect-size terms technically correct and consistently used?

**Mostly, but not completely.** The revision correctly reserves “likelihood” and “AIC” for the primary $\ell^1$ criterion and calls $\ell^2$ an expected-log-density scoring sensitivity. It also uses the common end-to-end log-density ratio

$$
\theta=\log\left\{\frac{f(651)}{f(11650)}\right\}
$$

appropriately to compare signed linear and exponential effects.

Two qualifications remain necessary.

First, using the calibrated posterior $p_i(x)$ in

$$
\ell_i=\log\int f(x\mid\theta)p_i(x)\,dx
$$

is equivalent to the observed-data marginal log likelihood up to a date-specific constant only under the calibration prior used to construct $p_i(x)$. The code trims each posterior to the strict analysis window and renormalizes it, so the implemented criterion is also conditional on posterior mass falling within that window. State the uniform calendar-age prior and the conditioning explicitly.

Second, bracketed retention contributes two dependent extrema from the same site. The fitted product criterion treats those posteriors under working independence. Thus ordinary AIC calibration is not exact for a paired-extrema generative likelihood. This does not invalidate the diagnostic result, but the manuscript should state that bracketed family-selection rates describe the analysed workflow rather than likelihood support under a joint paired-order-statistic model.

With those additions, the terminology is adequate.

## 2.7 Are the abstract, results, figures, discussion, highlights and cover letter traceable to the evidence?

**Almost all are traceable.** The signed direction, reversal, manufactured-uniform-trend, random-retention and family-recovery statements match the supplied summaries. The empirical oldest and youngest statements match the primary and sensitivity evidence. Figure labels and captions are consistent with the machine-readable results.

The two weak points are:

- equal headline treatment of primary-only bracketed empirical evidence; and
- use of “strong” without always naming the ten-fold contrast.

The cover letter repeats both. The replacement abstract and highlights below resolve them.

## 2.8 Is the author-anonymized repository scientifically useful despite excluding raw AustArch records?

**Yes, for the paper’s simulations and for auditing the aggregate empirical result; no, it is not a complete empirical reproduction package, and it does not pretend to be.** The repository is unusually candid about its boundary. Reviewers can inspect active filtering and curve code, the accepted aggregate curves, effective counts, distance summaries, tie audits, sensitivity gates, synthetic artefacts, checksums and provenance. They cannot reconstruct the empirical curves from source records without separately governed access.

That is acceptable for peer review where licensing, sensitive-location risk and Indigenous data governance prevent casual redistribution. What remains incomplete is provenance rather than honesty: the manuscript/SI should identify the exact source extract, retrieval or version date, access route and dataset DOI, and explain why the extract contains 5,288 age records whereas the published release reports 5,044 radiocarbon determinations. Cite the dataset record, DOI `10.5284/1027216`, separately from the data paper DOI `10.11141/ia.36.6`.

## 2.9 Were any major first-round criticisms answered only rhetorically or allowed to disappear?

**The central scientific criticisms were not.** M2–M4 were repaired analytically; M1, M5–M7 were narrowed in a manner that now matches the paper’s estimand; and M8 was substantially corrected. The residual gaps are visible rather than concealed.

Two crosswalk judgements require correction:

- M8 is better classified as **partly resolved**, because prior/window conditioning and paired bracket dependence remain unstated.
- M10 was incorrectly rejected. The current official *JAS* Guide for Authors says the journal follows a **single anonymized** review process, not double-anonymized review.

The bracketed sensitivity omission is acknowledged in the review brief and crosswalk and therefore has not disappeared, but it still needs a manuscript-level resolution.

## 2.10 What is the smallest additional revision that would materially change the submission recommendation?

The recommendation is already “minor targeted revision.” The minimum set required to move to **submit** is:

1. sensitivity-test bracketed retention or demote it explicitly to primary-specification-only status;
2. add the likelihood-prior/window and bracketed working-independence qualifications;
3. make the ten-fold/full-treatment qualifiers explicit in high-visibility claims;
4. complete AustArch provenance and archive identifiers;
5. correct the single-anonymized/250-word journal requirements and the small production defects.

No additional large simulation programme is required.

---

# 3. M1–M10 adequacy matrix

| Issue | Second-round classification | Basis for classification | Required final action |
|---|---|---|---|
| **M1. Exchangeable site labels do not represent site histories** | **Adequately bounded** | The title, estimand, Methods and limitations now identify a post hoc exchangeable-date retention experiment and reject onset, termination, stratigraphic and prospective-sampling interpretations. | Add one sentence saying the diagnostic rules’ prevalence in real compilations is not estimated. No site-history generator is mandatory. |
| **M2. One-direction candidate space forced part of the result** | **Resolved** | Both generating and fitted linear/exponential families now admit either sign; increasing and decreasing truths are included. The full-treatment reversal result survives the repair. | Retain explicit “full treatment” and “ten-fold” qualifiers. |
| **M3. SPD, FD and KDE used different observations and edge rules** | **Resolved** | The 540-date/68-site benchmark uses common membership, common bins, unit-integral normalization and declared boundary treatment. Quantitative total-variation gates replace visual comparison. | Clarify that the nine-way suite covers oldest/youngest only; bracketed requires its own resolution. |
| **M4. Raw extrema mixed reservoir-sensitive materials** | **Resolved** | Shell and human bone are excluded; all retained dates use SHCal20; extrema use calibrated posterior medians with deterministic tie-breaking. | Report source-data provenance more exactly; no reservoir model is required for the stated terrestrial benchmark. |
| **M5. Realised-noise evidence omitted headline rules and v1 failed** | **Adequately bounded** | v1 remains FAIL, v2 is labelled post-unblinding, and neither is used to validate oldest/youngest/bracketed rules. The primary observation-model boundary is now explicit. | Keep the limitation in abstract/SI/discussion. No new realised-noise run is mandatory. |
| **M6. Random-$n$, total sample size and site weighting were conflated** | **Adequately bounded** | Random-2 was added; direction and family recovery are separated; random retention is not promoted as an optimal design or universal minimum. The paper admits that count loss and composition are not separated. | Retain the matched-total-date limitation. No resource-allocation factorial is mandatory. |
| **M7. Generated signal was narrow and strong** | **Adequately bounded** | The paper repeatedly states the ten-fold monotonic design and defers weaker, pulsed and heterogeneous truths. Claims are now mechanism-specific. | Replace vague “strong” wording in abstract/conclusion/highlights with “simulated ten-fold.” |
| **M8. Likelihood, score and support terminology** | **Partly resolved** | $\ell^2$ is correctly treated as a score, and family/state outcomes are separated. The $\ell^1$ prior/window equivalence and bracketed working-independence issue remain unstated. | Add the two technical qualifications set out in Section 6 below. |
| **M9. Archive identification, licensing and Indigenous data governance** | **Partly resolved** | Exclusions, code licensing and governance limits are clear and honest. Exact source-extract provenance, dataset citation, final repository identifiers and release timing remain incomplete. | Add dataset DOI/version/access details; replace placeholders; state public availability no later than publication, subject to named restrictions. |
| **M10. Journal anonymization statement** | **Unresolved** | The crosswalk and checklist incorrectly say double-anonymized. Current *JAS* instructions specify single-anonymized review. | Correct all administrative text and inspect the portal-generated reviewer PDF to ensure author details appear as the live workflow requires. |

---

# 4. Claims-to-evidence audit

| Manuscript-level claim | Evidence inspected | Assessment | Revision needed |
|---|---|---|---|
| The common empirical benchmark contains 540 terrestrial charcoal/wood dates from 68 sites. | `reference_flow.csv`, material/occupation compositions, validation record. | **Supported.** | Add exact source-extract provenance and dataset DOI. |
| SPD, FD and KDE use identical memberships. | Curve-basis code, effective-count file, validation record. | **Supported.** | None scientifically. |
| Full oldest retention deforms curves more than method differences. | Primary $C=0.1925$; all nine sensitivity configurations positive; direction always older. | **Strongly supported.** | None beyond wording. |
| Full youngest retention deforms curves more than method differences. | Primary $C=0.3703$; all nine sensitivity configurations positive; direction always younger. | **Strongly supported.** | None beyond wording. |
| Full bracketed retention deforms curves more than method differences. | Primary $C=0.0837$, older shift. | **Supported under the primary specification only.** | Sensitivity-test it or label/demote it everywhere. |
| Retention generally matters more than curve construction. | Half-site and random rules fail the gate. | **Not claimed in the detailed Results; correctly rejected.** | Ensure abstract/cover do not imply a general hierarchy. |
| Full oldest imposes decreasing and full youngest increasing selection under all truths. | Primary signed summaries: 1.000 in every full-treatment cell. | **Supported.** | Say “under full treatment.” |
| The adverse one-sided rule reverses every non-uniform truth. | Direction-reversal rate 1.000 in every adverse full-treatment non-uniform cell. | **Supported conditionally.** | Add “under full treatment” and “simulated ten-fold.” |
| Either one-sided rule manufactures a trend under uniform truth. | Full oldest/youngest select corresponding exponential state in 1,000/1,000 replicates. | **Supported conditionally.** | Retain observation-model limitation. |
| Random retention preserves direction. | Direction selection 1.000 in all 48 non-uniform random-rule cells. | **Supported only for the simulated ten-fold monotonic truths.** | Insert exact qualifier in abstract, conclusion and highlights. |
| Sparse random retention weakens family recovery. | Family-selection rate across random cells 0.754–0.995. | **Supported.** | Avoid converting this into a field-sampling recommendation. |
| Bracketed retention preserves direction but not family. | Full bracket: all non-uniform directions preserved; linear family recovery 0%, exponential 100%. | **Supported for the implemented working-independence workflow.** | Add paired-extrema dependence caveat. |
| $\ell^1$ is a marginal likelihood and minimum AIC selects family. | Code integrates model density against window-renormalized calibrated posteriors. | **Substantively valid under an unstated uniform calibration prior and conditional window.** | State those conditions. |
| $\ell^2$ is a sensitivity score, not likelihood/AIC. | Text and code. | **Correctly described.** | None. |
| Realised-noise differences were small for tested rules. | v1/v2 summaries; oldest/youngest/bracketed absent. | **Supported for all/random rules only.** | Current limitation is adequate; do not generalize. |
| The conclusion establishes a dataset-formation mechanism, not Australian demography. | Design and manuscript framing. | **Supported.** | Add prevalence caveat and exact ten-fold wording. |

---

# 5. Scientific and archaeological-method assessment

## 5.1 What the revision now gets right

The revised paper has a clear scientific identity. It is no longer trying to make an exchangeable regional-age simulation stand in for an archaeological site-formation model. Instead, it asks what happens when a completed set of dates is filtered through named post hoc rules before a regional summary or density model is constructed. That mechanism is simple, but it is not trivial: any downstream method inherits the selected observations, and no sophistication in calibration handling or population modelling can restore dates that have been systematically removed.

The empirical and simulation components also now have appropriately different roles:

- the empirical benchmark shows the magnitude and direction of descriptive deformation in a real database subset, while avoiding a claim that the imposed rule generated the historical archive; and
- the simulation identifies the order-statistic mechanism because the regional truth and retention rule are controlled.

That division is methodologically sound and should remain explicit.

## 5.2 Archaeological consequence without prevalence evidence

The paper does not demonstrate that actual database curators commonly retain only the calibrated oldest or youngest determination from every well-dated site. Nor does it need to. These are stress-test rules that establish the potential leverage of a within-site filter. The practical archaeological recommendation—report per-site contributions, document inclusion logic and repeat key analyses under plausible alternatives—is proportionate to that evidence.

The one point to prevent is an implicit prevalence claim. The phrase “a regional compilation may also retain only selected determinations” is reasonable, but readers should not infer that the empirical scenarios reconstruct the actual curation history of AustArch. The recommended prevalence sentence resolves this cleanly.

## 5.3 The empirical benchmark is now interpretable

The common-membership repair is decisive. The earlier comparison could not separate curve-construction method from which observations entered each method. The revised analysis uses the same 540 dates for SPD, FD and KDE, common bins and unit-integral scaling. This makes the all-date distances an interpretable baseline for construction-method disagreement in relative temporal shape.

The conservative contrast

$$
C=\min_m D_{\mathrm{TV}}(p_{m,\mathrm{retained}},p_{m,\mathrm{all}})
-\max_{m\ne m'}D_{\mathrm{TV}}(p_{m,\mathrm{retained}},p_{m',\mathrm{retained}})
$$

is defensible for the stated descriptive question. Requiring the smallest retention deformation to exceed the largest retained-data method difference is deliberately stringent. The paper also correctly avoids calling the conditional realisation envelopes confidence intervals over sites, archival inclusion or population history.

## 5.4 Why bracketed retention is the only material empirical loose end

The bracketed primary gate margin, $C=0.0837$, is materially smaller than the oldest and youngest margins. A positive margin is sufficient for the primary claim, but the result is more exposed to specification changes. Because the sensitivity infrastructure already exists, applying it to bracketed retention would be the cleanest closure and should be inexpensive relative to the work already completed.

If there is a substantive reason not to do this—such as the sensitivity plan having been frozen specifically around the primary one-sided headline—the manuscript can remain defensible by demotion. Suggested wording is:

> Under the primary specification, full-site bracketed retention also passed the ordering gate, with a smaller positive contrast; bracketed retention was not included in the nine-configuration sensitivity suite.

Then reserve “robust across sensitivities” solely for oldest and youngest.

## 5.5 The simulation repair is adequate

The signed design now tests the core mechanism fairly. Increasing and decreasing truths and candidates prevent direction from being predetermined by model support. Full one-sided retention produces the direction expected from order statistics, even when that direction opposes the generating regional density. The fact that partial treatment generally selects uniform rather than the opposite direction is scientifically informative and appropriately reported; it shows that the deterministic reversal is not casually extrapolated across treatment proportions.

The study also usefully separates three distinct outcomes:

1. signed-state selection;
2. generating-family selection; and
3. fitted effect on a common end-to-end log-density-ratio scale.

That separation prevents a correct direction from being mistaken for recovery of the generating functional form.

## 5.6 Why no further factorial programme is mandatory

Several omitted analyses would be useful extensions but do not invalidate the present claim:

- **site histories and stratigraphy:** needed for inference about prospective context selection or occupation endpoints, which the paper disclaims;
- **weaker, pulsed or heterogeneous truths:** needed for a general performance surface, not for demonstrating the mechanism under the stated ten-fold monotonic design;
- **matched total retained dates:** needed to decompose compositional selection from information loss, while the present paper openly reports their combined effect;
- **new realised-noise one-sided run:** needed for observation-model robustness, not for the conditional result now claimed;
- **alternative model criteria:** potentially informative, but unlikely to overturn the exact signed-state result in the deterministic full-treatment cells.

These should remain future work, not be converted into another presubmission barrier.

---

# 6. Statistical and inferential corrections

## 6.1 State the calibration prior and analysis-window conditioning

The primary criterion is presented as

$$
\ell_i=\log\int f(x\mid\theta)p_i(x)\,dx,
$$

where $p_i(x)$ is a calibrated posterior. Let the radiocarbon likelihood for observation $y_i$ be $L_i(x)$ and the calibration prior be $\pi_i(x)$. Then

$$
p_i(x)\propto L_i(x)\pi_i(x).
$$

Consequently, integrating $f(x\mid\theta)$ against $p_i(x)$ is proportional to the desired observed-data marginal likelihood only when the calibration prior is constant over the relevant support, or when the prior is explicitly divided out. The supplied workflow appears to use the standard normalized calibration posterior without a non-uniform archaeological prior. The manuscript should state this rather than leave the equivalence implicit.

The code also keeps only grid points satisfying the strict analysis-window bounds and renormalizes each retained posterior to unit mass. The resulting criterion is conditional on the calibrated date lying inside that window. This is not inherently wrong, especially because the simulation itself is generated over the same window, but it should be stated precisely.

### Recommended Methods text

> Calibration used a uniform calendar-age prior. For the primary analysis, each calibrated posterior was restricted to the strict analysis window and renormalized. Conditional on posterior mass within that window, $\ell_i$ is the observed-data marginal log likelihood up to a date-specific additive constant independent of $\theta$; these constants cancel in within-dataset AIC comparisons.

Use equivalent wording in SI S2.4.

## 6.2 Disclose working independence for bracketed extrema

For oldest- or youngest-only retention, a treated site contributes one selected order statistic. Under the exchangeable generator, different sites remain independent conditional on their site counts. Bracketed retention is different: each treated site contributes its oldest and youngest selected observations, which are dependent order statistics from the same site.

The implemented objective adds their pointwise contributions as though they were independent dates. Therefore:

- the fitted direction/family result accurately describes what the analysed downstream workflow does;
- it is not the full likelihood for paired extrema; and
- the ordinary AIC penalty does not have its standard joint-likelihood interpretation for bracketed data.

### Recommended caveat

> For bracketed retention, the two retained extrema from a site are dependent. The fitted product criterion treats them under working independence; bracketed AIC and family-selection results therefore describe the analysed workflow rather than calibrated likelihood support under a joint paired-extrema generative model.

This sentence should appear in Methods or SI S2.4 and be echoed briefly in the limitations.

## 6.3 Keep $\ell^2$ terminology as revised

The secondary score

$$
\ell_i^2=\int \log\{f(x\mid\theta)\}p_i(x)\,dx
$$

is correctly described as a posterior expected log-density score. The manuscript does not call its penalized criterion AIC, and the primary conclusions do not depend on it. No further change is needed beyond avoiding the generic phrase “both likelihoods.”

## 6.4 Effect-size and boundary reporting

The common log-density-ratio effect is a strong improvement over comparing raw linear slopes and exponential rates. Figure 4 appropriately flags frequent optimizer-bound hits. The text correctly says extreme magnitudes are censored rather than interpreting boundary estimates literally.

One small wording improvement is to distinguish the **selected-family** effect plotted in some summaries from the **generating-family** effect summarized in the Results. The current text is mostly clear, but captions should retain the exact estimand to prevent readers from comparing unlike quantities.

## 6.5 Monte Carlo uncertainty

The stated maximum Monte Carlo standard error of 0.016 for a rate from 1,000 replicates is correct. No additional simulation uncertainty analysis is necessary for rates equal to 0 or 1 in all 1,000 replicates, although those should still be described as observed simulation frequencies rather than mathematical certainties outside the design.

---

# 7. Reproducibility, provenance and governance

## 7.1 Repository strengths

The reviewer repository is scientifically useful and unusually well organized. Particularly strong features include:

- a pinned R 4.5.3 environment and digest-recorded production image;
- immutable source snapshots for earlier production and observation-noise analyses;
- explicit Stage 2 and Stage 3 frozen designs;
- common-random-number and source-fingerprint checks;
- accepted raw simulation artefacts, machine-readable summaries and validation records;
- aggregate empirical curves, distances, counts, tie audits and sensitivity decisions;
- a clean separation between code licensing and data/licensing constraints; and
- explicit refusal to describe governed archaeological records as “de-identified.”

The README also correctly tells reviewers what cannot be reproduced from the archive alone.

## 7.2 Correct the SI description of the fast path

Current SI line 153 says:

> The fast verification path runs the consequential scientific tests and validates accepted artefacts ...

That is not what `make verify-evidence` does. The Makefile shows:

- `make verify-evidence`: verifies SHA-256 manifests;
- `make test`: runs focused scientific tests under R 4.5.3; and
- `make signed-figures`: rebuilds the signed figures after preflight and checksum verification.

### Replacement

> The fast checksum path, `make verify-evidence`, validates all supplied accepted-evidence manifests without repeating the high-volume simulations. The focused scientific tests are run separately with `make test` under R 4.5.3 and the locked environment; signed display items can be rebuilt with `make signed-figures`.

## 7.3 Identify the AustArch source object exactly

The SI reports that the published release contains 5,044 determinations from 1,748 sites, whereas the source extract used here contains 5,288 age records, including 4,828 radiocarbon records from 1,704 named sites. That discrepancy may be entirely legitimate—for example, because the extract includes non-radiocarbon age rows, later corrections, duplicated or differently counted records, or a distinct exported table—but a reviewer cannot determine this from the current text.

Add:

- exact extract filename or immutable local identifier;
- source repository and dataset DOI `10.5284/1027216`;
- retrieval/access date;
- release/version field if one exists;
- a one-sentence reconciliation of the published and extracted counts; and
- a checksum for the governed source extract in a non-public provenance record, if redistribution is prohibited.

The data paper DOI `10.11141/ia.36.6` is not a substitute for the dataset citation. Current *JAS* instructions encourage separate dataset references with a persistent identifier.

## 7.4 Data availability should be exact about what is shared

The current main-text statement promises “supporting code, permitted data and accepted evidence,” but the supplied review archive deliberately contains no raw or record-level AustArch data. “Permitted data” is therefore ambiguous. State “aggregate empirical evidence” instead.

“Made public after acceptance” is also less definite than necessary. An accepted pre-proof can appear rapidly, so the reproducibility record should be public no later than publication unless a governed component cannot be released. The source archaeological records may remain access-controlled; the code, synthetic artefacts and permitted aggregate evidence should not.

### Recommended data-availability statement

> For peer review, supporting code, aggregate empirical evidence and accepted synthetic artefacts are available at [PRIVATE REVIEW LINK; RESERVED DOI]. The review archive does not contain raw or record-level AustArch data. Rebuilding the empirical curves from source records requires separately governed access to the cited AustArch dataset [dataset DOI and version/access date]. The repository record will be made public no later than publication, while any release of source or record-level archaeological data remains subject to source licensing, sensitive-location review and Indigenous data-governance requirements.

## 7.5 Placeholder and release gate

`[PRIVATE_REVIEW_LINK]` and `[RESERVED_DOI]` remain in the manuscript. These must be resolved before upload. The final archive should be rebuilt after insertion, and the private reviewer link should be checked in a clean browser session without an authenticated author account.

## 7.6 Internal identifiers

Remove or generalize any internal machine hostname, such as `deep-server`, from reviewer-facing documentation unless it is scientifically required. Container digests, commit hashes and software versions are useful; local infrastructure names are not.

---

# 8. Figures and display items

## 8.1 Main figures

The five figures are now aligned with the revised claims:

- **Figure 1** establishes common-membership baseline method differences;
- **Figure 2** reports method-specific departures from each all-date baseline and makes the full-site boundary scenarios visually distinct;
- **Figure 3** reports truth-consistent signed-state selection rather than conflating direction with family;
- **Figure 4** puts effects on a common log-density-ratio scale and flags boundary-heavy cells; and
- **Figure 5** separates generating-family recovery from directional recovery.

I found no display-level contradiction with the supplied summaries.

## 8.2 Accessibility

Figures 3–5 use symbols or cell labels that preserve most interpretation without colour. Figures 1–2 rely more heavily on colour, although direct labels and captions help. As an optional improvement, give the three curve methods distinct line types as well as colours. This is not a submission blocker.

## 8.3 Figure-caption precision

Where bracketed retention appears in simulation captions, add “working-independence fit” or place the dependence caveat in Methods/SI and cross-reference it. In Figure 2 or its caption, make clear that the nine empirical sensitivities apply to full oldest and youngest, not to bracketed.

## 8.4 Supplementary Figure S1

The five signed truths are now shown and correctly define “increase” relative to low cal BP. Retain the explicit statement that every non-uniform trajectory has a ten-fold endpoint ratio.

---

# 9. Submission-readiness audit

## 9.1 Current *JAS* requirements requiring correction

The official *Journal of Archaeological Science* Guide for Authors, checked on 11 August 2026, states:

- the journal follows a **single anonymized** review process;
- the abstract must not exceed **250 words**;
- highlights should comprise 3–5 bullets, each no more than 85 characters including spaces; and
- preprints should be marked clearly as preprints or by naming the preprint server.

The present packet has two direct mismatches:

1. the crosswalk and checklist claim double-anonymized review; and
2. the current abstract contains approximately 262 words by a normal word-token count.

The anonymous manuscript may remain a useful clean source file, but the submission workflow must be configured so that the reviewer PDF contains author information as required by the live single-anonymized process. Follow the portal prompts rather than assuming that a separate title page will be hidden from reviewers.

## 9.2 Items already compliant

- The article is comfortably below the stated normal 5,000-word limit under the authors’ conservative count.
- There are seven keywords, within the stated 3–7 range.
- There are five highlights and all current bullets are below 85 characters.
- The cover letter is addressed to the current Editors-in-Chief named in the packet.
- The manuscript includes a competing-interests statement and an AI declaration.
- Figure and SI file counts are internally consistent.

## 9.3 Title-page superscript

Source line 3 currently contains:

```markdown
Barry W. Brook^a,*^, ...
```

The asterisk is parsed literally in the PDF. Escape it:

```markdown
Barry W. Brook^a,\*^, ...
```

Then inspect both PDF and DOCX outputs.

## 9.4 Radiocarbon glyph corruption

The reference PDF renders several `¹⁴C` strings as `¹�C`, including the Mendez-Quiros title, Timpson et al. title and AustArch title. This is a build/font-encoding defect, not a reference-data error. The safest repair is to use plain `14C` or LaTeX-safe `$^{14}$C` in titles where the CSL/Pandoc path cannot preserve the Unicode superscript. Rebuild and inspect the final PDF text layer.

## 9.5 Preprint labelling

Arthur et al. (2023), DOI `10.48550/arXiv.2312.05152`, is an arXiv preprint. The YAML identifies the publisher as arXiv but the formatted reference resembles an ordinary article. Ensure the final bibliography visibly says “arXiv preprint” or “arXiv:2312.05152,” in line with the current guide.

## 9.6 AI declaration

The current declaration identifies manuscript-source conversion, citation tokenisation, reproducibility-workflow checks and language editing. This second-round process also used ChatGPT/Codex for presubmission critical review. The declaration should describe the actual purpose and scope accurately.

### Recommended declaration for manuscript preparation

> During preparation of this work, the authors used OpenAI ChatGPT/Codex for manuscript-source conversion, citation tokenisation, reproducibility-workflow checks, presubmission critical review and language-editing suggestions. The authors independently evaluated, verified and edited all outputs and take full responsibility for the content of the article.

The current Elsevier policy distinguishes manuscript preparation from research methods. **If** generative AI assisted scientific code development, data analysis, simulation design or generation of data visualizations—not merely formatting or checking—describe that use reproducibly in Methods, including tool/model, version or access date and developer. Do not add such a Methods statement unless it reflects the actual research process.

---

# 10. Detailed material line edit

Line numbers refer to the supplied source Markdown files.

## 10.1 Main manuscript

| Location | Current issue | Recommended edit |
|---|---|---|
| `main.md:5` | Abstract is approximately 262 words, gives bracketed equal empirical status and uses “strong” without defining the ten-fold contrast. | Replace with the 238-word abstract in Section 11.1. |
| `main.md:21` | “A regional compilation may also retain only selected determinations” could be read as an undocumented prevalence assertion. | Add: “The stress-test rules examined below are not estimates of how frequently particular retention practices occur in existing compilations.” |
| `main.md:25` | “The primary criterion is a marginal likelihood fitted directly to calibrated posteriors” omits the calibration-prior and window condition. | Use “a posterior-integrated marginal-likelihood criterion under the stated uniform-prior and analysis-window conditioning.” |
| `main.md:33` | Source reference is only to the data paper; exact extract provenance is absent. | Add dataset DOI/version/retrieval date and reconcile published versus extracted record counts, with fuller detail in SI. |
| `main.md:35` | “centred 100-year running mean” is over-specific given the even-width `stats::filter` convention. | Use “a 100-year running mean using the specified edge-fill convention.” |
| `main.md:47` | “Prespecified sensitivities varied ...” can imply all boundary scenarios were tested. | Begin: “For full-site oldest and youngest retention, prespecified sensitivities varied ...” |
| `main.md:61–67` | Marginal-likelihood equivalence and strict-window renormalization are unstated. | Insert the uniform-prior/window sentence from Section 6.1. |
| `main.md:67` | Bracketed extrema dependence is unstated. | Add the working-independence caveat from Section 6.2. |
| `main.md:69` | Correct, but “earlier uniform-and-increasing design” could be more exact. | Say “earlier uniform, linear-increase and exponential-increase design.” |
| `main.md:73` | “Data inclusion in the final archive remains conditional ...” is vague and may imply record data will be included. | Distinguish code/synthetic/aggregate evidence from governed source records. |
| `main.md:81` | Primary bracketed result is numerically correct but not marked primary-only. | End the bracketed sentence with “under the primary specification.” |
| `main.md:83` | Oldest/youngest sensitivity result is clear, but bracket omission is only implicit. | Add: “Bracketed retention was not included in this nine-configuration suite.” |
| `main.md:87` | “Thus ... it reversed ... in every replicate” relies on the preceding full-treatment context. | Write “Thus, under full treatment, ...” |
| `main.md:89` | “All four random rules preserved the correct direction” needs the effect-size scope in high-visibility text. | Add “for every simulated ten-fold non-uniform truth.” |
| `main.md:97` | Bracketed family result is treated as ordinary AIC evidence. | Add “under the working-independence fit.” |
| `main.md:105` | “under this strong-signal design” is acceptable but less exact than available. | Use “under this ten-fold monotonic design.” |
| `main.md:107` | Bracketed appears alongside sensitivity-robust oldest/youngest. | Write “and, under the primary specification, bracketed retention produced ...” |
| `main.md:111` | Says ordering held for all three scenarios without sensitivity distinction. | Add “under the primary specification; robustness across the nine sensitivities was established for oldest and youngest.” |
| `main.md:115` | “strong monotonic truths” is vague. | Use “simulated ten-fold monotonic truths.” |
| `main.md:119` | Limits are strong, but prevalence is not addressed. | Add the diagnostic-stress-test/prevalence sentence. |
| `main.md:121` | Bracket dependence absent. | Add “Bracketed fits treated the two within-site extrema under working independence.” |
| `main.md:123` | “The present evidence establishes only ...” is well bounded. | Retain. Optionally add “under the stated calibration-curve-mean observation model.” |
| `main.md:127` | “without reversing strong trends” omits exact scope; “empirical ordering ... clear for full-site extrema” implies common robustness. | Replace the conclusion with the text in Section 11.3. |
| `main.md:131` | Placeholders, ambiguous “permitted data,” and public timing after acceptance. | Replace with Section 7.4 text and insert final identifiers. |
| `main.md:139` | AI declaration omits presubmission critical review and may be incomplete if AI assisted research methods. | Replace with Section 9.6 statement; add Methods detail only if factually required. |

## 10.2 Supplementary Information

| Location | Current issue | Recommended edit |
|---|---|---|
| `supplementary.md:7` | The 5,044/1,748 published count and 5,288/4,828/1,704 extract count are not reconciled; extract identity is absent. | Add source filename/identifier, dataset DOI `10.5284/1027216`, version/retrieval date and a count reconciliation. |
| `supplementary.md:24` | “centred two-bin running mean” is ambiguous for an even-width filter. | Use “a two-bin running mean implemented with `stats::filter(..., sides = 2)`, retaining unsmoothed edge cells,” or state the exact alignment in plain language. |
| `supplementary.md:49–57` | Bracketed is presented as one of three passing scenarios without a sensitivity qualifier. | Add “Bracketed refers to the primary specification only.” |
| `supplementary.md:61` | Correctly names oldest and youngest, but the exclusion of bracketed should be explicit. | Add: “Bracketed retention was not included in the sensitivity suite.” |
| `supplementary.md:99–111` | $\ell^1$ is called a marginal likelihood without prior/window conditions. | Add the uniform-prior and strict-window-renormalization statement. |
| `supplementary.md:111–113` | Bracket working independence absent. | Add the paired-extrema caveat. |
| `supplementary.md:127` | Bracketed result accurate but ordinary family-selection language lacks dependence caveat. | Add “under the working-independence criterion.” |
| `supplementary.md:131` | Excellent exact reconciliation of $\ell^1/\ell^2$ selected state. | Retain. |
| `supplementary.md:143–149` | Realised-noise boundary is transparent. | Retain; no new run required. |
| `supplementary.md:153` | Says the fast path runs tests and validates artefacts. | Replace with the split checksum/test wording in Section 7.2. |
| `supplementary.md:155` | Public release timing and source-data route are vague. | Align with revised Data Availability and state public no later than publication. |

## 10.3 Cover letter

| Location | Current issue | Recommended edit |
|---|---|---|
| `draft_cover_letter.md:12` | Gives oldest, youngest and bracketed equal empirical robustness. | State that oldest/youngest remained robust across nine sensitivities and bracketed passed the primary specification only, unless bracketed sensitivities are added. |
| `draft_cover_letter.md:12` | “Adverse rule reversed all non-uniform replicates” lacks full-treatment wording. | Add “under full-site treatment.” |
| `draft_cover_letter.md:12–14` | “strong monotonic truths” should name the ten-fold contrast. | Use “simulated ten-fold monotonic truths.” |
| `draft_cover_letter.md:18` | “made public after acceptance” and “data inclusion” are imprecise. | Promise public code/synthetic/permitted aggregate evidence no later than publication; distinguish governed source records. |

### Suggested replacement for the scientific-results paragraph

> In a common-membership benchmark of 540 terrestrial charcoal or wood determinations from 68 well-replicated AustArch sites, full-site oldest and youngest retention changed temporal shape more than the remaining differences among SPD, FD and KDE summaries across all nine prespecified sensitivity configurations. Full-site bracketed retention also passed this gate under the primary specification, with a smaller margin. In controlled simulations with signed regional event-age-density models and ten-fold monotonic generating contrasts, full-site oldest retention selected a decreasing direction and full-site youngest retention an increasing direction under every truth. The opposing one-sided rule reversed every non-uniform replicate under full treatment, and either one-sided rule manufactured a trend under uniform truth. Random retention preserved direction under these simulated ten-fold truths, although sparse retention weakened linear-versus-exponential family recovery.

## 10.4 Highlights

The current bullets all satisfy the character limit, but two need exact scope. Replace them with Section 11.2.

## 10.5 Checklist and crosswalk

- `submission_checklist.md:31`: replace “double-anonymised” with “single anonymized” and follow the portal’s live file prompts.
- `stage4_response_crosswalk.md:24`: change M10 to “reviewer correction accepted after live recheck.”
- `stage4_response_crosswalk.md:57–60`: correct the review model.
- Do not mark the abstract compliant until it is below 250 words.
- Add explicit checks for bracketed sensitivity status, dataset citation, radiocarbon glyphs and title-page superscript.

## 10.6 Title page and references

- Escape the corresponding-author asterisk as described in Section 9.3.
- Mark Arthur et al. as an arXiv preprint.
- Repair all corrupted `¹⁴C` renderings.
- Add the AustArch dataset as a separate data reference with DOI `10.5284/1027216` and, if known, version/year/access details.

---

# 11. Replacement high-visibility text

## 11.1 Recommended abstract (238 words by a standard token count)

> Radiocarbon “dates-as-data” analyses can be distorted before curve construction because the determinations retained from each archaeological site define the regional evidence base. We quantified this dataset-formation effect using a common-membership AustArch benchmark and simulations. The benchmark contained 540 terrestrial charcoal or wood determinations from 68 well-replicated sites; summed probability distributions, frequency distributions and kernel density estimates used identical dates. Simulations drew exchangeable regional ages from uniform, signed linear and exponential trajectories, with each non-uniform truth spanning a ten-fold endpoint density contrast. We imposed eight post hoc retention rules at three site-treatment proportions and fitted regional event-age-density models directly to calibrated posteriors. Empirically, full-site oldest and youngest retention produced total-variation deformation larger than between-method differences across nine sensitivity configurations; full-site bracketed retention did so only under the primary specification. Under full treatment, oldest retention selected a decreasing direction and youngest retention an increasing direction in all 1,000 replicates under every truth. The rule opposing a non-uniform truth reversed direction in every replicate, while either one-sided rule created an exponential trend under uniform truth. Random retention preserved direction under the simulated ten-fold monotonic truths, although sparse retention weakened linear-versus-exponential recovery. Bracketed retention preserved direction but not functional-family recovery. The simulation isolates post hoc selection among exchangeable dates; it does not represent prospective sampling, occupation histories or site endpoints, and one-sided rules were not tested under realised observation noise. Dates-as-data studies should audit per-site contributions and test alternative retention rules.

If the authors add bracketed sensitivity results and they are stable, replace “did so only under the primary specification” with the appropriate sensitivity statement.

## 11.2 Recommended highlights

Each bullet is within 85 characters including spaces.

- Post hoc within-site retention can control inferred temporal direction.
- Full one-sided retention reversed opposing ten-fold monotonic truths.
- Either one-sided rule manufactured a trend under uniform truth.
- Sparse random retention retained direction but weakened family recovery.
- Oldest/youngest deformation exceeded method differences across sensitivities.

## 11.3 Recommended conclusion

> Dates-as-data inference begins with dataset formation. Under full treatment in the exchangeable-date simulation, one-sided retention controlled the selected temporal direction; bracketed retention preserved direction but could replace linear with exponential change; and sparse random retention reduced family discrimination without reversing the simulated ten-fold monotonic trends. In the empirical benchmark, full-site oldest and youngest retention exceeded summary-method differences across nine sensitivity configurations, whereas bracketed retention passed under the primary specification only. These diagnostic rules do not estimate the prevalence of particular curation practices in existing databases. Regional analyses should nevertheless report per-site contributions and retention logic, test plausible alternative dataset-formation rules, and state the residual uncertainty when those rules cannot be reconstructed.

## 11.4 Recommended Data Availability

> For peer review, supporting code, aggregate empirical evidence and accepted synthetic artefacts are available at [PRIVATE REVIEW LINK; RESERVED DOI]. The review archive does not contain raw or record-level AustArch data. Rebuilding the empirical curves from source records requires separately governed access to the AustArch dataset [dataset DOI `10.5284/1027216`; version and access date]. The repository record will be made public no later than publication, while any release of source or record-level archaeological data remains subject to source licensing, sensitive-location review and Indigenous data-governance requirements.

## 11.5 Recommended AI declaration

> During preparation of this work, the authors used OpenAI ChatGPT/Codex for manuscript-source conversion, citation tokenisation, reproducibility-workflow checks, presubmission critical review and language-editing suggestions. The authors independently evaluated, verified and edited all outputs and take full responsibility for the content of the article.

Add a reproducible Methods disclosure only if AI tools participated in research design, scientific code development, data analysis or data-visualization generation.

---

# 12. Mandatory fixes versus optional future work

## 12.1 Mandatory before submission

1. **Resolve bracketed empirical status.** Run the existing nine sensitivity configurations for full-site bracketed retention, or label it consistently as primary-specification-only and demote it from equal headline status.
2. **Correct the statistical qualification.** State the calibration prior, strict-window renormalization/conditioning and bracketed working independence.
3. **Make scope exact in high-visibility text.** Use “full treatment” and “simulated ten-fold monotonic truths” in the abstract, conclusion, highlights and cover letter.
4. **Strengthen AustArch provenance.** Add the dataset DOI, source-extract identifier/version/access date and count reconciliation.
5. **Complete repository fields.** Replace `[PRIVATE_REVIEW_LINK]` and `[RESERVED_DOI]`; verify the reviewer link; make the permitted repository public no later than publication.
6. **Correct journal administration.** Replace double-anonymized with single-anonymized and inspect the portal-generated reviewer PDF.
7. **Reduce the abstract.** Use a version of no more than 250 words.
8. **Repair production defects.** Fix the title-page superscript and `¹⁴C` glyph corruption.
9. **Label the arXiv preprint clearly.** Format Arthur et al. as a preprint.
10. **Reconcile the AI declaration.** Include the presubmission review use and add Methods detail only where actual research-process AI use requires it.
11. **Correct SI reproducibility wording.** Separate checksum verification from execution of scientific tests.
12. **Rebuild and inspect every submission file.** Check manuscript, SI, title page, cover letter, highlights, metadata, reference rendering and portal PDF after the final edits.

## 12.2 Strongly preferred but not mandatory

- Run bracketed through the existing sensitivity suite rather than demoting it.
- Add line-type redundancy to Figures 1–2 for colour-independent interpretation.
- Remove nonessential internal machine names from reviewer-facing documentation.
- Archive a governed checksum and identity record for the exact source AustArch extract.

## 12.3 Optional future research, not conditions of submission

- hierarchical site-duration, occupation-history and stratigraphic generators;
- weaker, non-monotonic, pulsed, changepoint or spatially heterogeneous truths;
- matched-total-date experiments separating composition from information loss;
- realised-noise experiments covering oldest, youngest and bracketed retention;
- explicit joint likelihoods for paired order statistics;
- alternative information criteria, predictive scoring or out-of-sample comparison;
- empirical research on the prevalence and provenance of within-site retention practices.

---

# 13. Final assessment

The first-round major-revision recommendation has been answered successfully. The paper’s central contribution is now coherent: **systematic post hoc retention among exchangeable within-site dates can impose an order-statistic filter on a regional radiocarbon dataset, and that filter can control the direction selected by a downstream regional event-age-density model under the stated design.** The empirical benchmark no longer confounds method with membership, and its oldest/youngest result is robust across the specified sensitivity suite. The manuscript is appropriately candid about the limits of exchangeability, strong monotonic truths, changing sample size, omitted realised noise and governed data access.

The remaining issues are narrow. None warrants renewed major revision. After the bracketed-status decision and the technical/submission corrections listed above, I would support submission to the *Journal of Archaeological Science* without requiring additional site-history or realised-noise analyses.

**Final recommendation: minor targeted revision, then submit.**

---

# Appendix A. Key independently reconciled evidence values

## A.1 Empirical primary gates

| Scenario | $C_{0.025}$ or deterministic $C$ | Gate | Direction |
|---|---:|---:|---|
| Oldest, 50% sites | -0.0655 | fail | not unambiguous |
| Oldest, 100% sites | 0.1925 | pass | older |
| Youngest, 50% sites | -0.0482 | fail | not unambiguous |
| Youngest, 100% sites | 0.3703 | pass | younger |
| Bracketed, 50% sites | -0.0582 | fail | not unambiguous |
| Bracketed, 100% sites | 0.0837 | pass | older |
| Random-1, 50% sites | -0.0687 | fail | not unambiguous |
| Random-1, 100% sites | -0.0804 | fail | not unambiguous |
| Random-5, 50% sites | -0.0796 | fail | not unambiguous |
| Random-5, 100% sites | -0.0701 | fail | not unambiguous |

## A.2 Oldest/youngest sensitivity minima

- Smallest oldest contrast across the nine named configurations: $C=0.0475$ in the `Y`-only subset; direction older.
- Smallest youngest contrast across the nine named configurations: $C=0.1571$ in the `Y`-only subset; direction younger.
- Bracketed retention has no corresponding row in `sensitivity_claim_gates.csv` or `sensitivity_decision.csv`.

## A.3 Full-treatment family/state percentages under primary $\ell^1$

Values are “generating family; truth-consistent signed state.”

| Truth | All dates | Oldest | Youngest | Bracketed |
|---|---:|---:|---:|---:|
| Uniform | 84.8; 84.8 | 0.0; 0.0 | 0.0; 0.0 | 99.9; 99.9 |
| Linear increase | 97.6; 100 | 19.5; 0.0 | 0.0; 100 | 0.0; 100 |
| Exponential increase | 99.6; 100 | 41.6; 0.0 | 100; 100 | 100; 100 |
| Linear decrease | 97.4; 100 | 0.0; 100 | 16.8; 0.0 | 0.0; 100 |
| Exponential decrease | 99.8; 100 | 100; 100 | 43.3; 0.0 | 100; 100 |

## A.4 Package provenance

- Bundle SHA-256: `3d5b591afbdf0e7e064ee36973a61fd75ee4d1d659bf5d458253ac97d19c8670`
- Bundle size: 18,102,648 bytes
- Package manifest entries verified: 227
- Active source snapshot commit: `863316f82ffc6e5341039e5eba4a1e8519d7fe8a`
- Accepted analysis runtime: R 4.5.3
- Signed design: 15 scenarios × 1,000 replicates; 720,000 fitted-result rows
- Empirical benchmark: 540 dates, 68 sites

