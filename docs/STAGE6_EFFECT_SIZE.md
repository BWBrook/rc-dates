# Stage 6: retention effects across signal strength

Prespecified on 18 October 2026, before any Stage 6 output exists. Authorised by Barry Brook on the same
day, as part of the editorial reworking in correspondence discussion 88 (messages 1940 onward). This
stage adds new evidence. It does not alter any accepted Stage 2 artefact, figure or decision.

## Question

The accepted simulations use one effect size, a ten-fold end-to-end density ratio. Under that signal,
an opposing oldest or youngest rule reversed the inferred direction in every replicate only when every
site was treated. At 50% and 75% treatment, no non-uniform replicate was reversed. A constant history
(ratio 1), however, was read as directional in about 97% of replicates at 50% treatment. The paper
therefore cannot say how the risk changes between no change and ten-fold change. This is the strongest
specialist objection to its scope.

Stage 6 asks one question: how do the correct-direction, reversal and uniform-selection rates under
each retention rule depend jointly on the true end-to-end ratio and the proportion of sites treated?

## Frozen design

Everything is identical to the accepted Stage 2 matrix (`docs/STAGE2_SIGNED_MODELS.md`) except the
effect ratio.

- **Code and runtime.** Accepted simulation sources, runner and data, verified by matching all seven
  recorded fingerprints: input, renv lock, model sources, distribution source, runner, container
  recipe and container install. Container image
  `sha256:01f5e221d0f3b70ccb3edd0fd6556ffd1c645784e98e147e81034866b9137777`, the accepted image, is
  reused without a rebuild.
- **Truths.** `lin_inc`, `lin_dec`, `exp_inc` and `exp_dec`. The uniform truth does not depend on the
  ratio and is taken from the accepted evidence.
- **End-to-end ratios.** 1.5, 2, 3 and 5. The accepted ratio-10 cells complete the series, and the
  accepted uniform cells supply ratio 1.
- **Site-treatment proportions.** 0.5, 0.75 and 1.
- **Replication.** 1,000 replicates per scenario, 48 scenarios in all. Replicate `i` uses seed
  `1234 + i` under `L'Ecuyer-CMRG`, as in Stage 2. The seed does not depend on the ratio, so latent
  structural draws are paired across ratios.
- **Rules and scores.** All eight retention rules, the `l1` marginal likelihood as primary and the `l2`
  score as sensitivity, exactly as in Stage 2.
- **Output.** `out/revision/effect-size-20261018/`, produced on `deep-server` in a fresh archive of
  commit `e40bfb6` plus the Stage 6 launcher.

## Technical acceptance, checked before any interpretation

1. **Reproducibility smoke test.** A 20-replicate rerun of the accepted `lin_inc`, 100%, ratio-10
   cell must reproduce the first 20 accepted replicates exactly in every result column. Only run
   metadata, such as timestamps and output path, may differ.
2. **Completeness.** All 48 scenario files must be present, each with 1,000 replicates and the same
   row count per file as the accepted Stage 2 files.
3. **Provenance.** Every Stage 6 metadata record must match the accepted fingerprints and image ID.
   The ratio field must equal the requested ratio.
4. **Truth specification.** Every truth must have the requested endpoint ratio and integrate to one.

If any check fails, Stage 6 is reported as not accepted and is not used in the manuscript.

## Outcomes reported regardless of result

For each truth, ratio, proportion and rule, under `l1`:

- correct-direction rate;
- reversal rate, meaning selection of the opposite direction;
- uniform-selection rate;
- generating-family selection rate.

The `l1`/`l2` agreement rate is also reported.

Derived summaries:

- **Adverse one-sided rule.** Oldest under increasing truths, youngest under decreasing truths.
- **Concordant one-sided rule.**
- **Bracketed retention.**
- **Random-1 and all dates.** Count-matched and full-data references.

Monte Carlo standard errors are at most 0.016.

## Interpretation rules

- Statements about weaker signals are restricted to the tested ratios. No interpolation between them
  is reported as a result.
- A ratio is not a population growth rate. It is the density contrast between the ends of an
  11,000-year window.
- Exchangeability, the calibration-curve-mean observation model and the absence of occupation
  histories all remain limits. Stage 6 does not address realised measurement scatter.
- Results can strengthen or narrow the paper's claims. Both outcomes are reported.

## Planned display

One new figure. The x-axis is the end-to-end ratio on a log scale, with ratio 1 marking the constant
history. The y-axis is the proportion of replicates in which AIC favours the true state: the correct
direction, or uniform for ratio 1. There is one line per treatment proportion, with rows for linear
and exponential families. Columns show the adverse one-sided rule, bracketed retention and random-1.
Increasing and decreasing truths are shown separately, not averaged. Concordant-rule and family
results go to the Supplementary Information.

## Amendment before any Stage 6 result was inspected (18 October 2026, 03:55 UTC)

The 1,000-replicate matrix was launched at 03:43 UTC and stopped at 03:54 UTC, after the first 40
replicates of 15 scenarios had been checkpointed and before any rate was computed. With 15 concurrent
jobs, each ran at about four replicates per minute, putting the full matrix at about 13 hours.
Replication is reduced to the first 500 replicates per scenario, seeds `1234 + i` for `i` = 1…500,
which halves the runtime. The largest possible Monte Carlo standard error for a rate becomes 0.022.
Replicates remain paired with replicates 1–500 of the accepted evidence. The stopped checkpoints are
kept, unused, under `out/revision/effect-size-20261018/aborted-nsim1000/`. Acceptance checks 2–3 now
require 500 replicates per Stage 6 scenario, and accepted ratio-10 and uniform cells are pooled at
their full 1,000 replicates. The planned figure shows the constant-history reference (ratio 1) as an
unconnected marker, because its success criterion is uniform selection rather than correct direction.
This follows Codex's point in discussion 88, message 1950.

## Acceptance enforcement repaired before any Stage 6 rate was inspected (18 October 2026, about 07:10 UTC)

Codex's static audit (discussion 88, message 1980;
`manuscript/reviews/codex_stage6_pre_results_audit_2026-10-18.md`) found that the summariser did not
enforce the design as written. These repairs change enforcement and display only. They change no estimand,
scenario or simulation.

- **Check 1.** The summariser now runs the smoke comparison itself. It requires every one of the 17
  result columns of the 20-replicate rerun to equal accepted replicates 1–20, with rows matched on
  replicate, score, rule and model. It records both file hashes in `stage6_smoke_check.csv`.
- **Scenario binding.** Every Stage 6 and accepted reference file must have stored truth,
  proportion, ratio and replicate count that match its row in the expected grid. The results must also
  carry that truth and proportion. Swapped or relabelled files therefore fail.
- **Frozen matrix.** The environment overrides for ratios and replicate count are removed. Acceptance
  requires all 48 scenarios at 500 replicates and all 15 accepted cells at 1,000.
- **Figure.** Lines connect only ratios greater than 1, and ratio 1 is drawn as an isolated marker. The
  caption gives 500 replicates for ratios 1.5–5 and 1,000 for ratios 1 and 10.

The repaired checks were exercised on the scenarios that had completed by then. The smoke comparison
matched in all 17 columns, and the binding rejected a wrong truth, proportion, ratio or replicate count.
Only completeness and acceptance status were read in that exercise, not selection rates. Files from
scenarios still running are checkpoints written to the final filename and correctly fail the
completeness check.
