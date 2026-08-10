# Observation-noise sensitivity source snapshot

This directory preserves the exact source files used to launch the paired
curve-mean versus realised-observation sensitivity matrix. The run used R
4.5.3 in container image
`sha256:01f5e221d0f3b70ccb3edd0fd6556ffd1c645784e98e147e81034866b9137777`.

The run inputs were the tracked filtered archive and dependency lock:

- `data/austarch_filtered.csv` MD5:
  `8d30b24e98088a7808c234d6b77ac382`
- `renv.lock` MD5:
  `96135a2d8be3bbf3d5e6efe11890188f`

Both files remain at repository root and are not duplicated here. The
production container recipe and package-install script are included because
their fingerprints are recorded in every checkpoint.

After the run began, two observation-model helpers were moved between the
current `R/` modules to restore isolated sourcing of the production runner.
That refactor did not alter the running calculation, but it changed the two
source-file fingerprints. Consequently, checkpoint provenance must be checked
against this frozen snapshot rather than against the later source layout.

`SHA256SUMS` fingerprints the seven computational source and container files
used by the run; this explanatory README and the inventory itself are excluded.
