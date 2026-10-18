# Independent Stage 6 result and integration audit

18 October 2026, Australia/Hobart. Codex (GPT-6), with a separate read-only
interpretation/display review. Reviewed checkout: `5ee7bb5`; Stage 6 evidence
commit: `41833cd`. This follows the pre-results implementation audit and its
live verification recorded in `codex_stage6_pre_results_audit_2026-10-18.md`.

**Decision: the emitted Stage 6 selection rates are independently verified and
support manuscript integration.** The post-results figure amendment is
legitimate: it displays a second prespecified outcome to distinguish reversal
from uniform selection, with no change to the simulation or estimand. The
wording and preservation repairs below are required before the integrated
manuscript and evidence package are complete. No new simulation is needed.

## Independent evidence check

The audit read all 48 new scenario files at 500 replicates and all 15 accepted
reference files at 1,000. In the accepted R 4.5.3 container on `deep-server`,
it independently aggregated the stored minimum-criterion selections without
calling the production selection or summary helpers. Direction was derived
from the sign of the fitted parameter and cross-checked against the stored
endpoint log ratio. Truth direction and family were derived from the expected
scenario. The audit also checked the complete replicate/rule/score/model grid,
scenario binding, truth log ratios and frozen provenance.

- All **1,008 rows and 13 columns** of `stage6_selection_rates.csv` matched
  exactly, including correct-state, reversal, uniform, family and score-agreement
  rates. Inputs comprised **1,872,000 fitted rows** across 63 scenario files.
- All 360 rows of `stage6_dose_response.csv` mapped to the independently verified
  primary-score rows, with the correct adverse/concordant rule, truth, ratio,
  treatment proportion and replicate count.
- The 20-replicate smoke file reproduced all **960 rows and 17 columns** of the
  accepted reference after sorting by replicate, score, rule and model.
- Every local fitted-result file matched its remotely audited MD5 and its local
  metadata sidecar. All **108 entries** in the Stage 6 SHA-256 manifest matched
  the files present locally. Four are not yet tracked in Git; see finding 4.
- Weighted selected-state agreement between `l1` and `l2` was
  **0.9969070513** over 312,000 paired rule-by-replicate selections. The minimum
  new truth/ratio/proportion/rule-cell agreement was **0.980**.

The bounded audit used one CPU, a 2 GiB memory cap, no container network and a
read-only project mount. Image:
`sha256:01f5e221d0f3b70ccb3edd0fd6556ffd1c645784e98e147e81034866b9137777`.
The audit script and CSV/JSON receipts are retained in
`tmp/editorial_rework_20261018/result_audit/`; its script SHA-256 is
`00b2b88a5f16a3a6a0efb4ce78a903ec426f8c65f600cdea0ceb727297f2e276`.
The production selection CSV SHA-256 is
`4c97d5132ea9d7573ffc03127819dcd0659ce2be17ab73e81025f57d5d8226b7`.

This independently verifies aggregation, labels, completeness and provenance
of the stored fitted outputs. The files contain selected-model flags rather
than every pointwise criterion, so this audit does not independently refit all
models or recompute every AIC minimum. It does not change the observation-model
limits or the historical failed noise-sensitivity gate.

## Findings for integration

### 1. P1: distinguish avoiding reversal from recovering direction

The new evidence makes several unqualified ten-fold statements false when read
as applying to the complete experiment. The proposed integration scopes Results
3.1, but leaves the abstract's bracketed-direction claim, the contribution
paragraph in the Introduction, the opening and last paragraph of Results 3.2,
and the second paragraph of Discussion 4.1 too broad.

At ratio 1.5 and full treatment, bracketed retention recovered direction in
only 10.6–16.8% of replicates, despite never reversing it. Random-1 recovered
direction in 40.4–49.2%. The remaining outcomes were predominantly or entirely
uniform selections. Keep three questions distinct throughout: was the trend
reversed, was its direction recovered, and was its generating family recovered?

Use explicit ten-fold qualifiers wherever those earlier results are retained.
For example, start Discussion 4.1 paragraph 2: "For ten-fold changes, keeping
both extrema preserved direction, but every linear history favoured an
exponential model under full-site retention." The abstract's "all 1,000
replicates of each history" must identify the original experiment or become
"every replicate" if it includes the 500-replicate extension.

### 2. P2: no tested proportion is established as safe

Reject "a treatment threshold that is safe for one signal strength is therefore
not safe for another". The study did not estimate a threshold, and no reversal
does not establish reliable recovery: at 75% treatment, up to 21.2% of the
ten-fold histories were selected as uniform. "Dilution protected strong trends
but not weak ones" is also too binary. At ratio 1.5, moving from full to half
treatment reduced reversal from 100% to 19.0–22.6%.

Suggested wording: "Untreated sites supplied more dates and reduced reversal
risk, but the result depended strongly on signal strength. For a fixed
proportion of sites treated, weaker trends were more vulnerable to reversal
or uniform selection. The tested proportions do not establish a safe retention
threshold." Describe the old full-treatment result as specific to ten-fold
signals, rather than calling it an artefact.

### 3. P2: repair the display explanation, retain the amended display

The statement "the gap between them is uniform selection" in the post-results
design amendment is mathematically wrong. If correct-direction rate is C and
reversal rate is R, the gap from −R to C has height C + R = 1 − U, where U is
the uniform-selection rate. The plotted values themselves agree with the
verified table.

Use: "For changing histories, the uniform-selection proportion is one minus
the correct and reversed proportions. At ratio 1, only uniform-selection
success is shown." Restrict the proposed manuscript caption's and renderer's
"remainder favours uniform" to ratios greater than 1: the ratio-1 remainder
favours a directional model. Keep the constant marker unconnected and the
increase/decrease series separate, as implemented. No further display redesign
is needed for scientific clarity.

### 4. P2: preserve all manifest-listed evidence

The following files exist and match the SHA-256 manifest, but are ignored and
untracked at the reviewed commit:

- `fig_effect_size_prespecified.pdf`
- `fig_effect_size_prespecified.png`
- `launcher.log`
- `smoke/logs/lin_inc_p1_ratio10.log`

These paths are relative to `out/revision/effect-size-20261018/`. Preserve them
explicitly in Git or a documented durable evidence archive. As committed, a
fresh checkout cannot verify all 108 manifest entries or inspect the preserved
prespecified display. Correcting the prose in the figure will also change its
rendered hashes; distinguish the preserved display from a corrected rendering
and update manifests only as part of that documented revision.

## Numerical claims and editorial recommendations

Every numerical range checked in Claude's integration draft agrees with the
verified selection table. The central result is substantial: at 75% treatment,
the opposing rule reversed 93.4–100% of 1.5- and 2-fold changes, while reversing
none of the ten-fold changes. At half treatment, it still reversed 19.0–22.6%
of 1.5-fold changes. The new experiment shows how signal strength changes the
consequence of the same retention rule; it does not establish how often such
rules operate in real archaeological archives.

Retain the bounded endpoint-contrast figure as well as the new selection-rate
figure. They answer different questions. Remove duplicated boundary/tolerance
explanation from the main Results, or move the necessary detail to the SI;
moving words into a caption does not reduce a text-plus-caption word count.
Compress the historical noise paragraph only if the failed prespecified gate,
post-unblinding status of the later diagnostic and absence of extreme-retention
rules all remain explicit.

An abstract that accommodates the extension without expanding the earlier
draft is proposed below. This is an editorial candidate, not a canonical edit.

> Regional radiocarbon analyses reconstruct past human activity from dated
> evidence, but date counts do not reveal how dates were chosen. We show that
> choosing among completed determinations can create or reverse an inferred
> trend. In simulations of constant and changing histories, retaining every
> site's oldest date imposed decline and retaining its youngest imposed growth
> in every replicate, even when models used full calibrated age distributions.
> With three-quarters of sites treated, keeping the extreme opposed to the trend
> reversed 93–100% of 1.5- and 2-fold changes but no ten-fold change. At half-site
> treatment, extreme retention created apparent change from constant histories
> in over 97% of replicates. Random retention reversed at most 0.6% of replicates
> in any changing-history scenario. Keeping both extrema avoided reversals but
> obscured weak changes; at full treatment, exponential models were favoured for
> every ten-fold linear history. In 540 charcoal or wood dates from 68 Australian
> sites, oldest and youngest retention shifted the mean summed probability distribution 3,133
> years older and 2,439 years younger; one random date per site shifted it about
> 100 years. Full-site oldest and youngest retention changed temporal shape more
> than the choice among three summary methods in all nine sensitivity configurations.
> The simulations isolate independent regional dates without occupation
> histories or realised measurement scatter. Regional inference needs the
> selection history of its inputs: equal date counts and agreement among methods
> do not establish temporal representativeness.

The added Results paragraph can also be shorter than the proposed 165 words,
with the complete table in the SI rather than every rate repeated in prose:

> Weaker trends reversed with fewer sites treated (Fig. 3). With three-quarters
> treated, the opposing rule reversed 93.4–100% of 1.5- and 2-fold changes,
> 35.2–50.0% of 3-fold changes, and no ten-fold changes. At half treatment, it
> still reversed 19.0–22.6% of 1.5-fold changes. Random retention reversed at most
> 0.6% of replicates in any changing-history scenario. Bracketed retention caused
> no reversals, but at full treatment it detected only 10.6–16.8% of 1.5-fold
> changes, compared with 60.6–66.6% for count-matched random-2. Avoiding reversal
> therefore did not ensure recovery of a trend. The complete ratio-by-treatment
> results are in Supplementary Section S2.7.

Claude retains ownership of canonical integration, figure/caption repairs and
the SI extension. Integration should extend the numerical-claim register for
the new rates, scope the inherited ten-fold claims, check figure numbering,
build both PDF and Word, and measure the complete text-plus-caption word count.
The previous 82-claim audit and earlier review PDFs do not cover that future
integrated manuscript. Refresh the scientific review archive after the
integrated candidate passes; its earlier package does not contain Stage 6.
