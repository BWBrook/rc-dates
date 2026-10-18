# Stage 6 integration draft

This draft was prepared by Claude (claude-opus-5-5) on 18 October 2026, after Stage 6 passed technical acceptance. It is
not canonical text. It is for Codex's independent audit of the results, in discussion 88, before integration into
`manuscript/text/main.md` and `figures.md`. All numbers come from `out/revision/effect-size-20261018/stage6_selection_rates.csv`
(`l1`). The ratio-10 and ratio-1 cells pool the accepted 1,000-replicate evidence; ratios 1.5–5 have 500 replicates.

## What the evidence says

These results use the opposing one-sided rule, called "adverse" in the CSV: oldest-date retention under increasing truths
and youngest under decreasing truths. Ranges span the four truths (`lin_inc`, `lin_dec`, `exp_inc`, `exp_dec`).

| Treated | Ratio 1.5 | 2 | 3 | 5 | 10 |
|---|---|---|---|---|---|
| 100%: reversed | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| 75%: reversed | 0.998–1.000 | 0.934–0.986 | 0.352–0.500 | 0.002–0.028 | 0 |
| 75%: correct | 0 | 0 | 0–0.010 | 0.140–0.498 | 0.788–1.000 |
| 50%: reversed | 0.190–0.226 | 0–0.004 | 0 | 0 | 0 |
| 50%: correct | 0.002–0.020 | 0.336–0.432 | 0.976–1.000 | 1.000 | 1.000 |

Other rules:

- **Reversal.** Across all 60 changing-truth cells, the maximum reversal rate was 0.006 for random-1, 0 for random-2, random-3,
  random-5 and all dates, and 0 for bracketed retention.
- **Lost power at full treatment.** At ratio 1.5, the correct direction was found in 0.404–0.492 of replicates with random-1
  and 0.106–0.168 with bracketed retention. The count-matched random-2 comparison found it in 0.606–0.666, and all dates in
  0.982–0.996. At ratio 2, the rates were 0.712–0.794 for random-1, 0.696–0.796 for bracketed retention and 0.932–0.952 for
  random-2.
- **Linear family under bracketed retention.** The generating linear family was selected in 0 replicates at 75% and 100%
  treatment at every ratio, and in at most 0.035 at 50% treatment. Random-2 selected it in 0.32–0.95.
- **Second scoring rule.** The `l2` reversal rates for the opposing rule match `l1` to within 0.002 in every partial-treatment
  cell. The lowest `l1`/`l2` selected-state agreement in any Stage 6 cell is 0.980.

Stage 6 therefore strengthens the paper rather than narrowing it. "Reversal only under full treatment" was a ten-fold
artefact. Partial treatment reverses weak trends, and dilution by untreated sites protects only strong ones.

## Proposed text

### Abstract (+13 words)

Replace "At half-site treatment, the same rules created apparent change from constant histories in over 97% of replicates,
but did not reverse the simulated ten-fold changes." and "Random retention preserved the direction of the ten-fold
changes." with:

> At half-site treatment, the same rules created apparent change from constant histories in over 97% of replicates. With
> three-quarters of sites treated, keeping the extreme opposed to the trend reversed 93–100% of 1.5- and 2-fold changes but
> no ten-fold change. Random retention reversed at most 0.6% of replicates at any tested strength.

### 2.3 Methods (+50 words)

- Replace "Each non-uniform truth had a ten-fold end-to-end ratio." with "Each non-uniform truth had a ten-fold end-to-end
  ratio in the main experiment."
- After "…applying every rule to the same simulated dates within a replicate.", add: "A signal-strength extension repeated
  the four changing histories at end-to-end ratios of 1.5, 2, 3 and 5, with 500 replicates each and otherwise identical
  code, data and seeds, so each replicate shared its latent draws across ratios (Supplementary Section S2.7)."
- Change the Monte Carlo sentence to: "…the largest possible Monte Carlo standard error for a selection rate is 0.016
  (0.022 with 500)."

### 3.1, paragraph 2 (scoped to ten-fold; −0 words)

Replace "This complete reversal occurred only when every site was treated." with "For these ten-fold changes, complete
reversal required every site to be treated." Leave the rest of the paragraph unchanged, because it describes ten-fold
evidence.

### 3.1, new paragraph 3, before the endpoint-contrast paragraph (+165 words)

> Weaker changes were reversed with fewer sites treated (Fig. 3). With every site treated, the opposing rule reversed every
> replicate at every tested ratio from 1.5 to 10. With three-quarters treated, it reversed 99.8–100% of 1.5-fold changes,
> 93.4–98.6% of 2-fold changes and 35.2–50.0% of 3-fold changes. At 5-fold, it recovered the correct direction in only
> 14.0–49.8% of replicates, and nearly all the rest were read as constant. With half treated, it reversed 19.0–22.6% of
> 1.5-fold changes and read most of the rest as constant. It recovered the correct direction in 33.6–43.2% of 2-fold
> replicates and in at least 97.6% from 3-fold. Random retention never reversed more than 0.6% of replicates in any
> combination, and bracketed retention reversed none. Both lost power instead. With every site treated, random-1 detected
> a 1.5-fold change in 40.4–49.2% of replicates. Bracketed retention detected it in 10.6–16.8%, against 60.6–66.6% for its
> count-matched random-2 comparison.

### 3.2 (+28 words)

After "…no linear history was recovered as linear.", add:

> The same held at every tested signal strength whenever three-quarters or more of sites were treated, and at most 3.5% of
> linear histories were recovered at half treatment.

### 4.3, paragraph 1 (replaces the current paragraph; about +10 words)

> The strength of the underlying trend and the extent of retention interact. At partial treatment, each filtered site
> contributed one date and each untreated site at least five, so filtered sites supplied a smaller share of retained dates
> than of sites. Within the tested ratios, this dilution protected strong trends but not weak ones. No ten-fold change was
> reversed at 75% treatment, whereas 1.5- and 2-fold changes almost always were, and about one in five 1.5-fold changes was
> reversed even at 50%. A treatment threshold that is safe for one signal strength is therefore not safe for another. The
> ratios are end-to-end density contrasts over 11,000 years, not growth rates, and non-monotonic histories were not tested.

### 4.4 Conclusions (0 words)

No change is needed. "…could create a trend, reverse one…" now holds without the full-treatment qualifier.

### New figure (insert as Fig. 3; renumber the current Figs 3–5 as 4–6 in the text and captions)

`manuscript/figures/fig_effect_size.pdf`, `{#fig-main-3 width=100%}`. Caption (+105 words):

> Reversal of weaker trends under partial retention. For each true end-to-end density ratio (log scale), points above zero
> give the proportion of replicates in which AIC favoured the true state: the correct direction, or uniform for the
> constant history at ratio 1, shown unconnected. Points below zero give the proportion favouring the opposite direction,
> and the remainder favoured uniform. Columns show the opposing one-sided rule (oldest date for increasing histories,
> youngest for decreasing), both extrema, and one random date per site. Colour gives the proportion of sites treated.
> Ratios 1.5–5 have 500 replicates per point, and ratios 1 and 10 have the accepted 1,000. Results use the primary marginal
> likelihood; bracketed cells use working independence.

The alternative is to move the endpoint-contrast figure (current Fig. 3) to the SI and keep five main figures. I prefer
six: endpoint bias is the figure the statistical reader will look for.

### Supplementary Section S2.7 (new)

This section gives the design, acceptance, and full selection-rate table, including the concordant rule and
family-selection rates. It also includes the prespecified correct-state-only display, with a note on the post-results
display amendment, and points to `docs/STAGE6_EFFECT_SIZE.md`.

## Word budget

The net addition to the main text and captions is about +370 words. Codex's round-2 count, made on the rendered Word
text, is 4,766, which would take the total to about 5,140. Cuts of at least 150 words are therefore needed. Candidates:

1. **3.1, paragraph 3.** Move the sentences on linear-boundary and optimiser tolerance ("For linear fits, the natural
   parameter boundary … would depend on optimiser tolerance.", about 75 words) to the Fig. 4 caption or the SI. The
   caption already says most of it.
2. **4.3, paragraph 3.** Compress the noise-sensitivity detail to two sentences, saving about 60 words. The full account is
   in SI S3.
3. **2.3.** "Here 'increase' means…" can lose the θ restatement, saving about 20 words.
4. **Fig. 2 caption.** Drop "The all-dates column is identical in every panel and is repeated for comparison.", which
   appears in two captions. That saves about 15 words.
