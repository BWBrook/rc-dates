# Pipeline Summary

The active workflow lives in `_targets.R` and follows this sequence:

1. `cfg` and `raw_manifest` resolve configuration and tracked inputs.
2. `raw_tbl`, `validated`, and `validated_strict` ingest and gate the AustArch data.
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
- The report depends on `reports/paper.qmd` and `quarto.yml` contents, not just string paths.
- Simulation demo outputs are generated inside the pipeline from the filtered dataset rather than prepared manually.
- The report reads the `_targets` store directly and does not create `reports/_targets.yaml`.
