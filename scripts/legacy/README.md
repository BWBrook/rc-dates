# Legacy Scripts (archived)

This folder preserves the original analysis and simulation scripts that
previously lived under `src/`:

- austarch_analysis.R, austarch_display.R, austarch_filtering.R,
  austarch_methods.R, austarch_sampling.R, re-sample_panel_plot.R
- simulation_functions.R, simulation_main.R, simulation_results.R

They are kept for historical reference and provenance only. The active,
reproducible workflow is now implemented as a `{targets}` pipeline
wired by `_targets.R` and modular helpers under `R/`.

For simulation results, this compendium integrates the precomputed summary
CSV files under `data/` via a read-only pipeline (`sim_*` targets). Heavy
simulation runners are intentionally disabled; see `R/legacy_simulation_helpers.R`
for pure helpers and `R/simulations.R` for the read-only integration.

Pro tip: if you need to replicate figures or code snippets, prefer to port
any remaining logic into small, pure helpers under `R/` and add targets/tests
rather than executing these legacy scripts directly.
