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
