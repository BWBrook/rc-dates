# Pipeline Summary

The active workflow lives in `_targets.R` and follows this sequence:

1. `cfg` and `raw_manifest` resolve configuration and tracked inputs.
2. `raw_tbl`, `validated`, and `validated_strict` ingest and gate the AustArch data.
   `interim_parquet` writes the validated data to intermediate storage, using
   Parquet when Arrow is enabled and safe for the host, and CSV on macOS.
3. `model_fit`, `calibrated`, `weighted_means`, `spd_summary`, `fd_summary`, and `kde_summary` produce the baseline analytical outputs.
4. Dynamic SITE_TYPE and SITE branches create overlay summaries and figures.
5. Simulation mode selection fans into one of three paths:
   - `demo`: generate reduced legacy-style simulation summary CSVs under `outputs/simulations/demo/`
   - `precomputed`: read external `simulation_summary_*.csv` files from the configured directory
   - `none`: skip simulations entirely
6. `sim_manifest`, `sim_tables`, `sim_all`, `fig_sim_overlays`, and `fig_sim_montage` provide the report-facing simulation artifacts.
7. `report_qmd`, `report_quarto_yml`, and `report` render the Quarto report directly from targets outputs.

Key reproducibility properties:

- File inputs are tracked via manifest and file-format targets.
- Intermediate storage is tracked as a file target and uses a macOS CSV
  fallback to avoid known local Arrow Parquet writer crashes.
- The report depends on `reports/paper.qmd` and `quarto.yml` contents, not just string paths.
- Simulation demo outputs are generated inside the pipeline from the filtered dataset rather than prepared manually.
- The report reads the `_targets` store directly and does not create `reports/_targets.yaml`.

## Opt-in manuscript evidence workflows

Two manuscript-scale workflows are intentionally separate from `_targets.R`:

1. `make empirical-figures` runs
   `scripts/render_manuscript_methods_figures.R`. It recalibrates the tracked
   976-date reference set, filters finite raw weighted means inclusively to
   651-11,650 cal BP before FD binning and KDE construction, and rebuilds
   `manuscript/figures/fig_1.png`, `manuscript/figures/fig_2.png`, and the
   auditable CSV/text outputs under `out/empirical-sampling/`. The primary
   1,000-realisation run and independent-seed/nested convergence checks passed.
2. `make observation-noise-rerun` runs the Docker-backed
   `scripts/run_observation_noise_sensitivity_matrix.sh`, which invokes
   `scripts/run_observation_noise_sensitivity.R` for each scenario. It creates
   nine paired checkpoints (three generating models x three site-sampling
   proportions) comparing calibration-curve expectation assays with realised
   assay noise. The focused strategies are all dates, random-1, random-3, and
   random-5; oldest, youngest, and bracketed extremes remain expectation-only
   in the production workflow. After all nine 1,000-pair checkpoints exist,
   `make observation-noise-summary` validates them, applies the paired
   cluster-bootstrap gates, and writes CSV/RDS/JSON/Markdown evidence under
   `out/sensitivity/observation-noise/summary/`.
3. `make observation-noise-estimand-aligned` retains the original v1 decision
   and writes the separately versioned post-unblinding v2 diagnostic under
   `out/sensitivity/observation-noise/estimand-aligned-v2/`. It calibrates
   difference-only within-metric intervals with 50,000 bootstrap resamples and
   repeats the calculation under an independent master seed.

The matrix is complete. The original v1 full-family screen remains FAIL
(15/18); the separately labelled v2 diagnostic passed all three
estimand-aligned gates under both bootstrap seeds. v2 is explicitly
post-unblinding and does not replace or retroactively pass v1.
