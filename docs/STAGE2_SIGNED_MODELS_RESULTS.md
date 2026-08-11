# Stage 2 signed-model results

## Acceptance

The production matrix completed on `deep-server` on 10 August 2026 and passed every frozen
acceptance gate in `docs/STAGE2_SIGNED_MODELS.md`:

- 15 scenarios and 1,000 complete replicates per scenario;
- 720,000 result rows under R 4.5.3 in one digest-recorded container image;
- exact all-dates common-random-number pairing across treatment proportions;
- consistent source, input, lockfile, runtime and artefact fingerprints; and
- valid metadata plus SHA-256 checksums for every accepted evidence file.

An independent read of the 15 RDS files confirmed one selected model for every
replicate-by-truth-by-proportion-by-rule-by-score combination (240,000 selections). It also
recomputed the headline direction results directly from the raw rows rather than from the emitted
summary tables.

## Headline decision

The signed model space changes the interpretation, but strengthens the central warning. One-sided
post hoc retention does not merely destroy model recovery. At full site treatment, it makes the
selected temporal direction follow the retention rule:

- oldest-date retention selected a decreasing trajectory in all 1,000 replicates of every truth;
- youngest-date retention selected an increasing trajectory in all 1,000 replicates of every
  truth;
- when this imposed direction opposed a non-uniform truth, all 1,000 replicates were directionally
  reversed; and
- under a uniform truth, oldest and youngest retention selected exponential decrease and increase,
  respectively, in all 1,000 replicates.

These exact results occurred under both the primary `l1` likelihood and the secondary `l2`
expected-log-density score. The appropriate headline is therefore **retention-induced directional
distortion**, not a general destruction of recovery or a collapse to the uniform model.

## Primary results

The table below gives the primary `l1` results when all sites were treated. The adverse one-sided
rule retains the edge opposite the generating trend (oldest for increasing truths; youngest for
decreasing truths); the concordant rule retains the other edge. The true non-uniform effect was
`|theta| = log(10) = 2.303`.

| Truth | Rule | Correct family | Correct direction | Reversed direction | Mean selected theta | Selected boundary |
|---|---|---:|---:|---:|---:|---:|
| Exponential increase | All dates | 0.996 | 1.000 | 0.000 | 2.314 | 0.000 |
| Exponential increase | Adverse: oldest | 0.416 | 0.000 | 1.000 | -7.890 | 0.584 |
| Exponential increase | Concordant: youngest | 1.000 | 1.000 | 0.000 | 10.999 | 1.000 |
| Exponential increase | Bracketed | 1.000 | 1.000 | 0.000 | 1.381 | 0.000 |
| Exponential decrease | All dates | 0.998 | 1.000 | 0.000 | -2.305 | 0.000 |
| Exponential decrease | Adverse: youngest | 0.433 | 0.000 | 1.000 | 7.753 | 0.567 |
| Exponential decrease | Concordant: oldest | 1.000 | 1.000 | 0.000 | -10.999 | 1.000 |
| Exponential decrease | Bracketed | 1.000 | 1.000 | 0.000 | -1.343 | 0.000 |
| Linear increase | All dates | 0.976 | 1.000 | 0.000 | 2.349 | 0.000 |
| Linear increase | Adverse: oldest | 0.195 | 0.000 | 1.000 | -5.081 | 0.195 |
| Linear increase | Concordant: youngest | 0.000 | 1.000 | 0.000 | 10.998 | 0.994 |
| Linear increase | Bracketed | 0.000 | 1.000 | 0.000 | 1.124 | 0.000 |
| Linear decrease | All dates | 0.974 | 1.000 | 0.000 | -2.318 | 0.000 |
| Linear decrease | Adverse: youngest | 0.168 | 0.000 | 1.000 | 4.871 | 0.168 |
| Linear decrease | Concordant: oldest | 0.000 | 1.000 | 0.000 | -10.997 | 0.994 |
| Linear decrease | Bracketed | 0.000 | 1.000 | 0.000 | -1.096 | 0.000 |

For the uniform truth, all dates selected the uniform model in 0.848 of replicates and bracketed
retention in 0.999. Full oldest and youngest retention never selected uniform: each selected the
corresponding exponential direction in all 1,000 replicates, with mean selected `theta` of -8.308
and 8.310.

## Qualifications that matter

1. **The deterministic reversal is a full-treatment result.** At treatment proportions 0.50 and
   0.75, no non-uniform replicate selected the opposite direction under the adverse one-sided rule.
   At 0.75, the adverse rule instead selected uniform in 0.181 of linear-increase replicates and
   0.212 of linear-decrease replicates.
2. **A uniform truth is affected earlier.** With half the sites treated, oldest and youngest
   retention selected a directional model in 0.973 and 0.979 of replicates. At treatment
   proportions 0.75 and 1.00, they selected the rule-imposed exponential direction in exactly all
   1,000 replicates.
3. **Random retention preserves direction.** Across random-1, random-2, random-3 and random-5, all
   treatment proportions and all four non-uniform truths, primary direction recovery was 1.000.
   Correct-family recovery ranged from 0.754 to 0.995 as information was discarded.
4. **Bracketed retention protects direction, not functional family.** It preserved the direction of
   every non-uniform truth and nearly always preserved a uniform truth, but at full treatment it
   selected exponential rather than linear for every linear-truth replicate. The paired loss in
   linear-family recovery relative to all dates was 0.974--0.976.
5. **The scoring sensitivity does not change the decision.** `l1` and `l2` agreed on the selected
   signed state in 99.75% of all 120,000 paired selections, including every deterministic headline
   result.

## Revision consequence

The manuscript should now make the bounded mechanism explicit: among exchangeable regional-age
draws, one-sided post hoc retention can manufacture, exaggerate or reverse an inferred temporal
trend. It must not imply that the simulation represents prospective field-sampling decisions,
occupation histories, site onset or site termination.

No broader simulation expansion is warranted before the manuscript and empirical analysis are
aligned with this result. The accepted raw evidence and machine-readable summaries are in
`out/revision/signed-models/`.
