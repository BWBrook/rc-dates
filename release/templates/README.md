# rc-dates: scientific reproduction files

Companion to **Within-site date-retention rules can distort radiocarbon
“dates-as-data” inference**, by Barry W. Brook, Rebecca Wheatley, Christopher N.
Johnson, Alan N. Williams, Sean Ulm and Luke A. Yates. Prepared 11 September 2026
for co-author review, preprinting and Journal of Archaeological Science.
Authorship details remain subject to co-author confirmation.

This repository contains the calculations and accepted evidence for this paper.
It is a single scientific release, without the development repository's history,
working notes, manuscript build system or superseded experiments. `Makefile` is
the command index. See `VALIDATION.md` for what was actually checked.

## Reproduce the paper from the included evidence

Use Linux x86_64 and R **4.5.3**, with the package versions in `renv.lock`.
The supplied Docker recipe restores the required subset of that unchanged lock
and preserves the production font mapping for mathematical axis labels:

```sh
make docker-build
docker run --rm --user "$(id -u):$(id -g)" --cpus 4 --memory 16g \
  -v "$PWD:/workspace" -w /workspace rc-dates-release:r4.5.3 make reproduce-paper
```

`make reproduce-paper` verifies the distributed checksums, derives every signed-model
summary from 720,000 fitted rows, recomputes both observation-noise bootstrap
analyses from the nine paired checkpoints, renders the seven paper figures,
and checks the 80 registered numerical values in `release/claims.csv`.
Summaries and figures are rebuilt independently from accepted evidence; the
summary comparisons require exact equality before the complete command passes.
Outputs go to `out/reproduced/`; accepted records are retained in place.
The registry checks values against evidence and validates manuscript anchors;
manual manuscript concordance and its coverage limits are recorded in `CLAIM_AUDIT.md`.
The original observation-noise decision remains **FAIL (15/18 criteria)**.
The separately labelled v2 result is a post-unblinding diagnostic, with
50,000 resamples and its original stability seed; it does not replace v1.

The bootstrap rebuild can take substantial time. Use an adequately provisioned
machine; do not infer resource requirements from the small archive size.
`make test` runs the focused scientific tests in the same container. For an
existing R 4.5.3 environment, restore the lock with `renv` and supply its library
through `R_LIBS_USER` before invoking these `--vanilla` commands.

## Regenerate the synthetic experiments

```sh
# Same docker invocation as above, replacing the final command with:
make simulation-check CORES=4
make simulations CORES=8
```

The first command checks two replicates in every signed and observation-noise
scenario. The second reruns all 1,000 replicates per scenario. Both compare
scientific rows against the accepted output, including the paired-noise
manifest. These are expensive computations: run the full command in `tmux` on a
server. It checkpoints atomically and resumes when repeated with the same
settings, sources and runtime. New outputs are under `out/rerun/`.

The generating site-count distribution and age-to-error regression are recorded
at full precision in `release/inputs/simulation_parameters.csv`. The adapter uses
these scalar estimates in the unchanged simulation engines. Fitted R model
objects are omitted because they retain archaeological observations. Seeds,
retention rules and common random numbers remain those of the accepted design.
The frozen 2026-07-26 observation-noise engine is necessary to reproduce that
experiment; its source and original checksums are kept under `provenance/`.

## Rebuild the empirical analysis from AustArch

Record-level archaeological inputs are acquired separately. Obtain
`Austarch_1-3_and_IDASQ_28Nov13-1.csv` from the
[AustArch collection, DOI 10.5284/1027216](https://doi.org/10.5284/1027216), using
its [download page](https://archaeologydataservice.ac.uk/archives/view/austarch_na_2014/downloads.cfm)
and the applicable ADS access terms. Automated access may return HTTP 403;
manual download is supported. Do not bypass the source checksum check.

```sh
# Make the acquired file visible inside the container, then run:
make reconstruct SOURCE=/workspace/data-raw/Austarch_1-3_and_IDASQ_28Nov13-1.csv
make empirical
```

Reconstruction explicitly applies the historical eligibility and calibration
rules: posterior overlap with 651–11,650 cal BP, then at least five dates per
site. It accepts two known input fingerprints and writes the 976-date,
116-site reference only after exact output-checksum agreement. The repository's
original 5,522-row import was replayed successfully. The separately fingerprinted
2026 ADS download was documented in the source audit but could not be acquired
again during release assembly; a fresh replay of that snapshot is subject to
the same output gate. The primary paper analysis then selects 540 dates at
68 sites using its distinct terrestrial/common-membership rules.

`make empirical` first refits and exactly checks the negative-binomial site-count
model and age-to-error regression (including R² and residual degrees of freedom),
then recalibrates, resamples and rebuilds all empirical CSV tables,
then compares their scientific values exactly with the accepted evidence.
The included aggregate curves alone support figure rendering, not a claim that
record-level calibration has been rerun. The reconstructed reference checksum is
`2f1b5ccc40038f9e30bce643d57191c545c98448266fcaab3b11c9a33059c70a`.

## Contents, provenance and use

- `R/`, `scripts/`, `tests/`: scientific functions, execution and focused tests.
- `release/inputs/`: aggregate site-count histogram and scalar simulation fit.
- `out/`: accepted empirical aggregates and synthetic replicate evidence.
- `provenance/`, `release/historical/`: source required by the accepted noise analysis.
  Frozen historical notes refer to the original development layout; the raw-input
  exception for this release is documented above and in `docs/AUSTARCH_PROVENANCE.md`.
- `manuscript/`: paper and supplement text plus the seven accepted figures, for
  interpreting the claims and comparing presentation; no document builder.
- `SHA256SUMS`, `RELEASE.json`: release inventory and source commit.

The top-level inventory checks all distributed files except itself and rejects
unlisted files outside the documented local data, runtime and generated-output paths. Nested
inventories preserve the original accepted evidence. `out/reproduced/`,
`out/rerun/`, acquired data and local runtimes are excluded from the release.
The ZIP contains the same scientific files as this repository, without `.git`.

This is an assembled local release awaiting the authors' publication decision.
No repository URL, archival DOI or new licence is asserted. The authors must
confirm a code licence and the sharing basis for the aggregate archaeological
outputs before public deposit. AustArch source records remain subject to their
own licensing, sensitivity and Indigenous data-governance considerations.
