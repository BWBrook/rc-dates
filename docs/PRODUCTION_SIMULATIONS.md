# Production population simulations

The manuscript's model-recovery, parameter-bias, and evidential-strength displays use a 3 x 3
simulation matrix: three generating models (`uni`, `lin`, `exp`) crossed with three proportions of
sites subjected to within-site subsampling (`0.5`, `0.75`, `1`). Each scenario has 1,000 replicates;
each replicate contains seven sampling strategies, two likelihood definitions, and three fitted
models (42 result rows).

## Accepted evidence

`out/production/` contains the nine accepted RDS files, their metadata sidecars, display summaries,
container image identifier, and checksum manifest. The matrix was generated on 10 July 2026 with R
4.5.3 on a 64-core Linux host. All 9,000 replicates completed (378,000 rows); the slowest scenario
took about 104 minutes.

The exact sources loaded for that run are immutable under
`provenance/production-20260710/`. The accepted files use provenance schema 1 because their stamps
were attached after preserving the completed raw RDS files. That historical fact is retained; it is
not a template for future runs.

Validate all accepted artefacts and rebuild Figures 3-5 with:

```sh
make production-figures
```

The renderer verifies every complete result block, RDS/metadata checksums, scenario identity,
replicate coverage, one common runtime, the frozen generation-source hashes, and the exact
common-random-number equality of the all-dates reference across sampling intensities. It then writes
the three manuscript summaries and figures.

## Active implementation

The active engine is separated by scientific responsibility:

- `R/population_distributions.R` — fitted error and truncated generating distributions;
- `R/population_simulation_design.R` — arguments, seeds, observation model, and checkpoint contract;
- `R/population_simulation_models.R` — likelihoods, optimisation, AIC and OSE selection;
- `R/population_simulation_run.R` — data generation and one-replicate evaluation;
- `R/population_simulation_artifacts.R` — accepted-artifact validation and display summaries.

`scripts/source_population_simulation.R` is the single ordered loader. New runs use provenance
schema 2, which fingerprints the model-source bundle and distribution module directly. They accept
only native checkpoints with an exact matching fingerprint; the former unstamped-checkpoint
migration and provenance overrides have been removed.

## Full rerun

Run the expensive matrix on `deep-server` in `tmux`, writing away from the accepted evidence:

```sh
RC_DATES_OUTPUT_DIR=out/rerun \
  bash scripts/run_production_simulation_matrix.sh
```

The launcher builds the digest-pinned R 4.5.3 image, checks the runtime, launches the nine scenario
jobs, and records the image ID. Outputs are checkpointed atomically after each batch and resume only
when scenario, seeds, source/input/lock/container hashes, runtime, and image ID match exactly.

Useful explicit overrides are `RC_DATES_NSIM`, `RC_DATES_CORES_PER_JOB`,
`RC_DATES_BATCH_SIZE`, and `RC_DATES_MASTER_SEED`. `RC_DATES_SKIP_IMAGE_BUILD=true` is reserved for
deliberate reuse of an already inspected image.

The master seed is 1234. Replicate `i` uses seed `1234 + i` under `L'Ecuyer-CMRG`; the same seed is
used across all nine scenarios. This pairing is part of the design, not an implementation detail.

## Figure 5 aggregation

The modified one-standard-error rule may retain more than one model. Figure 5 first reduces each
`(truth, proportion, strategy, likelihood, replicate)` group to one Boolean: success requires every
retained model to be the generating model. It then averages those replicate-level values and uses
paired cluster-bootstrap intervals over replicate identifiers, retaining the three generating-family
outcomes together. Ambiguous replicates therefore receive no extra weight.
