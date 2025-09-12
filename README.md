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
- Report `reports/paper.qmd` reads targets directly and includes figures.

See `docs/DEVELOPMENT.qmd` for configuration details and common commands.
