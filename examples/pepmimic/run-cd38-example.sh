#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE=(docker compose -f "$ROOT_DIR/compose/docker-compose.yml")

CONFIG="${CONFIG:-/opt/PepMimic/example_data/CD38/config.yaml}"
CKPT="${CKPT:-/opt/PepMimic/checkpoints/model.ckpt}"
OUTPUT_DIR="${OUTPUT_DIR:-/data/outputs/examples/pepmimic-cd38}"
GPU="${GPU:-0}"
N_CPU="${N_CPU:-4}"

"${COMPOSE[@]}" --profile pepmimic run --rm --no-deps pd-pepmimic-gpu bash -lc "
  set -euo pipefail
  source /opt/conda/etc/profile.d/conda.sh
  conda activate pepmimic
  test -f '$CONFIG'
  test -f '$CKPT'
  mkdir -p '$OUTPUT_DIR'
  cd /opt/PepMimic
  python mimic_design.py \
    --config '$CONFIG' \
    --ckpt '$CKPT' \
    --save_dir '$OUTPUT_DIR' \
    --gpu '$GPU' \
    --n_cpu '$N_CPU'
"
