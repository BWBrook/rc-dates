# Historical draft: clarity and context review

11 September 2026. Current manuscript reviewed at `b4fdf7d`.

The current paper is stronger, and no old section warrants reinstatement. The earlier draft does, however, contain two useful pieces of reader orientation that would repay restoring in shorter, scientifically updated form. Together the proposed additions total 55 words. This review recommends text; it does not change the manuscript.

The comparison covered the complete [historical DOCX](/home/bwbrook/data/tmp/Brook_et_al_radiocarbon_sampling_bias_v3.docx), including its five figures, against the current main text and captions. An independent scientific review of the old Discussion checked whether its interpretations remained defensible under the revised evidence. The source DOCX was left unchanged (SHA-256 `617d7a39416c030618fb4c78b6353e2fd050707208b0f0ba1b4f5baecea7d19d`). Page references below refer to its 31-page LibreOffice PDF rendering.

## Two worthwhile restorations

**1. Explain the dates-as-data premise in everyday language.** The old Introduction, Section 1.1 (p. 4), explains the attraction as “more people were doing datable things”. The current opening names activity and population as a proxy relationship but moves immediately to applications and methods. A brief causal explanation would help archaeological readers without suggesting that the proxy is unconditional.

After the first sentence of current Section 1.1, add:

> The premise is that, other things being equal, more people leave more evidence of dateable activity, so the frequency of dates may track changes in population size.

This is 27 words. The following paragraph already explains why preservation, research effort and other processes complicate that premise. No additional literature survey is needed.

**2. Make the two analytical parts unmistakable.** The old methodological pivot in Section 1.2 (p. 6), reinforced in Section 2.1.2 (p. 7), explicitly separates descriptive curves from date-level model fitting. Current Section 2.3 specifies fitting to calibrated posteriors correctly, but readers may still assume that the simulated models are fitted to the SPD, FD or KDE curves introduced earlier.

At the end of current Section 2.1, add:

> These curves provide descriptive summaries of the empirical benchmark. In the simulations, models are fitted to individual calibrated age distributions, not to the SPD, FD or KDE curves.

This is 28 words. It links the empirical figures to the simulation results without reviving the old claim that the likelihood framework itself solves retention bias.

## Optional, lower-priority addition

Old Section 4.4 (p. 16) considers interactions with taphonomy and research effort. The current paper retains those processes as context but says little about their joint effects. If one further sentence is wanted in Section 4.3, after its opening paragraph:

> Age-dependent retention can compound or offset temporal structure produced by taphonomic loss and uneven research effort, but the present simulations do not identify those joint effects.

This is a possibility and a limit, not a reported result. Its value is smaller than the two additions above; omitting it would avoid expanding an already sufficient limitations discussion.

## Material that should remain retired

| Earlier material | Assessment under the current study |
| --- | --- |
| Broad descriptions of basal dating, legacy practices and cheaper modern dating | The experiment selects among completed determinations. It does not establish the prevalence or consequences of prospective context-selection practices. |
| A minimum of three dates per site, random sampling as span-preserving, and bracketing as an acceptable compromise | These prescriptions exceed the design. Random retention does not guarantee temporal span; full-site bracketing selected exponential models for every simulated linear history. |
| More sites merely increase confidence in a biased answer | Memorable phrasing, but site number was fixed in the simulation. The study did not test increasing site coverage or allocation of a fixed budget. |
| Oldest dates as site onsets, or the empirical all-date curve as truth | These confuse retained age summaries with archaeological occupation boundaries or a known population history. |
| A prescribed sequence of retention correction followed by taphonomic adjustment | Joint effects and correction order were not evaluated. |
| OSE-based evidential-strength claims and broad promotion of the likelihood method | They belong to superseded analyses or imply protection against retention bias that the current fits do not provide. |

The useful metadata advice survives in current Section 4.2: report site contributions, distinguish available from retained dates, document age-dependent inclusion, and test alternative selection histories. The Introduction also retains the wider methodological context. Neither needs its former length restored.

## Presentation and one small trim

The old curve and line plots are easy to approach, but the current figures communicate distinctions essential to the revised study: deformation relative to the baseline, constant and opposing histories, and direction versus generating-family selection. The old Figure 5 also reports a different evidential criterion. No figure restoration is recommended; the second proposed addition supplies the missing orientation economically.

Current Section 3.1 repeats the bracketed-retention comparison immediately after giving its numbers. Delete the sentence beginning “Its mean shift remained within the random-1 range”. The preceding sentence already reports both the mean-shift and total-variation comparisons, and the following count-matching qualification should remain.

The recommended revision is therefore two short additions and one redundant-sentence deletion. No analysis, result, figure or scientific qualification needs changing for this historical clarity pass.

## Implementation

Barry approved the two proposed additions and the redundant-sentence deletion on 11 September. They have been applied verbatim to Sections 1.1, 2.1 and 3.1. The optional taphonomy sentence was not added. The net change is 38 words; the historical DOCX remains unchanged.
