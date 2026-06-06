# Pre-submission Module 4: Review-package lock

Purpose: make the de-identified code/data review package repeatable,
minimal, and honest about what a reviewer can rerun outside GitHub.

Status: complete on 2026-05-25, pending Barry's manual private-repository
upload and final private-link/DOI replacement.

## Scope Addressed

- Added `scripts/build_review_package.R` as the canonical package builder.
- Rebuilt `/home/bwbrook/papers/de_identified_repos/rc_review_package/` from
  the source checkout instead of maintaining a hand-edited package tree.
- Replaced the original full raw AustArch CSV in the review package with
  `data/austarch_input_deidentified.csv`, containing only columns read by the
  analysis pipeline and a neutral `RECORD_SOURCE` marker.
- Kept `data/austarch_filtered.csv` as a locked 976-row reference table for
  reviewer inspection of the manuscript-scale Holocene set.
- Added package-side `SIMULATION_PROVENANCE.md` so the fast demo path is not
  confused with the unavailable high-volume production simulation outputs.
- Updated root README and submission workflow notes so the review package is
  built through the scripted de-identification path.

## Validation

- Package directory rebuilt from `scripts/build_review_package.R`.
- Package source parsed with base R structural checks.
- Package contents scanned for forbidden manuscript/docs/reference/report and
  source-control folders.
- Package scanned for common author, institution, ORCID, email, and local-path
  markers after removing the original free-text source/notes fields.
- Review zip rebuilt and copied to `manuscript/submission/dist/`.
- Final Module 4 zip SHA256:
  `bc86c21c7add239370e126fb516b8a7c5a68851a3871ecd360f061b24bd42a42`.
- Final Module 4 zip size: 280 KB, 64 entries.
- `make submission-build` and `make manuscript-check` rerun after manuscript
  data-accessibility wording changed.

## Residual Human-eye Items

- Full reviewer `renv::restore()` and package tests still need to be rerun
  after final editorial lock if the archive contents change. The macOS checkout
  now has Makefile wrappers that select `/usr/local/bin/Rscript` for the
  lockfile-matching R 4.5.x path.
- The high-volume production simulation RDS files were not found locally in the
  repository or broader `/home/bwbrook` search. The package therefore documents
  them as external production artefacts rather than claiming exact numerical
  rerun support.
- Barry still needs to inspect the final zip, upload it manually to the private
  review repository, reserve the DOI, create/check the private link, and replace
  the manuscript placeholders.
