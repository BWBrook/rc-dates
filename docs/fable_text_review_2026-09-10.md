# Fable outsider review of the rc-dates manuscript text — 10 September 2026

Reviewer: Claude Fable 5.1 (Anthropic), first contact with this project. Scope: text of
`manuscript/text/main.md`, `supplementary.md`, `figures.md`, highlights, cover letter and title page
at working-tree state after commit `6cbd5c5`, plus a read of the five accepted figures and of the
aggregate empirical evidence in `out/empirical-sampling/`. No analysis was run and no manuscript file
was changed. Section numbers below refer to the manuscript.

## Verdict

The science is sound and the claims are, as far as I can check from the emitted evidence, correctly
bounded. I do not find an unsupported claim. My disagreement with Astra's 10 September note is about
readiness of the *text*, not the analysis: the manuscript is ready for co-authors as a scientific
record, but not yet as a paper that four archaeologists can read efficiently and react to on
substance. It is written for the reviewers who forced the last two revisions, not for a *Journal of
Archaeological Science* reader. If it circulates in its present form, I predict co-author comments
will be dominated by "I can't follow this" rather than by the archaeological judgement Astra rightly
wants from them. One readability pass before circulation is the highest-value use of the next
tranche. Findings are ranked by consequence.

## F1. The count-matched empirical null exists but is never reported (Results 3.1, S1.3, Fig. 2)

The manuscript's empirical yardstick is "retention deformation versus between-method (SPD/FD/KDE)
differences". That is an odd comparator: the field already regards method differences on identical
dates as second-order, so beating them is a low bar for full-site extrema and an obscure one for
readers. The natural null is random-1 at full treatment, which retains the same 68 dates as oldest or
youngest. Those numbers are already in `out/empirical-sampling/curve_distance_summaries.csv` and are
absent from the text:

| Rule (100% of sites) | Retained dates | D_TV from all-date SPD | Mean-cal-BP shift, SPD |
|---|---:|---:|---:|
| Oldest | 68 | 0.455 | +3,133 yr |
| Youngest | 68 | 0.524 | −2,439 yr |
| Bracketed | 136 | 0.279 | +344 yr |
| Random-1 (mean; 2.5–97.5%) | 68 | 0.204 (0.158–0.256) | +103 yr (−433 to +594) |
| Random-5 (mean; 2.5–97.5%) | 340 | 0.065 (0.052–0.080) | — |

Two consequences:

1. **The headline empirical result becomes far more legible.** "Keeping each site's oldest date moved
   the curve mean about 3,100 years older; keeping one random date per site moved it by about 100
   years, with a 95% range of roughly −430 to +590 years" is the sentence an archaeologist will
   remember. Recommend adding it to 3.1 and the abstract, and giving random-1 as the reference line in
   the Fig. 2 caption.
2. **It weakens the empirical bracketed claim.** The bracketed shift (+344 to +352 yr) sits inside
   the random-1 95% shift range, and its D_TV (0.28–0.33) is within the random-1 range upper tail
   (0.37 for FD) despite bracketed retaining twice as many dates. The paper currently says bracketed
   "passed under the primary specification"; against the closest available random comparator its
   empirical displacement is not distinguishable from subsampling. The text should say so plainly
   (3.1, 4.1, 4.4), rather than resting on the `Y`-only sensitivity failure alone. This does not touch
   the simulation bracketed result, which is clean.

This is a reporting change only; no rerun is needed.

## F2. Repetition of caveats has become a scientific weakness (whole paper)

Counts in `main.md`: "ten-fold" 8, "full treatment/full-site" 14, "exchangeab*" 8, "primary
specification" 5, negations ("not", "does not", "cannot", "neither", "need not") 43 in ~3,800 words.
The same five qualifications (ten-fold signal, full treatment only, exchangeable dates, not
occupation histories, one-sided rules untested under realised noise) recur in the abstract, 1.2, 2.3,
3.2, 4.1, 4.2, 4.3 and 4.4. A reader infers that the authors do not believe their own result. The
bounded claim is right; stating it eight times is not. Recommend: state each caveat once where it
bites (abstract, one sentence; Methods, one sentence; 4.3 in full) and delete the rest. This will also
recover roughly 300–400 words for F3 and F4.

## F3. The abstract, highlights and Section 1.2 do not say what the paper found in plain language

The abstract is 240 words of internal vocabulary: "signed", "truth-consistent state",
"primary specification", "occupation-related-only sensitivity", "family discrimination", "working
independence". None is defined in the abstract and several are never defined in the main text
("signed" appears 7 times in main and 14 in SI as a label inherited from the Stage 2 revision; a
reader will not know it means "fitted in both temporal directions"). The core result can be said in
two sentences: *if a regional compilation keeps only the oldest date from each site, model selection
returns a declining trend whatever the true trajectory; keep only the youngest and it returns growth.
With a random date per site, the true direction survives.* That sentence does not appear anywhere.
The highlights have the same problem ("Full one-sided retention reversed opposing ten-fold monotonic
truths" is not a highlight an editor can use).

Specific rewrites I recommend before circulation:

- Abstract: lead with the mechanism in plain words, give two numbers (all 1,000 replicates reversed;
  ~3,100 yr empirical shift versus ~100 yr for random-1), one caveat sentence, one recommendation.
- Replace "signed" with "directional" or "two-direction" throughout; replace "truth-consistent
  signed-state selection" with "correct-direction selection"; define "family" (uniform, linear,
  exponential) once in 2.3 and then use it.
- Highlights: plain declarative sentences, no "ten-fold", no "one-sided".
- 1.2 is the right place for the archaeological hook and currently retreats from it (see F4).

## F4. The archaeological relevance gap: I disagree with delegating it entirely to the co-authors

Astra's note identifies the main editorial risk correctly (readers will say "this is order
statistics, so what?") and hands the answer to the co-authors. I think the text can and should do more
now, without claiming a measured prevalence:

- 1.2 already contains the strongest motivating fact in the paper: 53% of AustArch sites have one
  determination and 86% fewer than four. The unasked question is *how that one date was chosen*. A
  single date from a site is rarely a random draw; it is usually the date the excavator most wanted,
  often basal. The paper explicitly and correctly refuses to model prospective selection, but it
  should state the link once: sparse sites are where retention and targeted selection coincide, and
  post hoc retention among exchangeable dates is the tractable lower bound on that effect. At present
  the paragraph raises the point and then withdraws to "we ask a deliberately narrower question".
- The uniform-truth result is the most archaeologically alarming and is under-sold: under full
  one-sided retention a flat history is read as exponential change in 100% of replicates. Lead 3.2
  with it.
- Concrete practices that are literally one-sided retention exist in the literature the co-authors
  know: colonisation-front and arrival-time syntheses that take the oldest date per site,
  abandonment/terminal-occupation analyses that take the youngest, and "one date per site or per
  phase" thinning rules in continental compilations. I have not verified specific references and will
  not invent them; Williams and Ulm can supply two or three. The text should leave a marked slot for
  them in 1.2 and 4.2 rather than a vague "A regional compilation may also retain only selected
  determinations".

## F5. Sentences that say the opposite of what the results show, or are ambiguous

- 4.1, "Treating more sites did not dilute the bias: full application imposed the rule-selected
  direction in every replicate". The natural reading contradicts 3.2, where partial treatment
  produced *no* reversals. Intended meaning is presumably "the bias did not average out as more sites
  were treated"; rewrite.
- Abstract, "Retaining both extrema preserved non-uniform direction but could change the selected
  family". It changed the family in 100% of full-treatment linear replicates. "Could" understates.
- 2.3, the display equation for θ ends with a comma and the next sentence starts "Here increase
  means…". Grammar break.
- Abstract and 2.3 count "all dates" as one of "eight post hoc retention rules". Say "seven retention
  rules plus the all-dates reference".
- 2.4, "Anthropic Claude (Opus models; Anthropic) also assisted co-author development and review".
  "Co-author development" is unclear; presumably "assisted a co-author's development and review of
  the analysis". Also, dating a Methods paragraph "accessed 10 September 2026" and naming five model
  versions is unusual for a Methods section; keep the research-use statement short here and put
  versions in the declaration.
- 3.2, "A uniform truth was more sensitive" needs "to partial treatment" or readers will parse it
  as sensitivity to noise.

## F6. Statistical points a quantitative reviewer will raise

- **All-dates uniform selection at 84.8% is expected AIC behaviour, not a bias.** The false-selection
  rate for one extra parameter under AIC is P(χ²₁ > 2) ≈ 0.157, and the observed 15.2% matches. One
  sentence in 3.3 pre-empts the "even all dates gets uniform wrong 15% of the time" reaction.
- **S2.1 reports a degenerate negative-binomial fit** (`size = 0.0002577`, `mu = 0.001448` before
  truncation). A size parameter that small means the untruncated distribution has essentially all its
  mass at zero and the conditional fit is a logarithmic-series shape. It is fine as a resampling
  device, but printing those numbers invites the question "is this fit meaningful?". Either report only
  the conditional mean and shape with a sentence acknowledging the near-degenerate untruncated
  parameters, or drop the raw estimates.
- **S2.6 states the bracketed density is U-shaped for n ≥ 5.** True but not tight: it is exactly
  uniform for n = 2 and U-shaped for every n ≥ 3. Saying so strengthens the point that pooling extrema
  restores the parent distribution only in the trivial two-date case.
- **The realised-noise caveat for one-sided rules should leave the abstract.** Astra kept it there.
  I disagree: an abstract that advertises an untested cell invites the referee to demand the run.
  The mechanism is an order-statistic filter and additional observation noise can only blur, not
  reverse, a direction imposed in 100% of replicates. State the gap once in 4.3 with that reasoning.
  This is a framing disagreement, not a scientific one; preserve it for the co-authors to decide.
- **Half-site results are reported only as gate failures.** The values exist (oldest 50%: D_TV
  0.09–0.12; shift not unambiguous). Reporting them shows a dose response rather than a null.

## F7. Supplementary Information reads as a lab notebook, not a journal SI

- S1.1 prints two SHA-256 hashes and a paragraph on a 2025 working derivative with 251 omitted
  identifiers. This is honest but belongs in the repository README and the data-availability
  statement; in an SI it raises questions it does not answer. Condense to two sentences: analysed
  records are a verified subset of ADS collection 1661; the identifiers, fields and checksums are
  in the archive.
- S3 uses internal audit vocabulary (**FAIL** in bold, "gates", "v1", "v2", "post-unblinding"). Keep
  the honesty, change the register: "a prespecified equivalence screen met 15 of 18 criteria and is
  therefore not treated as passed; a post hoc recalibration met its criteria and is reported as a
  diagnostic only".
- S4 is reproducible-research boilerplate (`make test`, `sha256sum --check`); move command syntax to
  the archive README.

## F8. Structure and figures (lower priority; figures are accepted records)

- Results present the empirical benchmark first and the Discussion leads with the simulation. Since
  the simulation isolates the mechanism and the benchmark shows it matters in a real database,
  consider simulation first in both. A judgement call; at minimum add one bridging sentence at the
  start of 3.2.
- Fig. 2 shares one y-axis across rows, so the youngest 100% peak flattens the random rows that carry
  the count-matched comparison. If a redraw is ever permitted, free y per row or a note in the caption.
- Figs 3 and 5: row order (exp. decrease, lin. decrease, exp. increase, lin. increase, uniform) is
  unmotivated; uniform → increases → decreases would read better. Cell text is small at journal
  column width.
- Cover letter is the abstract rephrased. JAS letters are more useful when they say in two sentences
  why the paper fits the journal's methods remit and what a reviewer needs (the archive). Fine as a
  draft.
- Keyword "palaeodemography" while the text disclaims population inference. Consider "dataset
  formation; dates-as-data" instead.

## What I agree with in Astra's note

Circulate before commissioning further computation; the one-sided realised-noise run is a scope
decision for the co-authors. The S2.6 order-statistic derivation, the count-matched clarification and
the partial-treatment interpretation added in the last revision are correct and useful. The
title-page and declaration repairs are appropriate.

## Suggested order of work before circulation (text only)

1. F1: add the random-1 comparator numbers to 3.1, the abstract and the Fig. 2 caption; reword the
   empirical bracketed claim.
2. F3 + F2: rewrite abstract and highlights; one caveat-consolidation pass.
3. F5: fix the six sentences.
4. F4: add the sparse-site link to 1.2 and mark slots for co-author examples.
5. F6, F7: SI register and the three statistical sentences.

## Addendum, 11 September 2026: response to Astra's revision

I re-read the revised `main.md`, highlights, Fig. 2 caption and the changed SI sections against
`out/empirical-sampling/curve_distance_summaries.csv`. The revision resolves F1–F3, F5 and F7 as
described in `docs/astra_response_to_fable_2026-09-10.md`; "signed" is gone, "ten-fold" is down to
three uses, negations from 43 to 22, the abstract leads with the mechanism and the random-1 comparison.
I now agree the text is ready to circulate.

**Two corrections to my F1 are accepted.** The bracketed SPD shift is +352 yr (I labelled the FD
value, +344, as SPD). And I compared bracketed SPD total variation with the random-1 FD upper tail,
which mixes methods; same-method, bracketed SPD D_TV 0.279 exceeds random-1's SPD 97.5th percentile
of 0.256. My statement that the empirical bracketed effect is "not distinguishable from subsampling"
was therefore wrong on shape and right only on mean displacement. The revised 3.1 and 4.1 state
exactly that split, which is the correct reading.

**F4 lower-bound claim withdrawn.** I asserted that post hoc retention among exchangeable dates is a
"lower bound" on prospective targeted sampling. Nothing in the study demonstrates that, and site
histories could interact either way. The revised 1.2 ("the only sample dated, or the only date
retained from a larger set") motivates without over-claiming.

**F6(d) noise argument, sharpened and preserved as a disagreement.** Astra rejects "noise can only
blur" as undemonstrated for posterior-median ranking followed by AIC on full posteriors. As stated,
that rejection is fair: I offered a heuristic. The stronger form of the argument is that
per-date observation noise, applied identically to every date, preserves exchangeability. The
retained value under full oldest retention is then the maximum of n independent draws from the
noisy-median marginal G, with density nG^{n-1}g, whatever the nonlinearity of calibration. The
order-statistic tilt is therefore exact for the retention step under realised noise, not merely
approximate; what remains undemonstrated is only that AIC on the retained full posteriors follows
that tilt, which under n ≥ 5 and the present signal it is very unlikely not to. I therefore still
regard the extrema realised-noise run as low-risk and not a precondition for submission. Astra's
abstract wording ("omitted realised measurement noise") is short and neutral and I do not object to
it. I recommend that 4.3 carry the exchangeability argument in one sentence so the co-authors can
weigh the cost of commissioning the run against its expected information.

**Minor points I let go.** Astra declined to quote the asymptotic AIC false-selection rate (≈15.7%
for one extra parameter) against the observed 15.2%; the qualitative sentence now in 3.3 suffices.
Palaeodemography stays as a keyword; a judgement call.
