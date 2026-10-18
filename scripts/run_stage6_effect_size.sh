#!/usr/bin/env bash
# Stage 6 (docs/STAGE6_EFFECT_SIZE.md): rerun the accepted Stage 2 runner at weaker effect ratios.
# Usage: RC_DATES_STAGE6_MODE=smoke|matrix bash scripts/run_stage6_effect_size.sh
set -euo pipefail

project_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_root"

image=${RC_DATES_SIM_IMAGE:-rc-dates-sim:r4.5.3}
expected_image_id=sha256:01f5e221d0f3b70ccb3edd0fd6556ffd1c645784e98e147e81034866b9137777
mode=${RC_DATES_STAGE6_MODE:-matrix}
cores_per_job=${RC_DATES_CORES_PER_JOB:-4}
max_jobs=${RC_DATES_MAX_JOBS:-15}
batch_size=${RC_DATES_BATCH_SIZE:-40}
master_seed=1234
matrix_nsim=${RC_DATES_NSIM:-500}
output_relative=out/revision/effect-size-20261018

image_id=$(docker image inspect --format '{{.Id}}' "$image")
if [[ "$image_id" != "$expected_image_id" ]]; then
  printf 'Image %s is %s, not the accepted %s\n' "$image" "$image_id" "$expected_image_id" >&2
  exit 1
fi

run_scenario() {
  local truth=$1 prop=$2 ratio=$3 nsim=$4 out_dir=$5
  local label="${truth}_p${prop}_ratio${ratio}"
  local output="$out_dir/results_${truth}_p${prop}_ratio${ratio}_nsim${nsim}_seed${master_seed}.rds"
  mkdir -p "$out_dir/logs"
  docker run --rm --cpus "$cores_per_job" \
    --env R_LIBS_USER=/opt/rc-dates-library/linux-ubuntu-noble/R-4.5/x86_64-pc-linux-gnu \
    --env "RC_DATES_IMAGE_ID=$image_id" \
    --volume "$project_root:/workspace" --workdir /workspace \
    "$image" \
    Rscript --vanilla scripts/run_population_simulation.R \
      "--truth=$truth" "--prop=$prop" "--ratio=$ratio" "--nsim=$nsim" \
      "--cores=$cores_per_job" "--batch-size=$batch_size" "--seed=$master_seed" \
      "--output=$output" \
    >"$out_dir/logs/${label}.log" 2>&1
}

case "$mode" in
  smoke)
    run_scenario lin_inc 1 10 20 "$output_relative/smoke"
    printf 'Smoke run complete: %s/smoke\n' "$output_relative"
    ;;
  matrix)
    printf '%s\n' "$image_id" > "$output_relative/container_image_id.txt" 2>/dev/null || {
      mkdir -p "$output_relative"; printf '%s\n' "$image_id" > "$output_relative/container_image_id.txt"; }
    status=0
    for ratio in 1.5 2 3 5; do
      for prop in 1 0.75 0.5; do
        for truth in lin_inc lin_dec exp_inc exp_dec; do
          while (( $(jobs -rp | wc -l) >= max_jobs )); do
            wait -n || status=1
          done
          printf '[%s] launching %s p=%s ratio=%s\n' "$(date -u +%H:%M:%S)" "$truth" "$prop" "$ratio"
          run_scenario "$truth" "$prop" "$ratio" "$matrix_nsim" "$output_relative" &
        done
      done
    done
    while (( $(jobs -rp | wc -l) > 0 )); do
      wait -n || status=1
    done
    printf '[%s] matrix finished with status %s\n' "$(date -u +%H:%M:%S)" "$status"
    exit "$status"
    ;;
  *)
    printf 'RC_DATES_STAGE6_MODE must be smoke or matrix\n' >&2
    exit 1
    ;;
esac
