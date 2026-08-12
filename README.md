# rc-dates

Scientific analysis and manuscript sources for testing how within-site date-retention rules and
model choice affect inference from radiocarbon-date distributions.

This is a private, paper-specific repository. Its current contract is the evidence used by the
manuscript—not a general R package or demonstration compendium.

## Start here

The analysis environment is locked to R 4.5.3. The root `Makefile` rejects other R releases for
direct analysis commands.

```sh
make renv-restore
make test
```

`renv.lock` is the authoritative dependency record. The fast test gate protects the scientific
maths, sampling semantics, stochastic pairing, accepted-artifact structure, and manuscript-facing
empirical transformations.

## Current evidence flow

```text
archaeological dates ──> common-membership empirical evidence ──> revised Figures 1-2
locked simulation evidence ──> independent validation ──> current Figures 3-5
Stage 2 signed design ────────> accepted 720,000-row evidence ──> decision tables
manuscript sources + accepted evidence ─────────────> makedoc ────────────────> submission files
```

Rebuild the inexpensive or already-computed evidence with:

```sh
make empirical-figures
make production-figures
```

The first command reconstructs empirical Figures 1-2 and the associated audit summaries from the
source data. The second independently validates the accepted production artefacts before rebuilding
Figures 3-5. It can use the immutable 2026-07-10 source snapshot when the active simulation code has
subsequently changed.

The accepted Stage 2 signed-model audit remains outside the fast gate:

```sh
make stage2-rerun
```

Run that target only for a deliberate expensive reproduction on `deep-server` inside `tmux`; its
accepted evidence is in `out/revision/signed-models`. The prespecified scientific gate is in
[docs/STAGE2_SIGNED_MODELS.md](docs/STAGE2_SIGNED_MODELS.md), and
[docs/PRODUCTION_SIMULATIONS.md](docs/PRODUCTION_SIMULATIONS.md) gives the runtime and acceptance
contract. The result is interpreted in
[docs/STAGE2_SIGNED_MODELS_RESULTS.md](docs/STAGE2_SIGNED_MODELS_RESULTS.md).

The common-membership empirical repair is specified and interpreted in
[docs/STAGE3_EMPIRICAL_REPAIR.md](docs/STAGE3_EMPIRICAL_REPAIR.md) and
[docs/STAGE3_EMPIRICAL_RESULTS.md](docs/STAGE3_EMPIRICAL_RESULTS.md). Its accepted summaries and
claim gates are under `out/empirical-sampling/`. The final bracketed-retention extension and frozen
decision are in [docs/STAGE5_FINAL_REVISION.md](docs/STAGE5_FINAL_REVISION.md).

## Historical sensitivity decisions

The completed observation-noise work is a frozen scientific record:

- v1 is the prespecified full-family sensitivity and remains **FAIL** (15/18 gates).
- v2 is a separately labelled post-unblinding diagnostic over paired differences; it passed its
  aligned gates and does not replace v1.

Accepted evidence is under `out/sensitivity/observation-noise/`; exact generation sources are under
`provenance/observation-noise-20260726/`. These historical decisions must not be silently redefined
by later model development.

## Manuscript and submission files

The manuscript is built through the neighbouring `makedoc` project:

```sh
make manuscript-check
make submission-build
```

`submission-build` assembles the manuscript, supplementary information, cover letter, title page,
and highlights under `manuscript/submission/dist/`. The previous reviewer-repository builder has
been retired; a smaller replacement will be designed only after the revised scientific outputs are
frozen, so it cannot package stale evidence or overstate data shareability.

## Repository map

- `R/` — active scientific functions.
- `scripts/` — focused empirical, simulation, validation, figure, and manuscript utilities.
- `tests/testthat/` — consequential scientific checks.
- `data/` — source and filtered archaeological inputs; inspect large files conservatively.
- `out/` — accepted machine-readable evidence and run artefacts.
- `provenance/` — immutable source snapshots tied to accepted outputs.
- `manuscript/` — article, supplementary, figure, review, and submission sources.
- `docker/` — the exact production-simulation runtime recipe.

The frozen production snapshot is `provenance/production-20260710/`. Git history contains superseded
demo, compatibility, and packaging machinery; it is intentionally absent from the active tree.

The deposited AustArch object, the project's non-pristine working derivative and the accepted
976-row analysis reference are reconciled in
[data/AUSTARCH_PROVENANCE.md](data/AUSTARCH_PROVENANCE.md). Raw or record-level AustArch data must
not be redistributed without a separate licensing, sensitive-location and Indigenous
data-governance decision.
