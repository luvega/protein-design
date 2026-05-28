#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE=(docker compose -f "$ROOT_DIR/compose/docker-compose.yml")

SETTINGS="${SETTINGS:-/workspace/examples/bindcraft/CD47_peptide_quick.json}"
FILTERS="${FILTERS:-/opt/BindCraft/settings_filters/peptide_filters.json}"
ADVANCED="${ADVANCED:-/opt/BindCraft/settings_advanced/peptide_3stage_multimer_mpnn.json}"

"${COMPOSE[@]}" --profile bindcraft run --rm --no-deps pd-bindcraft-gpu bash -lc "
  set -euo pipefail
  source /opt/conda/etc/profile.d/conda.sh
  conda activate BindCraft
  test -f '$SETTINGS'
  test -f '$FILTERS'
  test -f '$ADVANCED'
  cd /opt/BindCraft
  python bindcraft.py \
    --settings '$SETTINGS' \
    --filters '$FILTERS' \
    --advanced '$ADVANCED'
"
