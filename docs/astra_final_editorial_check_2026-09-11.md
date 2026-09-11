# Astra final check of Fable's editorial pass — 11 September 2026

Reviewed the working-tree edits against `d7e13aa`, Fable's itemised log and correspondence message 48. Accepted the reader-focused revision with the amendments below. Fable's log is preserved as the record of its proposed edits, including the two disputed formulations. A bounded independent GPT-5.6 Sol check identified no other material scientific regression.

## Accepted editorial changes

The abstract names the summaries; first-use glosses explain common membership, the contrast C, the endpoint log ratio and working independence. The main text names the order-statistic mechanism early, distinguishes posterior-median ordering from true age ordering, explains the curve-mean observation model and splits the likelihood paragraph. The revised Results heading, caption explanations and removal of internal SI labels are retained.

## Final amendments

- **AIC (item 15).** Kept a qualitative explanation of the fit–penalty tradeoff and removed the 16% parenthetical. The value follows from a regular nested likelihood comparison with one unnecessary parameter, where the likelihood-ratio statistic has a chi-squared-one limit and AIC adds a penalty of two. It is not a universal AIC false-selection rate. The present curve-mean observations were not generated under the fitted measurement model. “Asymptotically” alone does not supply those missing conditions. A fully qualified theoretical aside would add more explanation than this Results paragraph needs; Fable's preference remains recorded in its log.
- **Noise (item 16).** Retained the noisy-median mechanism and restored independence explicitly. The final sentence leaves both the direction and magnitude inferred by AIC untested. Fable's expectation about persistent fitted direction remains a plausible judgement, rather than evidence established by the median-ordering result.
- **Normalisation and posterior summaries.** Described the event-age density as a relative temporal distribution, retaining the unit-integral definition. Restored that empirical screening and extrema use the full calibrated posterior's median, preserving the distinction from subsequent likelihood-window restriction. Described simulated quoted errors as drawn from the empirical model rather than asserting their realism.
- **Optimisation and bracketed retention.** A bound limits the fitted contrast; it does not censor the known generating truth or identify an unconstrained optimum. Reworded the gloss accordingly. Kept the bracketed empirical comparison explicitly tied to the SPD ranges. The fourth highlight now says all sites were treated and that simulated linear trends appeared exponential, avoiding an implication that the generating process changed.

## AI disclosure and reproducibility

Followed Barry's instruction: all AI disclosure is in the end declaration, covering analysis development and manuscript preparation. Removed the residual AI pointer from Reproducibility. The declaration states that reruns require the archived code, pinned environment and required input data, without AI tools or original prompts. Code and environment alone do not reconstruct the empirical curves because source archaeological records are governed separately.

The [Elsevier policy](https://www.elsevier.com/about/policies-and-standards/generative-ai-policies-for-journals), checked on 11 September, asks for Methods disclosure when AI is used in the research process and in generating data visualisations. Reproducible execution does not by itself remove that wording. End-only placement is Barry's explicit editorial decision, with both uses fully disclosed; the submission checklist records the remaining format question. No additional approval is needed for co-author circulation.

## Verification and delivery

The manuscript and SI checks, PDF/DOCX build, layout review and co-author packet checks are recorded in the updated co-author review note. No scientific output, figure asset, gate, seed, model implementation, data record or locked environment was changed. No R analysis or simulation was rerun. The amended source is the final editorial baseline for co-author review, with the existing archaeological interpretation, author approval and possible realised-noise scope decisions preserved.

## Scientific-tests CI repair

Barry also reported the failing GitHub Actions run [34554369704](https://github.com/BWBrook/rc-dates/actions/runs/34554369704). Dependency restore succeeded, but three plotting tests failed with `package ‘grid’ does not have a namespace` and three rcarbon-dependent tests skipped.

The old `.Renviron` set `RENV_PATHS_SANDBOX=renv/sandbox`. renv retains that relative override as R's base library path. When testthat changes the working directory to `tests/testthat`, base-package lookup resolves it against the wrong directory. Removed this obsolete one-line file so renv uses its default absolute sandbox. The sandbox remains enabled; R 4.5.3, renv.lock, dependency versions, scientific code and test assertions are unchanged. The existing scientific suite on GitHub Actions checks the fix; full simulation jobs are not needed.

The source chain was checked against [renv's path handling](https://github.com/rstudio/renv/blob/v1.1.5/R/paths.R), [sandbox activation](https://github.com/rstudio/renv/blob/v1.1.5/R/sandbox.R), [testthat's directory handling](https://github.com/r-lib/testthat/blob/v3.2.3/R/local.R), and [R's base-package lookup](https://github.com/wch/r-source/blob/R-4-5-branch/src/library/base/R/library.R). Loading grid before the directory change would mask the failure through namespace caching; the retained tests exercise loading from the test directory.
