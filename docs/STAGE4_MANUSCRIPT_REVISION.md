# Stage 4: integrated figures and manuscript revision

## Purpose

Bring the accepted Stage 2 signed-model evidence and Stage 3 common-membership empirical evidence
into one submission-facing paper. This is a results-outward revision of the existing five-figure
manuscript, not a new scientific analysis.

The paper is now explicitly an **exchangeable-date retention experiment**. It asks how post hoc
retention of completed determinations changes descriptive calendar-age densities and selection of
simple regional event-age-density models. It does not represent prospective context selection,
site occupation histories, stratigraphy, site onset or site termination.

## Claims fixed by accepted evidence

1. The primary empirical benchmark contains 540 terrestrial charcoal or wood determinations from
   68 sites. SPD, FD and KDE use identical determinations and are normalised to unit integral.
2. In that benchmark, retention deformation exceeds between-method variation only when every site
   is reduced to its oldest posterior-median determination, youngest determination or both
   extrema. The ordering does not hold generally for half-site or random retention.
3. In the signed simulation, full-site oldest-date retention selects a decreasing direction and
   full-site youngest-date retention selects an increasing direction in every replicate under
   every truth. The adverse rule reverses every non-uniform replicate; either one-sided rule
   manufactures a directional exponential fit under uniform truth.
4. Random retention preserves direction across the strong ten-fold monotonic truths, although
   sparse retention reduces generating-family recovery. Bracketed retention protects direction
   but not linear-versus-exponential family recovery.
5. The realised-observation-noise v1 screen remains failed. The later v2 diagnostic remains a
   labelled post-unblinding diagnostic and is not used to validate the one-sided rules, which were
   not included in that experiment.

## Display-item design

### Figures 1–2: empirical benchmark

- Figure 1 shows the three common-membership all-date summaries and states the effective sample
  size and all-date between-method total-variation distances.
- Figure 2 shows density difference from each method's own all-date baseline for all ten retention
  scenarios. It is printed at full manuscript width. Its caption reports that full-site extrema are
  deterministic and distinguishes conditional-realisation envelopes from inferential uncertainty.

### Figure 3: truth-consistent signed-state selection

Use the accepted `selection_performance.csv` primary (`l1`) results. Show three site-treatment
panels (50%, 75%, 100%), with generating truths as rows and retention rules as columns. Cell fill and
printed values give truth-consistent direction selection for non-uniform truths and uniform-state
selection for uniform truth. This directly exposes full-treatment reversal and manufactured
direction without pooling across truths. Printed values make the figure interpretable without
colour.

### Figure 4: common-scale effect estimates

Use the accepted `log_ratio_bias.csv` primary results at full site treatment. For each non-uniform
truth and retention rule, plot the mean fitted generating-family effect

$$
\theta=\log\{f(651)/f(11650)\}
$$

and its central 95% replicate range. Show zero and the true value, and mark estimates with high
optimiser-boundary frequency. The common effect scale replaces incomparable native linear and
exponential parameters.

### Figure 5: generating-family selection

Use `selection_performance.csv` to show the minimum-AIC generating-family selection rate in the
same truth-by-rule, three-proportion heatmap structure as Figure 3. This separates direction from
functional-family recovery and makes the bracketed linear-truth failure visible. Do not use a
chance line or the old pooled “accuracy” display.

## Manuscript rewrite

Revise in this order:

1. figures and quantitative results;
2. empirical and simulation methods;
3. discussion, limitations and conclusions;
4. introduction;
5. title, abstract and keywords;
6. captions, supplementary information, highlights, cover letter, title page and submission
   checklist.

Use the title **Within-site date-retention rules can distort radiocarbon “dates-as-data”
inference**. Use “post hoc date retention”, “site-treatment proportion”, “regional event-age
density”, “generating-family selection rate” and “expected-log-density scoring sensitivity”
consistently. Reserve likelihood and AIC language for the primary `l1` criterion. Describe plotted
quantiles of replicate-level effects as central replicate ranges, not confidence intervals.

The discussion may recommend auditing site-level contributions and retention rules. It may present
random multi-date retention as a representative benchmark for this strong-signal exchangeable-date
experiment. It may not prescribe a universal minimum number of dates, equate extrema with field
contexts, or infer site histories from the experiment.

## Source changes

- Create `R/manuscript_signed_figures.R` for validation, transformation and plotting of accepted
  Stage 2 summary tables.
- Replace the legacy production renderer in `scripts/render_population_simulation_figures.R` with
  a focused renderer for `out/revision/signed-models/`.
- Add consequential tests in `tests/testthat/test_manuscript_signed_figures.R` and source the module
  from `tests/testthat/helper-setup.R`.
- Regenerate `manuscript/figures/fig_1.png` through `fig_5.pdf` from accepted evidence.
- Revise `manuscript/text/main.md`, `manuscript/text/figures.md`,
  `manuscript/text/supplementary.md`, and the journal-facing Markdown under
  `manuscript/submission/`.

## Verification and stopping rule

Acceptance requires:

- exact R 4.5.3 tests pass;
- both accepted evidence checksum manifests pass before rendering;
- plotted values reconcile with the Stage 2 and Stage 3 decision tables;
- all five regenerated figures are visually legible at manuscript dimensions;
- manuscript and supplementary citations parse and the submission build succeeds;
- the article remains within the journal's 5,000-word limit under the established counting rule;
- title, abstract, results, discussion, captions, highlights and cover letter make the same bounded
  claims; and
- one focused scientific/prose self-review finds no material contradiction or unsupported claim.

Do not add weaker-signal, matched-total-date, site-history or all-rule realised-noise experiments in
this tranche. Their absence is reported as scope, not disguised by extra engineering or prose.
