# Scientific release verification — 19 September 2026

## Bounded Figure 4 revision

This release supersedes the 11 September presentation. Figure 4 now reports
per-replicate bounded endpoint contrasts and every original near-boundary
frequency. Figures 3 and 5 have larger labels. Raw fits, original summaries,
empirical evidence, noise decisions and the R lock are unchanged.
The correction is specified in `docs/FIGURE4_BOUNDARY_REVISION_20260919.md`.

The revision passed the following checks in the same pinned R 4.5.3 image:

- All 37 scientific test blocks passed without failures, warnings or skips.
- Independent direct-parameter reconstruction matched all 32 new means,
  type-7 quantile ranges, truth values, denominators and boundary counts to
  absolute tolerance 1e-12. The near-boundary random-1 fractions remain 0.072
  and 0.082.
- A clean release candidate rebuilt the five original signed summary tables
  exactly from all 720,000 fitted rows and passed all 82 current registry values.
- All seven figure commands completed. Figures 1–5 and S1 match the distributed
  revised figures pixel for pixel; the previous S2 presentation caveat remains.
- The complete 190-file inventory and all nested inventories passed before and
  after reproduction, including the two-file derived-contrast inventory.
- The independent reviewer accepted the targeted correction. The rebuilt paper
  and supplement passed strict manuscript checks and affected-page PDF/DOCX
  inspection.

No new simulation campaign, noise-bootstrap recalculation or empirical-source
reconstruction was needed for this presentation correction. Those unchanged
calculations retain the dated verification below. The runtime image and lockfile
were not rebuilt or changed.

## Inherited verification — 11 September 2026

Verification used Linux x86_64 on the analysis server, with R 4.5.3. The
archaeological source was accessible only in the separate author workspace;
the isolated release checkout had no source or filtered archaeological records.

| Check | Result |
|---|---|
| Original empirical, signed and observation-noise inventories | All original checksums passed; accepted evidence was not changed. |
| Historical source reconstruction | The original 5,522-row import reproduced the accepted 976-record, 116-site reference byte for byte (SHA-256 recorded in the README). |
| Empirical analysis replay | All 15 empirical CSV tables matched exactly after parsing, including curves, distances, effective counts, filtering, ties and sensitivities. |
| Generating-parameter refit | Site-count fit, error-regression coefficients, residual SD, R², residual degrees of freedom and count histogram matched exactly under both the production and review R 4.5.3 images. |
| Scalar input adapter | Negative-binomial estimates, predictions on 30,001 ages, generated errors and final RNG state matched the original fitted objects exactly. |
| Signed summary rebuild | All 720,000 fitted rows validated; all-date pairing across treatment proportions and all five summary CSVs matched exactly. |
| Observation-noise bootstrap rebuild | Every v1 CSV and all v2 metrics, gates and stability values matched exactly; v1 retained 15/18 FAIL and v2 retained its diagnostic PASS/AGREE. |
| Limited simulation replay | Two replicates in each of 15 signed scenarios and nine noise scenarios matched accepted scientific rows exactly: 1,440 signed rows, 864 noise rows and all 18 noise-pair records. |
| Rerun safeguards | A changed runtime-recipe fingerprint was rejected before resuming, and a destination inside accepted evidence was rejected before directory creation. |
| Released scientific tests | All 35 test blocks passed without failures, warnings or dependency skips in an isolated checkout. |
| Numerical registry | All 80 registered evidence values passed; manuscript anchors exist. Manual prose concordance and evidence-only decompositions are documented in CLAIM_AUDIT.md. |
| Figures | Figures 1–5 and S1 matched raster content exactly; PDFs compared after rasterisation at 144 dpi. S2's aggregate counts and fitted distribution are reproduced, with presentation differences described below. |
| Clean Docker recipe | Clean build succeeded; signed summaries, 80 registry values, 35 tests and the 24-scenario limited replay passed. Core R/base/stats/BLAS/LAPACK binaries matched the production image byte for byte; the final font mapping restores the six matching figures. |

The accepted production simulation image was
`sha256:01f5e221d0f3b70ccb3edd0fd6556ffd1c645784e98e147e81034866b9137777`.
The scalar adapter and limited simulation replay were checked against it.
The final release image was
`sha256:7c44e3585626a5cd4b25979dd19b052359ae0df1bac930123c5db27fc41c65fc`.
The full limited replay used its computational parent
`sha256:21a1c90243b7d6eadcf3efad0630a715b84ec869669e5e12490f2a923ccffd94`;
the final layer adds only the verified font mapping, with no R or analysis changes.
The release Dockerfile pins the same R 4.5.3 base and restores required package
versions from the unchanged lockfile; it is a build recipe, not a claim that the
historical image is publicly downloadable.

## Presentation and interpretation limits

Supplementary Figure S2's original plotting code could not be recovered.
Its release renderer uses the exact aggregate histogram and fitted distribution,
but its title and point sizing differ from the accepted raster. At the original
971 × 747 pixels, 32,782 pixels (4.52%) differ. The accepted S2 image is distributed
unchanged for comparison. At the 11 September release, all other figures reproduced pixel for pixel
in the verified rendering environment. The 19 September Figure 4 correction
and Figure 3/5 typography supersede those three historical presentations. The Dockerfile installs a small fontconfig
rule preserving the production Nimbus faces in mathematical axis labels; other
font/device stacks may differ.

The evidence registry checks registered numbers against aggregate files and
checks manuscript locations. It is not an automated semantic review of prose.
The accompanying dated manual concordance check covers the registered values;
co-authors remain responsible for reviewing the scientific interpretation.

The full 1,000-replicate experiments were not regenerated for release assembly.
The package includes every accepted replicate and an executable resumable rerun
path; limited replay checks every scenario and preserves the original RNG and
pairing semantics. No new simulation experiment was introduced. The 19 September derived
presentation correction was specified after review of the accepted results
and does not replace any original scientific decision gate.

The original observation-noise v1 decision remains FAIL (15 of 18 criteria).
The separately labelled v2 diagnostic uses the accepted 50,000-resample seeds;
it is post-unblinding and cannot retroactively pass v1 or validate untested
oldest, youngest and bracketed retention.

The full source route was verified from the original repository import. The
2026 ADS-audit snapshot was not reacquired during assembly; the reconstruction
script subjects either recognised input snapshot to the same exact accepted-
output checksum gate. Licensing and public deposit remain author decisions.
