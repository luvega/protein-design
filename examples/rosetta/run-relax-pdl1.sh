#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE=(docker compose -f "$ROOT_DIR/compose/docker-compose.yml")

INPUT_PDB="${INPUT_PDB:-/data/inputs/PDL1.pdb}"
OUTPUT_DIR="${OUTPUT_DIR:-/data/outputs/examples/rosetta-relax-pdl1}"
NSTRUCT="${NSTRUCT:-1}"

"${COMPOSE[@]}" --profile rosetta run --rm --no-deps pd-rosetta-cpu-parallel bash -lc "
  set -euo pipefail
  test -f '$INPUT_PDB'
  test -f /opt/rosetta_db/scoring/weights/ref2015.wts
  mkdir -p '$OUTPUT_DIR'
  cd '$OUTPUT_DIR'
  relax.cxx11thread.linuxgccrelease \
    -database /opt/rosetta_db \
    -s '$INPUT_PDB' \
    -nstruct '$NSTRUCT' \
    -out:path:all '$OUTPUT_DIR' \
    -out:suffix _relaxed \
    -overwrite
"
