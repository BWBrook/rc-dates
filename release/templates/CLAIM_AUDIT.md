# Manuscript claim audit

Audit date: 2026-09-19

The release registry contains 82 evidence-value claims. `scripts/release/audit_manuscript_claims.py` checks each value against its accepted CSV evidence and now also checks that every `location` points to a non-empty line in `manuscript/text/main.md` or `manuscript/text/supplementary.md`. The registry is an evidence-value index; it does not attempt unrestricted natural-language parsing of the manuscript.

The current audit found full concordance for all 82 registered values:

- empirical filter flow, composition, sensitivity counts, shifts, distances and contrasts are anchored to the Supplementary filter, benchmark and sensitivity tables or the corresponding Results paragraphs;
- accepted simulation counts, retention-direction results, family-selection ranges, boundary summaries and scoring agreement are anchored to the main Results and Supplementary simulation-results paragraphs;
- observation-noise v1 and v2 endpoints and decisions are anchored to Supplementary Section S3;
- site-count summaries and the reported-error regression parameters are anchored to Supplementary Figure S2 and Section S2.1. The intercept, slope, residual standard deviation and $R^2$ claims use tolerances implied by the values quoted in the manuscript.

The two former bracketed log-ratio rows now use the derived bounded-contrast summary, and two new rows check the linear random-1 near-boundary fractions (0.072 and 0.082). These are generating-family summaries, irrespective of the selected family. Original log-ratio evidence remains archived, but is no longer used to substantiate finite Figure 4 effect magnitudes.

No registered value contradicted the current manuscript. The following rows are evidence-only decompositions whose exact integer or range is not printed separately in the prose: `sim.oldest.forced_direction_rows`, `sim.oldest.forced_direction_replicates`, `sim.youngest.forced_direction_rows`, `sim.youngest.forced_direction_replicates`, `sim.oldest.reversal_count`, `sim.youngest.reversal_count`, `sim.random.direction_all`, `sim.bracketed.family_all_changing`, `sim.boundary.oldest_aligned`, `sim.boundary.youngest_aligned`, and `sim.score_agreement`. Their linked Results/Supplementary passages state the corresponding experiment or outcome; the exact decomposition remains evidence metadata rather than an additional prose claim. `error_residual_df=974` is also metadata-only: it is present in `release/inputs/simulation_parameters.csv` but is not stated in the manuscript, so it was not added as a prose claim.
