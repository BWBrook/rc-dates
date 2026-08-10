# AGENT_NOTES

## 2026-08-09
- Created a cold external peer-review dress-rehearsal bundle containing the
  anonymous manuscript, captions, Supplementary Information, display items,
  highlights, build/reference inputs, and the expanded validated reviewer
  repository. Identifying cover-letter, title-page, author, and deposit
  materials are isolated in a clearly marked editor-only directory.
- Excluded assembled manuscript and Supplementary Information PDF/DOCX files;
  the only included PDFs are native figure assets. The reviewer-facing
  directories passed an identifying-string scan, and the final 201-file ZIP
  passed archive integrity and internal SHA-256-manifest verification.
- Imported the resulting adversarial external review verbatim at
  `manuscript/reviews/rc-dates_external_review_report_2026-08-09.md` for
  author triage. Its source and repository copy have identical SHA-256
  `fc40f74a7b8b32c44610ae426a60e904917db4cadc4c733e91ceb1958451bb94`;
  no recommended manuscript or analysis changes were applied during intake.

## 2026-07-26
- Initially integrated the empirical Figure 1-2 renderer and paired
  observation-noise
  sensitivity into the root Makefile, README, pipeline summary, and development
  guide without changing manuscript prose or the package builder.
- Recorded the repaired empirical boundary contract: finite raw weighted means
  are filtered inclusively to 651-11,650 cal BP before FD binning and KDE
  construction. The 1,000-realisation primary render and independent-seed/nested
  convergence checks passed.
- Documented the focused paired sensitivity scope (all dates and random-1,
  random-3, and random-5). Oldest, youngest, and bracketed extremes remain
  expectation-only production scenarios.
- Reconciled the manuscript, Supplementary Information, figure captions, cover
  letter, highlights, and checklist with the completed 3-model x 3-intensity x
  1,000-pair matrix. Accuracy and support point shifts were small and the
  substantive ranking, bias, RMSE, mass, strategy-contrast, and likelihood
  gates passed. Three simultaneous gates did not pass, so the formal decision
  remains FAIL (15/18), not an overall robustness pass; no 2,000-pair extension
  was run.
- Independently reviewed the v1 inferential family and retained its 15/18 FAIL.
  Added a separately versioned, explicitly post-unblinding v2 diagnostic over
  the 96 accuracy differences, 96 support differences, and 72 directional
  boundary differences. Under exact R 4.5.3, primary and independent
  50,000-resample bootstraps gave identical critical widths and passed all
  three aligned gates. v2 is reported as qualified supporting evidence, not as
  a replacement for v1.
- Hardened the v2 implementation after independent review: every bootstrap
  cell must now share identical ordered simulation IDs, and the stability test
  constructs genuinely distinct seed-specific metric objects. The refreshed
  exact-R evidence retained the same widths, margins, and gate decisions.
- The complete R suite passed under R 4.5.3 in the validated p2 container.
  `make manuscript-check` also passed lint, citation, author-injection, and
  document-build checks. The 15-page PDF and 20-page LibreOffice rendering of
  the DOCX were inspected without blank or clipped pages.
- Isolated reviewer-package validation exposed and fixed a recursive
  directory-inventory bug in `scripts/build_review_package.R`;
  `include.dirs = TRUE` now enforces the exact frozen-source and summary
  directory boundaries. The builder now also enforces the exact v2
  files/schema/checksums and supplies a non-destructive rebuild target.
- Built and independently validated the final 178-file de-identified review
  package under exact R 4.5.3. Package tests, the 38-target manifest, a clean
  158-target pipeline rerun, checksum verification, anonymity scanning, and
  the packaged v2 rebuild all passed. The supplied archive SHA-256 is
  `ba732e9c326757843112b4ccf49be26ff396982c413de9ff23e8a76ea6b95822`.
- Rebuilt the complete submission packet from that validated archive and
  checked every PDF, DOCX, and ZIP. PDF and LibreOffice renders had no blank or
  clipped pages; the cover letter was tightened so its editable DOCX remains
  one page.
- Narrowed ignore rules so empirical summaries and final observation-noise
  evidence can be versioned while sensitivity run logs and the local validated
  review-package handoff directory remain ignored.

## 2026-07-24
- Performed a final submission-level review using independent scientific,
  editorial, and submission/reproducibility passes, followed by direct checks
  against the manuscript source, production code, archived empirical table,
  locked simulation outputs, and current JAS author guidance.
- Found that `simulate_population_data_set()` groups independent regional age
  draws into arbitrary site bundles: site identity controls date count and
  sub-sampling but not occupation onset, duration, stratigraphy, or temporal
  dependence. The random-3 result therefore does not test an
  oldest + youngest + intermediate field design or establish a universal
  three-date minimum.
- Found that the simulation converts latent calendar ages to the SHCal20
  central conventional age (`ccCRA`), assigns a simulated reported error, and
  recalibrates without drawing a realised noisy conventional age. This
  suppresses between-assay variation and makes the absolute recovery and
  support values conditional on assays at the calibration-curve expectation.
- Verified directly from all nine production RDS files that 100% oldest
  sampling always selects uniform, 100% youngest always selects exponential,
  and 100% bracketed selects exponential for both increasing truths. Corrected
  the false claim that bracketed sampling generally recovers models more
  reliably than random-1 and disclosed the deterministic classification
  collapse hidden by pooled one-third/two-thirds values.
- Verified from `data/austarch_filtered.csv` and the summary functions that the
  empirical KDE uses 87 weighted means outside 651-11,650 cal BP, while the FD
  drops 17 valid means in 651-699 and admits two above 11,650. The submission
  checklist now blocks release until common-window filtering, boundary tests,
  and regeneration of Figures 1-2 are complete.
- Applied a surgical prose revision across the main manuscript, SI, cover
  letter, highlights, and Figure 2 caption. The text now separates visual from
  inferential findings, discloses the conditional simulation design and
  optimiser saturation, and retains the locked figures and numerical outputs
  unchanged pending analysis repair.
- Rechecked the live JAS Guide for Authors: review is double-anonymized, new
  submissions may use one Word or PDF file, highlights require 3-5 bullets of
  at most 85 characters, and manuscripts require line numbering. Removed
  identifying author, funding, and CRediT content from the manuscript build,
  retaining it in the separate title page.
- The revised abstract is 202 words; the source is approximately 3,700 words
  from Abstract through Discussion and 4,868 including all five figure
  legends. All five revised highlight bullets are 77 characters or fewer.
- Shortened the cover letter after LibreOffice showed that the editable DOCX
  spilled only the signature block onto a second page. The rebuilt PDF and
  DOCX render as one page.
- Replaced empty-base inline superscript mathematics in the manuscript, SI,
  and cited reference titles with Unicode superscripts. This removed visible
  hollow-square glyphs before `¹⁴C`, `yr⁻¹`, and `yr⁻²` in the editable DOCX
  while preserving the direct PDF rendering.
- Final verification: `make manuscript-check` passed config validation, lint,
  the citation audit (`Unknown keys: 0`), author-metadata checks, the DOCX
  build, and all 61 tests; `make submission-build` passed. Direct and
  LibreOffice-rendered PDFs passed `qpdf --check`, every DOCX passed
  `unzip -tq`, the editable cover/highlights/title files rendered as one page,
  and visual inspection found no blank pages or clipped display items.
- Rechecked the immutable inputs to the review: every entry in
  `out/production/SHA256SUMS` passed, and both copies of
  `rc_review_package.zip` passed `unzip -tq` with the same SHA-256
  (`88256bf8a93e1b27757c189ae2e959417558ae5e555dafdf5a27c0b76b114d5c`).
- The AI-writing scanner's nominal high risk for the manuscript and SI was
  driven by legitimate Markdown headings and scientific list structure:
  vocabulary hits were 1 in 3,666 main-text words and 0 in 2,087 SI words,
  with no transition-template hits. Manual review found no material
  AI-writing signature requiring further stylistic alteration.

## 2026-07-10
- Repeated the manuscript review in two passes: first with the
  `audit-ai-writing` skill for scientific tone and AI-writing surface cues,
  then as a claim-evidence audit against the data, legacy production scripts,
  rendered figures, and relevant `references/refs.yaml` records.
- The prose scan's nominal high score was driven almost entirely by legitimate
  Markdown section headings. Manual review found very low AI-vocabulary and
  transition-template density; edits concentrated on formulaic framing,
  over-neat conclusion structure, and service-template cover-letter prose.
- Corrected the empirical reference-set description to 976 determinations from
  116 sites, with a median of 7 and range of 5-33 dates per site, and
  distinguished the archived 5,288-row source extract from the published
  AustArch release totals.
- Removed unsupported claims about duplicate-date combination and
  `rcarbon::compare_spds`, and aligned empirical oldest/youngest selection with
  conventional radiocarbon age while documenting the simulation's separate
  median-calibrated-age rule.
- Clarified that each synthetic dataset has 116 sites, true calendar ages are
  uncalibrated and recalibrated, the increasing models rise tenfold towards the
  present, and each accuracy point pools 3,000 replicates equally across the
  three generating families.
- Corrected the Figure 4 legend: its bars are the 2.5th and 97.5th percentiles
  of replicate-level bias, not bootstrap intervals. Also clarified the
  deterministic full-site panels in Figure 2 and the two-bin smoothing used to
  display Figure 1's FD.
- Found that the legacy Figure 5 summary weighted ambiguous simulations once
  per retained OSE model. Updated `scripts/legacy/simulation_results.R` to
  collapse to one Boolean value per simulation before aggregation and added a
  fixed bootstrap seed. Because the nine production RDS artefacts are absent,
  the corrected display cannot be regenerated locally; Figure 5 and all claims
  that depend on it are therefore excluded from the current manuscript.
- Corrected the embedded Figure 3 title typo without rasterising the vector
  plot. Replaced bibliography `¹⁴C` glyphs with Pandoc math notation so the
  superscript survives XeLaTeX conversion.
- Added a project-specific `makedoc` LaTeX scratch directory after diagnosing a
  concurrent-build collision that produced a 4 KiB truncated PDF despite a
  zero exit status. Final PDF integrity is now checked with `qpdf`.
- Added `scripts/normalize_docx_page_breaks.py` to replace standalone Word page
  break paragraphs with `pageBreakBefore` formatting on the following
  paragraph. This removes the blank line-numbered page that appeared between
  Figures 2 and 3 in an independent LibreOffice render of the required DOCX.
- Final source count after restoring Figure 5 is about 3,600 words from
  Abstract through Discussion and about 4,200 including all five display
  legends, below the 5,000-word limit. The JAS highlights remain at or below
  85 characters, and the cover letter now renders on one page.
- Verification: `make submission-build` succeeded; `make manuscript-check`
  passed manuscript lint, author injection, `Unknown keys: 0`, and all 61
  makedoc tests; all four PDFs pass `qpdf --check`; all five DOCX files pass
  `unzip -tq`; the normalized manuscript DOCX renders to 19 complete pages in
  LibreOffice; and the manuscript/SI/cover PDFs were visually inspected.
- `scripts/legacy/simulation_results.R` passes base-R parsing. The R compendium
  and production simulation rerun were not run because this WSL host currently
  has R 4.6.1 while the project is pinned to R 4.5.3, and the production RDS
  inputs remain unavailable.
- Superseding that provisional state, the production simulation matrix was run
  on the 64-core `deep-server` after the user requested that Figure 5 be
  restored. All nine model-by-intensity scenarios completed with 1,000
  replicates each, producing 378,000 result rows; the slowest scenario took
  about 104 minutes.
- The run used an exact R 4.5.3 Docker image, deterministic common-random-number
  replicate seeds, atomic checkpoints, and nine concurrent seven-worker jobs.
  Unstamped completed artefacts and logs were retained before provenance was
  added, and the exact generation source is locked under
  `provenance/production-20260710/`.
- Validated all nine RDS files and metadata sidecars against embedded source,
  input, lockfile, container-recipe, image-ID, and SHA-256 evidence. Figure 3
  model recovery, Figure 4 parameter bias, and corrected Figure 5 unambiguous
  support were regenerated from the 378,000-row matrix and visually checked.
- Restored Figure 5 and its exact results to the main text, legend,
  Supplementary Information, highlights, cover letter, and submission
  checklist. The all-dates recovery estimate is 0.965; random-3 remains 0.917
  at full application, while oldest and youngest sampling fall to chance-level
  recovery at high intensity.
- Added production parity, provenance, checkpoint, cluster-bootstrap, archive,
  and empty-site-posterior tests. The empty-site case fixes the Abbot Bay branch
  that previously had no calibrated support inside the analysis window.
- Rebuilt the anonymous code-review package with 91 files, including all nine
  production RDS files and exact source provenance. In a fresh exact-R
  container, `make check` restored dependencies, passed the packaged tests,
  rebuilt Figures 3-5, and completed 158 targets with zero failures; total
  elapsed time was 17 minutes and the pipeline itself took 12m58s.
- Confirmed the review package contains no manuscript, reference, report, docs,
  Git metadata, or symlinks. Text and deserialised-RDS scans found no author,
  affiliation, email, ORCID, or local-path identifiers. The final local ZIP is
  `/home/bwbrook/papers/de_identified_repos/rc_review_package.zip`, 1,046,659
  bytes, SHA-256 `88256bf8a93e1b27757c189ae2e959417558ae5e555dafdf5a27c0b76b114d5c`.
- Left the source workspace, exact generation and maintained images, review
  validation image, logs, source snapshots, and complete R 4.5.3 `renv` cache
  in place on `deep-server` for post-review revisions.
- Final repository gate: the complete root test suite passed under exact R
  4.5.3, including the production, archive-replacement, and empty-site tests.
  `make submission-build` succeeded and `make manuscript-check` passed lint,
  author injection, 54 cited keys with `Unknown keys: 0`, and all 61 makedoc
  tests. All submission PDFs and Figures 3-5 pass `qpdf --check`; all five DOCX
  containers pass `unzip -tq`. Visual checks covered every PDF page and
  LibreOffice renders of the 20-page manuscript DOCX and seven-page SI DOCX,
  with Figure 5 complete on the final manuscript page.

## 2026-06-29
- Applied the `audit-ai-writing` skill to the manuscript-facing sources:
  `manuscript/text/main.md`, `manuscript/text/figures.md`,
  `manuscript/text/supplementary.md`, `manuscript/submission/draft_cover_letter.md`,
  and `manuscript/submission/submission_checklist.md`.
- Treated Markdown headings and required scholarly contrasts as scanner false
  positives, then made conservative line edits to reduce generic
  `framework`/`robust`/`valuable` phrasing, service-template cover-letter
  tone, and over-neat concluding language while preserving claims and
  citations.
- Verification after the line edit: `make submission-build` completed, and
  `make manuscript-check` passed with manuscript lint clean, `Unknown keys: 0`,
  and 61 makedoc tests passing.

## 2026-06-06
- WSL crash recovery and rsync sanity check: verified the checkout is still a
  normal `main` worktree tracking `origin/main`; `git diff --check` is clean,
  no macOS sidecar files remain at shallow project depth, and no stale R
  `00LOCK*` install locks remain under the user or project R libraries.
- The dirty worktree appears to be real Mac-side portability/reproducibility
  content rather than Git metadata oddness; `.envrc` is currently untracked but
  matches the documented Mac hardening changes.
- Hardened `.Rprofile` so it only activates `renv` automatically under the
  lockfile-compatible R 4.5 series, or when
  `RC_DATES_ALLOW_NON45_RENV=true` is set. This prevents WSL's R 4.6.0 from
  re-entering recursive `renv` bootstrap attempts during simple probes.

## 2026-05-28
- Mac migration hardening: made the root `Makefile` prefer `/usr/local/bin/Rscript`
  and reject non-R-4.5.x compendium runs, added `.envrc` so `direnv` shells put
  `/usr/local/bin` first, and changed `.Rprofile` to disable `renv` pak
  delegation by default unless the caller overrides it.
- Added `make review-package`, switched the review-package builder's default
  parent to `/Users/bwbrook/papers/de_identified_repos` on macOS, and updated
  the anonymous repository workflow notes away from WSL-only `/home/...`
  commands.
- Fixed a stale `_targets` migration failure by keeping config and manifest
  paths relative inside cached targets instead of storing WSL absolute paths.
- Updated the development/handoff docs to use Makefile wrappers for local
  reproducibility and renamed the Quarto project title from the scaffold
  placeholder to `rc-dates`.
- Verification after the Mac hardening: `make compendium-bootstrap` restored
  the lockfile-clean R 4.5.3 library, `renv::status()` reported no issues,
  `make compendium-test` passed, `make compendium-pipeline` completed 75
  targets with 6 skipped, and `make review-package` rebuilt
  `/Users/bwbrook/papers/de_identified_repos/rc_review_package.zip` with SHA256
  `c3e27f10af685c0f0ee22172ab6b28b7d00a0741e779077cd1a444f9a89246f5`.

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
