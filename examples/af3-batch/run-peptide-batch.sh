#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INPUT_CSV="${INPUT_CSV:-$ROOT_DIR/examples/af3-batch/peptide_candidates.csv}"
JSON_DIR="${JSON_DIR:-$ROOT_DIR/data/inputs/af3-batch/example-peptides}"
MANIFEST="${MANIFEST:-$JSON_DIR/manifest.csv}"
OUTPUT_DIR="${OUTPUT_DIR:-/data/outputs/af3-batch}"
OUT_CSV="${OUT_CSV:-af3_summary.csv}"
BATCH_LIMIT="${BATCH_LIMIT:-0}"
HOST_OUTPUT_DIR="$ROOT_DIR/${OUTPUT_DIR#/}"

python3 "$ROOT_DIR/scripts/prepare_af3_batch.py" \
  --input-csv "$INPUT_CSV" \
  --out-dir "$JSON_DIR" \
  --manifest "$MANIFEST" \
  --force

if [[ "${RUN_FULL:-0}" != "1" ]]; then
  python3 "$ROOT_DIR/scripts/run_af3_batch.py" \
    --manifest "$MANIFEST" \
    --output-dir "$OUTPUT_DIR" \
    --limit "$BATCH_LIMIT" \
    --dry-run
  echo "Set RUN_FULL=1 to run the AF3 batch. Full runs scan the AF3 databases and can be slow."
  exit 0
fi

mkdir -p "$HOST_OUTPUT_DIR"

python3 "$ROOT_DIR/scripts/run_af3_batch.py" \
  --manifest "$MANIFEST" \
  --output-dir "$OUTPUT_DIR" \
  --limit "$BATCH_LIMIT"

python3 "$ROOT_DIR/scripts/summarize_af3_results.py" \
  --root-dir "$HOST_OUTPUT_DIR" \
  --out-csv "$OUT_CSV" \
  --top 10
