# Bounded endpoint-contrast evidence — 19 September 2026

This derived summary replaces the finite log-ratio magnitude presentation in
Figure 4. It does not replace any original fitted result, model-selection
summary or scientific decision. The acceptance criteria were recorded before
derivation in `docs/FIGURE4_BOUNDARY_REVISION_20260919.md`.

`endpoint_contrast.csv` contains 32 groups of 1,000 fits: four non-uniform
truths, eight retention rules, full site treatment, primary marginal likelihood,
and the generating family irrespective of the AIC-selected family. Each row
names its source RDS file in `out/revision/signed-models/`, whose original
38-file checksum inventory passed before calculation.

For each stored fitted log ratio theta, the renderer calculates tanh(theta/2),
then the mean and R type-7 2.5th/97.5th percentiles. Original near-boundary flags
are retained exactly. No fit is reclassified or moved to an endpoint.

Independent Python reconstruction used the stored slope or rate directly:
`slope * 10999^2 / 2` for linear fits and `tanh(rate * 10999 / 2)` for
exponential fits. All 32 means, quantiles, truth contrasts, sample sizes and
boundary counts agree to absolute tolerance 1e-12. The increasing/decreasing
linear random-1 boundary counts remain 72 and 82 out of 1,000.

The pinned `rc-dates-release:r4.5.3` image on deep-server generated the figure
and summary with read-only source mounts, network disabled, two CPUs and 8 GB
memory. All 37 scientific test blocks passed without warnings or failures.
The exact runtime image is
`sha256:7c44e3585626a5cd4b25979dd19b052359ae0df1bac930123c5db27fc41c65fc`.

The development review logs and independent helper are retained in
`tmp/revision_20260919/`. Reproduction from the release uses its Makefile and
`scripts/render_population_simulation_figures.R`; a regenerated summary is
compared with this distributed reference before the command can complete.

The contrast compresses large endpoint ratios. It is an endpoint-density
summary, not a growth rate or a test of complete shape recovery. Near-boundary
flags are tolerance-based and do not certify exact endpoint optima.
