#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE=(docker compose -f "$ROOT_DIR/compose/docker-compose.yml")

usage() {
  cat <<'EOF'
Usage: scripts/smoke-test.sh <target>

Targets:
  compose     Validate Docker Compose configuration
  host-gpu    Check host NVIDIA driver
  foundry     Check Foundry Python environment
  bindcraft   Check BindCraft installation
  af2         Check AlphaFold Multimer JAX GPU runtime
  af3         Check AlphaFold 3 image, model file, and JAX runtime
  rosetta     Check Rosetta database mount via Compose
  pepmimic    Check PepMimic PyTorch CUDA runtime
  rfpeptide   Check RFpeptide fixed image runtime
  all         Run all checks
EOF
}

run_compose() {
  "${COMPOSE[@]}" config --quiet
}

run_host_gpu() {
  nvidia-smi
}

run_foundry() {
  "${COMPOSE[@]}" --profile foundry run --rm --no-deps pd-foundry-gpu \
    bash -lc '/opt/conda/bin/conda run -n foundry python -c "import numpy,pandas,Bio; print(\"foundry ok\")"'
}

run_bindcraft() {
  "${COMPOSE[@]}" --profile bindcraft run --rm --no-deps pd-bindcraft-gpu \
    bash -lc 'test -d /opt/BindCraft && /opt/conda/bin/conda env list | grep -q BindCraft && echo "bindcraft ok"'
}

run_af2() {
  timeout 90s "${COMPOSE[@]}" --profile af2 run --rm --no-deps pd-af2multimer-gpu \
    bash -lc 'af2multimer-check'
}

run_af3() {
  timeout 120s "${COMPOSE[@]}" --profile af3 run --rm --no-deps pd-af3-gpu \
    bash -lc 'test -f /root/models/af3.bin.zst && python -c "import jax, alphafold3; print(\"jax\", jax.__version__); print(\"devices\", jax.devices()); print(\"alphafold3 ok\")"'
}

run_rosetta() {
  "${COMPOSE[@]}" --profile rosetta run --rm --no-deps pd-rosetta-cpu-parallel \
    bash -lc 'test -f /opt/rosetta_db/scoring/weights/ref2015.wts && echo "rosetta db ok"'
}

run_pepmimic() {
  "${COMPOSE[@]}" --profile pepmimic run --rm --no-deps pd-pepmimic-gpu \
    bash -lc '/opt/conda/bin/conda run -n pepmimic python -c "import torch; print(\"torch\", torch.__version__, torch.version.cuda, torch.cuda.is_available())"'
}

run_rfpeptide() {
  "${COMPOSE[@]}" --profile rfpeptide run --rm --no-deps pd-rfpeptide-gpu \
    bash -lc 'source /opt/conda/etc/profile.d/conda.sh && conda activate SE3cuda && python -c "import torch,dgl; print(\"torch\", torch.__version__, torch.version.cuda, torch.cuda.is_available()); print(\"dgl\", dgl.__version__)"'
}

target="${1:-}"
case "$target" in
  compose) run_compose ;;
  host-gpu) run_host_gpu ;;
  foundry) run_foundry ;;
  bindcraft) run_bindcraft ;;
  af2) run_af2 ;;
  af3) run_af3 ;;
  rosetta) run_rosetta ;;
  pepmimic) run_pepmimic ;;
  rfpeptide) run_rfpeptide ;;
  all)
    run_compose
    run_host_gpu
    run_foundry
    run_bindcraft
    run_af2
    run_af3
    run_rosetta
    run_pepmimic
    run_rfpeptide
    ;;
  *)
    usage
    exit 2
    ;;
esac
