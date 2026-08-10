# rc-dates

Testing the impact of sampling bias and estimation method on inferring
population growth trends in radiocarbon dates of archaeological sites.

## Quickstart

This project is locked to R 4.5.3, the exact release used for the final
analysis environment. On Barry's macOS machine, the root `Makefile` prefers
`/usr/local/bin/Rscript` and refuses to run direct R targets under a different
release. With `direnv`, run `direnv allow` once in this checkout so the shell
also prefers that runtime.

The default project workflow is a development/demo compendium, not the
de-identified reviewer archive. For anonymous peer review, build the minimal
code/data package with:

```sh
make review-package
```

That package rewrites the manifest to use a de-identified input table and omits
manuscript, report, reference, docs, source-control, and author-identifying
surfaces.

In an RStudio Console using R 4.5.3:

```r
renv::restore(prompt = FALSE)
source("dependencies.R")
pak::pkg_install(project_dependencies())
targets::tar_make()
quarto::quarto_render("reports/paper.qmd")
```

From a shell, prefer the Makefile wrappers so the R 4.5.3 preflight is applied:

```sh
make compendium-test
make compendium-pipeline
make compendium-report
```

Two opt-in manuscript reproducibility surfaces sit outside the default demo
pipeline:

- `make empirical-figures` rebuilds `manuscript/figures/fig_1.png` and
  `fig_2.png`, plus audit summaries under `out/empirical-sampling/`. The
  renderer filters finite raw weighted means inclusively to 651-11,650 cal BP
  before either FD binning or KDE construction.
- `make observation-noise-rerun` launches the resumable paired
  curve-mean-versus-realised observation-noise matrix, and
  `make observation-noise-summary` validates and summarises a complete matrix
  under `out/sensitivity/observation-noise/`. After v1, `make
  observation-noise-estimand-aligned` reproduces the separately versioned,
  post-unblinding v2 difference diagnostic. This focused sensitivity covers all
  dates and random-1, random-3, and random-5 only; oldest, youngest, and
  bracketed extremes remain expectation-only production scenarios.

The empirical 1,000-realisation run and independent-seed/nested convergence
checks passed. The 3-model x 3-intensity x 1,000-pair observation-noise matrix
is also complete. Accuracy and support point shifts were small and substantive
ranking, bias, RMSE, mass, strategy, and likelihood gates passed, but the
original v1 full-family decision remains FAIL (15/18). The separately labelled
v2 diagnostic used 50,000 resamples over paired differences only and passed all
three aligned gates under both bootstrap seeds; it does not replace v1.
Complete evidence is under `out/sensitivity/observation-noise/summary/` and
`out/sensitivity/observation-noise/estimand-aligned-v2/`.

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
- Manuscript-scale empirical and observation-noise modules are exposed through
  focused scripts and Make targets rather than folded into the demo pipeline.

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
    iterations: 2
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
