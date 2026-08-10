#!/usr/bin/env bash
set -euo pipefail

project_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
image=${RC_DATES_SIM_IMAGE:-rc-dates-sim:r4.5.3}
nsim=${RC_DATES_NSIM:-1000}
cores_per_job=${RC_DATES_CORES_PER_JOB:-7}
batch_size=${RC_DATES_BATCH_SIZE:-70}
master_seed=${RC_DATES_MASTER_SEED:-1234}
output_relative=${RC_DATES_OUTPUT_DIR:-out/production}
output_dir="$project_root/$output_relative"
log_dir="$output_dir/logs"
skip_image_build=${RC_DATES_SKIP_IMAGE_BUILD:-false}

mkdir -p "$log_dir"

case "$skip_image_build" in
  true)
    if ! docker image inspect "$image" >/dev/null 2>&1; then
      printf 'Requested image does not exist: %s\n' "$image" >&2
      exit 1
    fi
    ;;
  false)
  docker build \
    --file "$project_root/docker/production-simulation.Dockerfile" \
    --tag "$image" \
    "$project_root"
    ;;
  *)
    printf 'RC_DATES_SKIP_IMAGE_BUILD must be true or false\n' >&2
    exit 1
    ;;
esac
image_id=$(docker image inspect --format '{{.Id}}' "$image")
r_version=$(docker run --rm "$image" Rscript --version 2>&1)
case "$r_version" in
  *"version 4.5.3 ("*) ;;
  *)
    printf 'Production image must provide R 4.5.3; got: %s\n' "$r_version" >&2
    exit 1
    ;;
esac
printf '%s\n' "$image_id" > "$output_dir/container_image_id.txt"

docker_environment=(
  --env R_LIBS_USER=/opt/rc-dates-library/linux-ubuntu-noble/R-4.5/x86_64-pc-linux-gnu
  --env "RC_DATES_IMAGE_ID=$image_id"
)

models=(uni lin exp)
proportions=(0.5 0.75 1)
pids=()
labels=()

for prop in "${proportions[@]}"; do
  for model in "${models[@]}"; do
    label="${model}_p${prop}"
    output="$output_relative/results_${model}_p${prop}_ratio10_nsim${nsim}_seed${master_seed}.rds"
    log="$log_dir/${label}.log"
    printf 'Launching %s -> %s\n' "$label" "$log"
    docker run --rm \
      --cpus "$cores_per_job" \
      "${docker_environment[@]}" \
      --volume "$project_root:/workspace" \
      --workdir /workspace \
      "$image" \
      Rscript --vanilla scripts/run_population_simulation.R \
        "--model=$model" \
        "--prop=$prop" \
        "--nsim=$nsim" \
        "--cores=$cores_per_job" \
        "--batch-size=$batch_size" \
        "--seed=$master_seed" \
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
