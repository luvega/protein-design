#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE=(docker compose -f "$ROOT_DIR/compose/docker-compose.yml")

INPUT_PDB="${INPUT_PDB:-/data/inputs/PDL1.pdb}"
OUTPUT_DIR="${OUTPUT_DIR:-/data/outputs/examples/foundry-mpnn-pdl1}"
CHECKPOINT="${CHECKPOINT:-/data/foundry_checkpoints/proteinmpnn_v_48_020.pt}"

"${COMPOSE[@]}" --profile foundry run --rm --no-deps pd-foundry-gpu bash -lc "
  set -euo pipefail
  test -f '$INPUT_PDB'
  test -f '$CHECKPOINT'
  mkdir -p '$OUTPUT_DIR'
  /opt/conda/bin/conda run -n foundry mpnn \
    --model_type protein_mpnn \
    --checkpoint_path '$CHECKPOINT' \
    --is_legacy_weights True \
    --structure_path '$INPUT_PDB' \
    --name PDL1 \
    --out_directory '$OUTPUT_DIR' \
    --batch_size 1 \
    --number_of_batches 1 \
    --write_fasta True \
    --write_structures False
"
