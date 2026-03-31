# AGENT_NOTES

## 2026-03-30
- Cloned `BWBrook/rc-dates` into `/home/bwbrook/papers/rc-dates` and completed
  a high-level orientation of the targets pipeline, tests, and report flow.
- Began repo bring-up. Bootstrap exposed two dependency issues: stale `qs`
  could not be resolved from current CRAN metadata, and optional `{magick}`
  failed without system ImageMagick development headers.
- Updated the dependency manifest and bootstrap script to reflect the code's
  real requirements, and hardened the non-package test helper to locate the
  project root without depending on `{here}`.
- Removed unused `duckdb` from the required dependency set after verifying it
  is not referenced by the current pipeline or tests.
- Regenerated `renv/activate.R` from the installed `renv` 1.1.5 template,
  refreshed `renv.lock` for R 4.5.3, and verified `renv::status()` is clean.
- Added the remaining Quarto-runtime and legacy plotting packages to
  `dependencies.R` so bootstrap and lockfile state stay aligned on fresh
  restores.
- Implemented a mode-based simulation workflow with generated demo outputs as
  the default fresh-clone path, while retaining precomputed and disabled modes.
- Ported the reduced legacy sampling workflow into modular demo helpers under
  `R/` and wired it into `_targets.R`, the report, and the test suite.
- Added pipeline/provenance docs to clarify the current DAG and how legacy
  scripts map onto the reproducible compendium.

## 2026-03-31
- Added a `makedoc`-ready external manuscript scaffold to this repository:
  placeholder markdown sources, tracked placeholder figure assets, author
  metadata, bibliography YAML, a placeholder CSL file, and `settings/build.yaml`
  with config-relative paths suitable for `makedoc` external-path mode.
- Updated `.gitignore` so future `makedoc` build outputs under `dist/` stay out
  of version control while the scaffold's tracked placeholder figure PNGs
  remain addable.
- Investigated the failing post-push GitHub Actions run on `main`, traced the
  CI failure to the workflow's test/manifest steps not explicitly activating
  the project `renv`, and updated `.github/workflows/compendium-ci.yml` to
  source `renv/activate.R` and reuse `tests/run-tests.R`.
