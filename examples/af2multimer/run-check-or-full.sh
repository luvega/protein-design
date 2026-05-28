#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE=(docker compose -f "$ROOT_DIR/compose/docker-compose.yml")

FASTA="${FASTA:-/workspace/examples/af2multimer/example_heteromer.fasta}"
OUTPUT_DIR="${OUTPUT_DIR:-/data/outputs/examples/af2multimer-example}"
MAX_TEMPLATE_DATE="${MAX_TEMPLATE_DATE:-2026-05-28}"

if [[ "${RUN_FULL:-0}" != "1" ]]; then
  "${COMPOSE[@]}" --profile af2 run --rm --no-deps pd-af2multimer-gpu bash -lc 'af2multimer-check'
  echo "Set RUN_FULL=1 to run AlphaFold Multimer. Full runs require complete databases under data/alphafold_db."
  exit 0
fi

"${COMPOSE[@]}" --profile af2 run --rm --no-deps pd-af2multimer-gpu bash -lc "
  set -euo pipefail
  test -f '$FASTA'
  mkdir -p '$OUTPUT_DIR'
  PYTHONPATH=/opt/pyfix OPENMM_PLUGIN_DIR=/opt/openmm_plugins_empty \
  python3 /opt/alphafold/run_alphafold.py \
    --fasta_paths='$FASTA' \
    --output_dir='$OUTPUT_DIR' \
    --data_dir=/data/alphafold_db \
    --model_preset=multimer \
    --db_preset=reduced_dbs \
    --max_template_date='$MAX_TEMPLATE_DATE'
"
