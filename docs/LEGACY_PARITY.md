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
| `simulation_main.R` and `simulation_results.R` | Archived provenance only | Intentionally not ported | These scripts describe the larger population-model simulation study. They remain out of the default reproducible workflow because of runtime and scale. |

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

## Remaining deliberate differences

- The default demo workflow is designed for accessibility, not numerical parity with the full historical simulation study.
- The archived full simulation scripts still represent the provenance source for large multi-core production runs.
- The active report presents simulation overlays and a montage rather than the exact historical resampling panel layout.
