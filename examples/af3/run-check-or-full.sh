#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE=(docker compose -f "$ROOT_DIR/compose/docker-compose.yml")

JSON_PATH="${JSON_PATH:-/workspace/examples/af3/example_peptide.json}"
OUTPUT_DIR="${OUTPUT_DIR:-/data/outputs/examples/af3-example}"
MODEL_DIR="${MODEL_DIR:-/root/models}"
DB_DIR="${DB_DIR:-/root/public_databases}"
JAX_CACHE_DIR="${JAX_CACHE_DIR:-/data/alphafold3/jax_cache}"
MAX_TEMPLATE_DATE="${MAX_TEMPLATE_DATE:-2026-05-28}"
NUM_DIFFUSION_SAMPLES="${NUM_DIFFUSION_SAMPLES:-1}"
NUM_RECYCLES="${NUM_RECYCLES:-3}"

if [[ "${RUN_FULL:-0}" != "1" ]]; then
  "${COMPOSE[@]}" --profile af3 run --rm --no-deps pd-af3-gpu bash -lc '
    set -euo pipefail
    test -f /root/models/af3.bin.zst
    test -f /alphafold3_venv/lib/python3.12/site-packages/alphafold3/constants/converters/ccd.pickle
    python -c "import jax, alphafold3; print(\"jax\", jax.__version__); print(\"devices\", jax.devices()); print(\"alphafold3 ok\")"
  '
  echo "Set RUN_FULL=1 to run AlphaFold 3. Full runs require databases under /mnt/ssd4t/protein-design/data/alphafold3/public_databases."
  exit 0
fi

"${COMPOSE[@]}" --profile af3 run --rm --no-deps pd-af3-gpu bash -lc "
  set -euo pipefail
  test -f '$JSON_PATH'
  test -f '$MODEL_DIR/af3.bin.zst'
  test -d '$DB_DIR'
  mkdir -p '$OUTPUT_DIR' '$JAX_CACHE_DIR'
  python run_alphafold.py \
    --json_path='$JSON_PATH' \
    --model_dir='$MODEL_DIR' \
    --db_dir='$DB_DIR' \
    --output_dir='$OUTPUT_DIR' \
    --jax_compilation_cache_dir='$JAX_CACHE_DIR' \
    --max_template_date='$MAX_TEMPLATE_DATE' \
    --num_diffusion_samples='$NUM_DIFFUSION_SAMPLES' \
    --num_recycles='$NUM_RECYCLES'
"
