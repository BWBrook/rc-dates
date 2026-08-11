# Population simulations

## Locked 2026 production evidence

The manuscript's current Figures 3–5 use the accepted 3 × 3 matrix under `out/production/`: uniform,
linear-increase and exponential-increase truths crossed with site-treatment proportions 0.50, 0.75
and 1.00. Each scenario contains 1,000 replicates, seven retention rules, two fitted criteria and
three fitted families (42 rows per replicate).

Those nine RDS files were generated on 10 July 2026 with R 4.5.3 on a 64-core Linux host. All 9,000
replicates completed (378,000 rows); the slowest scenario took about 104 minutes. Their exact sources
are immutable under `provenance/production-20260710/`. The original evidence remains a scientific
record while the Stage 2 revision is evaluated.

Validate the locked artefacts and rebuild the current figures with:

```sh
make production-figures
```

The renderer verifies complete result blocks, RDS and metadata hashes, scenario identity, replicate
coverage, a common runtime, the frozen generation-source fingerprints, and exact all-dates pairing
across treatment proportions.

## Stage 2 signed-model audit

The frozen question, estimand, truth matrix, effect scale and claim gates are in
`docs/STAGE2_SIGNED_MODELS.md`. The new matrix contains five truths crossed with three treatment
proportions. Each replicate contains eight retention rules, the primary `l1` likelihood, the `l2`
scoring sensitivity, and three signed fitted families (48 rows).

The matrix completed and passed its acceptance gates on 10 August 2026. The scientific decision and
bounded interpretation are recorded in `docs/STAGE2_SIGNED_MODELS_RESULTS.md`; the accepted evidence
is under `out/revision/signed-models/`.

The active engine is separated by scientific responsibility:

- `R/population_distributions.R` — signed generating densities and random generators;
- `R/population_simulation_design.R` — truth contract, common effect scale, seeds and CLI;
- `R/population_simulation_models.R` — fitted scores, signed optimisation and parsimony selection;
- `R/population_simulation_run.R` — data generation, isolated random-2 and replicate evaluation;
- `R/population_simulation_artifacts.R` — locked-artifact validation and Stage 2 summaries;
- `scripts/run_population_simulation.R` — one resumable scenario with schema-3 provenance;
- `scripts/summarise_stage2_signed_models.R` — matrix-wide independent acceptance checks.

`scripts/source_population_simulation.R` is the single ordered loader. Stage 2 checkpoints resume
only when truth, effect ratio, treatment proportion, seeds, source/input/lock/container hashes,
runtime and image ID match exactly.

## Running Stage 2

Run the expensive matrix on `deep-server` inside `tmux`:

```sh
make stage2-rerun
```

The default output is `out/revision/signed-models/`, separate from the locked manuscript evidence.
The launcher builds the digest-pinned R 4.5.3 image, verifies the runtime, launches the 15 scenarios,
waits for every resumable job, and then runs the independent matrix summariser in the same container.
It allocates four cores per scenario by default, for at most 60 of the server's 64 CPUs.

Useful explicit overrides are `RC_DATES_NSIM`, `RC_DATES_CORES_PER_JOB`, `RC_DATES_BATCH_SIZE`,
`RC_DATES_MASTER_SEED`, `RC_DATES_RATIO` and `RC_DATES_OUTPUT_DIR`.
`RC_DATES_SKIP_IMAGE_BUILD=true` is reserved for deliberate reuse of an inspected image.

The accepted Stage 2 directory must contain:

- 15 RDS checkpoints and 15 metadata sidecars;
- a scenario manifest and container image record;
- truth-state confusion, selection, log-ratio bias, boundary and paired-contrast tables;
- `VALIDATION.txt` recording all-dates pairing and provenance acceptance;
- `SHA256SUMS` covering every accepted evidence file.

Revalidate an already completed matrix with:

```sh
make stage2-summarise
```

The master seed is 1234. Replicate `i` uses seed `1234 + i` under `L'Ecuyer-CMRG`; the same seed is
used across all 15 scenarios. Random-2 is generated on an isolated deterministic state after the
locked structural draws, so adding it cannot alter the other seven retention rules.
