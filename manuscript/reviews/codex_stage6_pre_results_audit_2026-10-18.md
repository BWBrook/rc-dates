# Stage 6 implementation audit before inspecting results

Date: 18 October 2026, Australia/Hobart.
Reviewed checkout: `28820af`, including Stage 6 specification/implementation
commit `f065c2c`. Codex commissioned an independent read-only code review while
continuing the editorial pass. No new Stage 6 outcomes or remote systems were
inspected and no simulation jobs were changed.

**Decision:** repair the acceptance and display gaps below before declaring
Stage 6 accepted or using its results in the manuscript. These findings do not
identify a defect in the running simulation kernel or require a rerun.
Posted to Claude in correspondence discussion 88, message 1980; Claude owns
the Stage 6 fixes.

## Findings

1. **P1: bind artefacts to the expected scenario.**
   `scripts/summarise_stage6_effect_size.R:55` checks frozen provenance and
   ratio but not the expected truth and treatment proportion. The underlying
   validator at `R/population_simulation_artifacts.R:245` checks internal
   consistency with an artefact's own provenance. Swapping valid same-ratio
   files and their sidecars between truth/proportion filenames can therefore
   pass, after which summary labels come from the filename grid at line 97.
   Require stored truth/proportion to match each expected grid row, including
   the accepted reference cells.

2. **P1: require evidence for the prespecified smoke comparison.**
   The launcher at `scripts/run_stage6_effect_size.sh:43` produces the
   20-replicate smoke output but does not compare it. The summariser explicitly
   starts at acceptance checks 2–4 and can declare technical acceptance
   without consuming the comparison. Claude reports that a separate comparison
   was bit-identical; this audit does not dispute that report or establish
   whether its evidence exists elsewhere. Acceptance should require every
   result column to match accepted replicates 1–20, or consume a saved
   machine-verifiable comparison bound to the relevant artefact hashes.

3. **P2: enforce the frozen production matrix.**
   `STAGE6_NSIM` and `STAGE6_RATIOS` at summariser lines 16–19 redefine the
   expected grid. Consequently a reduced diagnostic run can receive the same
   acceptance declaration as the amended 48-scenario, 500-replicate design.
   Enforce the frozen matrix for production acceptance; label reduced modes
   incomplete if they are retained.

4. **P2: implement the amended figure estimands and sample sizes.**
   `scripts/render_stage6_effect_size_figure.R:36` connects all ratios,
   including the constant-history reference at ratio 1. This joins uniform
   selection to correct-direction selection despite the written amendment.
   The caption at line 49 also says 1,000 replicates at every point. Draw lines
   only for ratios greater than 1, keep the constant-history points isolated,
   and identify 500 replicates at new ratios versus 1,000 in accepted cells.

## Reassuring static findings and limits

The launcher enumerates the intended 48 scenarios and passes the effect ratio
into the generation specification. Ratio-independent seeds `1234 + i`,
L'Ecuyer-CMRG and inverse-CDF generation preserve the intended structural
pairing. The accepted runner validates checkpoints, writes them by atomic
rename and validates final replicate identifiers and provenance; its artefact
validation requires matching metadata and output hashes.

Selection summaries use one selected result per replicate, rule and score.
The definitions of correct direction, reversal, uniform selection and
generating-family selection are consistent, including the uniform-history
reference. Density parameters and endpoint-ratio orientation match the
specified increasing/decreasing truths. These are code-level findings, not a
verification of completed output.

The ratio-10 smoke replay checks computational reproducibility of one accepted
cell. It does not establish the weaker-signal findings. Once the complete
outputs and corrected acceptance code are available, they still require the
prespecified checks and an independent evidence audit.
