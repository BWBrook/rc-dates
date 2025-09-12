# Legacy Scripts: What, Why, and How to Run

This folder contains the archived analysis and simulation scripts that
preceded the current `{targets}` pipeline. They are preserved for
provenance and comparison. The active, reproducible workflow now lives in
`_targets.R` with modular helpers under `R/`, and the report in
`reports/paper.qmd` reads pipeline outputs directly.

## Why are these here?
- They document the original interactive workflow (setwd, sourcing, ad‑hoc
  plotting) used during exploration.
- Portions have been migrated into pure helpers under `R/` and wired into
  the pipeline. Heavy simulation “runners” are intentionally disabled in
  the compendium; instead we integrate precomputed summaries under `data/`.

## Running these scripts (optional)
These scripts are not used by the pipeline and are provided as-is. If you
wish to run them:

1) Open a clean R session (outside the pipeline), and set your working
   directory to the project root. Some scripts still call `setwd()`—you may
   want to comment those out and instead rely on `here::here()`.
2) Ensure required packages are installed (see `dependencies.R`).
3) For simulation code, prefer sourcing `R/legacy_simulation_helpers.R`
   rather than the in-place `simulation_functions.R` (which is not shipped
   here). The file `simulation_main.R` has been adjusted to source
   `../R/legacy_simulation_helpers.R`.
4) Large computations (e.g., thousands of simulation iterations) are
   intentionally not part of the compendium; expect long runtimes and
   substantial outputs if you scale up.

Example (run a legacy simulation driver):

```r
# from project root
source("scripts/legacy/simulation_main.R")
```

## Prefer the pipeline
For reproducible results and report generation, use the `{targets}`
pipeline instead:

```r
renv::restore(prompt = FALSE)
source("dependencies.R")
pak::pkg_install(project_dependencies())
targets::tar_make()
quarto::quarto_render("reports/paper.qmd")
```

If you need functionality that only exists in a legacy script, consider
porting the minimal logic into a small, pure helper under `R/` and adding
it to the pipeline with tests.
