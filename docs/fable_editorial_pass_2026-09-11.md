# Fable editorial pass — 11 September 2026

Direct edits to `manuscript/text/main.md`, `figures.md`, `supplementary.md` and
`manuscript/submission/highlights.md`, starting from commit `d7e13aa`. Target readers, in order:
archaeologists with limited statistics, radiocarbon specialists, statistical methodologists. No
number, claim boundary, figure or prespecified decision was changed. Each edit is listed so Barry and
Astra can accept, amend or revert it individually; `git diff d7e13aa -- manuscript/` shows the exact
text.

## Edits for the archaeological reader

1. **Abstract.** "simulations of constant, increasing and decreasing regional dating activity" →
   "simulations in which the true regional history was constant, increasing or decreasing through
   time". "three summary methods" → named the three summaries. "summed-probability curve's mean" →
   "mean of the empirical summed probability distribution".
2. **2.1.** Dropped the repo word "tracked". Defined "common-membership benchmark" at first use
   ("because exactly these dates entered every summary method").
3. **2.2.** Added a one-sentence plain reading of the conservative contrast $C$ after its formal
   definition, and gave the symbol $C$ where it is defined so the Results usage has an antecedent.
4. **2.3.** Glossed "regional event-age density" ("how the rate of dated events changed through
   time"); replaced "We defined the common effect" with a sentence saying what $\theta$ is.
5. **3.1.** "Displacement and shape deformation therefore tell different stories" → a sentence that
   says what the two findings are.
6. **3.2 heading.** "Retention controls selected direction" → "The retention rule controlled the
   inferred direction". Body: "selected no reversed non-uniform trajectories" → "never reversed a
   changing history, although it increasingly selected a constant one instead".
7. **3.2.** Glossed "optimisation boundary" (fitted contrast hit the optimiser's limit, magnitude
   censored).
8. **4.2.** "assume that the retained observations are regional draws" → "assume that the retained
   dates are a representative sample of the regional distribution".
9. **Highlights.** Replaced the vague fourth highlight with "Keeping both extremes kept direction but
   turned linear change into exponential."

## Edits for the radiocarbon specialist

10. **2.2.** Added: a median summarises a possibly multimodal posterior, so "oldest" and "youngest"
    are rules about calibrated summaries, not claims about true age order within a site.
11. **2.3.** Spelled out what the calibration-curve-mean observation model does and does not
    include: realistic quoted error and full posterior shape, but central conventional age equal to
    the curve mean with no added measurement scatter; pointer to Supplementary S3. This makes the
    abstract's "omitted realised measurement noise" intelligible.
12. **Fig. 4 caption.** Glossed $\theta$ in words (log ratio of recent-end to old-end density;
    positive = increase towards the present).

## Edits for the statistical reader

13. **1.2.** Added one sentence naming the mechanism at the outset: the retained values are extreme
    order statistics whose distribution differs systematically from the parent.
14. **2.3.** Split the long likelihood paragraph before "We measured…"; glossed "working
    independence" as "as if they were independent draws".
15. **3.3.** Added the asymptotic AIC false-selection rate "(asymptotically in about 16% of cases for
    a single added parameter)". **Preserved difference with Astra**, who declined to quote the figure
    on the ground that the asymptotic heuristic is not an exact expectation for this
    calibrated-posterior workflow. I include it because a statistical referee will compute it and the
    observed 15.2% is informative; "asymptotically" carries the qualification. Strike if Astra still
    objects.
16. **4.3.** Rewrote the compressed sentence on noise and order statistics into two plain sentences:
    identical per-date noise preserves within-site exchangeability, so the retained value stays an
    extreme order statistic and we expect the direction of the distortion to persist; the size of the
    effect on fitted models is untested. **Preserved difference with Astra**: "expect … to persist" is
    my judgement; Astra would stop at "untested". Moderate to taste.
17. **SI.** Removed the last four uses of "signed" as a label (S2.4 ×2, S3 ×2) and the repo word
    "tracked" (S1.1 ×2, S2.1, Fig. S2). Left "slopes and rates were signed" in S2.2, which is
    correct usage.
18. **Fig. 5 caption.** "Rows are generating truths" → "Rows are the five generating histories", to
    match Fig. 3 and the main text's vocabulary.

## AI-use statement moved (Barry's instruction, mid-pass)

19. Removed the AI paragraph from 2.4 Reproducibility and merged it into the end-of-paper
    declaration, which now distinguishes the two roles (developing the analysis; preparing the
    manuscript) and states that the evidence is reproducible from the archived code without any AI
    tool. 2.4 retains one pointer sentence. **Note for Astra and Barry:** Elsevier's current policy
    asks that AI used "as part of the research methodology" be described in Methods, which was
    Astra's reason for keeping it there. Barry's position is that the tools assisted the authors'
    development process and are not part of the reproducible method. Both roles are now disclosed
    under the mandated declaration heading; if the journal objects at submission, the "developing the
    analysis" sentence can be copied back into 2.4 verbatim.

## Not changed, deliberately

- All numbers, the frozen gate language in 3.1 and S1.3/S1.4, and the v1/v2 register in S3.
- Section order (empirical first). Astra's bridging sentence at the start of 3.2 does the job.
- Keyword "palaeodemography". Astra's indexing argument is reasonable.
- Cover letter. Already short and journal-focused.

## Verification

`make manuscript-check` passed after the edits (37 builder tests, manuscript/SI lint, citation checks,
DOCX build). The first run flagged the new AI declaration as a possible manual author-year citation
because of a "Name … 2026" parenthetical; the sentence was rephrased and the check rerun clean. Edits
are left uncommitted for Barry and Astra to review. No simulation or R analysis was run.
