# JAS Submission Checklist

Checked against the Journal of Archaeological Science Guide for Authors and
reproducibility guidance on 26 July 2026.

## Ready for submission packet

- Initial manuscript: JAS permits a single Word or PDF file for a new
  submission; editable source files are required at revision or acceptance.
- Anonymous manuscript: the manuscript build omits authors, affiliations,
  funding, and CRediT details; continuous line numbering and page numbering are
  enabled.
- Title page: separate title-page file contains author names, affiliations,
  corresponding-author contact, declaration of competing interest, funding
  statement, and CRediT-style author contributions.
- Cover letter: dated 26 July 2026 and matched to the current manuscript and review-package data plan.
- Highlights: separate editable highlights file created, with five bullets under the 85-character limit.
- Supplementary Information: separate SI source includes two SI figures and the paired realised-observation-noise design, outcome, and gate-table reference.
- Data/code package: submit `rc_review_package.zip` as the de-identified code/data package for review after the private-for-review repository record is locked.

## Scientific status after the final hard review

- The paired realised-observation-noise sensitivity is complete at 1,000 pairs
  per model-intensity cell. Its original v1 full-family screen remains FAIL
  (15/18). A separately labelled, explicitly post-unblinding v2 diagnostic
  aligned to the three failed difference estimands passed with stable
  50,000-resample results; it is not described as retroactively passing v1.
  No 2,000-pair precision extension was run.
- Site-specific occupation histories and a genuine stratified strategy remain
  outside scope. The manuscript states that independent regional ages are
  grouped into exchangeable sites, does not claim a universal three-date
  minimum, and does not equate random-3 with field-stratified sampling.
- Empirical FD/KDE boundary handling was repaired and Figures 1-2 regenerated
  under the common 651-11,650 cal BP contract; primary and convergence checks
  passed.
- Main text, SI, captions, cover letter, and highlights have been reconciled
  with the curve-expectation production results and both versioned sensitivity
  assessments. Oldest, youngest, and bracketed remain expectation-only
  scenarios.

## Items to double-check in the submission portal

- JAS currently uses double-anonymized review. Upload the anonymous manuscript
  and the identified title page as separate files, and inspect the portal-built
  review PDF for author-identifying metadata.
- Enter the corresponding author's phone number in Editorial Manager if requested; the local title-page draft includes email and postal address but not a phone number.
- The guide says article submissions should not normally exceed 5,000 words
  excluding tables and references. The current source contains 3,804 words
  from Abstract through Discussion and 4,960 under the conservative source
  count including all five figure legends.
- The five-figure manuscript uses the regenerated production RDS set and
  corrected one-row-per-replicate Figure 5 summary. The final de-identified
  archive was rebuilt and inspected after prose lock: package tests, manifest,
  clean pipeline, checksum, anonymity, and packaged-v2 rebuild checks passed.
- JAS research-data guidance asks for repository deposition and article citation/linking. The current manuscript has placeholders for a private-for-review link and reserved DOI; replace `[PRIVATE_REVIEW_LINK]` and `[RESERVED_DOI]` after the final package lock and before submission.
- Final repository upload remains a manual human-eye gate: inspect the de-identified zip, upload it to the selected private-for-review repository, reserve the DOI, create the anonymous review link, and verify the link from a fresh browser session before submission.
- The journal requires a declaration if generative AI tools were used in manuscript preparation. A draft statement has been added before the references.
- Ensure all five main figures are included with the initial manuscript or uploaded
  separately as the portal requests; verify that figure citations and captions
  remain paired in the generated review PDF.
- Confirm whether to opt in to a graphical abstract or Research Elements/Data in Brief co-submission; neither is required for the current packet.
