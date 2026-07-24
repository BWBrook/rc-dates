# Production Generation Snapshot

These are the exact source files loaded when the nine production simulation
jobs began on 2026-07-10. They are retained because checkpoint-provenance and
artefact-sidecar validation were added to the active source while the
already-loaded jobs were running. Those later changes do not alter the
simulation engine, but retaining this snapshot makes the RDS source hashes
directly auditable.

The completed data frames were preserved on the compute server before the new
fingerprint attribute was added. Supplied RDS files record
`provenance_origin: post-run-stamp`; future checkpoints created by the active
runner record `native-checkpoint` instead. Stamping adds only the provenance
attribute and does not alter result rows.

The jobs used R 4.5.3 in container image:

```text
sha256:15cefece042e56e50ee822bd00c9c400dd6259c7a18cf25d6ff333ccea4aa3bc
```

At build time, `rocker/r-ver:4.5.3` resolved to
`sha256:c3f39b365d1077fe24f8e9ab2742e352b6d3950897f51af1624a5bb5550c21c0`;
the active Dockerfile now pins that resolved digest. File MD5 values embedded
in the RDS provenance are:

```text
f8cff6c13663ca12083e9dc115b4c3ac  R/population_simulation_production.R
0a55f28d18bab310a68235becb3561ec  R/legacy_simulation_helpers.R
7304d936296129636c087e1dde1cb536  scripts/run_population_simulation.R
5e0643f79bffeaae4d86f98adc034ccb  docker/production-simulation.Dockerfile
96135a2d8be3bbf3d5e6efe11890188f  renv.lock
8d30b24e98088a7808c234d6b77ac382  data/austarch_filtered.csv
```

The launch-time Dockerfile contains its package-restore command inline, so the
corresponding RDS field records `container_install_md5: inline-in-recipe`. The
active recipe uses a separate install script and records that file's MD5.

The active runner is the maintained rerun path. This directory records the
generation state of the supplied production artefacts and is not a second
entry point.
