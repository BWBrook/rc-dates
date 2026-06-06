# rc-dates

Testing the impact of sampling bias and estimation method on inferring
population growth trends in radiocarbon dates of archaeological sites.

## Quickstart

This project is locked to the R 4.5.x series used for the final analysis
environment. On Barry's macOS machine, the root `Makefile` prefers
`/usr/local/bin/Rscript` and refuses to run compendium targets under a different
R minor version. With `direnv`, run `direnv allow` once in this checkout so the
shell also prefers that runtime.

The default project workflow is a development/demo compendium, not the
de-identified reviewer archive. For anonymous peer review, build the minimal
code/data package with:

```sh
make review-package
```

That package rewrites the manifest to use a de-identified input table and omits
manuscript, report, reference, docs, source-control, and author-identifying
surfaces.

In an RStudio Console using R 4.5.x:

```r
renv::restore(prompt = FALSE)
source("dependencies.R")
pak::pkg_install(project_dependencies())
targets::tar_make()
quarto::quarto_render("reports/paper.qmd")
```

From a shell, prefer the Makefile wrappers so the R 4.5.x preflight is applied:

```sh
make compendium-test
make compendium-pipeline
make compendium-report
```

Optional figure montage support uses `{magick}`. If you want that and have the
system ImageMagick development libraries installed, run:

```r
pak::pkg_install(project_dependencies(include_optional = TRUE))
```

## What’s inside

- Reproducible pipeline (`_targets.R`) with ingest -> validation -> calibration -> summaries ->
  grouped and site-level figures -> simulation mode selection (`demo`, `precomputed`, `none`) -> report.
- Modular helpers in `R/` with explicit imports; legacy scripts archived in `scripts/legacy/`.
- Config file `config/config.yml` with calibration, branching, report and simulations knobs.
- Example report `reports/paper.qmd` reads targets directly and now distinguishes generated demo simulations from precomputed summaries.
- `{magick}`-backed montages are optional; the pipeline writes placeholder montage images when it is unavailable.

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
  mode: demo
  precomputed:
    dir: data
    pattern: ^simulation_summary_.*\.csv$
  demo:
    iterations: 10
    seed: 1234
    site_proportions: [0.5, 1.0]
    strategies: [oldest, youngest, bracketed, singleton, multiton]
    singleton_n: 1
    multiton_n: 3
```

After updating config, rebuild the relevant targets:

```r
targets::tar_make()
quarto::quarto_render("reports/paper.qmd")
```

Default fresh-clone behavior is `simulate.mode: demo`, which generates a
reduced legacy-style simulation matrix under `outputs/simulations/demo/`.
Switch to `precomputed` to read external `simulation_summary_*.csv` files, or
to `none` to skip simulations entirely.
