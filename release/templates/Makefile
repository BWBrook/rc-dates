SHELL := /bin/bash
.NOTPARALLEL:
RSCRIPT ?= Rscript
PYTHON ?= python3
CORES ?= 4
IMAGE ?= rc-dates-release:r4.5.3

.PHONY: help verify test reproduce-paper figures summaries stage6-summaries claims simulation-check simulations reconstruct empirical parameters docker-build
help:
	@echo "make verify          Check every distributed file and frozen evidence manifest"
	@echo "make reproduce-paper Rebuild summaries, nine figures and numerical claim audit"
	@echo "make test            Run focused scientific tests (R 4.5.3)"
	@echo "make simulation-check  Replay two replicates in each of 72 scenarios and compare accepted rows"
	@echo "make simulations     Replay all accepted simulations (heavy; resumable)"
	@echo "make reconstruct SOURCE=/path/to/Austarch_1-3_and_IDASQ_28Nov13-1.csv"
	@echo "make empirical       Rebuild empirical results after source reconstruction"
	@echo "make docker-build    Build the pinned R 4.5.3 runtime"
verify:
	python3 scripts/release/verify_release.py
test:
	$(RSCRIPT) --vanilla -e 'stopifnot(as.character(getRversion()) == "4.5.3"); testthat::test_dir("tests/testthat", reporter="summary", stop_on_failure=TRUE, stop_on_warning=TRUE)'
summaries: verify stage6-summaries
	$(RSCRIPT) --vanilla scripts/release/rebuild_signed_summaries.R
	$(RSCRIPT) --vanilla scripts/release/rebuild_noise_summaries.R
stage6-summaries: verify
	$(RSCRIPT) --vanilla scripts/release/rebuild_stage6_summaries.R
figures: verify stage6-summaries
	$(PYTHON) scripts/render_retention_mechanism.py --output-dir=out/reproduced/figures
	$(RSCRIPT) --vanilla scripts/release/render_empirical_figures.R
	$(RSCRIPT) --vanilla scripts/render_population_simulation_figures.R --figure-dir=out/reproduced/figures --summary-dir=out/reproduced/endpoint-contrast
	$(RSCRIPT) --vanilla scripts/release/render_site_counts.R
	$(RSCRIPT) --vanilla scripts/render_stage6_effect_size_figure.R out/reproduced/effect-size out/reproduced/figures/fig_effect_size
claims:
	python3 scripts/release/audit_manuscript_claims.py
reproduce-paper: summaries figures claims
simulation-check: verify
	$(RSCRIPT) --vanilla scripts/release/rerun_simulations.R --design=signed --nsim=2 --cores=$(CORES) --batch-size=2 --output-dir=out/rerun/check-signed
	$(RSCRIPT) --vanilla scripts/release/rerun_simulations.R --design=noise --nsim=2 --cores=$(CORES) --batch-size=2 --output-dir=out/rerun/check-noise
	@for ratio in 1.5 2 3 5; do \
		$(RSCRIPT) --vanilla scripts/release/rerun_simulations.R --design=stage6 --ratio=$$ratio --nsim=2 --cores=$(CORES) --batch-size=2 --output-dir=out/rerun/check-stage6/ratio$$ratio || exit $$?; \
	done
simulations: verify
	$(RSCRIPT) --vanilla scripts/release/rerun_simulations.R --design=signed --nsim=1000 --cores=$(CORES)
	$(RSCRIPT) --vanilla scripts/release/rerun_simulations.R --design=noise --nsim=1000 --cores=$(CORES)
	@for ratio in 1.5 2 3 5; do \
		$(RSCRIPT) --vanilla scripts/release/rerun_simulations.R --design=stage6 --ratio=$$ratio --nsim=500 --cores=$(CORES) || exit $$?; \
	done
reconstruct:
	@test -n "$(SOURCE)" || { echo "Set SOURCE to the separately acquired AustArch source CSV"; exit 1; }
	$(RSCRIPT) --vanilla scripts/release/reconstruct_austarch_reference.R "$(SOURCE)" data/austarch_filtered.csv
parameters: verify
	$(RSCRIPT) --vanilla scripts/release/export_simulation_specification.R
empirical: parameters
	$(RSCRIPT) --vanilla scripts/render_manuscript_methods_figures.R --figure-dir=out/reproduced/empirical-figures --summary-dir=out/reproduced/empirical-sampling
	$(RSCRIPT) --vanilla scripts/release/compare_empirical.R
docker-build:
	docker build -t $(IMAGE) -f docker/Dockerfile .
