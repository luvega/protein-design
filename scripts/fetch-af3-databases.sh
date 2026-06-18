#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AF3_SSD_ROOT="${AF3_SSD_ROOT:-/mnt/ssd4t/protein-design}"
AF3_SRC="${AF3_SRC:-$AF3_SSD_ROOT/data/src/alphafold3}"
AF3_DB_DIR="${AF3_DB_DIR:-$AF3_SSD_ROOT/data/alphafold3/public_databases}"
AF3_LOG_DIR="${AF3_LOG_DIR:-$ROOT_DIR/data/outputs/logs}"
AF3_LOG_FILE="${AF3_LOG_FILE:-$AF3_LOG_DIR/af3-fetch-databases-$(date +%Y%m%d).log}"
AF3_PID_FILE="${AF3_PID_FILE:-$AF3_LOG_DIR/af3-fetch-databases.pid}"
AF3_EXTRA_PATH="${AF3_EXTRA_PATH:-/home/a/anaconda3/bin}"

usage() {
  cat <<'USAGE'
Usage: scripts/fetch-af3-databases.sh [start|foreground|status|log]

Commands:
  start       Start the official AlphaFold 3 fetch_databases.sh in the background.
  foreground Run the official script in the foreground.
  status      Show the saved PID, matching download processes, and database size.
  log         Follow the download log.

Environment:
  AF3_SSD_ROOT   SSD root for AlphaFold 3 source and data.
  AF3_SRC        Official AlphaFold 3 source checkout.
  AF3_DB_DIR     Target public_databases directory.
  AF3_LOG_FILE   Log file for background runs.
  AF3_PID_FILE   PID file for background runs.
  AF3_EXTRA_PATH Extra PATH prefix used to find zstd, if needed.
USAGE
}

ensure_official_script() {
  if [[ ! -x "$AF3_SRC/fetch_databases.sh" ]]; then
    echo "Missing executable official script: $AF3_SRC/fetch_databases.sh" >&2
    echo "Clone AlphaFold 3 into /mnt/ssd4t/protein-design/data/src/alphafold3 and run chmod +x fetch_databases.sh." >&2
    exit 1
  fi
}

start_background() {
  ensure_official_script
  mkdir -p "$AF3_DB_DIR" "$AF3_LOG_DIR"

  if [[ -f "$AF3_PID_FILE" ]]; then
    local old_pid
    old_pid="$(cat "$AF3_PID_FILE")"
    if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
      echo "AF3 database fetch already appears to be running: $old_pid"
      exit 0
    fi
  fi

  setsid bash -lc '
    set -euo pipefail
    cd "$1"
    export PATH="$2:$PATH"
    exec ./fetch_databases.sh "$3"
  ' bash "$AF3_SRC" "$AF3_EXTRA_PATH" "$AF3_DB_DIR" >"$AF3_LOG_FILE" 2>&1 < /dev/null &

  echo "$!" > "$AF3_PID_FILE"
  echo "Started AF3 database fetch: $(cat "$AF3_PID_FILE")"
  echo "Log: $AF3_LOG_FILE"
  echo "Database dir: $AF3_DB_DIR"
}

run_foreground() {
  ensure_official_script
  mkdir -p "$AF3_DB_DIR"
  cd "$AF3_SRC"
  export PATH="$AF3_EXTRA_PATH:$PATH"
  exec ./fetch_databases.sh "$AF3_DB_DIR"
}

show_status() {
  local saved_pid=""
  if [[ -f "$AF3_PID_FILE" ]]; then
    saved_pid="$(cat "$AF3_PID_FILE")"
    if [[ -n "$saved_pid" ]] && kill -0 "$saved_pid" 2>/dev/null; then
      echo "Process: running ($saved_pid)"
    else
      echo "Process: not running (stale PID file: $AF3_PID_FILE; saved PID: ${saved_pid:-empty})"
    fi
  else
    echo "Process: not running (PID file missing: $AF3_PID_FILE)"
  fi

  echo "Matching download processes:"
  pgrep -af 'fetch_databases|alphafold-databases|wget|zstd|tar --no-same-owner' || echo "  none"

  echo "Database size:"
  du -sh "$AF3_DB_DIR" 2>/dev/null || true

  local latest_log=""
  if [[ -d "$AF3_LOG_DIR" ]]; then
    latest_log="$(
      find "$AF3_LOG_DIR" -maxdepth 1 -type f -name 'af3-fetch-databases-*.log' -printf '%T@ %p\n' 2>/dev/null \
        | sort -nr \
        | head -n 1 \
        | cut -d' ' -f2- || true
    )"
  fi
  if [[ -n "$latest_log" ]]; then
    echo "Latest log: $latest_log"
    echo "Last log line: $(tail -n 1 "$latest_log")"
  fi
}

follow_log() {
  mkdir -p "$AF3_LOG_DIR"
  touch "$AF3_LOG_FILE"
  tail -f "$AF3_LOG_FILE"
}

case "${1:-start}" in
  start)
    start_background
    ;;
  foreground)
    run_foreground
    ;;
  status)
    show_status
    ;;
  log)
    follow_log
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
