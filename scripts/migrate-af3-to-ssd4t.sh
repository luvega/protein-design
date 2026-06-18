#!/usr/bin/env bash
set -euo pipefail

DISK="${DISK:-/dev/nvme1n1}"
PART="${PART:-/dev/nvme1n1p1}"
MOUNT="${MOUNT:-/mnt/ssd4t}"
SSD_ROOT="${SSD_ROOT:-$MOUNT/protein-design}"
PROJECT_ROOT="${PROJECT_ROOT:-/data/protein-design}"
LABEL="${LABEL:-ssd4t}"
EXPECTED_MODEL="${EXPECTED_MODEL:-ZHITAI TiPlus7100 4TB}"
EXPECTED_SERIAL="${EXPECTED_SERIAL:-ZTA54T0AB2348290H0}"
MIGRATE_DOCKER_ROOT="${MIGRATE_DOCKER_ROOT:-0}"
DOCKER_ROOT="${DOCKER_ROOT:-$MOUNT/docker}"

AF3_ARCHIVE="pd-af3-gpu_v3.0.2_20260529.tar"
AF3_ARCHIVE_SHA="pd-af3-gpu_v3.0.2_20260529.tar.sha256"

usage() {
  cat <<'USAGE'
Usage:
  sudo scripts/migrate-af3-to-ssd4t.sh

This clears /dev/nvme1n1, formats it as ext4, mounts it at /mnt/ssd4t,
and moves the local AlphaFold 3 source, model, database, cache, and image
archive assets to deterministic SSD paths under /mnt/ssd4t/protein-design.

No symlinks are created. Project Compose and docs refer directly to
/mnt/ssd4t/protein-design paths.

Optional:
  sudo MIGRATE_DOCKER_ROOT=1 scripts/migrate-af3-to-ssd4t.sh

MIGRATE_DOCKER_ROOT=1 moves Docker's global data-root to /mnt/ssd4t/docker.
That affects all local Docker images and containers, not just AlphaFold 3.
USAGE
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "error: run with sudo because this formats a block device and updates /etc/fstab" >&2
    exit 1
  fi
}

require_device_match() {
  local model serial
  model="$(lsblk -dn -o MODEL "$DISK" | sed 's/[[:space:]]*$//')"
  serial="$(lsblk -dn -o SERIAL "$DISK" | sed 's/[[:space:]]*$//')"

  if [[ "$model" != "$EXPECTED_MODEL" || "$serial" != "$EXPECTED_SERIAL" ]]; then
    echo "error: refusing to format unexpected device" >&2
    echo "  disk: $DISK" >&2
    echo "  model: '$model' expected '$EXPECTED_MODEL'" >&2
    echo "  serial: '$serial' expected '$EXPECTED_SERIAL'" >&2
    exit 1
  fi

  local mounted_at=""
  mounted_at="$(findmnt -rn -S "$PART" -o TARGET 2>/dev/null || true)"
  if [[ -n "$mounted_at" && "$mounted_at" != "$MOUNT" ]]; then
    echo "error: $PART is mounted at $mounted_at, not $MOUNT" >&2
    exit 1
  fi
}

format_and_mount() {
  if [[ "$(findmnt -rn -S "$PART" -o TARGET 2>/dev/null || true)" == "$MOUNT" ]]; then
    echo "$PART is already mounted at $MOUNT; skipping format"
    return
  fi

  echo "Formatting $DISK and mounting $PART at $MOUNT"
  wipefs -a "$DISK"
  sgdisk --zap-all "$DISK"
  sgdisk -n 1:0:0 -t 1:8300 -c 1:"protein-design-ssd4t" "$DISK"
  partprobe "$DISK"
  udevadm settle
  mkfs.ext4 -F -L "$LABEL" "$PART"

  mkdir -p "$MOUNT"
  local uuid
  uuid="$(blkid -s UUID -o value "$PART")"
  cp -a /etc/fstab "/etc/fstab.bak-$(date +%Y%m%d-%H%M%S)"
  if grep -qE "[[:space:]]$MOUNT[[:space:]]" /etc/fstab; then
    sed -i "s#^[^#].*[[:space:]]$MOUNT[[:space:]].*#UUID=$uuid $MOUNT ext4 defaults,nofail 0 2#" /etc/fstab
  else
    printf 'UUID=%s %s ext4 defaults,nofail 0 2\n' "$uuid" "$MOUNT" >> /etc/fstab
  fi

  mount "$MOUNT"
  chown a:a "$MOUNT"
}

copy_dir_contents() {
  local src="$1"
  local dst="$2"
  if [[ ! -d "$src" ]]; then
    echo "skip missing directory: $src"
    return
  fi
  mkdir -p "$dst"
  rsync -aHAX --numeric-ids --info=progress2 "$src/" "$dst/"
}

copy_file() {
  local src="$1"
  local dst="$2"
  if [[ ! -f "$src" ]]; then
    echo "skip missing file: $src"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  rsync -aHAX --numeric-ids --info=progress2 "$src" "$dst"
}

require_copied_path() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "error: expected copied path is missing: $path" >&2
    exit 1
  fi
}

remove_old_af3_assets() {
  echo "Removing old AF3 large assets from HDD project tree"
  rm -rf "$PROJECT_ROOT/data/alphafold3"
  rm -rf "$PROJECT_ROOT/data/src/alphafold3"
  rm -f "$PROJECT_ROOT/releases/$AF3_ARCHIVE"
  rm -f "$PROJECT_ROOT/releases/$AF3_ARCHIVE_SHA"
}

migrate_af3_assets() {
  local ssd_af3="$SSD_ROOT/data/alphafold3"
  local ssd_src="$SSD_ROOT/data/src/alphafold3"
  local ssd_release="$SSD_ROOT/releases"

  mkdir -p "$SSD_ROOT/data" "$SSD_ROOT/data/src" "$ssd_release"

  copy_dir_contents "$PROJECT_ROOT/data/alphafold3" "$ssd_af3"
  copy_dir_contents "$PROJECT_ROOT/data/src/alphafold3" "$ssd_src"
  copy_file "$PROJECT_ROOT/releases/$AF3_ARCHIVE" "$ssd_release/$AF3_ARCHIVE"
  copy_file "$PROJECT_ROOT/releases/$AF3_ARCHIVE_SHA" "$ssd_release/$AF3_ARCHIVE_SHA"

  require_copied_path "$ssd_af3/models/af3.bin.zst"
  require_copied_path "$ssd_af3/public_databases"
  require_copied_path "$ssd_src/fetch_databases.sh"
  require_copied_path "$ssd_release/$AF3_ARCHIVE"

  if [[ -f "$ssd_release/$AF3_ARCHIVE_SHA" ]]; then
    (cd "$SSD_ROOT" && sha256sum -c "releases/$AF3_ARCHIVE_SHA")
  fi

  remove_old_af3_assets
  chown -R a:a "$SSD_ROOT"
}

migrate_docker_root() {
  if [[ "$MIGRATE_DOCKER_ROOT" != "1" ]]; then
    return
  fi

  local current_root
  current_root="$(docker info --format '{{.DockerRootDir}}' 2>/dev/null || echo /var/lib/docker)"
  if [[ "$current_root" == "$DOCKER_ROOT" ]]; then
    echo "Docker data-root is already $DOCKER_ROOT"
    return
  fi

  echo "Migrating Docker data-root from $current_root to $DOCKER_ROOT"
  systemctl stop docker
  systemctl stop containerd || true

  mkdir -p "$DOCKER_ROOT"
  if [[ -d "$current_root" && -n "$(find "$current_root" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    rsync -aHAX --numeric-ids --info=progress2 "$current_root/" "$DOCKER_ROOT/"
    mv "$current_root" "${current_root}.hdd-backup-$(date +%Y%m%d-%H%M%S)"
  fi

  cp -a /etc/docker/daemon.json "/etc/docker/daemon.json.bak-$(date +%Y%m%d-%H%M%S)"
  python3 - <<PY
import json
from pathlib import Path

path = Path("/etc/docker/daemon.json")
data = json.loads(path.read_text()) if path.exists() and path.read_text().strip() else {}
data["data-root"] = "$DOCKER_ROOT"
path.write_text(json.dumps(data, indent=4, ensure_ascii=False) + "\n")
PY

  systemctl start containerd || true
  systemctl start docker
}

verify_migration() {
  echo "Mounted SSD:"
  findmnt "$MOUNT"
  df -hT "$MOUNT"

  echo "AF3 SSD paths:"
  du -sh "$SSD_ROOT/data/alphafold3" "$SSD_ROOT/data/src/alphafold3" \
    "$SSD_ROOT/releases/$AF3_ARCHIVE"

  echo "AF3 HDD paths should be absent:"
  test ! -e "$PROJECT_ROOT/data/alphafold3"
  test ! -e "$PROJECT_ROOT/data/src/alphafold3"
  test ! -e "$PROJECT_ROOT/releases/$AF3_ARCHIVE"

  if [[ "$MIGRATE_DOCKER_ROOT" == "1" ]]; then
    docker info --format 'Docker Root Dir: {{.DockerRootDir}}'
    docker load -i "$SSD_ROOT/releases/$AF3_ARCHIVE"
    docker image ls --format '{{.Repository}}:{{.Tag}} {{.ID}} {{.Size}}' | grep '^pd-af3-gpu:v3.0.2 '
  fi
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi
  require_root
  require_device_match
  format_and_mount
  migrate_af3_assets
  migrate_docker_root
  verify_migration
}

main "$@"
