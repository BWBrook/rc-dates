# Stage 7 integration draft

Claude (claude-opus-5-5), 23 October 2026. These are proposed edits, not canonical text. They are to be applied after
Barry's read-through, so his markup applies to an unchanged source (`docs/SUBMISSION_WORKFLOW.md`, stage 1). The
numbers come from `out/revision/realised-noise-20261023/`, and the design and its decision rule are in
`docs/STAGE7_REALISED_NOISE.md`.

## Result in one line

The prespecified rule holds. Under realised measurement scatter, every one of the 75 headline rates stayed within 0.001
of its curve-mean value; the gate was 0.02. That includes oldest, youngest and bracketed retention, which were
previously untested.

## Main text (about +14 words net)

**Abstract.** Replace "The simulations isolate independent regional dates without occupation histories or realised
measurement scatter." with:

> The simulations isolate independent regional dates without occupation histories; their headline results held under
> realised measurement scatter.

That adds 4 words, taking the abstract to about 243.

**Section 2.3, final sentence of the observation-model paragraph.** Replace "Realised scatter was examined only in an
earlier paired sensitivity, restricted to constant and increasing histories and to the all-dates, random-1, random-3
and random-5 rules; its prespecified assessment and subsequent diagnostic are reported in Supplementary Section S3."
with:

> An earlier paired sensitivity added realised scatter only for constant and increasing histories and the all-dates and
> random rules (Supplementary Section S3); a later paired rerun applied it to the whole main experiment (Supplementary
> Section S2.8).

**Section 4.3, paragraph 3.** Replace the paragraph with:

> The main observation model omits realised conventional-age variation and correlated calibration-curve errors. An
> earlier realised-noise sensitivity, limited to all-date and random rules and growth-only candidates, met 15 of 18
> prespecified criteria and remains failed; a post-unblinding diagnostic met revised criteria (Supplementary Section
> S3). A later prespecified rerun of the main experiment with realised scatter, including oldest, youngest and
> bracketed retention, moved no headline rate by more than 0.001 (Supplementary Section S2.8). Correlated curve errors,
> laboratory offsets and outliers remain untested.

This keeps the failed v1 status and the post-unblinding label explicit. The v1 accuracy and support ranges (−1.5 to
+0.8 and −1.9 to +0.9 points) move out of the main text; they are already in SI S3, so their claims need re-anchoring
there.

## Supplementary Information

**New Section S2.8, "Realised measurement scatter".**

> The rerun was prespecified on 23 October 2026, after the earlier assessment in Section S3 (`docs/STAGE7_REALISED_NOISE.md`
> in the archive). It repeated the main ten-fold matrix of five truths, three treatment proportions, eight rules and 1,000
> replicates, with every conventional age drawn as Normal(curve-mean age, √(curve error² + quoted error²)), rounded and
> recalibrated with its quoted error. The draws used an isolated random-number stream. Calendar ages, quoted errors,
> sites, treated sites and random selections were therefore identical to the main experiment; only conventional ages,
> posteriors and posterior-median extrema differed. As in Section S3, a retained date with no posterior mass inside the
> strict window was dropped and counted; this affected at most 0.011% of retained dates. That rule was adopted after the
> first launch stopped on such a date and before any rate was computed.
>
> Before interpretation, the rerun code reproduced 20 accepted replicates exactly under the curve-mean model. Six paired
> datasets confirmed identical structural draws, and all 15 scenarios were complete with the accepted provenance.
>
> | Headline result | Rates | Curve mean | Realised | Largest change |
> |---|---:|---:|---:|---:|
> | Full opposing-rule reversal | 4 | 1.000 | 1.000 | 0.000 |
> | Full concordant-rule direction | 4 | 1.000 | 1.000 | 0.000 |
> | Constant history, full oldest/youngest: uniform selection | 2 | 0.000 | 0.000 | 0.000 |
> | Constant history, half oldest/youngest: directional selection | 2 | 0.973–0.979 | 0.972–0.980 | 0.001 |
> | Partial opposing-rule reversal | 8 | 0.000 | 0.000 | 0.000 |
> | Random-rule reversal | 48 | 0.000 | 0.000 | 0.000 |
> | Full bracketed: constant uniform selection | 1 | 0.999 | 0.999 | 0.000 |
> | Full bracketed: direction | 4 | 1.000 | 1.000 | 0.000 |
> | Full bracketed: linear family for linear histories | 2 | 0.000 | 0.000 | 0.000 |
>
> Across all cells, the largest change in any rate was 0.015, in a generating-family rate. Each cell had at least 95.2%
> of replicates selecting the same family and direction under both observation models; the median was 99.1%. Scatter
> changed which date was a site's posterior-median oldest for about 0.2–1.5% of dates. The rerun covers the ten-fold
> design only, with independent curve errors and no laboratory offsets or outliers.

**Section S3, last sentence.** Replace "It neither replaces the failed prespecified assessment nor validates the
untested oldest, youngest and bracketed rules." with "It does not replace the failed prespecified assessment. Section
S2.8 tests oldest, youngest and bracketed retention separately."

## Housekeeping on integration

- Add Stage 7 claims to `release/claims.csv`: the headline maximum change, the largest cell change, the same-state
  minimum and median, the dropped share, the l1/l2 agreement, and the 0.973–0.979 to 0.972–0.980 ranges.
- Re-anchor the v1 accuracy and support claims to SI S3.
- Tick the checklist item "Decide whether realised-observation-noise checks…".
- Rebuild, then rerun the claims audit and the word count.
