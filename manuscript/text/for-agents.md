---
document: agent-facing paper
study: post hoc retention of radiocarbon dates and regional dates-as-data inference
status: internal draft; journal version in preparation for the Journal of Archaeological Science
human_paper: manuscript/text/main.md (+ supplement.md, brief.md)
claims_ledger: manuscript/claims.csv (single source for all renderings; checked by tools/claims.py)
interpretation: manuscript/estimands.md (what each analysis bounds; allowed and forbidden phrasings)
governing_docs: [AGENTS.md, docs/SUBMISSION_WORKFLOW.md, docs/STAGE2_SIGNED_MODELS.md, docs/STAGE6_EFFECT_SIZE.md, docs/STAGE7_REALISED_NOISE.md]
authority: Barry W. Brook decides public release, submission and any correspondence outside the collaboration
updated: 2026-11-08
---

# Choosing among a site's radiocarbon dates, for agents: what this study established, how to verify it, and how not to break it

This is the version of the paper written for an agent arriving cold. The human paper argues; this one indexes. It says
what is claimed, where each number lives, which commands regenerate it, what has been superseded, and where the open
edges are. When this file and a primary artefact disagree, the artefact wins and this file is wrong: fix it in the same
commit.

## 1. Read order and trust

1. This file, then `manuscript/estimands.md`, then `manuscript/claims.csv`. Quote a claim only with its limit.
2. `manuscript/text/main.md` for the argument; `supplement.md` for the machinery (S1 empirical, S2 simulation, S2.7
   weaker trends, S2.8 realised scatter, S3 the failed earlier noise gate).
3. The stage documents in `docs/` (`STAGE2_…`, `STAGE6_…`, `STAGE7_…`) for each analysis's prespecification,
   amendments and acceptance record; `docs/SUBMISSION_WORKFLOW.md` for where the paper stands now.
4. `manuscript/reviews/` for audits; the Codex audits of Stage 6 are the model for an independent result check.

`status` is *supported* (checked against its evidence by an agent or person other than its author), *provisional*
(awaiting that check), *refuted* or *superseded*. `basis` says what kind of result it is and who checked it.
`release/claims.csv` is an older, finer-grained numeric registry (111 row-filter checks) that still runs in
`make manuscript-check`; it and the ledger must agree.

## 2. The answer, as claims

- **Does choosing among a site's dates change the regional curve?** Yes, in the AustArch benchmark: full-site oldest
  and youngest retention shifted the SPD mean 3,133 years older and 2,439 years younger (C02), against about a century
  for one random date per site (C03), and changed shape more than the choice among SPD, FD and KDE in all nine
  sensitivity configurations (C04–C06). Half-site treatment moved it less (C07).
- **Can retention set the inferred direction?** In simulation, full-site oldest (youngest) retention imposed decline
  (growth) in every replicate, reversing opposing trends at every tested ratio (C10, C18). For ten-fold trends, reversal
  needed every site treated (C11); for weaker trends it did not: at three-quarter treatment, 93.4–100% of 1.5- and
  2-fold changes were reversed (C19), and at half treatment 19.0–22.6% of 1.5-fold changes (C20).
- **Do random or bracketed rules avoid it?** Random rules reversed at most 0.6% of replicates, and bracketed none (C21).
  Avoiding reversal is not recovering direction: full bracketed retention detected 10.6–16.8% of 1.5-fold changes,
  against 60.6–66.6% for count-matched random-2 (C22), and never recovered linear form at three-quarter or full
  treatment (C13, C23).
- **Do the results survive realised measurement scatter?** In the ten-fold design, all 75 headline rates moved by at
  most 0.001 (C25). The earlier v1 noise gate, which did not test extreme rules, remains failed (C26).
- **Why?** An extreme is not a typical draw: of five uniform ages, the oldest is in the oldest fifth with probability
  about two in three (C27).

## 3. Vocabulary that the files use

| Term | Meaning |
|---|---|
| retention rule | which of a site's completed dates are kept: `r_all`, `r_1`, `r_2`, `r_3`, `r_5` (random-k), `r_old`, `r_young`, `r_bracket` (both extrema) |
| treated / `prop` | proportion of sites to which the rule is applied (0.5, 0.75, 1); untreated sites keep all dates |
| adverse / opposing rule | the one-sided rule running against the true trend: `r_old` for increasing truths, `r_young` for decreasing |
| concordant rule | the one-sided rule running with the trend |
| truth | generating density: `uni`, `lin_inc`, `lin_dec`, `exp_inc`, `exp_dec`; "increase" means more density towards the present (low cal BP) |
| ratio | end-to-end density ratio $f(651)/f(11650)$ over 651–11,650 cal BP; 10 in the main experiment, 1.5–5 in Stage 6. Not a growth rate |
| `l1`, `l2` | primary marginal log likelihood (fitted to calibrated posteriors) and the expected-log-density scoring sensitivity |
| correct state | uniform selected for `uni`, otherwise the correct direction regardless of family |
| family rate | generating family (linear or exponential) selected, regardless of direction |
| $c$ | bounded endpoint contrast $\tanh(\theta/2)$; $\pm9/11$ for ten-fold truths |
| $C$ | conservative contrast: smallest retention distance minus largest between-method distance (empirical) |
| `curve_mean`, `realised` | observation models: conventional age at the calibration-curve mean, or drawn around it with quoted and curve error |
| Stage 2, 6, 7 | the accepted main simulation, the signal-strength extension and the realised-scatter rerun |
| benchmark | the 540-date, 68-site common-membership AustArch subset (C01) |

## 4. Provenance map

| Result | Inputs | Code | Output | Claims |
|---|---|---|---|---|
| empirical benchmark and retention | `data/austarch_filtered.csv` (from the ADS AustArch file; `data/AUSTARCH_PROVENANCE.md`) | `scripts/render_manuscript_methods_figures.R` (`make empirical-figures`) | `out/empirical-sampling/` | C01–C08 |
| main simulation | `data/austarch_filtered.csv`; `R/population_*.R` | `scripts/run_population_simulation.R` via `scripts/run_stage2_signed_matrix.sh`; summary `scripts/summarise_stage2_signed_models.R` | `out/revision/signed-models/` | C09–C14, C16 |
| endpoint contrasts | Stage 2 RDS | `scripts/render_population_simulation_figures.R` | `out/revision/endpoint-contrast-20260919/` | C15 |
| weaker trends | as Stage 2 | `scripts/run_stage6_effect_size.sh`, `scripts/summarise_stage6_effect_size.R`, `scripts/render_stage6_effect_size_figure.R` | `out/revision/effect-size-20261018/` | C17–C24 |
| realised scatter | as Stage 2 | `scripts/run_stage7_realised_noise.{R,sh}`, `scripts/summarise_stage7_realised_noise.R` | `out/revision/realised-noise-20261023/` | C25 |
| earlier noise gate | frozen snapshot | `provenance/observation-noise-20260726/` | `out/sensitivity/observation-noise/` | C26 |
| brief figure | `out/empirical-sampling/figure{1_baseline,2_sampling}_curves.csv` | `scripts/render_brief_figure.py` | `manuscript/figures/figB1_brief.png` | C01–C03 |

Row filters that select the primary results (most misquotations drop one):

- Simulation rates: `type == "l1"`; one selected model per (sim, type, strategy) with `min == 1`. Stage 6 ranges in the
  text span the four changing truths for one (prop, ratio, role). Uniform truth appears at ratio 1 in the dose table.
- Empirical shifts and distances: `method == "SPD"`, `comparison == "mean_calBP_shift_vs_all"` or `"retention_vs_all"`,
  `proportion == 1` for full-site rules.

## 5. Traps: superseded results and known misreadings

1. **"Reversal happens only when every site is treated."** True only for ten-fold trends. Weaker trends are reversed at
   three-quarter and half treatment (C19, C20). Governs: `estimands.md`, weaker trends.
2. **"No reversal at partial treatment, so that proportion is safe."** Absence of reversal is not recovery: at
   three-quarter treatment up to 21.2% of ten-fold trends were read as constant (C19), and bracketed retention detected
   few weak trends (C22). No tested proportion is a safe threshold.
3. **"Bracketed retention preserves the history."** It preserves direction for ten-fold trends but always selects the
   exponential family for linear histories at three-quarter or full treatment (C13, C23), and its uniform selection for
   a constant history does not establish shape: the pooled extrema are U-shaped, outside the candidate set (SI S2.6).
4. **"The noise sensitivity passed."** v1 met 15 of 18 criteria and remains failed; v2 is a post-unblinding diagnostic
   (C26). Stage 7 is a separate, prespecified test of the extreme rules and does not rescue v1 (C25).
5. **Percentages versus proportions.** Evidence files hold proportions (0.934); prose quotes percentages (93.4%). The
   ledger lists both, with the percentage marked derived (`~`).
6. **"2,439 years younger" versus −2439.** The youngest shift is negative in the evidence and quoted unsigned in prose.
7. **The figure-2 sampling CSV labels random rules `strategy == "random"`**; select random-1 by `strategy_label`.
8. **Loading `rcarbon` consumes random numbers.** Load it before `set.seed` when regenerating paired datasets, as the
   production replicate functions do (Stage 7 amendment).
9. **Accepted sources are fingerprinted.** Editing any file in `R/population_*` or `scripts/run_population_simulation.R`
   breaks the Stage 2 summary rebuild, which checks active sources against checkpoint fingerprints. New analyses get
   their own runner (as Stage 7 did).
10. **A results file present is not a complete scenario.** Runners checkpoint into the final filename; check replicate
    IDs before reading rates (Stage 6 progress-count error).

## 6. Checks before and after any change

```sh
make manuscript-check     # claims ledger, render scan, makedoc lint and citation audit, 111-check numeric registry
make manuscript-build     # article, supplement and brief into manuscript/build/, brief two-page check
make test                 # scientific tests under R 4.5.3
python3 scripts/release/count_manuscript_words.py manuscript/build/manuscript.docx   # JAS limit 5,000; abstract 250
```

On a machine whose `/tmp` is a tmpfs, set `TMPDIR` to a directory on the repository's filesystem before building.

Invariants: seeds `production_simulation_seed(truth, prop, sim, 1234)` under `L'Ecuyer-CMRG` with common random numbers
across rules; 48 rows per replicate; accepted evidence directories have `SHA256SUMS` manifests that must verify;
`r_all` results are identical across treatment proportions.

## 7. Open edges

- **Correlated calibration-curve errors, laboratory offsets and outliers** are untested (C25 limit). The smallest
  useful check would perturb the curve jointly per replicate in the Stage 7 runner.
- **Occupation histories and stratigraphy.** Dates are exchangeable regional draws; a site-process model would test
  whether site structure changes the reversal results.
- **Prevalence.** How often archives hold extreme-retained dates is unknown; it needs archival metadata, not simulation.
- **Weaker trends under realised scatter** (Stage 7 covered ten-fold only).
- **Ledger convergence.** `release/claims.csv` (row-filter checks) and `manuscript/claims.csv` (result-level claims)
  overlap; merging them into value bindings is pending.

## 8. Conduct in this repository

- Read `AGENTS.md`. Facts and citations come from sources read in the task; the bibliography is a Zotero export
  (`references/refs.yaml`) with DOIs listed in `references/dois.txt`.
- To add or change a claim: edit `manuscript/claims.csv`, reverify the evidence, run
  `python3 tools/claims.py stamp manuscript/claims.csv ID`, then make every document pass the check.
- Change `manuscript/estimands.md` before changing how a result is described.
- New analyses: prespecify in `docs/STAGE<n>_….md`, commit before running, record amendments before any result is
  inspected, verify independently, then ledger, then products.
- Do not edit generated artefacts by hand: `references/refs.yaml`, `manuscript/figures/`, `manuscript/build/`, `out/`.
