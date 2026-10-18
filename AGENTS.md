# AGENTS.md — rc-dates

## Product and user

This private research repository exists to produce defensible evidence and submission files for the
`rc-dates` paper. Barry Brook is its only current user. It is not an R package, a generic compendium,
or a public software product.

## Operating principle

Rigour at the scientific decision boundary; proportional engineering everywhere else.

- Use the smallest legible implementation that answers the current research question.
- Protect data, estimands, simulation semantics, stochastic design, provenance, and claims.
- Stop when more work is unlikely to alter a scientific or submission decision.
- Do not preserve backwards compatibility, speculative options, dormant features, or package-like
  ceremony. Git preserves superseded code.

## Canonical workflow

- Work from the repository root under WSL/Linux.
- Use the root `Makefile` as the command index. Do not introduce another workflow framework.
- Run R work with exactly R 4.5.3. `renv.lock` records the analysis environment; never stream or edit
  it unless the user explicitly approves an environment change.
- Keep reusable scientific functions in `R/`, focused execution scripts in `scripts/`, tests in
  `tests/testthat/`, manuscript sources in `manuscript/`, and generated evidence in `out/`.
- Heavy simulations are explicit, resumable jobs. Use the documented container/runtime and run them
  on `deep-server` in `tmux` when they exceed the local interactive budget.
- Use qualified package calls (`pkg::fun`) where this improves clarity. This is not a package, so do
  not add Roxygen exports, import scaffolding, `DESCRIPTION`, or `NAMESPACE` machinery.

## Protected invariants

- Preserve deterministic seeds and common-random-number pairing where the design requires them.
- Preserve atomic checkpoints and validation before accepting completed heavy-run artefacts.
- Preserve the original observation-noise v1 decision and the separately labelled v2 diagnostic;
  never rewrite a failed prespecified gate after unblinding.
- Treat `provenance/production-20260710/` and
  `provenance/observation-noise-20260726/` as immutable snapshots.
- Treat accepted manuscript figures, tabular evidence, source snapshots, and checksum manifests as
  scientific records. Change them only as part of an explicit analysis revision.
- Do not claim data are de-identified or shareable without checking licensing, sensitivity, and
  Indigenous data-governance constraints.

## Verification

- Keep fast tests only where they protect a distinct consequential failure: likelihood maths,
  selection/retention semantics, pairing and seeds, artefact integrity, and manuscript-facing
  transformations.
- For a scientific revision, prespecify the decision gate, run the analysis once, and independently
  verify the emitted evidence. A successful parse, render, or pipeline run is not scientific proof.
- Use one focused self-review and repair pass. Do not add redundant permutations or repeat an
  unchanged full run without a named source of nondeterminism.

## Safety and delivery

- Never bulk-stream large files under `data/` or `data-raw/`; inspect only headers, schemas, samples,
  and counts unless a bounded analysis is required.
- Preserve unrelated user changes. Prefer recoverable and narrowly scoped file operations.
- Local commits and routine Git synchronisation (fetch, pull and push) to Barry's own repository
  are authorised reversible work. Preserve unrelated changes and shared history.
- Barry reviews the final research artefact before release. First public release, submission,
  repository-visibility changes and contact outside the collaboration require his approval.
- At handoff, report completed work, material residual risk, and the next highest-value tranche.
