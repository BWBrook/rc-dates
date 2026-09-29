# Prose pass on the main text and captions — 29 September 2026

Editor: Claude Opus 5.5 (Anthropic), continuing the Claude Code session that produced the Fable reviews
of 10–14 September. Scope, at Barry's request: `manuscript/text/main.md` and
`manuscript/text/figures.md` only, starting from commit `0b6b7d6`. The Supplementary Information,
highlights, cover letter and title page were not touched. The edits are in the commit that adds this log.

## What was protected, and how it was checked

- Every citation (57 uses of 43 keys), all four display equations, all inline mathematics and every
  standalone number are identical before and after, checked by script.
- No claim, caveat boundary, gate result or prespecified decision was changed. Astra's 18–19 September
  Figure 4 and noise-sensitivity wording is retained in substance.
- No em dashes, no new "not X but Y" constructions, no stock intensifiers or signposting vocabulary.
  British spelling is kept throughout.
- `make manuscript-check` passed: 38 builder tests, manuscript lint, reference audit and build.

## Word budget

A fuller first draft added about 750 words and was discarded. The limit, taken here as 5,000 words
excluding references, leaves little room. This pass therefore pays for its explanations by joining
choppy sentences and trimming repeated caveats.

| Rendered words (citations expanded) | Before | After |
|---|---:|---:|
| Abstract | 229 | 230 |
| Introduction to Conclusions | 3,660 | 3,866 |
| Captions | 579 | 602 |
| Abstract + body + captions | 4,468 | 4,698 |
| Everything except references, plus captions | 4,689 | 4,921 |

If the journal counts the declarations, data statement, title and keywords, the margin is under 100
words.

## Rhythm

| Body sentences | Short (<12 words) | Medium (12–28) | Long (>28) | Mean length |
|---|---:|---:|---:|---:|
| Before | 41 | 132 | 14 | 18.0 |
| After | 25 | 103 | 34 | 22.0 |

Short sentences were kept where they carry a point: "The link between dates and people is
conditional." "Partial treatment mixes unequal contributions." "Bracketed retention illustrates the
distinction."

## Main moves

- **Plain-language glosses for general readers.** They cover what a calibrated age is and why it is
  often multimodal, what an SPD does, and why there is a "pull of the recent". They also cover what
  random-1 and random-5 mean, total variation as the share of mass that must be moved, and AIC's
  parameter penalty. The likelihood is read as the candidate density averaged over a date's
  calibrated age distribution, and the pooled-extrema U-shape as too many dates near both ends of the
  range.
- **One concrete illustration of order statistics (1.2).** Of five ages drawn from a constant
  distribution, the oldest falls in the oldest fifth of the range about two times in three, against
  one in five for a random date. This is 1 − 0.8⁵ = 0.67, from the paper's own F(x)ⁿ formula with
  exact ages.
- **One consequence of that formula (4.1).** A site with ten dates tends to contribute a more extreme
  oldest date than one with five.
- **Choppy sequences joined** in 1.2, 2.1, 2.2, 2.3, 3.1, 3.2, 4.1, 4.2 and 4.3. The two-sentence
  paragraph on the earlier noise sensitivity in 2.3 is merged into the observation-model paragraph.
  The technical simplifications in 4.3 move to the first paragraph, so the noise paragraph ends on the
  untested question.
- **Internal jargon removed.** "Treatment files" in the Figure 3 and 5 captions becomes "every panel".
  "Synthetic artefacts" becomes "synthetic simulation outputs", since "artefacts" misleads in an
  archaeology journal. "Signed candidate set" becomes "candidates that allow change in either
  direction".
- **Heading 3.1** now states its result: "Oldest and youngest retention moved the empirical curves by
  millennia". This matches the style of 3.2 and 3.3.
- **Figure captions.** Figure 2 now says what positive values mean. Figure 4 now explains the
  triangles, which the caption previously omitted.
- **Smaller changes.** The abstract says "in all nine" rather than "across nine", and minus signs are
  made typographically consistent.

## Sentences Astra should check for precision

1. **1.2, order-statistic example.** It is idealised and uses exact ages. It adds one illustrative
   number that the paper did not previously state.
2. **2.3, likelihood and AIC glosses.** These are "the log of the candidate density averaged over the
   date's calibrated age distribution" and "Because AIC penalises each fitted parameter…". In 3.3,
   the AIC sentence is shortened accordingly.
3. **3.2, boundary sentence.** "Even random-1 produced near-boundary linear fits in 7.2% and 8.2%…, so
   finite log-ratio means at the linear boundary would depend on optimiser tolerance" merges two
   sentences from 19 September.
4. **4.3, dropped clause.** The clause "near-boundary frequencies identify where the fitted parameter
   domain constrains interpretation" is dropped as a repeat. The same point stands in Methods 2.3,
   Results 3.2 and the Figure 4 caption.
5. **2.2, percentile caveat.** The Figure 2 caveat is folded into the sentence that introduces
   Figure 2. It still says the envelopes are not uncertainty over the archive or population history.

## Offered, not inserted

An ecology bridge would help the general ecological and conservation readership. It was not inserted
because it needs a citation that is not in `refs.yaml`. Suggested wording, for the end of 4.1:

> The same reasoning is familiar from the estimation of arrival and extinction times from a species'
> earliest or latest dated records [cite], and it applies with equal force when such extremes are
> compiled into a regional time series.

Candidate sources for the authors to choose and verify are the Signor–Lipps literature and the
authors' own extinction-timing work.

## Still open from earlier reviews (unchanged here)

- The Data availability statement still offers a "named" archive to peer reviewers under
  double-anonymised review.
- Section 2.3 does not say that the 976-date reference, used for the site-count and error models,
  includes the marine records that the benchmark excludes.
- The AI declaration names "Opus", which covers this pass. The authors should confirm version details.

## Follow-up, 29 September

At Barry's request, the offered and open items above were resolved in the two commits that follow
the prose pass.

- The bridge sentence is now in Section 4.1, reworded to match its sources. It cites Signor and Lipps
  (1982) and Bradshaw et al. (2012), both verified against Crossref and added to `refs.yaml`.
- Section 2.3 now states that the 976-date reference also contains the 239 shell and human-bone
  determinations excluded from the benchmark.
- The Data availability statement, Supplementary Section S4 and the cover letter now describe an
  anonymised review archive. The submission checklist records that the release README, which names
  the authors, must be anonymised in the copy uploaded for review.
- The AI declaration is left for Barry's editorial pass.
