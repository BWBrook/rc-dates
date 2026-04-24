# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog.

## [Unreleased]
### Added
- Added a root `Makefile` with MacBook-friendly helper targets for the
  manuscript workflow (`manuscript-validate`, `manuscript-check`,
  `manuscript-build`, `manuscript-profile`) and the core R compendium checks.
- Added a `makedoc`-ready manuscript scaffold under `manuscript/`,
  `references/`, `csl/`, and `settings/build.yaml` so the paper can be
  migrated into the WSL document build workflow with valid placeholder inputs.
- Added `docs/READ_THIS_FIRST.md` as a detailed handoff note for resuming the
  compendium and manuscript workflow from a fresh MacBook clone.

### Changed
- Made the intermediate pipeline storage target fall back to CSV automatically
  on macOS, avoiding a local Arrow Parquet writer crash while preserving the
  existing Arrow preference on other platforms.
- Replaced the placeholder `makedoc` manuscript scaffold with the real
  converted manuscript artefacts from `/mnt/c/output`, including the main
  markdown draft, bibliography YAML, JAS CSL file, real figure files, and a
  draft cover letter; the build profile now points at those real inputs.
- Converted the manuscript's hard-coded in-text author-year references in
  `manuscript/text/main.md` to Pandoc/CSL citation tokens matched against
  `references/refs.yaml`, so `makedoc`/Pandoc can generate citations and the
  reference list automatically.
- Restructured `manuscript/text/main.md` into real Markdown section headings,
  subsection headings, end-matter headings, and list syntax so the document is
  usable as authored Markdown rather than raw DOCX-conversion output.
- Split manuscript metadata into a `makedoc`-native scheme by restoring
  `manuscript/authors.yaml`, moving figure captions and links into
  `manuscript/text/figures.md`, and trimming conversion-only front matter and
  embedded base64 figure blocks from `main.md`.
- Cleaned a focused set of conversion artefacts in `main.md`, such as malformed
  spacing before punctuation, escaped inline code underscores, and stray
  soft-hyphen/non-breaking-hyphen characters, without otherwise editing the
  manuscript wording or references.
- Cleaned an additional pass of obvious prose-level conversion artefacts in
  `manuscript/text/main.md`, including malformed hyphenation, citation-adjacent
  punctuation, and a small set of conversion-driven spelling/spacing glitches,
  while leaving equations and other content-bearing unresolved conversions for
  a later pass.
- Repaired the manuscript's broken likelihood/math notation in
  `manuscript/text/main.md` and `manuscript/text/figures.md`, restoring the
  $\ell^1$/$\ell^2$ likelihood definitions, the AIC expression, and related
  inline scientific symbols such as $\chi^2$, $\Delta R$, and $^{14}$C where
  the DOCX conversion had dropped or degraded them.
- Performed a source-aware cleanup pass over the manuscript methods/results
  prose in `manuscript/text/main.md`, tightening the remaining clearly
  conversion-driven wording glitches and citation-adjacent artefacts without
  changing the scientific substance.
- Performed a matching source-aware cleanup pass over the manuscript
  discussion prose in `manuscript/text/main.md`, fixing the remaining obvious
  conversion artefacts and restoring a dropped contrast in the discussion of
  smoother choice versus within-site sampling.
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
- Updated GitHub Actions to activate `renv` explicitly before the test and
  manifest steps, and to use the repo's `tests/run-tests.R` harness so CI
  matches the validated local test path.

### Fixed
- Hardened the GitHub Actions dependency restore path by installing the system
  libraries reported by `renv` and disabling `pak` delegation in CI, avoiding a
  broad `pak` solver failure before tests can run.
