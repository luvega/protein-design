#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

ROOT_INPUT="${ROOT_INPUT:-$ROOT_DIR/data/outputs/AAAWZY/srcr-rf3}"
OUT_CSV="${OUT_CSV:-$ROOT_DIR/data/outputs/examples/confidence/srcr-rf3-confidence.csv}"

mkdir -p "$(dirname "$OUT_CSV")"

python3 "$ROOT_DIR/scripts/merge_confidence_tables.py" \
  --root-dir "$ROOT_INPUT" \
  --out-csv "$OUT_CSV" \
  --no-xlsx
