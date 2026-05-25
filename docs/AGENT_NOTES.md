# AGENT_NOTES

## 2026-05-25
- Module 4 review-package lock: added `scripts/build_review_package.R` as the
  repeatable de-identification builder, rebuilt the review package around a
  trimmed `austarch_input_deidentified.csv` input table, retained the filtered
  976-row reference set for audit, and added package-side
  `SIMULATION_PROVENANCE.md` to separate the fast verification path from the
  unavailable high-volume production simulation outputs.
- Local package restore/tests were not run under the intended reviewer runtime
  because this shell uses R 4.6.0 and no R 4.5.x binary is installed; validation
  therefore used structural parsing, content/de-identification scans, zip
  inspection, and the manuscript `submission-build` / `manuscript-check` gates.

## 2026-05-23
- Module 2 reproducibility/de-identification pass: replaced promissory
  GitHub/Zenodo-on-acceptance language with a private-for-review link plus
  reserved-DOI workflow, retaining the user's manual upload gate before final
  repository deposition.
- Added submission-side upload scaffolding under `manuscript/submission/` and
  reviewer-facing reproduction notes inside the de-identified package, including
  an explicit distinction between fast code verification and locked production
  simulation artefacts.
- Fresh-restore smoke testing confirmed that the de-identified archive needs the
  documented R 4.5.x runtime; the local default R 4.6.0 path hits the known
  pinned-source `S7` compile failure before tests can run.
- Module 3 text-code-caption alignment pass: reconciled weighted means versus
  medians, the 500-20,000 radiocarbon-year initial screen, posterior-overlap
  Holocene retention, Marine20/no-Delta R wording, all-dates simulation
  references, Figure 2 labels and legacy provenance labels, CRediT dashes, and
  the title-page affiliation typo identified in the independent pre-submission
  review.

## 2026-05-18
- Investigated the failing GitHub Actions `compendium-ci / tests` run on
  `main` with the GitHub plugin and `gh`, tracing the failure to
  `r-lib/actions/setup-r@v2` floating from R 4.5.3 in the last green run to
  R 4.6.0 in the failing run.
- Pinned both GitHub Actions workflows that restore `renv` dependencies to
  R 4.5.3, matching the documented lockfile series and avoiding the observed
  `S7` source compile failure under R 4.6.0.

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
- Confirmed the MacBook checkout is ahead of the written handoff baseline at
  `1eb054d agent: fix(ci): stabilise renv restore`, with clean local state
  before manuscript setup.
- Added a root `Makefile` so common manuscript commands can run directly from
  this repository while using `/Users/bwbrook/work/makedoc` and its repo-local
  virtualenv automatically.
- Verified `make manuscript-validate` and `make manuscript-check` from the
  `rc-dates` root after hardening `makedoc`'s manual-citation lint against
  parenthesized acronym-plus-Pandoc-citation false positives.
- Produced fresh manuscript outputs under
  `/Users/bwbrook/work/makedoc/dist/rc-dates/`: `manuscript.pdf`,
  `manuscript.docx`, and `manuscript_build_manifest.json`.
- Installed local MacBook build prerequisites `cmake` and `imagemagick@6` with
  Homebrew, then restored the `renv` library to the checked-in lockfile
  versions; `renv::status()` reports a consistent project library.
- Ran `make compendium-test` successfully after the MacBook `renv` restore.
- Attempted `make compendium-pipeline`; the run exposed a macOS Arrow Parquet
  writer segfault at the `interim_parquet` target, so the pipeline now routes
  intermediate storage to CSV on Darwin while retaining Arrow use elsewhere.
- Re-ran `make compendium-test`, `make compendium-pipeline`, and
  `make compendium-report` successfully after the macOS intermediate-storage
  fallback; the pipeline completed 67 targets with 14 skipped.

## 2026-05-18
- Began the interactive co-author/comment pass by incorporating Sean's
  recommended Park et al. (2026) citation into the manuscript where it
  complements, but does not replace, the paper's within-site sampling focus:
  inter-settlement sampling heterogeneity in the Introduction and rescaling as
  a complementary database-level response in the Discussion.
- Made the root `Makefile` manuscript helpers portable between the MacBook
  `makedoc` checkout, which uses `.venv`, and the WSL checkout, which currently
  runs the `makedoc` checks successfully with host `python3`.
- Addressed a co-author comment on the abstract phrase "extreme-focused and
  singleton rules" by standardising the manuscript's sampling-rule terminology
  around the declared labels (`all dates`, `random-*n*`, `oldest`, `youngest`,
  and `bracketed`) across the abstract, results, discussion, and Figure 2
  caption.
- Addressed a co-author comment on cultural resource management by adding a
  concise sentence to the sampling-practice paragraph about development-led
  contract work and price/timeline constraints, using an existing Codding et al.
  (2024) citation already present in the bibliography.
- Addressed a co-author comment that the Introduction's methodological pivot
  paragraph was too technical by rewriting it in plainer language: smoothed
  curves are descriptive, each calibrated date retains its uncertainty, and the
  likelihood/AIC workflow asks which simple growth model best explains those
  uncertain dates.
- Addressed a co-author comment that the "Aims and approach" subsection was
  redundant by deleting the aims list and leaving the methodological-scope
  paragraph as the closing paragraph of section 1.2.
- Addressed a co-author comment asking why the analysis used a Holocene-only
  subset by adding a Methods sentence that this reduces long-term taphonomic
  contrast while retaining a large regional dataset.
- Addressed a co-author comment that the AustArch "radiocarbon" tag
  explanation was redundant by deleting that sentence from the initial
  screening pass.
- Addressed a co-author comment about sites with fewer than three
  determinations by clarifying that the >=5-date eligibility threshold creates a
  well-dated empirical reference set and that sparse-site consequences are
  assessed by down-sampling those better-dated sites into sparse analogues.
- Addressed a co-author comment about repeated simulation-metric definitions by
  leaving formal definitions in Methods section 2.2.4 and trimming Results
  section 3.2/3.2.3 to concise interpretive signposting.
- Addressed the remaining Discussion/Conclusion comments in one pass: explained
  `random-*n*` as an unbiased simulation benchmark rather than a literal field
  instruction, translated the practical guidance to oldest/youngest plus
  intermediate contexts, added regional-synthesis sensitivity guidance for
  sparse legacy sites, replaced confusing phrases such as "systematic
  aggregation pipelines" and "pathological cases", clarified date-count
  metadata, added a Pleistocene limitation note, and expanded the Conclusions to
  include sparse-site auditing as a third key finding.
- Ran the batched manuscript check after the comment pass with
  `MAKEDOC_DIR=/home/bwbrook/work/makedoc make manuscript-check`; makedoc
  validation, lint, reference audit, author metadata checks, and DOCX build all
  passed with zero unknown citation keys.
- Completed a light editorial pass over `manuscript/text/main.md` and
  `manuscript/text/figures.md`, tightening wording for clarity, replacing
  remaining rhetorical flourishes and contrastive phrasing, and confirming that
  the manuscript text/figure sources contain no em dashes. The user-edited
  `manuscript/submission/draft_cover_letter.md` was intentionally left alone.
- Re-ran `MAKEDOC_DIR=/home/bwbrook/work/makedoc make manuscript-check` after
  the editorial pass; makedoc validation, lint, reference audit, author metadata
  checks, and DOCX build all passed with zero unknown citation keys.
- Reworked `manuscript/submission/draft_cover_letter.md` to align with the
  current manuscript: replaced older labels such as "singleton",
  "extreme-focused", and "moderate multitons" with the current sampling-rule
  terminology, removed the "method wars" framing, added sparse-site audit
  guidance, and tightened the pitch for JAS.
- Re-ran `MAKEDOC_DIR=/home/bwbrook/work/makedoc make manuscript-check` before
  committing the revision bundle; makedoc validation, lint, reference audit,
  author metadata checks, and the build target all passed with zero unknown
  citation keys.

## 2026-05-19
- Prepared the manuscript for a JAS submission-readiness pass: dated the cover
  letter as 20 May 2026, changed public GitHub/Zenodo placeholder wording to
  match the de-identified `rc_review_package.zip` review package, and added a
  generative-AI declaration before the references.
- Added submission-facing support files under `manuscript/submission/`: a
  separate highlights file with five bullets under the 85-character JAS limit,
  a title-page draft, and a JAS submission checklist noting current Guide for
  Authors requirements and remaining human checks.
- Added `manuscript/text/supplementary.md` with draft SI captions for
  `SI_data_generating_distributions.png` and
  `SI_dates_per_site_in_austarch_holocene.png`, plus a short likelihood-
  sensitivity note to support the main-text references to Supplementary
  Information.
- Added `make submission-build`, which builds/copies local submission outputs
  into ignored `manuscript/submission/dist/`: manuscript PDF/DOCX, cover letter
  PDF/DOCX, title page PDF/DOCX, highlights DOCX, Supplementary Information
  PDF/DOCX, and the de-identified review package.
- Cross-checked against the live JAS Guide for Authors. Important findings:
  current JAS peer review is single-anonymized and editable source files are
  required for submission (PDF alone is not an acceptable source file). At this
  point in the workflow, before the later Methods/Discussion tightening, the
  manuscript remained above the journal's usual 5,000-word article guidance.
- Ran `make submission-build` successfully and visually inspected rendered cover
  letter and Supplementary Information PDF pages via `pdftoppm`; also ran
  `make manuscript-check`, which passed with `Unknown keys: 0` and 13 unused
  bibliography keys reported as non-fatal.
- First-pass word-count reduction moved the full reproducibility-level Methods
  text into `manuscript/text/supplementary.md` as Supplementary Methods and
  replaced the main Methods with a condensed design summary. This reduced the
  manuscript from 5,937 to approximately 4,900 words from Abstract through
  Discussion while preserving the details in the SI.
- Updated `make submission-build` so the Supplementary Information render uses
  citeproc with `references/refs.yaml` and the JAS CSL; `make submission-build`
  and `make manuscript-check` both passed after the Methods move.
- Tightened the Discussion and then sanity-checked the Introduction against the
  leaner Methods and conclusions. The Discussion was consolidated from six
  subsections to five, with repeated method-debate and implications material
  compressed into a sharper JAS-style argument. The manuscript is now roughly
  3,500 words from Abstract through Discussion.
- Ran a final co-author-comment regression sanity pass after the manuscript
  tightening. Confirmed that the earlier concerns remained addressed: sampling
  descriptors stay aligned, the CRM/budget point remains, the technical
  likelihood framing is still in plain language, sparse-site guidance remains
  nuanced, and confusing phrases such as "pathological" or "best performing"
  have not returned. Added a small parenthetical defining site-level date counts
  for non-technical readers.
- Reviewed the large diff from the fuller submission packet (`d04546d`) to the
  tightened JAS version to check whether explanatory context had been cut too
  aggressively. Most removed material was either moved into the Supplementary
  Information or was safely redundant. Restored only small clarity points: made
  `random-*n*` notation consistent, clarified that simulation intensities apply
  to sub-sampling strategies, translated "precision around a biased estimator"
  into plainer language, and reintroduced the compact point that smaller,
  well-spaced site sequences can outperform larger edge-only/one-date datasets.
