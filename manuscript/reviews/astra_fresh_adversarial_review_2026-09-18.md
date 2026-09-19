# Fresh external scientific review of rc-dates

Reviewer: independent Astra review, 18 September 2026. Intended journal: *Journal of Archaeological Science*.

**Recommendation: APPROVE WITH CHANGES.** The central scientific result withstands substantial challenge and fresh execution. I found one consequential problem in the interpretation and presentation of fitted effect magnitudes, and one smaller omission in the description of the historical noise sensitivity. These should be corrected before submission. I found no demonstrated defect requiring rejection of the empirical comparison or the main direction/family-selection results, and no justification for repeating the production simulation matrix merely to establish those results again.

This is a scientific-readiness recommendation, not permission to submit. The current version should not be submitted unchanged. The necessary work is bounded: revise Figure 4 and its numerical interpretation, disclose the historical sensitivity's different candidate model space, and sharpen the contribution's positioning. A new site-history or noisy-extrema simulation campaign is optional for the paper's present, explicitly limited claim.

## Scope and reconstructed argument

I read the manuscript, captions and supplement before consulting provenance documentation; traced consequential claims through the scientific functions, raw synthetic results and empirical tables; read relevant primary literature; and executed checks in a fresh, read-only copy of the accompanying release. I did not consult earlier review reports or adopt previous acceptance decisions as evidence. A minimal workspace-memory lookup supplied navigation only.

The paper asks whether selecting among a site's completed radiocarbon determinations can change regional dates-as-data conclusions. Its contribution has three parts:

1. A common-membership AustArch benchmark makes the effect tangible. From 540 charcoal/wood determinations at 68 well-replicated sites, keeping oldest, youngest or random-1 dates always leaves 68 determinations, yet produces markedly different temporal shapes. The comparison with SPD/FD/KDE construction on identical dates separates this retention effect from a particular curve method.
2. A controlled simulation establishes a mechanism and a counterexample to innocuous thinning. Independent ages from five regional densities are grouped under 116 site labels; full oldest/youngest retention imposes decline/growth throughout the tested matrix, including reversals of opposing ten-fold trends. Random thinning retains direction in this setting, while family discrimination declines. Bracketed retention shows that retaining direction can conceal severe shape distortion.
3. The practical conclusion is an audit of dataset formation: record site contributions and age-dependent retention, and test plausible alternatives. The paper does not estimate the prevalence of these practices, infer Sahul population history, establish an optimal dating allocation, or validate sampling occupation onsets and terminations.

That is a defensible methods contribution. The basic order-statistic mechanism is established mathematics; the value here lies in its calibrated implementation, count-matched comparisons, transparent counterexamples and empirical scale. The realistic claim is that such retention **can** distort inference under stated conditions, not that the simulation predicts the frequency or size of distortion in ordinary archaeological datasets.

## Demonstrated defects and necessary corrections

### 1. MAJOR — Figure 4 treats a numerical approximation to an infinite linear endpoint contrast as an ordinary finite effect summary

**Evidence.** [Methods and Figure 4 description](/home/bwbrook/papers/rc-dates/manuscript/text/main.md:69), [Results](/home/bwbrook/papers/rc-dates/manuscript/text/main.md:95), [caption](/home/bwbrook/papers/rc-dates/manuscript/text/figures.md:7), [fit bounds](/home/bwbrook/papers/rc-dates/R/population_simulation_models.R:107), [effect transformation](/home/bwbrook/papers/rc-dates/R/population_simulation_design.R:70), and [plotting threshold](/home/bwbrook/papers/rc-dates/R/manuscript_signed_figures.R:234).

The linear model's slope bounds are its natural nonnegative-density limits, ±2/L², where L = 10,999 years. Write q = slope × L²/2. Then the reported effect is log((1+q)/(1−q)); at q = ±1 one endpoint density is zero and the effect is ±∞. The code itself returns infinity at that exact boundary. This differs from the exponential model's deliberately imposed finite rate cap, ±0.001, corresponding to |θ| = 10.999.

The optimiser normally stops just inside the linear boundary. Its finite reported endpoint effect is therefore determined by stopping tolerance. I reproduced all 48 accepted rows for linear-increase, full-treatment replicate 1 exactly under R 4.5.3, then changed only the linear optimiser tolerance on its retained data:

| Tolerance on the scaled slope | Reported absolute endpoint effect |
|---:|---:|
| 10⁻⁴ | 6.253833 |
| 10⁻⁶, current setting | 11.096725 |
| 10⁻⁸ | 15.398778 |
| 10⁻¹⁰ | 18.415351 |

For both oldest and youngest retention, the exact endpoint gives a lower negative log likelihood than these interior approximations. Thus “magnitude beyond a preset limit was not resolved” does not accurately describe the linear model: the boundary maximum corresponds to an infinite endpoint ratio, not a finite scientific limit near 11.1.

The issue is not confined to the conspicuous triangles. The full-treatment linear-increase random-1 cell has 72/1,000 boundary flags and the linear-decrease cell has 82/1,000. Their plotted means are 3.105604 and −3.136238, and their affected 95% endpoints are ±11.096725. Seventy-one and 81 estimates, respectively, take that same extreme optimiser value. These cells receive ordinary circles because the figure marks only boundary frequencies of at least 50%. See [increasing cell](/home/bwbrook/papers/rc-dates/out/revision/signed-models/log_ratio_bias.csv:90) and [decreasing cell](/home/bwbrook/papers/rc-dates/out/revision/signed-models/log_ratio_bias.csv:66).

I separately reproduced all six accepted model/score rows for linear-increase replicate 2, random-1. Its linear negative log likelihood is convex in q, with derivative −2.362938 at q = 1; its constrained optimum is therefore exactly at θ = +∞. Tightening tolerance again changes 11.096725 to 15.398778 and 18.415351. This is a demonstrated numerical interpretation problem, not speculation based solely on the boundary flag. I have not proved that every near-boundary flag is an exact endpoint optimum.

**Scientific impact.** The stored means and quantiles are accurate summaries of the current optimiser's finite outputs. They are not stable finite summaries of the corresponding linear maximum-likelihood endpoint effects. In particular, part of the apparent random-1 mean bias and upper/lower range depends on numerical tolerance. The existing censoring caveat acknowledges part of the problem but misses affected intervals in cells below the 50% threshold and conflates two different kinds of boundary. The verified direction and family-selection tallies remain the results of the documented workflow; I did not rerun the entire matrix with exact endpoint optimisation to assess any marginal selection changes.

**Smallest defensible remedy.** Explicitly distinguish the natural zero-density linear endpoint from the finite exponential cap; give both parameter domains and optimisation tolerance in S2.4. Make boundary involvement visible whenever it affects a displayed summary or range, with the actual boundary fraction. Do not present tolerance-dependent linear means as finite effect-size estimates. A bounded linear-shape scale q, or medians with open-ended/boundary-marked ranges and endpoint frequencies, would provide interpretable alternatives. Existing fitted rows suffice to prepare a transparent replacement display; any exact-endpoint reclassification should be a labelled, targeted numerical correction with a stated acceptance check. Preserve the accepted raw artefacts and document the derived revision. This does not require a new set of simulated dates.

### 2. MINOR — The historical noise sensitivity used a different, growth-only candidate model space

**Evidence.** [Current signed bounds](/home/bwbrook/papers/rc-dates/R/population_simulation_models.R:117) allow both directions. The frozen sensitivity's [fitter](/home/bwbrook/papers/rc-dates/provenance/observation-noise-20260726/R/population_simulation_production.R:535) restricts linear slopes to 10⁻¹² through 2/L² and exponential rates to 10⁻¹⁰ through 10⁻³: both are positive. Its [paired runner](/home/bwbrook/papers/rc-dates/provenance/observation-noise-20260726/R/observation_noise_sensitivity.R:306) calls that fitter. [S3](/home/bwbrook/papers/rc-dates/manuscript/text/supplementary.md:160) states the historical status, limited truths and retention rules, but does not state this candidate-space difference; neither does the [main limitation](/home/bwbrook/papers/rc-dates/manuscript/text/main.md:127).

**Scientific impact.** The historical estimates are valid descriptions of that earlier workflow, but they do not directly measure the noise response of today's signed model competition, even for the overlapping all-date/random rules. This matters particularly under a uniform truth, for which an added decreasing candidate changes the available alternatives. The paper already correctly refuses to claim that noisy extrema were validated and retains the failed v1 decision; those safeguards should remain.

**Smallest remedy.** Add a sentence to S3 specifying uniform versus growth-only linear/exponential candidates and defining historical “accuracy” as generating-family selection under that candidate set. Briefly flag the different candidate set when referring to the historical sensitivity in the Discussion. No rerun is required if its evidential role remains historical and limited.

## Positioning, presentation and optional improvements

### 3. MINOR — Make the incremental contribution explicit against established selection-bias work

This is a positioning gap, not a demonstrated false novelty claim. The Introduction already distinguishes post hoc retention from selecting basal contexts, which is good. Nevertheless, [Sections 1.2 and 4.2](/home/bwbrook/papers/rc-dates/manuscript/text/main.md:19) would withstand review better with one direct antecedent and a sentence identifying what this paper adds.

Nicholls and Jones explicitly discuss selecting datable material expected to lie near the beginning or end of a layer and the resulting violation of their thinning assumptions. Their setting is prospective sample selection and chronological inference, not this paper's post hoc calibrated-date retention experiment; cite it as related prior recognition, not as an equivalent analysis. The relevant paragraph is on PDF page 11 of the [author manuscript of *Radiocarbon dating with temporal order constraints*](https://www.math.auckland.ac.nz/~nicholls/linkfiles/papers/archaeo2.pdf), published in 2001, DOI 10.1111/1467-9876.00250.

The useful distinction from the already-cited [Park et al. rescaling study](https://doi.org/10.1017/RDC.2026.10203) is also concrete: correcting unequal site contributions and correcting age-dependent choice of dates are different tasks. A sentence making that distinction would connect the paper to a live methodological question without implying that count rescaling corrects within-site selection.

The smallest remedy is a short positioning paragraph, not a new literature review or a claim that the selected extremes are routinely reused in existing databases. The latter prevalence claim has not been established here and is appropriately disclaimed.

### 4. MINOR, optional — Improve the readability of the dense simulation heatmaps

In the submitted reading PDF, Figures 3 and 5 on pages 11 and 13 have small row and rotated column labels when viewed at normal page size. Figure 2 on page 10 is similarly dense, although its common vertical scale is explicitly disclosed and serves a valid comparison. I found no clipping, missing symbols or corrupted mathematics in the inspected figures and equation pages.

For final production, increase the effective label size or rearrange panels while preserving direct comparisons. This is a presentation improvement, not evidence that the numerical results are wrong. Whole-percentage labels necessarily round 999/1,000 to 100; the prose and caption already make the important bracketed-uniform qualification, so I do not treat that rounding as a false result.

### 5. NIT, optional — Two citation refinements

- Hanna 2025, cited with the count-model literature at main lines 17 and 119, is a PCI recommendation of de Navascués et al., which is already cited alongside it. The author's [publication list](https://www.grenadaarchaeology.com/about/CV/Hanna_CV.pdf), pages 3–4, identifies that relationship. Prefer the original methods article alone, or identify Hanna as commentary. This is citation precision, not an unsupported methodological claim.
- [Park's bibliography entry](/home/bwbrook/papers/rc-dates/references/refs.yaml:1816) retains advance pagination 1–26. The [publisher PDF](https://www.cambridge.org/core/services/aop-cambridge-core/content/view/50071261A07BB137E9781D96F1783BB8/S0033822226102033a.pdf/rescaling_radiocarbon_data_a_method_for_addressing_intersite_sampling_heterogeneity_in_reconstructing_population_history.pdf) now gives *Radiocarbon* 68, 541–566. Updating this is routine final bibliography work.

## Strengths that survived challenge

**The empirical comparison is reproducible and isolates a real contrast.** A fresh reconstruction from the earliest repository source import exactly reproduces the accepted 976-record reference. Recalibration and filtering then reproduce 976/116 → 737/106 → 645/106 → 540/68 dates/sites. A fresh execution reproduces the baseline, all primary retention summaries, the 1,000-realisation stochastic distances/shifts and the nine prespecified deterministic sensitivity configurations. Independently recomputing distances from the emitted curves recovers oldest SPD TV = 0.455185 and shift = +3,132.543 years; youngest TV = 0.524365 and shift = −2,439.060 years; and bracketed TV = 0.279084 and shift = +351.996 years. The stated conservative contrasts also reproduce. The distinction between conditional retention ranges and archaeological/population uncertainty is explicit.

**The primary likelihood is defensible under its stated assumptions.** With a uniform calendar-age calibration prior, the calibrated posterior is proportional to the date likelihood. Restriction and renormalisation over the fixed fitting window introduce date-specific constants independent of the population-density parameter. They therefore cancel in model comparisons on the same retained dataset. The implemented log of a posterior-weighted density integral is not the common error of treating the expected log density as an ordinary likelihood. The latter is separately labelled as a score. This is consistent with the marginal-likelihood construction in [Timpson et al. 2021](https://pmc.ncbi.nlm.nih.gov/articles/PMC7741102/). It remains a workflow that ignores the retention process; the paper explicitly says so.

**The simulation's central claims match the raw fitted results.** Independent aggregation of all 720,000 rows reproduces the direction, family, reversal, boundary and effect-summary tables. All-date rows are exactly repeated across treatment proportions, and full-treatment retained counts are 116/232/348/580 as specified. There are no dropped primary dates. Primary and secondary criteria agree on family-and-direction in 119,698 of 120,000 comparisons, which correctly rounds to 99.75%. The candidate families allow both signs, so full-treatment reversal is not forced by a one-direction fitting restriction.

**The bracketed result is interpreted cautiously.** The exact-age order-statistic derivation is correct. Symmetric bracketed samples from a uniform truth are U-shaped for the site counts used here; uniform selection against only monotonic alternatives cannot establish recovery of that shape. The manuscript says this plainly and discloses working independence for the paired extrema. Likewise, it does not overinterpret a bracketed/random-1 empirical comparison as count-matched; random-2 is present in the simulation and absent from that empirical comparison.

**The scope restrictions are scientifically consequential and mostly clear.** Independent regional ages, ten-fold signals, at least five dates per site, no occupation histories, no prospective-budget optimisation, no realised scatter in the main study and no abundance interpretation of normalised empirical curves are all disclosed. These are genuine limits; none by itself invalidates the narrow existence demonstration. The empirical oldest/youngest findings surviving the Y-only subset are useful, particularly because 359 of 540 primary records have uncertain occupation relation.

**Failed prespecified evidence has been preserved.** The noise v1 assessment remains failed at 15/18, and v2 is labelled post-unblinding. Independent aggregation of all 432,000 frozen noise fitted rows reproduces all 288 accuracy and 288 unique-support arm means/paired differences, including the reported ranges −0.015 to +0.008 and −0.019 to +0.009. I did not rerun the bootstrap interval calculations. Nothing found warrants converting v2 into a retrospective pass of v1.

**The numerical specification is more coherent than its awkward count-model fit first suggests.** Independent calculation recovers the reported age–error regression and residual scale. The near-boundary untruncated negative-binomial parameters induce a well-defined conditional count distribution, with q = 0.848924 and conditional mean 8.412401; the supplement correctly interprets the truncated shape rather than the unstable untruncated parameters.

## Evidence gaps and review limits

These are limits on what the present evidence establishes, not additional required simulation projects:

- No test establishes the direction/family-selection performance of the current signed fits after realised noise is added to oldest, youngest or bracketed retention. The current wording mostly handles this correctly; finding 2 closes the remaining historical-model distinction. If the authors want a stronger noise-robustness claim, that needs a prospectively specified extension.
- Site histories, occupation durations, spatial dependence, correlated calibration-curve error, weak/non-monotonic trends and dating allocation are outside the generator. Their effects cannot be inferred from 100% success under the tested ten-fold truths. A JAS reviewer may request such extensions; the defensible response is the paper's isolation of a mechanism, not an assertion that these structures do not matter.
- The empirical experiment diagnoses this conditioned archive; it does not infer how the original samples were chosen, the prevalence of later retention practices, or archaeological truth. The analysis is consequently not validation of an optimal regional sampling design.
- I replayed the recovered original-import route. I did not independently reacquire the August 2026 ADS snapshot or repeat its complete field reconciliation. Exact original-source reconstruction supports the analysed reference; it does not resolve every change to the larger historical working derivative or authorise archaeological data redistribution.
- I did not rerun the full primary or realised-noise simulation campaigns, the 5,000/50,000-resample simultaneous bootstrap calculations, or fit an independent radiocarbon calibration engine. Fresh empirical replay uses the authors' scientific functions; the Python raw-result/curve calculations and the analytic linear-endpoint diagnosis provide separate checks, not a wholly independent implementation of the entire study.
- I read the full manuscript sources and extracted PDF text, visually inspected all main figure pages, the principal likelihood/effect equation page and SI pages 6–8. I did not perform an every-page DOCX layout audit, a complete bibliography audit, or journal-portal compliance review. Those should not be confused with this scientific recommendation.

## Reproducibility record

Development HEAD reviewed: **e2f252ae2686c233f130b234da7ac8f325229c8e**. Standalone release: **dist/rc-dates-scientific-reproducibility-2026-09-11/**; recorded release commit **534cfb9d0a8bd2841079aaaf0fce1644922d2674**. The three current manuscript source files are byte-identical to those in the release. The parent supplied a neutral [identity snapshot](/home/bwbrook/papers/rc-dates/tmp/astra_review_snapshot_2026-09-18.json); scientific conclusions above come from the checks described here.

| Item | SHA-256 |
|---|---|
| Release ZIP | 3b82512ae35e8b1bc473b3d9ba2ce6cc6c258691d8cf7d32b1b8f992ee5ca949 |
| Release top-level manifest | 1db0631293c8bd1db0bf1eb0915cc5a2f3286620baf8cb676493994e2d4fc2e9 |
| Main reading PDF, 13 pages | d99c7aa12c99929896cea5731f527859ad599b259ee75da007bbfe2ef90565d7 |
| Supplement reading PDF, 8 pages | 1214eb88bcea5c27239dac9daace5dddf8ee4c107c1efc1702bc533070e7a31e |
| Original repository import | 67cf7f5b10662165544d5a7525ac56b65d109530c51ca00030d39c8275b4fd1d |
| Reconstructed 976-row reference | 2f1b5ccc40038f9e30bce643d57191c545c98448266fcaab3b11c9a33059c70a |

Local R is newer than required and was not used. Following the user's authorisation, bounded R execution used deep-server-ts and the existing image **rc-dates-release:r4.5.3**, image ID **sha256:7c44e3585626a5cd4b25979dd19b052359ae0df1bac930123c5db27fc41c65fc**. The freshly staged release was mounted read-only with network disabled, two CPUs and an 8 GB memory limit. No image was built and no package environment was altered.

Checks performed:

| Check | Result and scope |
|---|---|
| Release verifier, local and pinned-R host | Passed: 186 top-level files, plus nested manifests covering 17 empirical, 38 signed, 57 noise, eight v2 and seven frozen-noise files; nested counts overlap the release inventory. |
| Release make verify test | Passed all 35 test cases, no failures, warnings or skips reported. Tests include densities/CDFs, flattened/direct likelihood agreement, retention/seeds/pairing, integrity and manuscript transformations. |
| Declarative manuscript-claim auditor | 80 checks passed. This verifies encoded claims; it is not a semantic audit of every prose sentence. |
| Independent Python aggregation | Recomputed all 240 truth × proportion × rule × score cells from 720,000 fitted rows, generating-family effect summaries and confusion counts; numerical agreement within 10⁻¹¹. Primitive XDR schema checked; trailing R object attributes were not parsed. |
| Original-source reconstruction | Archived R script returned 5,522 → 3,700 → 3,076 → 2,553 → 976 records and the exact accepted reference checksum. |
| Fresh empirical execution | Baseline 333 rows; retained curves and differences 3,330 rows each; ten primary gates; 100 non-baseline distance/shift summary rows; all nine deterministic sensitivity configurations reproduced to 10⁻¹². |
| Existing simulation replay and endpoint challenge | Replicate 1, linear increase/full treatment: all 48 rows exact. Replicate 2, random-1: six model/score rows exact. Targeted optimiser-tolerance and analytic endpoint checks expose finding 1. |
| Independent frozen-noise point summaries | All 432,000 rows read; 288 accuracy and 288 unique-support estimates reproduced to 10⁻¹⁴. No bootstrap rerun. |
| Code/input fingerprints | Active scientific-source, input and lockfile fingerprints agree with the accepted metadata. The lockfile was hashed, not streamed or edited. |

Review helpers and logs are preserved as temporary audit material at [tmp/astra_fresh_review_2026-09-18/](/home/bwbrook/papers/rc-dates/tmp/astra_fresh_review_2026-09-18). They contain no copied record-level source dataset. The raw original import and reconstructed reference used for execution remain separately in scratch storage.

The essential execution commands were:

    # From the standalone release
    python3 scripts/release/verify_release.py
    make verify test

    # From development root
    python3 scripts/release/audit_manuscript_claims.py --json
    PYTHONPATH=tmp/astra_fresh_review_2026-09-18 python3 tmp/astra_fresh_review_2026-09-18/independent_checks.py .
    git show dea1f336:data/Austarch_1-3_and_IDASQ_28Nov13-1.csv > /tmp/rc_dates_astra_review_20260918/original_import.csv

    # Inside R 4.5.3, release working directory, scratch-mounted inputs/output
    Rscript --vanilla scripts/release/reconstruct_austarch_reference.R /scratch/original_import.csv /scratch/reconstructed_reference.csv
    Rscript --vanilla /scratch/empirical_check.R
    Rscript --vanilla /scratch/boundary_check.R
    Rscript --vanilla /scratch/random_boundary_check.R
    Rscript --vanilla /scratch/noise_points_check.R

Actual remote scratch root: /data/codex/scratch/rc-dates-astra-review-20260918-OZksqJ/. The release directory beneath it was bound to /workspace; helper scripts and separately governed inputs were bound through /scratch. The principal test invocation was:

    ssh deep-server-ts 'docker run --rm --network none --cpus 2 --memory 8g --mount type=bind,src=/data/codex/scratch/rc-dates-astra-review-20260918-OZksqJ/rc-dates-scientific-reproducibility-2026-09-11,dst=/workspace,readonly --workdir /workspace rc-dates-release:r4.5.3 make verify test'

The initial custom simulation helper loaded rcarbon after seeding and therefore failed exact replay. Loading the package before setting the seed, as the canonical runner does, resolved every discrepancy. An initial empirical comparison helper also required removal of data-frame column names before passing them to R's order function. These were reviewer-helper errors, not repository findings; successful logs and final helpers are retained. No accepted scientific files were changed during this review.

No author decision question is needed to complete this assessment. Before submission, the highest-value next action is the bounded Figure 4/numerical-interpretation correction and the historical-model disclosure, followed by the planned prose and figure edit.

## Implementation acceptance addendum — 19 September 2026

**APPROVE the targeted corrections: findings 1 and 2 are resolved.** This addendum records one focused acceptance check, not a second full scientific review.

The revised Figure 4 transforms every stored generating-family fit to the bounded endpoint-density contrast before computing means and type-7 replicate quantiles. It retains all 1,000 fits per cell regardless of AIC selection, reports the original near-boundary fraction for every cell, and marks any nonzero fraction. The revised manuscript distinguishes the natural linear endpoint from the imposed exponential rate cap, defines the tolerance-based flags without certifying endpoint optima, and explains the bounded scale's interpretation and compression. The historical noise disclosure now states its growth-only candidate space and restricted definition of accuracy while preserving the failed v1 assessment and post-unblinding status of v2.

I inspected the revised scientific/plotting functions and renderer, the affected text, the Figure 4 preview, the direct-parameter Python checker and its successful log, and the pinned-R 4.5.3 test log. I independently compared all 32 emitted summary rows with the direct-parameter reference to 10⁻¹², including means, quantiles, truths, denominators, boundary counts/rates, percentage labels and any-flag symbols. The 7.2% and 8.2% random-1 fractions are visible. I also rechecked all 38 files in the original signed-evidence manifest; every checksum matched. The figure is legible and the necessary qualifications are explicit. No consequential unresolved defect was found within this scope.

Accepted derived CSV: out/revision/endpoint-contrast-20260919/endpoint_contrast.csv, SHA-256 **5102eb4378fbfc0d43f412498f10352739289c4c82898304bae7a7aeda95ac91**. Inspected Figure 4 PDF: manuscript/figures/fig_4.pdf, SHA-256 **e49bef1fd913166c21b2914160212e5d0f36b2b2f8815c0b18442f89e0aed990**. Supporting implementation checks are under tmp/revision_20260919/.

No new simulation, refit or R test rerun was performed in this acceptance check. Final manuscript assembly and the newly dated release were still being completed by the parent task and are outside this addendum's approval. The original review's external-validity limits remain unchanged.
