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

DEFAULT_REVIEW_PACKAGE_PARENT := $(firstword $(wildcard /Users/bwbrook/papers/de_identified_repos) $(wildcard /home/bwbrook/papers/de_identified_repos))
REVIEW_PACKAGE_PARENT ?= $(if $(DEFAULT_REVIEW_PACKAGE_PARENT),$(DEFAULT_REVIEW_PACKAGE_PARENT),/Users/bwbrook/papers/de_identified_repos)
REVIEW_PACKAGE ?= $(REVIEW_PACKAGE_PARENT)/rc_review_package.zip
REVIEW_PACKAGE_ABS := $(abspath $(REVIEW_PACKAGE))
PRODUCTION_RERUN_DIR ?= out/rerun

.PHONY: help
help:
	@echo "rc-dates helper targets"
	@echo
	@echo "Manuscript via makedoc:"
	@echo "  make manuscript-validate   Validate the makedoc profile"
	@echo "  make manuscript-check      Run strict makedoc checks and build"
	@echo "  make manuscript-build      Build DOCX/PDF outputs"
	@echo "  make manuscript-profile    Show resolved makedoc profile"
	@echo "  make submission-build      Build manuscript, SI, cover letter and packet files"
	@echo
	@echo "R compendium:"
	@echo "  make r-preflight          Confirm Rscript resolves to R 4.5.3"
	@echo "  make compendium-bootstrap  Restore/install R dependencies"
	@echo "  make compendium-test       Run testthat harness"
	@echo "  make compendium-pipeline   Run targets pipeline"
	@echo "  make compendium-report     Render Quarto report"
	@echo "  make production-figures    Validate RDS files and rebuild Figures 3-5"
	@echo "  make production-rerun      Run the full Docker simulation into out/rerun"
	@echo "  make review-package        Build de-identified review package zip"

.PHONY: r-preflight
r-preflight:
	@ver="$$("$(RSCRIPT)" --version 2>&1)"; \
	case "$$ver" in \
		*"version $(R_VERSION_REQUIRED) ("*) \
			echo "Using $(RSCRIPT): $$ver"; \
			;; \
		*) \
			echo "Wrong Rscript for rc-dates: $(RSCRIPT) reports '$$ver'"; \
			echo "This project is locked to R 4.5.3; use RSCRIPT=/usr/local/bin/Rscript or run under rig:"; \
			echo "  rig run -r 4.5-arm64 make <target>"; \
			exit 1; \
			;; \
	esac

.PHONY: makedoc-preflight
makedoc-preflight:
	@test -d "$(MAKEDOC_DIR)" || { echo "Missing makedoc repo: $(MAKEDOC_DIR)"; exit 1; }
	@if ! test -x "$(MAKEDOC_VENV_BIN)/python3"; then \
		command -v python3 >/dev/null || { echo "Missing python3 and makedoc virtualenv: $(MAKEDOC_VENV_BIN)/python3"; exit 1; }; \
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
	@mkdir -p "$(SUBMISSION_DIST)"
	@test -f "$(MAKEDOC_OUTPUT_DIR)/manuscript.pdf" || { echo "Missing makedoc PDF: $(MAKEDOC_OUTPUT_DIR)/manuscript.pdf"; exit 1; }
	@test -f "$(MAKEDOC_OUTPUT_DIR)/manuscript.docx" || { echo "Missing makedoc DOCX: $(MAKEDOC_OUTPUT_DIR)/manuscript.docx"; exit 1; }
	cp "$(MAKEDOC_OUTPUT_DIR)/manuscript.pdf" "$(SUBMISSION_DIST)/manuscript.pdf"
	cp "$(MAKEDOC_OUTPUT_DIR)/manuscript.docx" "$(SUBMISSION_DIST)/manuscript.docx"
	python3 scripts/normalize_docx_page_breaks.py "$(SUBMISSION_DIST)/manuscript.docx"
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
		-V mainfont="DejaVu Serif" -V papersize=a4 \
		-V geometry:margin=2.5cm \
		-o ../submission/dist/supplementary_information.pdf
	cd manuscript/text && pandoc supplementary.md --standalone \
		--from markdown+tex_math_dollars+tex_math_single_backslash --citeproc \
		--bibliography ../../references/refs.yaml \
		--csl ../../csl/journal-of-archaeological-science.csl \
		--resource-path=.:../figures \
		-o ../submission/dist/supplementary_information.docx
	@if test -f "$(REVIEW_PACKAGE)"; then \
		cp "$(REVIEW_PACKAGE)" "$(SUBMISSION_DIST)/rc_review_package.zip"; \
	else \
		echo "Warning: review package not found: $(REVIEW_PACKAGE)"; \
	fi

.PHONY: review-package
review-package: r-preflight
	@command -v zip >/dev/null || { echo "Missing zip"; exit 1; }
	R_PROFILE_USER=/dev/null "$(RSCRIPT)" scripts/build_review_package.R "$(REVIEW_PACKAGE_PARENT)"
	bash scripts/create_review_package_archive.sh \
		"$(REVIEW_PACKAGE_PARENT)/rc_review_package" "$(REVIEW_PACKAGE_ABS)"
	@echo "Built review package: $(REVIEW_PACKAGE_ABS)"

.PHONY: production-figures
production-figures: r-preflight
	"$(RSCRIPT)" scripts/render_population_simulation_figures.R

.PHONY: production-rerun
production-rerun:
	RC_DATES_OUTPUT_DIR="$(PRODUCTION_RERUN_DIR)" bash scripts/run_production_simulation_matrix.sh

.PHONY: compendium-bootstrap
compendium-bootstrap: r-preflight
	"$(RSCRIPT)" scripts/bootstrap.R

.PHONY: compendium-test
compendium-test: r-preflight
	"$(RSCRIPT)" tests/run-tests.R

.PHONY: compendium-pipeline
compendium-pipeline: r-preflight
	"$(RSCRIPT)" -e 'targets::tar_make()'

.PHONY: compendium-report
compendium-report: r-preflight
	"$(RSCRIPT)" -e 'quarto::quarto_render("reports/paper.qmd", quiet = FALSE)'
