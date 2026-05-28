#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE=(docker compose -f "$ROOT_DIR/compose/docker-compose.yml")

OUTPUT_PREFIX="${OUTPUT_PREFIX:-/data/outputs/examples/rfpeptide-macrocycle/uncond_cycpep}"
NUM_DESIGNS="${NUM_DESIGNS:-1}"

"${COMPOSE[@]}" --profile rfpeptide run --rm --no-deps pd-rfpeptide-gpu bash -lc "
  set -euo pipefail
  source /opt/conda/etc/profile.d/conda.sh
  conda activate SE3cuda
  test -f /opt/RFdiffusion/examples/input_pdbs/7zkr_GABARAP.pdb
  mkdir -p \"\$(dirname '$OUTPUT_PREFIX')\"
  cd /opt/RFdiffusion
  python scripts/run_inference.py \
    --config-name base \
    inference.output_prefix='$OUTPUT_PREFIX' \
    inference.num_designs='$NUM_DESIGNS' \
    'contigmap.contigs=[12-18]' \
    inference.input_pdb=/opt/RFdiffusion/examples/input_pdbs/7zkr_GABARAP.pdb \
    inference.cyclic=True \
    diffuser.T=50 \
    inference.cyc_chains='a'
"
