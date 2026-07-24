# Legacy Parity Crosswalk

This note records how the archived `scripts/legacy/` workflow maps onto the current reproducible compendium.

## Crosswalk

| Legacy component | Current equivalent | Status | Notes |
| --- | --- | --- | --- |
| `austarch_filtering.R` | `R/austarch_filters.R`, `R/validation.R`, `R/io.R` | Functionally superseded | Ingest, filtering, calibrated-date range trimming, and site-level gating are now pure helpers with tests. |
| `austarch_methods.R` baseline analysis helpers | `R/model_fit.R`, `R/analysis_summaries.R`, `R/plots_methods.R` | Functionally superseded | SPD/FD/KDE generation and overlay plotting are preserved with explicit config for curves and time range. |
| `austarch_analysis.R` interactive main script | `_targets.R`, `reports/paper.qmd` | Functionally superseded | The analytical flow is now expressed as tracked targets and a report sourced entirely from the pipeline. |
| `austarch_sampling.R` and the simulation workflow portions of `austarch_methods.R` | `R/simulation_demo.R`, `R/simulations.R`, `_targets.R` | Partially ported | The active repo now generates a reduced, legacy-style demo simulation matrix by default. The full heavy study remains out of the default pipeline. |
| `re-sample_panel_plot.R` | `fig_sim_overlays`, `fig_sim_montage`, report simulation section | Partially ported | Current outputs expose each scenario-size combination and a montage, but do not recreate the exact old patchwork panel as a tracked artifact. |
| `simulation_main.R` and `simulation_results.R` | `R/population_simulation_production.R`, `scripts/run_population_simulation.R`, `scripts/run_production_simulation_matrix.sh`, `scripts/render_population_simulation_figures.R` | Ported as an opt-in production path | The 3 x 3 high-volume matrix remains outside the default target graph, but now has deterministic seeds, resumable checkpoints, an R 4.5.3 container, validated RDS artefacts, and reproducible Figures 3-5. |

## Drift Classification

- Intentional simplification worth keeping:
  - Default data input remains the small example dataset for fast onboarding.
  - Demo simulations use reduced iteration counts and a safe default `multiton_n = 3` so the example dataset can run end-to-end.
- Missing reproducibility feature now addressed:
  - Fresh clones now generate visible simulation outputs in default mode instead of rendering an empty simulation section.
  - Simulation configuration is explicit and mode-based (`demo`, `precomputed`, `none`) instead of a single read-only flag.
- Documentation and provenance gaps now addressed:
  - The current pipeline shape is summarised in `docs/PIPELINE.md`.
  - This crosswalk documents which legacy scripts are superseded, partially ported, or intentionally archived.
  - The high-volume population-model study is documented in
    `docs/PRODUCTION_SIMULATIONS.md` and can be verified from supplied RDS files
    without rerunning the expensive simulation matrix.

## Remaining deliberate differences

- The default demo workflow is designed for accessibility, not numerical parity with the full historical simulation study.
- The archived scripts remain historical provenance; the tested production
  helpers and runners are now the executable source for large multi-core runs.
  Their likelihoods and optimisations are method-equivalent to the archived
  calculations, but the deterministic seed stream is not claimed to reproduce
  unavailable historical RDS files bit for bit.
- The active report presents simulation overlays and a montage rather than the exact historical resampling panel layout.
