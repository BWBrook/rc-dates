SHELL := /bin/bash

DEFAULT_MAKEDOC_DIR := $(firstword $(wildcard /home/bwbrook/work/makedoc) $(wildcard /Users/bwbrook/work/makedoc))
MAKEDOC_DIR ?= $(if $(DEFAULT_MAKEDOC_DIR),$(DEFAULT_MAKEDOC_DIR),/Users/bwbrook/work/makedoc)
MAKEDOC_CONFIG := $(abspath settings/build.yaml)
MAKEDOC_VENV_BIN ?= $(MAKEDOC_DIR)/.venv/bin
MAKEDOC_PATH = $(if $(wildcard $(MAKEDOC_VENV_BIN)/python3),$(MAKEDOC_VENV_BIN):$(PATH),$(PATH))
MAKEDOC_OUTPUT_DIR ?= $(MAKEDOC_DIR)/dist/rc-dates
MAKEDOC_PDF_ENGINE_OUTPUT_DIR ?= .cache/latex/rc-dates
SUBMISSION_DIST ?= manuscript/submission/dist

DEFAULT_RSCRIPT := $(firstword $(wildcard /usr/local/bin/Rscript) Rscript)
RSCRIPT ?= $(DEFAULT_RSCRIPT)
R_VERSION_REQUIRED ?= 4.5.3
STAGE2_OUTPUT_DIR ?= out/revision/signed-models
STAGE6_REPRODUCED_DIR := out/reproduced/effect-size

.PHONY: help
help:
	@echo "rc-dates: manuscript and analysis commands"
	@echo
	@echo "Fast gate:"
	@echo "  make test                  Run the scientific test suite under R 4.5.3"
	@echo "  make renv-restore          Restore the frozen R environment"
	@echo
	@echo "Evidence:"
	@echo "  make concept-figure        Draw the exact-age retention illustration (Python/uv)"
	@echo "  make empirical-figures     Rebuild empirical Figure 6, SI Figure S3 and audit summaries"
	@echo "  make production-figures    Validate accepted simulations and rebuild Figures 2, 4 and 5"
	@echo "  make stage2-rerun          Run the signed-model matrix and acceptance summary"
	@echo "  make stage2-summarise      Revalidate completed Stage 2 evidence"
	@echo "  make stage6-reproduce      Rebuild and compare Stage 6 summaries and Figure 3"
	@echo "  make scientific-release   Assemble the nine-figure scientific reproduction package"
	@echo
	@echo "Manuscript:"
	@echo "  make manuscript-validate   Validate the makedoc profile"
	@echo "  make manuscript-check      Run strict makedoc checks and build"
	@echo "  make manuscript-build      Build manuscript DOCX/PDF"
	@echo "  make submission-build      Assemble journal-facing manuscript files"

.PHONY: r-preflight
r-preflight:
	@ver="$$($(RSCRIPT) --version 2>&1)"; \
	case "$$ver" in \
		*"version $(R_VERSION_REQUIRED) ("*) echo "Using $(RSCRIPT): $$ver" ;; \
		*) \
			echo "Wrong Rscript for rc-dates: $(RSCRIPT) reports '$$ver'"; \
			echo "This project is locked to R $(R_VERSION_REQUIRED)."; \
			exit 1 ;; \
	esac

.PHONY: renv-restore
renv-restore: r-preflight
	"$(RSCRIPT)" -e 'renv::restore(prompt = FALSE)'

.PHONY: test
test: r-preflight
	"$(RSCRIPT)" tests/run-tests.R

.PHONY: empirical-figures
empirical-figures: r-preflight
	"$(RSCRIPT)" scripts/render_manuscript_methods_figures.R

.PHONY: production-figures
production-figures: r-preflight
	"$(RSCRIPT)" scripts/render_population_simulation_figures.R

.PHONY: concept-figure
concept-figure:
	uv run --script scripts/render_retention_mechanism.py

.PHONY: stage2-rerun
stage2-rerun:
	RC_DATES_OUTPUT_DIR="$(STAGE2_OUTPUT_DIR)" bash scripts/run_stage2_signed_matrix.sh

.PHONY: stage2-summarise
stage2-summarise:
	docker run --rm \
		--env R_LIBS_USER=/opt/rc-dates-library/linux-ubuntu-noble/R-4.5/x86_64-pc-linux-gnu \
		--env "RC_DATES_IMAGE_ID=$$(cat $(STAGE2_OUTPUT_DIR)/container_image_id.txt)" \
		--volume "$(CURDIR):/workspace" --workdir /workspace rc-dates-sim:r4.5.3 \
		Rscript --vanilla scripts/summarise_stage2_signed_models.R \
			--input-dir="$(STAGE2_OUTPUT_DIR)"

.PHONY: stage6-reproduce
stage6-reproduce: r-preflight
	"$(RSCRIPT)" --vanilla scripts/release/rebuild_stage6_summaries.R
	"$(RSCRIPT)" --vanilla scripts/render_stage6_effect_size_figure.R "$(STAGE6_REPRODUCED_DIR)" out/reproduced/figures/fig_effect_size

.PHONY: makedoc-preflight
makedoc-preflight:
	@test -d "$(MAKEDOC_DIR)" || { echo "Missing makedoc repo: $(MAKEDOC_DIR)"; exit 1; }
	@if ! test -x "$(MAKEDOC_VENV_BIN)/python3"; then \
		command -v python3 >/dev/null || { echo "Missing python3 and makedoc virtualenv"; exit 1; }; \
	fi
	@test -f "$(MAKEDOC_CONFIG)" || { echo "Missing makedoc config: $(MAKEDOC_CONFIG)"; exit 1; }

.PHONY: manuscript-validate
manuscript-validate: makedoc-preflight
	@PATH="$(MAKEDOC_PATH)" $(MAKE) -C "$(MAKEDOC_DIR)" validate-config CONFIG="$(MAKEDOC_CONFIG)"

.PHONY: manuscript-check
manuscript-check: makedoc-preflight
	@PATH="$(MAKEDOC_PATH)" $(MAKE) -C "$(MAKEDOC_DIR)" check CONFIG="$(MAKEDOC_CONFIG)" \
		PDF_ENGINE_OUTPUT_DIR="$(MAKEDOC_PDF_ENGINE_OUTPUT_DIR)"

.PHONY: manuscript-build
manuscript-build: makedoc-preflight
	@PATH="$(MAKEDOC_PATH)" $(MAKE) -C "$(MAKEDOC_DIR)" all CONFIG="$(MAKEDOC_CONFIG)" \
		PDF_ENGINE_OUTPUT_DIR="$(MAKEDOC_PDF_ENGINE_OUTPUT_DIR)"

.PHONY: manuscript-profile
manuscript-profile: makedoc-preflight
	@PATH="$(MAKEDOC_PATH)" $(MAKE) -C "$(MAKEDOC_DIR)" profile-show CONFIG="$(MAKEDOC_CONFIG)"

.PHONY: submission-build
submission-build: manuscript-build
	@command -v pandoc >/dev/null || { echo "Missing pandoc"; exit 1; }
	@command -v xelatex >/dev/null || { echo "Missing xelatex"; exit 1; }
	@command -v pdftoppm >/dev/null || { echo "Missing pdftoppm for DOCX figure conversion"; exit 1; }
	@mkdir -p "$(SUBMISSION_DIST)"
	@test -f "$(MAKEDOC_OUTPUT_DIR)/manuscript.pdf" || { echo "Missing makedoc PDF"; exit 1; }
	@test -f "$(MAKEDOC_OUTPUT_DIR)/manuscript.docx" || { echo "Missing makedoc DOCX"; exit 1; }
	cp "$(MAKEDOC_OUTPUT_DIR)/manuscript.pdf" "$(SUBMISSION_DIST)/manuscript.pdf"
	cp "$(MAKEDOC_OUTPUT_DIR)/manuscript.docx" "$(SUBMISSION_DIST)/manuscript.docx"
	python3 scripts/normalize_docx_page_breaks.py "$(SUBMISSION_DIST)/manuscript.docx"
	python3 scripts/normalize_docx_figures.py "$(SUBMISSION_DIST)/manuscript.docx" manuscript/text/figures.md
	pandoc manuscript/submission/draft_cover_letter.md --standalone --pdf-engine=xelatex \
		-V mainfont="DejaVu Serif" -V papersize=a4 -V geometry:margin=2.5cm \
		-o "$(SUBMISSION_DIST)/cover_letter.pdf"
	pandoc manuscript/submission/draft_cover_letter.md --standalone \
		-o "$(SUBMISSION_DIST)/cover_letter.docx"
	pandoc manuscript/submission/title_page.md --standalone --pdf-engine=xelatex \
		-V mainfont="DejaVu Serif" -V papersize=a4 -V geometry:margin=2.5cm \
		-o "$(SUBMISSION_DIST)/title_page.pdf"
	pandoc manuscript/submission/title_page.md --standalone \
		-o "$(SUBMISSION_DIST)/title_page.docx"
	pandoc manuscript/submission/highlights.md --standalone \
		-o "$(SUBMISSION_DIST)/highlights.docx"
	cd manuscript/text && pandoc supplementary.md --standalone \
		--from markdown+tex_math_dollars+tex_math_single_backslash --citeproc \
		--bibliography ../../references/refs.yaml \
		--csl ../../csl/journal-of-archaeological-science.csl \
		--resource-path=.:../figures --pdf-engine=xelatex \
		-V mainfont="DejaVu Serif" -V papersize=a4 -V geometry:margin=2.5cm \
		-o "$(abspath $(SUBMISSION_DIST))/supplementary_information.pdf"
	cd manuscript/text && pandoc supplementary.md --standalone \
		--from markdown+tex_math_dollars+tex_math_single_backslash --citeproc \
		--bibliography ../../references/refs.yaml \
		--csl ../../csl/journal-of-archaeological-science.csl \
		--resource-path=.:../figures \
		-o "$(abspath $(SUBMISSION_DIST))/supplementary_information.docx"
	python3 scripts/normalize_docx_page_breaks.py "$(SUBMISSION_DIST)/supplementary_information.docx"

SCIENTIFIC_RELEASE_DIR ?= dist/rc-dates-scientific-reproducibility-2026-10-19
.PHONY: scientific-release
scientific-release:
	python3 scripts/release/build_package.py --destination="$(SCIENTIFIC_RELEASE_DIR)"
