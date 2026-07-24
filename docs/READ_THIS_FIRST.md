# READ THIS FIRST

This document is a handover note for continuing the `rc-dates` work from a
fresh clone on Barry's macOS machines after the original WSL setup.
It records where the project is up to, what has already been fixed, and what the
next agent should do first.

## Executive Summary

`rc-dates` now has two connected but distinct workflows:

1. A reproducible R compendium for radiocarbon date analysis, driven by
   `{targets}` and `renv`.
2. A manuscript workflow, driven by Barry's separate `makedoc` repository, with
   manuscript inputs now stored inside this repo under `manuscript/`,
   `references/`, `csl/`, and `settings/`.

The compendium has been stabilised, the default pipeline runs with a small demo
simulation mode, and GitHub CI was green after the latest CI fix. The manuscript
has been moved from placeholder/demo content to real converted sources and then
cleaned enough to be a proper Markdown/manuscript source rather than raw
DOCX-conversion output.

The next major step is the first real `makedoc` DOCX/PDF build from the current
manuscript sources, followed by visual/layout cleanup.

## Current Repository State

Pre-handoff baseline commit:

```text
5f2b5ea agent: feat(manuscript): import and clean manuscript sources
```

Important recent commits:

```text
5f2b5ea agent: feat(manuscript): import and clean manuscript sources
fd9f05d agent: feat(manuscript): scaffold makedoc inputs and fix ci
a6fbd43 agent: feat(repro): harden pipeline and add demo simulation mode
```

Branch:

```text
main
```

The WSL working tree was clean immediately after commit `5f2b5ea`. This
handoff document was added afterward as the next commit.

## Repository Layout To Know

Core compendium files:

- `_targets.R` - main `{targets}` pipeline.
- `config/config.yml` - calibration, branching, report, and simulation config.
- `dependencies.R` - canonical package list used by bootstrap.
- `scripts/bootstrap.R` - project bootstrap helper.
- `tests/run-tests.R` - correct non-package test harness.
- `reports/paper.qmd` - Quarto compendium/report document.
- `docs/PIPELINE.md` - compact DAG summary.
- `docs/LEGACY_PARITY.md` - legacy-to-current crosswalk.

Manuscript files:

- `manuscript/text/main.md` - main manuscript Markdown.
- `manuscript/text/figures.md` - figure links/captions.
- `manuscript/authors.yaml` - structured author/affiliation metadata.
- `manuscript/figures/` - real imported figure assets.
- `manuscript/submission/draft_cover_letter.md` - imported cover letter draft.
- `references/refs.yaml` - CSL YAML bibliography.
- `csl/journal-of-archaeological-science.csl` - active CSL style.
- `settings/build.yaml` - `makedoc` build profile for this manuscript.

Archived provenance:

- `scripts/legacy/` - original scripts used as provenance, not active runtime.

## What Has Been Done

### 1. R Compendium Stabilisation

The repo started as legacy R scripts converted into a reproducible framework. We
reviewed and hardened that framework.

Key fixes:

- Bootstrap now installs the declared project dependencies and no longer
  snapshots `renv.lock` by default.
- `renv.lock` and `renv/activate.R` were synchronised for R 4.5.3.
- Tests run through `tests/run-tests.R`; do not use `devtools::test()` because
  this is a non-package compendium.
- Optional `{magick}` support was made non-blocking and later confirmed working
  on the WSL machine after system packages were installed.
- CSV reading and helper preload issues were fixed so tests are deterministic.
- The pipeline was made robust when simulation inputs are absent.

Verification that passed during the WSL work:

```sh
Rscript scripts/bootstrap.R
Rscript tests/run-tests.R
Rscript -e 'targets::tar_destroy(destroy = "all"); targets::tar_make()'
Rscript -e 'quarto::quarto_render("reports/paper.qmd", quiet = FALSE)'
Rscript -e 'renv::status()'
```

### 2. Review Findings Already Addressed

The old review findings about the report and pipeline were fixed before the
manuscript work resumed.

Resolved items:

- `reports/_targets.yaml` is no longer part of the tracked workflow. The report
  reads the project `_targets` store directly and should not create a
  machine-specific `_targets.yaml`.
- The report target now tracks `reports/paper.qmd` and `quarto.yml` as file
  inputs, so report source edits invalidate the target.
- Real Quarto render failures should fail the target instead of writing a fake
  placeholder HTML file.
- Analytical figure branches no longer hide SPD/FD/KDE failures behind empty
  tibbles or placeholder plots.
- `scripts/bootstrap.R` only snapshots when explicitly requested via
  `RC_DATES_BOOTSTRAP_SNAPSHOT=true`.

### 3. Demo Simulation Workflow

The active pipeline now has explicit simulation modes:

- `demo` - default fresh-clone mode.
- `precomputed` - read external `simulation_summary_*.csv` files.
- `none` - skip simulations.

Default `demo` mode generates a reduced legacy-style scenario matrix under:

```text
outputs/simulations/demo/
```

Default demo shape:

- strategies: `oldest`, `youngest`, `bracketed`, `singleton`, `multiton`
- site proportions: `0.5`, `1.0`
- iterations: `2`
- output filenames like `simulation_summary_oldest_50.csv`

The full population-model simulation study is intentionally not in the default
pipeline. The demo workflow is for accessible reproduction and orientation,
not numerical parity with the production-scale simulations. The production
path is now executable and documented separately:

```sh
# Validate supplied RDS artefacts and rebuild manuscript Figures 3-5.
Rscript scripts/render_population_simulation_figures.R

# Optional expensive Linux/Docker rerun, written away from supplied artefacts.
RC_DATES_OUTPUT_DIR=out/rerun \
  bash scripts/run_production_simulation_matrix.sh
```

See `docs/PRODUCTION_SIMULATIONS.md` for the scenario matrix, seed design,
checkpoint behaviour, and Figure 5 aggregation rule.

### 4. CI Repair

GitHub Actions initially failed because the workflow bypassed the repo's actual
test harness and did not explicitly activate `renv`.

The workflow was updated to:

- source `renv/activate.R` before tests and manifest checks;
- run `tests/run-tests.R`;
- activate the same dependency context as local validation.

Barry confirmed the updated GitHub CI landed clean and green.

### 5. Manuscript Migration Into `makedoc`

Barry had a fully drafted Word manuscript. Converted manuscript artefacts were
placed in `/mnt/c/output` on the WSL machine and then imported here.

The placeholder `makedoc` scaffold was replaced with real content:

- real manuscript Markdown in `manuscript/text/main.md`;
- real bibliography in `references/refs.yaml`;
- real Journal of Archaeological Science CSL in `csl/`;
- real figures in `manuscript/figures/`;
- draft cover letter in `manuscript/submission/`;
- active build profile in `settings/build.yaml`.

The placeholder CSL and placeholder figures were removed.

### 6. Manuscript Cleanup Already Done

The converted manuscript was cleaned from "algorithmic DOCX-to-Markdown" into
usable Markdown.

Completed cleanup:

- headings and section levels normalised;
- front matter split into `manuscript/authors.yaml`;
- figure links/captions split into `manuscript/text/figures.md`;
- embedded/base64 image blocks removed from `main.md`;
- hard-coded author-year citations converted to Pandoc/CSL tokens;
- obvious conversion artefacts cleaned;
- broken likelihood notation restored in LaTeX;
- methods/results prose cleaned source-aware;
- discussion prose cleaned source-aware.

Important notation restored:

```tex
\ell_i^1 = \log \int f(x \mid \theta)\, p_i(x)\, dx
\ell_i^2 = \int \log\!\bigl(f(x \mid \theta)\bigr)\, p_i(x)\, dx
\mathrm{AIC} = -2\ell + 2k
\Delta \mathrm{AIC} \le \mathrm{SE}(\Delta \mathrm{AIC})
```

Also preserved/fixed:

- `$\chi^2$`
- `$\Delta R$`
- `$^{14}$C`
- `$\ell^1$` and `$\ell^2$` references in text and figure captions.

Pandoc validation that passed:

```sh
pandoc --citeproc \
  --bibliography=references/refs.yaml \
  --resource-path=manuscript/text \
  manuscript/text/main.md manuscript/text/figures.md \
  -o /tmp/rc_dates_discussion_cleanup.docx
```

## Known Decisions And Constraints

### Do Not Accidentally Revert These

- `reports/_targets.yaml` should stay absent/untracked.
- `scripts/legacy/` is provenance; do not edit it for active workflow changes
  unless Barry explicitly asks.
- The default simulation mode should stay `demo` unless deliberately changed.
- Bootstrap should not mutate `renv.lock` unless explicitly requested.
- `docs/CHANGELOG.md` and `docs/AGENT_NOTES.md` should be updated for meaningful
  behaviour, workflow, or manuscript-source changes.

### Citation Mappings Worth Eyeballing Later

The CSL conversion resolved cleanly, but these were best-guess mappings from
ambiguous author-year references and are worth a human glance before submission:

- `Williams, 2013` -> `@williams2013NewPopulationCurve`
- `Williams et al., 2015` -> `@williams2015HoloceneDemographicChanges`
- `Torfing, 2015` -> `@torfing2015NeolithicPopulationSummed`

### Manuscript Text Scope So Far

Cleanup has been conservative. It fixed conversion damage and obvious
mechanical problems, but it has not yet become a full editorial rewrite.

Not yet done:

- full copyedit for style, concision, and journal tone;
- consistency pass on figure numbering/cross-references;
- detailed reference audit beyond citation-token resolution;
- full review of the cover letter;
- final Zenodo/archive link in Data accessibility;
- first visual inspection of rendered DOCX/PDF output.

## How To Resume On macOS

### Clone And Restore The R Compendium

From the macOS machine:

```sh
git clone git@github.com:BWBrook/rc-dates.git
cd rc-dates
```

Then in R or from shell:

```sh
make compendium-bootstrap
make compendium-test
make compendium-pipeline
make compendium-report
```

Notes:

- The project expects R >= 4.5 and currently has a lockfile refreshed for
  R 4.5.3. On Barry's macOS machine, the root `Makefile` prefers
  `/usr/local/bin/Rscript`, and `.envrc` can put `/usr/local/bin` first for
  interactive shells after `direnv allow`.
- If bootstrap asks about optional `{magick}` support, it is useful for montages
  but should not block core work.
- On macOS, system libraries for packages such as `{magick}` may need Homebrew
  packages. Treat those as local setup issues, not project-code failures.

### Clone Or Locate `makedoc`

The manuscript build uses Barry's separate `makedoc` repo. On WSL it lived at:

```text
/home/bwbrook/work/makedoc
```

On macOS, the default path is `/Users/bwbrook/work/makedoc`. Then run
`makedoc` from the `makedoc` repo root while pointing `CONFIG` at this repo's
build profile.

Example shape:

```sh
cd /path/to/makedoc
CONFIG=/path/to/rc-dates/settings/build.yaml make validate-config
CONFIG=/path/to/rc-dates/settings/build.yaml make check
CONFIG=/path/to/rc-dates/settings/build.yaml make all
```

The profile is config-relative. Do not rewrite paths in `settings/build.yaml`
just because the shell working directory changed.

Expected outputs, based on the prior scaffold run, should be under something
like:

```text
makedoc/dist/rc-dates/
```

Exact output location depends on the current `makedoc` implementation and the
profile's `output_dir`.

## Recommended Next Steps

1. Run `makedoc` validation and the first real DOCX/PDF build.
2. Visually inspect the DOCX and PDF outputs.
3. Fix rendering/layout issues in source Markdown or local build settings.
4. Check that figures appear in the intended order and quality.
5. Review author block, affiliations, line numbering, page numbering, margins,
   figure placement, and reference formatting.
6. Perform a light scientific/editorial pass only after the render path is
   stable.
7. Fill in the Zenodo/archive placeholder in Data accessibility once the
   archive exists.

## Useful Commands

Compendium:

```sh
make compendium-bootstrap
make compendium-test
make compendium-pipeline
make compendium-report
/usr/local/bin/Rscript -e 'renv::status()'
```

Manuscript source parse check:

```sh
pandoc --citeproc \
  --bibliography=references/refs.yaml \
  --resource-path=manuscript/text \
  manuscript/text/main.md manuscript/text/figures.md \
  -o /tmp/rc_dates_manuscript_check.docx
```

`makedoc` build, from the `makedoc` repo root:

```sh
CONFIG=/path/to/rc-dates/settings/build.yaml make validate-config
CONFIG=/path/to/rc-dates/settings/build.yaml make check
CONFIG=/path/to/rc-dates/settings/build.yaml make all
```

macOS helper targets, from this repo root:

```sh
make manuscript-validate
make manuscript-check
make manuscript-build
make manuscript-profile
```

These helper targets assume `makedoc` is at `/Users/bwbrook/work/makedoc` and
prepend its repo-local `.venv/bin` to `PATH` before calling `make` there.

Git hygiene:

```sh
git status --short
git log --oneline -8
```

## Final Orientation For The Next Agent

The immediate goal is no longer "make the repo runnable"; that phase is done.
The immediate goal is now "turn the real converted manuscript into a reliable
`makedoc` manuscript workflow and inspect the first rendered outputs."

Be careful not to reopen already-settled infrastructure questions unless a Mac
setup issue exposes a genuine portability bug. The most valuable next work is
likely document-build inspection and source/layout cleanup.
