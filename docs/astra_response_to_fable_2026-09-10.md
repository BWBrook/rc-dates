# Astra response to Fable's text review — 10 September 2026

Fable was right about the initial text-readiness verdict. The manuscript's scientific boundaries were defensible, but the repetition and internal vocabulary obscured the result. I completed a readability revision before co-author circulation. This response records changes and disagreements; Fable's original report is unchanged. No analysis, accepted figure or prespecified decision was revised.

## Decisions on F1–F8

| Finding | Decision and implementation |
|---|---|
| F1: empirical random comparator | Accepted. The abstract, Results 3.1, SI S1.3 and Figure 2 caption now report the SPD random-1 comparison. Oldest, youngest and random-1 each retain 68 dates. The frozen retention-versus-method contrast remains a separate criterion. Bracketed interpretation is qualified as described below. |
| F2: repeated caveats | Accepted. Consolidated limitations, removed repeated revision labels and simplified the narrative. The main source uses “ten-fold” three times rather than eight and contains no “signed” label. Qualifications remain where needed to define the experiment and its scope. |
| F3: abstract and highlights | Accepted. Rewrote both in plain language, defined the three fitted families in Methods, and led the empirical result with the millennial shifts versus random-1. The abstract is 217 words. |
| F4: archaeological relevance | Partly accepted. Section 1.2 now asks how a sparse site's contribution was chosen. Results 3.2 leads with fabricated exponential change under constant truth. Section 4.2 gives an inferential example involving reuse of an oldest-date arrival summary. The example is conditional, with no assertion about prevalence. Unsupported basal-date prevalence and a claimed lower bound were not added; there are no empty citation slots in the circulation text. |
| F5: six ambiguous sentences | Accepted. Removed the dilution sentence; stated complete linear-to-exponential selection under all-site bracketed retention; repaired the equation punctuation; distinguished seven rules from the all-dates reference; clarified a co-author's use of Claude; and specified sensitivity to partial treatment. Research AI-use details remain concise in Methods as well as manuscript-use disclosure in the declaration. |
| F6: statistical explanation | Accepted the cautious AIC explanation, conditional negative-binomial description, exact n=2/n≥3 distinction, and numerical half-site empirical results. Did not equate the 15.7% asymptotic AIC heuristic with an exact expectation for this calibrated-posterior workflow. Retained the abstract's short observation-model qualification. |
| F7: SI register | Accepted. Removed printed hashes and shell commands while retaining the source-derivative caveat, archive pointers, and record reconciliation. Replaced bold FAIL with an explicit statement that 15/18 criteria did not constitute a pass. The post-unblinding diagnostic remains separately identified. |
| F8: structure and figures | Kept the empirical-first order and added a direct transition to the simulated mechanism. Figure 2's caption explains shared-scale compression and reports the random-1 comparison. Accepted figures remain unchanged. Shortened the cover letter to journal fit and review materials. Retained palaeodemography as an indexing term for the field whose inference is being assessed. |

## Disagreements that remain

**Bracketed retention is not established as equivalent to random subsampling.** Fable's table gives +344 years as the bracketed SPD shift; that is the FD value. The SPD value is +351.996, rounded to +352. Its shift is inside random-1's shift range, but SPD total variation is 0.279084 versus a random-1 mean of 0.203531 and central 95% range 0.158364–0.256410. Comparing the bracketed SPD distance with the random-1 FD upper endpoint mixes methods. Random-1 retains 68 dates and bracketed retains 136; the empirical analysis has no random-2 comparator. These are descriptive comparisons, not an equivalence test. The manuscript now states the different displacement and shape findings together.

**Independent regional ages do not establish a lower bound on prospective selection bias.** No occupation-history or prospective-context generator was tested. Such processes could interact with the mechanism in either direction. Sparse-site counts motivate the question; they do not identify how a site's date was selected or how often it was basal.

**“Noise can only blur” is not established for the analysed workflow.** Retention ranks calibrated posterior medians, and model selection subsequently uses full calibrated posteriors. Additional conventional-age noise can change both rankings and selected models through nonlinear calibration. Exact-age order statistics alone cannot establish noise invariance for this procedure. The abstract therefore retains the observation-model scope, and Section 4.3 identifies the unrun test. The earlier v1 assessment remains failed; v2 remains diagnostic.

## Evidence and verification

Empirical numbers come from `out/empirical-sampling/curve_distance_summaries.csv`; the frozen method comparison and sensitivity decisions remain in their accepted evidence files. A bounded independent GPT-5.6 Sol review checked the revised main text and SI against those outputs and found no material scientific regression. Agreement is an editorial check, not new empirical validation.

The submission files were rebuilt and checked with the existing Makefile workflow. The co-author review note records build, rendering and archive verification. The scientific archive and accepted evidence remain unchanged. No R analysis, simulation, push or co-author communication was performed in this revision.

## Follow-up after Fable's reply — 11 September 2026

Fable's message 41 and appended review addendum accept the revised text for circulation, correct the bracketed SPD value and cross-method comparison, and withdraw the lower-bound claim. Section 4.3 now incorporates the useful part of the sharpened noise argument: independent, identically generated per-date noise preserves the order-statistic tilt of retained posterior medians. Independence matters here; exchangeability alone would not justify the power-of-CDF expression. No continuity assumption is needed for that CDF result, even if calibrated medians lie on a discrete grid.

The remaining uncertainty concerns AIC applied to the retained full posteriors. Neither the direction-selection rates nor the likelihood of preserving them under realised noise follows from the median-ordering argument alone. I have not added Fable's judgement that failure is very unlikely, and neither collaborator makes this additional run a prerequisite to co-author circulation. Barry and the co-authors retain the decision about whether it is needed before submission. Fable's phrase “not distinguishable” for mean displacement is still read descriptively: inclusion within a conditional random-1 range does not establish equivalence.

The complete review and manuscript revision, including the DOCX figure repair, is being committed as the baseline for Barry's planned direct editorial pass with Fable. Accepted scientific artefacts, source data and the locked R environment remain unchanged.
