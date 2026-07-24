# Production Population Simulations

The manuscript's model-recovery, parameter-bias, and evidential-strength
displays use an opt-in production simulation matrix. It is separate from the
small default `{targets}` demo so reviewers can verify the ordinary pipeline
without first running an expensive experiment.

## Supplied Artefacts

The locked production outputs live under `out/production/`:

- nine RDS files for three generating models (`uni`, `lin`, `exp`) crossed with
  three site-subsampling proportions (`0.5`, `0.75`, `1`);
- 1,000 replicates per model-proportion scenario;
- one runtime metadata file beside each RDS file; and
- CSV summaries for accuracy, parameter bias, and unambiguous OSE selection;
- a recorded container image ID and `SHA256SUMS` manifest.

Each replicate contains 42 rows: seven within-site sampling strategies, two
likelihood definitions, and three fitted population models.

## Rebuild Figures

With the pinned R 4.5.3 environment restored, validate the RDS files and rebuild
Figures 3-5 with:

```sh
Rscript scripts/render_population_simulation_figures.R
```

The renderer checks every 42-row replicate block, verifies each embedded
provenance stamp against its metadata sidecar and file checksum, and confirms
that one runtime generated the full matrix. It also verifies all expected
replicate identifiers and confirms that the common-random-number design makes
the all-dates reference identical across sampling intensities. It then refreshes
the three CSV summaries, rewrites `SHA256SUMS`, and writes the PDFs under
`manuscript/figures/`.

## Full Rerun

The full Linux runner uses the exact R 4.5.3 Docker recipe and defaults to nine
concurrent jobs with seven workers each:

```sh
bash scripts/run_production_simulation_matrix.sh
```

Outputs are checkpointed atomically after each batch. A checkpoint resumes only
when its scenario, seed, input, source-code hashes, R runtime, container recipe,
package lock, package-install definition, and image ID match the requested run.
To preserve supplied artefacts during an independent rerun, choose a separate
output directory:

```sh
RC_DATES_OUTPUT_DIR=out/rerun \
  bash scripts/run_production_simulation_matrix.sh
```

Useful overrides are `RC_DATES_NSIM`, `RC_DATES_CORES_PER_JOB`,
`RC_DATES_BATCH_SIZE`, and `RC_DATES_MASTER_SEED`.

The launcher rebuilds the pinned image by default so its tag cannot silently
refer to stale code dependencies. `RC_DATES_SKIP_IMAGE_BUILD=true` is reserved
for deliberate use of an already inspected, immutable image tag.

## Recorded Production Run

The supplied matrix was generated on 10 July 2026 under exact R 4.5.3. Nine
concurrent jobs used seven workers each on a 64-core Linux host. All 9,000
replicates completed, yielding 378,000 rows; the slowest single scenario was
the uniform model at 50% sampling intensity and took about 104 minutes.

The exact generation image is retained as
`rc-dates-sim:production-20260710`, image ID
`sha256:15cefece042e56e50ee822bd00c9c400dd6259c7a18cf25d6ff333ccea4aa3bc`.
The source snapshot loaded by that image is retained under
`provenance/production-20260710/`. The supplied RDS files were fingerprinted
after the raw completed files had been preserved, so they record a separate
generation-completion time and later provenance-recording time; validation
confirms that stamping did not alter any result row.

The code-only review package was then checked from a fresh exact-R container.
It restored the lockfile, passed the packaged tests, validated and rendered all
three production figures, and completed 158 targets with no failures. The
reviewer configuration runs two demo iterations and 12 optional per-site
diagnostic branches; this does not subset the global analyses or supplied
production results.

## Random-Number Design

The master seed is 1234. Replicate `i` uses seed `1234 + i` under
`L'Ecuyer-CMRG`. The same replicate seed is used across all nine scenarios,
giving common random numbers for paired comparisons. Consequently, the
all-dates reference is exactly repeated across the three sampling intensities.

## Figure 5 Aggregation

The modified one-standard-error rule may retain more than one model. Figure 5
first reduces each `(truth, proportion, strategy, likelihood, replicate)` group
to one Boolean value: success requires that every retained model is the
generating model. The figure then averages those replicate-level values and
uses paired cluster-bootstrap 95% intervals, resampling replicate identifiers
while retaining all three generating-family outcomes together. This prevents
ambiguous replicates from receiving extra weight and respects the common-random-
number dependence across generating models.

## Relationship To The Historical Run

This rerun is method-equivalent, not a bitwise reconstruction of unavailable
historical RDS files. Tests compare both likelihood definitions and both
growth-model optimisations with direct calculations from the archived method.
The production runner makes the seed stream and sampling order explicit, so its
deterministic RDS files need not match an older, unrecorded random-number stream.

The exact files loaded by the supplied production jobs are retained under
`provenance/production-20260710/`. Their MD5 values match the source fingerprints
embedded in the RDS files. The active source includes later validation and
summary safeguards and is the maintained entry point for future reruns.
The supplied files explicitly record `post-run-stamp` because their provenance
attributes were added after the completed, unstamped RDS files had been
preserved; future clean runs record `native-checkpoint`.

The supplied package can be used without GitHub. It is not an air-gapped
dependency bundle: the first `renv` restore or Docker build requires access to
the configured package and operating-system mirrors.
