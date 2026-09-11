# Minimal scientific release: acceptance boundary

Approved by Barry Brook on 11 September 2026. The release is named, suitable for
a public preprint and Journal of Archaeological Science submission. Assembly is
authorised; public repository creation, DOI publication and journal submission
remain separate actions. The development repository's history and accepted scientific records
are preserved.

## Required outcome

One small, explicitly selected repository and a matching ZIP, with a root
Makefile and a documented R 4.5.3 runtime. Exclude working notes, manuscript
build machinery, obsolete production results, caches, Git history, credentials
and record-level archaeological inputs lacking a release decision. Include
only source, inputs, evidence and provenance needed for the current paper.

The release must distinguish:

1. Reproduction from accepted evidence: regenerate all seven figures, derive
   signed-model and observation-noise summaries from replicate-level synthetic
   outputs, and audit the numerical claims in the manuscript and supplement.
2. Simulation regeneration: use original seeds, source algorithms and a frozen
   scalar fitted specification; preserve common random numbers, selection
   semantics, and the original failed v1 and subsequent diagnostic v2 decisions.
3. Empirical reconstruction from source: provide an executable, hash-verified
   route for separately acquired governed input; document any unresolved source
   transformation rather than treating cached curves as a raw-data rerun.

## Checks set before running the release

- The original evidence and source manifests must pass without alteration.
- Re-derived tables must agree by keys, columns and scientific values with
  accepted tables; integers and classifications must match exactly. Compare
  numeric values exactly after parsing the same accepted CSV serialization.
- The scalar simulation specification must reproduce the original fitted
  model's predictions, simulated errors and final RNG state exactly under the
  original R 4.5.3 production image.
- Regenerated simulation rows must match accepted replicate rows by scenario,
  replicate, retention, criterion and model, excluding only run metadata.
- Figure checks must distinguish plot-data equality from rendering differences.
  PDF creation dates and compression are not scientific quantities. Compare
  rasterised content in the verified runtime and record any presentation-only
  difference; do not silently replace accepted figures.
- v1 remains FAIL with 15/18 criteria met. v2 remains explicitly post-unblinding,
  with its original 50,000-resample seeds and stability comparison.
- Test a fresh extraction, with no access to the workbook or its raw data, and
  perform an independent final audit. Report full versus sampled regeneration
  explicitly; do not label an unrun calculation as verified.

The source-input and runtime provenance are part of the scientific contract.
No new effect-size, retention, or observation-noise experiment is commissioned
by this packaging work.

## Completed verification

The named release was assembled and independently audited on 11 September 2026.
All 15 empirical CSVs, five signed summary CSVs, 16 original observation-noise
CSVs and three v2 CSVs were reproduced exactly. The 24-scenario, two-replicate
simulation check, 35 scientific tests and 80-value registry passed. A fresh
ZIP extraction, complete inventories and clean Docker build were verified.
Six figures reproduce pixel for pixel after preserving the production font
mapping. S2 reproduces the aggregate observations and fit with an explicitly
recorded presentation difference; its accepted original remains included.

The full 1,000-replicate experiments were not repeated. The historical raw
source route was verified byte for byte; fresh replay of the separately hashed
2026 ADS download remains conditional on acquiring that snapshot. Licensing,
public repository creation, archival DOI and submission remain author decisions.
See release/templates/VALIDATION.md and CLAIM_AUDIT.md for the checked scope.
