#!/usr/bin/env bash
set -euo pipefail

project_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
image=${RC_DATES_SIM_IMAGE:-rc-dates-sim:r4.5.3}
nsim=${RC_DATES_SENSITIVITY_NSIM:-1000}
cores_per_job=${RC_DATES_SENSITIVITY_CORES_PER_JOB:-7}
batch_size=${RC_DATES_SENSITIVITY_BATCH_SIZE:-70}
master_seed=${RC_DATES_SENSITIVITY_MASTER_SEED:-1234}
strategies=${RC_DATES_SENSITIVITY_STRATEGIES:-r_all,r_1,r_3,r_5}
artifact_dir=${RC_DATES_SENSITIVITY_ARTIFACT_DIR:-"$project_root/out/sensitivity/observation-noise"}
log_dir="$artifact_dir/logs"

if ! docker image inspect "$image" >/dev/null 2>&1; then
  printf 'Requested image does not exist: %s\n' "$image" >&2
  exit 1
fi
r_version=$(docker run --rm "$image" Rscript --version 2>&1)
case "$r_version" in
  *"version 4.5.3 ("*) ;;
  *)
    printf 'Sensitivity image must provide R 4.5.3; got: %s\n' "$r_version" >&2
    exit 1
    ;;
esac

mkdir -p "$log_dir"
image_id=$(docker image inspect --format '{{.Id}}' "$image")
printf '%s\n' "$image_id" > "$artifact_dir/container_image_id.txt"
models=(uni lin exp)
proportions=(0.5 0.75 1)
pids=()
labels=()

for prop in "${proportions[@]}"; do
  for model in "${models[@]}"; do
    label="${model}_p${prop}"
    output="/sensitivity-output/observation_noise_${model}_p${prop}_ratio10_nsim${nsim}_seed${master_seed}.rds"
    log="$log_dir/${label}.log"
    printf 'Launching %s -> %s\n' "$label" "$log"
    docker run --rm \
      --cpus "$cores_per_job" \
      --env R_LIBS_USER=/opt/rc-dates-library/linux-ubuntu-noble/R-4.5/x86_64-pc-linux-gnu \
      --env "RC_DATES_IMAGE_ID=$image_id" \
      --volume "$project_root:/workspace:ro" \
      --volume "$artifact_dir:/sensitivity-output" \
      --workdir /workspace \
      "$image" \
      Rscript --vanilla scripts/run_observation_noise_sensitivity.R \
        "--model=$model" \
        "--prop=$prop" \
        "--nsim=$nsim" \
        "--cores=$cores_per_job" \
        "--batch-size=$batch_size" \
        "--seed=$master_seed" \
        "--strategies=$strategies" \
        "--output=$output" \
      >"$log" 2>&1 &
    pids+=("$!")
    labels+=("$label")
  done
done

status=0
for index in "${!pids[@]}"; do
  if wait "${pids[$index]}"; then
    printf 'Completed %s\n' "${labels[$index]}"
  else
    printf 'Failed %s; inspect %s/%s.log\n' \
      "${labels[$index]}" "$log_dir" "${labels[$index]}" >&2
    status=1
  fi
done

exit "$status"
