# Pre-submission Module 3: Text-code-caption alignment

Purpose: close the independent-review items where manuscript wording, figure
captions, metadata, or figure labels were not aligned with the active analysis
code and supplied artefacts.

Status: complete on 2026-05-25.

## Scope Addressed

- Recast the abstract and cover-letter sampling-rule wording so empirical
  experiments use random-1/random-5, while simulations add random-3.
- Softened the practical three-date recommendation from a direct
  "well-spaced" simulation claim to a field translation of the random-3 result.
- Framed the >=5 dates-per-site reference set as a benchmarking substrate rather
  than an unbiased demographic sample of Sahul.
- Added main-text and limitations wording for Marine20 calibration without
  site-specific Delta R corrections.
- Clarified Holocene-window handling as posterior-grid overlap and analysis
  evaluation within 11,650-651 cal BP, with figures using a padded display range.
- Reconciled FD/KDE language to weighted-mean calibrated ages rather than
  median calibrated ages.
- Reconciled the initial radiocarbon-age screen to 500-20,000 14C yr BP.
- Explained repeated all-dates references in Figs 3 and 5, and chance accuracy
  in Fig. 3.
- Added Fig. 4 caption guidance on scientific-notation scale and youngest-rule
  bias direction.
- Changed Fig. 2 panel labels and legacy provenance-script labels from
  Singleton/Multiton to random-1/random-5.
- Reduced the keyword list to seven entries.
- Corrected the affiliation typo, funding full stop, and CRediT dash/taxonomy
  wording.

## Validation

- `git diff --check`
- Targeted stale-phrase scan for old age-screen, median-age, 12 ka, affiliation,
  and Singleton/Multiton wording.
- `make submission-build`
- `make manuscript-check`
- Generated-PDF spot checks with `pdftotext` for the corrected methods,
  captions, title-page, and funding wording.

## Residual Human-eye Items

- Fig. 2 now has corrected embedded labels in the tracked PNG; a future
  vector-quality re-export from original full intermediate data would be cleaner
  for final production, if those full inputs are available.
- Supplementary Fig. S2 is displayed smaller with a caption explaining the long
  right tail; a future re-export can further improve the aspect ratio.
- No new stratified-3 simulation strategy was added in this module. The
  manuscript instead states the defensible prose bridge between random-3
  simulation performance and deliberate field spacing.
