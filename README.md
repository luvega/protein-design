# Protein Design Workbench

Docker-based local workbench for protein design workflows on this machine.

This repository tracks only lightweight engineering assets. Large local assets
stay outside Git under `data/` and `releases/`.

## Repository Policy

Tracked in Git:

- `compose/`: Docker Compose service definitions
- `images/*/Dockerfile`: Docker build recipes
- `scripts/`: utility scripts
- `docs/`, `README.md`, `.gitignore`, and other small configuration files

Not tracked in Git:

- model weights and checkpoints
- Rosetta source/database assets
- AlphaFold, BindCraft, Foundry, PepMimic, and RFdiffusion parameters
- generated outputs and score tables
- Docker image archives and release bundles
- local crash logs, PDFs, shell history, and editor caches

## Local Asset Layout

- `data/inputs/`: input structures and workflow configuration
- `data/outputs/`: generated workflow outputs
- `data/alphafold_db/`: AlphaFold parameter/database assets
- `data/bindcraft_models/`: BindCraft model parameters
- `data/foundry_checkpoints/`: Foundry/ProteinMPNN/LigandMPNN checkpoints
- `data/pepmimic_checkpoints/`: PepMimic checkpoints
- `data/rfpeptide_models/`: RFpeptide/RFdiffusion checkpoints
- `data/rosetta_db`: symlink to the local Rosetta database
- `releases/`: exported local image bundles

## Compose Profiles

| Profile | Service | Purpose | GPU |
| --- | --- | --- | --- |
| `foundry`, `design`, `rfd3`, `mpnn` | `pd-foundry-gpu` | Foundry/RFD3/MPNN workflows | yes |
| `bindcraft` | `pd-bindcraft-gpu` | BindCraft binder design | yes |
| `af2`, `multimer` | `pd-af2multimer-gpu` | AlphaFold Multimer validation | yes |
| `rosetta`, `post`, `rosetta-parallel` | `pd-rosetta-cpu-parallel` | Rosetta relax/scoring/post-processing | no |
| `pepmimic` | `pd-pepmimic-gpu` | PepMimic workflows | yes |
| `rfpeptide`, `macrocycle` | `pd-rfpeptide-gpu` | RFpeptide/RFdiffusion macrocycle workflows | yes |

## Common Commands

Validate Compose configuration:

```bash
docker compose -f compose/docker-compose.yml config --quiet
```

Check host GPU:

```bash
nvidia-smi
```

Open a service shell:

```bash
docker compose -f compose/docker-compose.yml --profile foundry run --rm pd-foundry-gpu
docker compose -f compose/docker-compose.yml --profile bindcraft run --rm pd-bindcraft-gpu
docker compose -f compose/docker-compose.yml --profile af2 run --rm pd-af2multimer-gpu
docker compose -f compose/docker-compose.yml --profile rosetta run --rm pd-rosetta-cpu-parallel
docker compose -f compose/docker-compose.yml --profile pepmimic run --rm pd-pepmimic-gpu
docker compose -f compose/docker-compose.yml --profile rfpeptide run --rm pd-rfpeptide-gpu
```

Run smoke checks:

```bash
./scripts/smoke-test.sh all
```

## Operational Notes

- Use Compose for Rosetta so that `data/rosetta_db` is mounted at
  `/opt/rosetta_db`.
- Use `pd-rfpeptide-gpu:fixed` for RFpeptide. The local `latest` tag is not the
  known-good runtime.
- Do not commit local model files or workflow outputs. Check `git status`
  before every commit.
- Docker build cache is large on this machine. Do not prune it until critical
  images are exported or confirmed rebuildable.
