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
- Replaced the placeholder manuscript scaffold with the real manuscript assets
  staged in `/mnt/c/output`, moving the converted markdown, bibliography YAML,
  JAS CSL, real figures, and draft cover letter into repo locations suitable
  for the next `makedoc` cleanup/integration pass.
- Updated `.gitignore` so real manuscript figure PDFs under `manuscript/figures`
  can be tracked even though generated build PDFs remain ignored elsewhere.
- Converted `manuscript/text/main.md` from pseudo-Markdown DOCX output into a
  proper Markdown document structure, promoting headings, subsection levels,
  end-matter labels, list syntax, and figure-block labels without yet cleaning
  the prose or conversion cruft.
- Cleaned a targeted set of conversion artefacts in `manuscript/text/main.md`,
  then split author metadata and figure content back out into `makedoc`-native
  files: `manuscript/authors.yaml` and `manuscript/text/figures.md`.
- Rewired `settings/build.yaml` so the manuscript profile again uses a main text
  file plus a separate figure file and structured author metadata, matching the
  intended external-manuscript contract for `makedoc`.
- Replaced the manuscript's hard-coded in-text citations with Pandoc/CSL
  citation tokens matched to `references/refs.yaml`, and confirmed a
  `pandoc --citeproc` dry run resolves them without unresolved citation output.
- Performed a conservative follow-up cleanup of prose-level conversion cruft in
  `manuscript/text/main.md` (hyphenation, punctuation, and a few clear
  conversion typos), while leaving unresolved equations and other content-heavy
  conversion gaps for a later, source-aware pass.
- Restored the broken mathematical notation in the manuscript methods/results
  text and figure captions, including the two likelihood definitions, AIC/OSE
  notation, and nearby scientific symbols (`$\chi^2$`, `$\Delta R$`,
  `$^{14}$C`), then verified the combined manuscript sources convert cleanly
  through Pandoc when given the correct manuscript resource path.
- Did a follow-up source-aware cleanup pass on the remaining non-math
  conversion artefacts in the methods/results prose, focusing on clearly
  mechanical wording and citation-placement glitches rather than substantive
  rewriting, and revalidated the manuscript sources with Pandoc.
- Did the corresponding source-aware cleanup pass on the discussion section,
  fixing the remaining obvious DOCX-conversion artefacts and validating the
  updated manuscript sources again through Pandoc before packaging the
  manuscript-import cleanup work for commit.

## 2026-04-24
- Added `docs/READ_THIS_FIRST.md` as a MacBook handoff guide, summarising the
  current project goals, recent stabilisation/manuscript work, resolved review
  findings, important paths, validation commands, and recommended next steps for
  continuing from a fresh clone.
- Investigated the failing `compendium-ci` GitHub Actions run on `main`, traced
  it to a `pak` dependency-solver failure during `renv::restore()`, and updated
  the workflow to install the required Ubuntu system libraries and force CI
  restores through `renv` without `pak` delegation.
