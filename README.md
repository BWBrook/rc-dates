# rc-dates

Testing the impact of sampling bias and estimation method on inferring
population growth trends in radiocarbon dates of archaeological sites.

## Quickstart

In RStudio Console:

```r
renv::restore(prompt = FALSE)
source("dependencies.R")
pak::pkg_install(project_dependencies())
targets::tar_make()
quarto::quarto_render("reports/paper.qmd")
```

## What’s inside

- Reproducible pipeline (`_targets.R`) with ingest → validation → calibration → summaries →
  grouped and site-level figures → simulations (read-only) → report.
- Modular helpers in `R/` with explicit imports; legacy scripts archived in `scripts/legacy/`.
- Config file `config/config.yml` with calibration, branching, report and simulations knobs.
- Example report `reports/paper.qmd` reads some targets directly and includes figures.

See `docs/DEVELOPMENT.qmd` for configuration details and common commands.

## Configuration

Edit `config/config.yml` to control calibration curves, branching, report figures,
and simulations. Example defaults:

```yaml
calibration:
  terrestrial_curve: shcal20
  marine_curve: marine20
  time_range: [651, 11650]

branching:
  site:
    include: []     # regex patterns to include SITE names
    exclude: []     # regex patterns to exclude SITE names
    limit: null     # optional integer to limit number of SITE branches

report:
  site_figures:
    include: []
    exclude: []
    limit: 12
    montage: true
    ncol: 3

simulate:
  use_precomputed: true
  dir: data
  pattern: ^simulation_summary_.*\.csv$
```

After updating config, rebuild the relevant targets:

```r
targets::tar_make()
quarto::quarto_render("reports/paper.qmd")
```
