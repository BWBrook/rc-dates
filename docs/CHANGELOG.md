# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog.

## [Unreleased]
### Changed
- Made the bootstrap dependency set match the current compendium workflow by
  removing stale `qs`, removing unused `duckdb`, making `{magick}` optional,
  and ensuring `{here}` is installed for report and test paths.
- Hardened the non-package test helper so it can find the project root without
  requiring `{here}` to already be installed.
- Expanded the declared dependency manifest to cover the Quarto runtime and the
  retained legacy plotting scripts, so bootstrap and `renv` agree on the
  project's full package surface.
- Refreshed `renv.lock` for R 4.5.3 and the current project library, and
  regenerated `renv/activate.R` from the installed `renv` 1.1.5 template to
  remove mixed-version bootstrap churn.
- Reworked simulations into explicit `demo`, `precomputed`, and `none` modes,
  with `demo` now generating reduced legacy-style summary CSVs under
  `outputs/simulations/demo/` on a fresh clone.
- Updated the report and simulation figure targets so each scenario-size
  combination is shown explicitly and the simulation section is non-empty in
  the default demo workflow.
- Added `docs/PIPELINE.md` and `docs/LEGACY_PARITY.md` to document the current
  target graph and the legacy-to-current provenance crosswalk.
