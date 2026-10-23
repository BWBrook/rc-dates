# Stage 7: retention under realised measurement scatter

Prespecified on 23 October 2026, before any Stage 7 output existed. Barry Brook authorised it the same day in chat with
Claude, choosing "Run it now" for the realised-noise check during his read-through (stage 2 of
`docs/SUBMISSION_WORKFLOW.md`). This stage adds evidence. It changes no accepted artefact, figure, decision or source
file.

## Question

The accepted simulations use the calibration-curve-mean observation model. Each simulated determination has the
expected conventional age at its true calendar age, and only its quoted error is drawn. Realised scatter was tested
earlier only for all-date and random rules (Supplementary Section S3). That assessment failed its prespecified gate and
was followed by a diagnostic run after unblinding. The manuscript therefore states that oldest, youngest and bracketed
retention are untested under realised scatter.

Stage 7 asks whether the main-experiment conclusions for those rules, and for the random and all-date references, hold
when every simulated conventional age carries realised measurement scatter.

## Frozen design

The design is identical to the accepted Stage 2 matrix (`docs/STAGE2_SIGNED_MODELS.md`) except for the observation
model:

- **Matrix.** Five truths (uniform; linear and exponential, increasing and decreasing), a ten-fold end-to-end ratio,
  treatment proportions of 0.5, 0.75 and 1, all eight retention rules, and 1,000 replicates per scenario. That is 15
  scenarios. The seeds are those of the accepted design (`production_simulation_seed`, master seed 1234, under
  `L'Ecuyer-CMRG`).
- **Observation model.** `realised`. Each conventional age is drawn by
  `rcarbon::uncalibrate(..., CRAerrors = errors, roundyear = TRUE)` as Normal(curve-mean age,
  √(curve error² + quoted error²)) and rounded, then calibrated with its quoted error. The draw uses an isolated stream
  derived from the replicate's structural RNG state with `parallel::nextRNGStream`, and the structural state is then
  restored. Calendar ages, quoted errors, site sizes, treated sites and every random retention draw are therefore
  identical to the accepted replicate with the same number. Only the conventional ages differ, and with them the
  calibrated posteriors and the posterior-median extrema.
- **Code.** All accepted sources stay byte-identical, including `R/` and `scripts/run_population_simulation.R`; the
  accepted Stage 2 summariser requires this. A Stage 7 runner, `scripts/run_stage7_realised_noise.R`, copies the
  production runner. It differs only in passing the observation model to the existing data generator and in recording
  `observation_model` and its own runner fingerprint. It has an `--observation-model` option, defaulting to `realised`,
  so that the smoke check can exercise the `curve_mean` path.
- **Runtime.** The accepted image `sha256:01f5e221d0f3b70ccb3edd0fd6556ffd1c645784e98e147e81034866b9137777` runs on
  `deep-server`. Output goes to `out/revision/realised-noise-20261023/`.

## Technical acceptance, checked before interpretation

1. **Wrapper equivalence.** A 20-replicate Stage 7 run of the accepted `lin_inc`, 100%, ten-fold scenario under
   `curve_mean` must reproduce accepted replicates 1–20 exactly in all 17 result columns.
2. **Pairing.** For replicates 1–3 of the `lin_inc` and `uni` scenarios at 50% treatment, the realised and curve-mean
   datasets must be identical in site, treatment flag, calendar age, expected conventional age, quoted error and the
   random-1, random-2, random-3 and random-5 selections. They must differ in conventional age for most dates.
3. **Completeness and binding.** All 15 files must be present, each with 1,000 replicates, 48 rows per replicate and
   replicate IDs 1–1,000. Each file's stored truth, proportion, ratio and replicate count must match its expected
   scenario.
4. **Provenance.** Every frozen field must equal the accepted Stage 2 provenance except `observation_model`, which must
   be `realised`, and `runner_source_md5`, which must be the committed Stage 7 runner's MD5. The model-source,
   distribution-source, input, lock-file, container and R-version fingerprints must match the accepted values.

If any check fails, Stage 7 is reported as not accepted and is not used in the manuscript.

## Outcomes reported regardless of result

For every truth, proportion and rule, under `l1`, we report the correct-state, reversal, uniform-selection and
generating-family rates under realised scatter, and their paired differences from the accepted curve-mean rates. For
each cell we also report the share of replicates that select the same family and direction under both observation
models, and `l1`/`l2` agreement under realised scatter.

## Manuscript decision rule

The headline results, under `l1` and the accepted values, are:

1. **Full treatment.** The opposing rule reverses all four changing truths (1.000), and the concordant rule recovers
   their direction (1.000).
2. **Constant truth.** Full-site oldest and youngest never select uniform (0.000). At 50% treatment they select a
   directional model in 0.973 and 0.979 of replicates.
3. **Partial treatment.** The opposing rule never reverses a ten-fold change at 50% or 75% (0.000).
4. **Random rules.** Random-1, random-2, random-3 and random-5 never reverse a changing truth at any proportion (0.000).
5. **Bracketed retention.** At full treatment it recovers the direction of every changing truth (1.000), selects the
   linear family for no linear truth (0.000), and selects uniform for the constant truth (0.999).

The results **hold** if every headline rate under realised scatter is within 0.02 of its accepted value. In that case,
the manuscript replaces the statement that these rules are untested under realised scatter with the result and its
ranges, scoped to the ten-fold design (Supplementary Section S2.8).

If any headline rate moves by more than 0.02, the manuscript reports which result changed and by how much in Results
and Section 4.3, and revises the abstract's limitation sentence to match. Cell-level results go to the Supplementary
Information either way.

## Interpretation limits

- The results cover the ten-fold design only. Weaker ratios under realised scatter are not tested.
- Dates remain exchangeable regional draws without occupation histories. Calibration-curve errors are independent
  across dates, not correlated.
- Stage 7 does not revisit the earlier failed v1 noise gate or its v2 diagnostic. Those used a growth-only candidate
  set and a different design and remain as reported.

## Amendment before any Stage 7 result was inspected (23 October 2026, 06:55 UTC)

The first matrix launch (06:01 UTC) stopped at 06:47 UTC. All 15 jobs aborted between replicates 27 and 212 with "A
calibrated date has no probability within the analysis window." Under realised scatter, a date near either end of the
window can calibrate wholly outside the strict 651–11,650 cal BP interior. The accepted evaluation aborts in that case
(`drop_empty = FALSE`). This never arises under the curve-mean model, which is why the prespecification did not cover
it. No selection rate was computed or inspected; only the job logs were read.

The earlier realised-noise sensitivity (Supplementary Section S3) met the same condition. It dropped such observations
and recorded the number (`drop_empty = TRUE`, counted in `n_dropped`). Stage 7 adopts that rule unchanged:

- Extrema are still chosen by posterior median among all of a site's dates.
- A retained date with no in-window mass is dropped from that rule's fit and counted.
- Under `curve_mean`, no date is ever dropped, so acceptance check 1 still tests exact reproduction of the accepted
  replicates.

The summaries report the dropped dates for each rule and scenario. Dropping falls mainly on dates near the window edges,
which oldest and youngest retention favour, so the reported rates also include these drops. Because the runner
fingerprint changes, the partial checkpoints are moved, unused, to
`out/revision/realised-noise-20261023/aborted-drop-empty-false/`. The smoke run and the matrix are both rerun with the
amended runner.

## Correction to acceptance check 2 before any selection rate was computed (23 October 2026, about 11:30 UTC)

The rerun matrix finished at 11:08 UTC with status 0, and all 15 scenarios completed. The first summariser run stopped
at acceptance check 2: the first of six paired datasets (`lin_inc`, 50%, replicate 1) had identical calendar ages but
different quoted errors and random-rule selections. The other five pairs were identical.

The cause was the check itself. Loading the rcarbon namespace in a fresh R session consumes random numbers; this was
confirmed directly in the accepted image. Both production replicate functions call
`requireNamespace("rcarbon")` before seeding, which is why acceptance check 1 reproduces the accepted replicates exactly.
The pairing check did not, so the first dataset it generated, the curve-mean arm, was drawn after the namespace load
had shifted the stream.

The check now loads rcarbon before seeding, exactly as the production code does, and the summariser was rerun. No
selection rate had been computed when the correction was made: the summariser stops at the first failed check, before
any rates are calculated.

## Result (23 October 2026)

Technical acceptance passed:
1. The curve-mean wrapper reproduced accepted replicates 1–20 exactly, in 960 rows and 17 columns.
2. All six paired datasets had identical structural draws, and conventional ages differed for 99.9–100% of dates.
3. All 15 scenarios had 1,000 replicates, matched their expected scenarios and carried the accepted provenance, apart
   from the realised observation model and the Stage 7 runner.

**The headline rule holds.** All 75 headline rates stayed within 0.02 of their accepted values, and the largest
absolute change was 0.001. Across all cells, the largest change in any `l1` rate was 0.015, a generating-family rate for
random-3 under linear increase at full treatment, and direction and reversal rates were essentially unchanged. At
least 95.2% of replicates in each cell selected the same family and direction under both observation models; the
median was 99.1%. Realised scatter changed which date was a site's posterior-median oldest for only about 0.2–1.5% of
dates in the paired check. At most 0.011% of retained dates were dropped for having no mass in the window. Under
realised scatter, `l1`/`l2` agreement on family and direction was 0.9975.

The evidence is in `out/revision/realised-noise-20261023/`, with checksums in `SHA256SUMS`. Per-replicate job logs are
on `deep-server` and are not tracked, following the repository's ignore rule for `logs/`. The partial checkpoints from
the aborted first launch remain unused on `deep-server` under `aborted-drop-empty-false/`.

## Independent verification (23 October 2026)

An independent Claude Sonnet subagent wrote its own base-R aggregation without sourcing any project code. It ran in the
accepted image with the checkout mounted read-only, and its script is `~/s7verify/verify_stage7.R` on `deep-server`.
It checked 1,440,000 fitted rows: every (replicate, score, rule) group had exactly one selected model, and every file
held replicates 1–1,000. Its rates matched all 240 rows of `stage7_selection_rates.csv` exactly in every rate column,
and its change columns agreed to within 1.4e-17. It rebuilt all 75 headline rows with exact agreement; the only nonzero
changes were the two constant-history half-treatment rows (±0.001). The committed SHA-256 manifest, which was
generated locally after copying, was then checked against the files on `deep-server`, and all 40 entries matched. As
in the Stage 6 audit, this verifies the stored selections and their aggregation; it does not refit every model.
