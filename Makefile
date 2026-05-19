SHELL := /bin/bash

MAKEDOC_DIR ?= /Users/bwbrook/work/makedoc
MAKEDOC_CONFIG := $(abspath settings/build.yaml)
MAKEDOC_VENV_BIN ?= $(MAKEDOC_DIR)/.venv/bin
MAKEDOC_PATH = $(if $(wildcard $(MAKEDOC_VENV_BIN)/python3),$(MAKEDOC_VENV_BIN):$(PATH),$(PATH))

.PHONY: help
help:
	@echo "rc-dates helper targets"
	@echo
	@echo "Manuscript via makedoc:"
	@echo "  make manuscript-validate   Validate the makedoc profile"
	@echo "  make manuscript-check      Run strict makedoc checks and build"
	@echo "  make manuscript-build      Build DOCX/PDF outputs"
	@echo "  make manuscript-profile    Show resolved makedoc profile"
	@echo
	@echo "R compendium:"
	@echo "  make compendium-bootstrap  Restore/install R dependencies"
	@echo "  make compendium-test       Run testthat harness"
	@echo "  make compendium-pipeline   Run targets pipeline"
	@echo "  make compendium-report     Render Quarto report"

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
	@PATH="$(MAKEDOC_PATH)" $(MAKE) -C "$(MAKEDOC_DIR)" check CONFIG="$(MAKEDOC_CONFIG)"

.PHONY: manuscript-build
manuscript-build: makedoc-preflight
	@PATH="$(MAKEDOC_PATH)" $(MAKE) -C "$(MAKEDOC_DIR)" all CONFIG="$(MAKEDOC_CONFIG)"

.PHONY: manuscript-profile
manuscript-profile: makedoc-preflight
	@PATH="$(MAKEDOC_PATH)" $(MAKE) -C "$(MAKEDOC_DIR)" profile-show CONFIG="$(MAKEDOC_CONFIG)"

.PHONY: compendium-bootstrap
compendium-bootstrap:
	Rscript scripts/bootstrap.R

.PHONY: compendium-test
compendium-test:
	Rscript tests/run-tests.R

.PHONY: compendium-pipeline
compendium-pipeline:
	Rscript -e 'targets::tar_make()'

.PHONY: compendium-report
compendium-report:
	Rscript -e 'quarto::quarto_render("reports/paper.qmd", quiet = FALSE)'
