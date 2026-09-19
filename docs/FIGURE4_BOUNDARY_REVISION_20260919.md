# Figure 4 boundary correction — 19 September 2026

## Approved scope and acceptance criteria

The author approved implementation of the fresh Astra review on 19 September
2026. This is a post-review presentation and interpretation correction, not a
new simulation experiment. In the development repository, the review and its original evidence remain in
`manuscript/reviews/astra_fresh_adversarial_review_2026-09-18.md`.

Before deriving the replacement summary, the correction is specified as follows:

- Use the bounded endpoint contrast
  `c = (f_recent - f_old) / (f_recent + f_old) = tanh(theta / 2)`.
  For the linear family this equals `slope * L^2 / 2`; for exponential fits it
  equals `tanh(rate * L / 2)`, where `L = 10999` years. Ten-fold truths have
  contrast `+9/11` or `-9/11`. Zero means equal endpoint density; +/-1 means
  zero density at one endpoint. The transformation compresses large density
  ratios and must not be described as preserving log-ratio magnitudes.
- Transform each stored primary-score, generating-family fit before taking
  its mean and central 95% (R type-7) replicate quantiles. Use the four
  non-uniform truths, full treatment, eight rules and 1,000 replicates per
  cell: 32,000 stored fits, yielding 32 summary rows. Never transform a mean
  log ratio as a substitute for a mean contrast.
- Retain every original near-boundary flag and display its frequency for
  every group, including zero. Do not infer an exact endpoint optimum from a
  near-boundary flag or move estimates to an endpoint.
- Explain the natural zero-density linear boundary separately from the
  imposed finite exponential rate cap. State scaled optimiser tolerance and
  the flag definition. Keep original likelihood, model-selection, seeds,
  simulation results, archived summaries and source manifests unchanged.
- Write new derived evidence under
  `out/revision/endpoint-contrast-20260919/`; revise the figure, captions,
  manuscript interpretation and executable release together. Retain the
  11 September release intact and assemble a newly dated release.

Acceptance requires an independent calculation from the stored fit parameters
agreeing with all 32 means, ranges, truths and boundary counts to absolute
tolerance 1e-12; the linear random-1 fractions must remain 72/1000 and 82/1000.
Tests must protect per-replicate transformation, endpoint/infinity behaviour,
truth values and the complete unique replicate grid. Validate all original
evidence hashes, run affected scientific tests under R 4.5.3, and inspect the
rendered figure and manuscript. A focused independent reviewer must confirm
that the correction resolves the original interpretation concern.

Also implement the historical growth-only noise-model disclosure, concise
prior-work positioning and bibliography corrections, and improve the label
readability of Figures 3 and 5. These do not change scientific evidence.

## Execution and outcome

Accepted after implementation and independent verification. All 32 derived
summary rows agree with the separate direct-parameter calculation to 1e-12,
including all original boundary counts. The figure uses triangles for any
nonzero near-boundary fraction and prints every percentage. Linear random-1
means are 0.825242 and -0.817156; their original boundary fractions remain
0.072 and 0.082. All-date mean absolute contrasts span 0.817276–0.822578,
compared with truth 9/11. Bracketed absolute means are 0.344675–0.351362
(linear) and 0.584762–0.596840 (exponential).

The existing R 4.5.3 release image on deep-server passed all 37 scientific test
blocks. A clean candidate release regenerated the five original signed summary
tables exactly from all 720,000 fitted rows, rebuilt seven figures, matched the
new endpoint summary, passed all 82 numerical registry checks, and passed its
complete checksums before and after reproduction. Figures 1–5 and S1 reproduce
pixel for pixel; S2 retains its previously documented aggregate-correct
presentation difference. Raster checks exposed an incidental S1 rendering
difference after the revised PDF panels; rendering the unchanged PNG first
restores exact reproduction of S1 and leaves all three revised PDFs pixel-identical.
The original evidence and lockfile fingerprints remain
unchanged (130 protected files checked); only the three explicitly revised
figure PDFs changed among the 133 initial fingerprints.

Astra's focused acceptance addendum on 19 September concludes that findings 1
and 2 are resolved and finds no consequential defect within the correction's
scope. It independently checked the 32 emitted cells, displayed fractions,
interpretation and original signed-evidence hashes.

The strict manuscript build passed. PDF and editable DOCX versions were built
and the changed equations, figures and passages inspected. The PDF is 14 pages
and the supplement 9 pages. A Word empty-exponent placeholder was repaired by
putting the complete rate unit inside the equation; Supplementary Figure S2
starts a new PDF page to keep its caption with its image. The dated review
packet and scientific release are assembled separately from the preserved
11 September versions.

No new fitted datasets, simulation campaign, bootstrap interval calculation or
empirical reconstruction was run for this revision. The historical v1 FAIL
and post-unblinding v2 diagnostic, source-access restrictions and external-
validity limits remain unchanged. Local runtime logs, independent-check code,
rendered previews and the candidate release are under `tmp/revision_20260919/`.
Remote scratch is `/data/codex/scratch/rc-dates-boundary-revision-20260919-Xorqt5/`.
The final archive records its exact development commit in `RELEASE.json`.
