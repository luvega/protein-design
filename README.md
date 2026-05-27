# Protein Design Workbench

Docker-based local workbench for protein design workflows on this machine.

Tracked in Git:

- Docker Compose service definitions in `compose/`
- Docker build recipes in `images/`
- Utility scripts in `scripts/`
- Project documentation and lightweight configuration

Not tracked in Git:

- Model weights and checkpoints
- Rosetta source/database assets
- AlphaFold/BindCraft/RFdiffusion parameters
- Generated outputs
- Docker image archives and release bundles

Those large assets are kept locally under `data/` and `releases/`.

## Common Commands

Validate Compose configuration:

```bash
docker compose -f compose/docker-compose.yml config --quiet
```

Open a service shell:

```bash
docker compose -f compose/docker-compose.yml --profile bindcraft run --rm pd-bindcraft-gpu
docker compose -f compose/docker-compose.yml --profile af2 run --rm pd-af2multimer-gpu
docker compose -f compose/docker-compose.yml --profile rosetta run --rm pd-rosetta-cpu-parallel
docker compose -f compose/docker-compose.yml --profile rfpeptide run --rm pd-rfpeptide-gpu
```

Check host GPU:

```bash
nvidia-smi
```
