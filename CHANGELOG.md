# Changelog

## Unreleased

No unreleased changes.

## v0.4.0 - 2026-05-29

### Added

- Added AF3 batch utilities for peptide candidate screening:
  `scripts/prepare_af3_batch.py`, `scripts/run_af3_batch.py`, and
  `scripts/summarize_af3_results.py`.
- Added `examples/af3-batch/` with a peptide candidate table, batch wrapper,
  and beginner-facing README.
- Added `docs/af3-batch-validation.md` for the peptide-candidate-to-AF3-summary
  workflow.
- Added local image archives and checksum records for
  `pd-bindcraft-gpu:installed`, `pd-pepmimic-gpu:latest`, and
  `pd-rfpeptide-gpu:fixed`.

### Changed

- Updated README, examples, and Chinese beginner guide with AF3 batch
  validation commands and result-summary guidance.

### Verified

- `./examples/af3-batch/run-peptide-batch.sh` in dry-run mode.
- `python3 scripts/summarize_af3_results.py --root-dir data/outputs/examples/af3-example --out-csv /tmp/af3-example-summary.csv --top 5`
- `python3 -m py_compile scripts/prepare_af3_batch.py scripts/run_af3_batch.py scripts/summarize_af3_results.py`
- `./scripts/smoke-test.sh af3`
- `sha256sum -c releases/pd-bindcraft-gpu_installed_20260529.tar.sha256`
- `sha256sum -c releases/pd-pepmimic-gpu_latest_20260529.tar.sha256`
- `sha256sum -c releases/pd-rfpeptide-gpu_fixed_20260529.tar.sha256`

## v0.3.1 - 2026-05-29

### Changed

- Documented the first successful full AF3 example run against the completed
  local database.

### Verified

- `RUN_FULL=1 ./examples/af3/run-check-or-full.sh`
- Output written to `data/outputs/examples/af3-example/example_peptide/`.
- AF3 protein MSA search completed in about `1506 s`; model inference completed
  in about `79 s` on the current HDD-backed database layout.

## v0.3.0 - 2026-05-29

### Added

- Added a Nature Methods-style `imagegen` graphical abstract and academic
  method-level flow diagrams to the README, covering each Docker image and the
  overall project workflow.
- Linked the graphical abstract from `docs/service-flows.md` and explained it
  for beginner readers in `docs/undergrad-guide-zh.md`.
- Added a large project icon plus generated explanatory figures for the
  method-level information flow and each per-image workflow in the README.
- Added Docker packaging and image archive documentation for AF3 and other
  high-priority local images.
- Created local AF3 image archive
  `releases/pd-af3-gpu_v3.0.2_20260529.tar` with SHA256
  `aed72560055a05a1d8c92610f882f9e36bde65a309004b8957850c91e5664fa1`.

### Changed

- Updated README and AF3 docs to describe the image/runtime-asset boundary:
  AF3 software is in `pd-af3-gpu:v3.0.2`, while weights and databases stay
  mounted from `data/alphafold3/`.
- Improved `scripts/fetch-af3-databases.sh status` so completed or stale PID
  states are explicit.

### Verified

- AF3 database fetch completed successfully under
  `data/alphafold3/public_databases/`.
- AF3 public databases use about `627G`; `mmcif_files/` contains `195859`
  files.

## v0.2.0 - 2026-05-28

### Added

- Added local AlphaFold 3 image workflow documentation and examples.
- Added `pd-af3-gpu` Compose service using the independently built
  `pd-af3-gpu:v3.0.2` image.
- Added AF3 smoke/full-run wrapper under `examples/af3/`.
- Added `scripts/fetch-af3-databases.sh` to launch the official AF3 database
  fetch script with project paths and logging.

### Changed

- Moved the AF3 model file into `data/alphafold3/models/af3.bin.zst` for direct
  container mounting.

### Verified

- `docker compose -f compose/docker-compose.yml config --quiet`
- Shell syntax checks for `examples/**/*.sh` and `scripts/**/*.sh`.
- `./scripts/smoke-test.sh af3`
- `./examples/af3/run-check-or-full.sh` in check mode.
- Official AF3 database fetch starts and populates
  `data/alphafold3/public_databases`; full AF3 prediction runs require the
  database fetch to complete first.

## v0.1.0 - 2026-05-28

Initial documented local peptide design workbench release.

### Added

- Bilingual English/Chinese README for the local protein design workbench.
- Docker Compose workflow documentation for Foundry/RFD3/ProteinMPNN/LigandMPNN,
  BindCraft, AlphaFold Multimer, Rosetta, PepMimic, and RFpeptide services.
- Runnable example scripts under `examples/` for peptide generation,
  modification, validation, Rosetta relaxation, and confidence-table merging.
- Detailed Chinese undergraduate guide for pharmacy students, including Linux
  basics, shell script usage, command parameters, and peptide workflow examples.
- Service flow diagrams in `docs/service-flows.md`.
- `.Trash/` cleanup policy for redundant local files that should be moved aside
  instead of deleted.

### Verified

- `docker compose -f compose/docker-compose.yml config --quiet`
- Shell syntax checks for all `examples/**/*.sh` scripts.
- `scripts/merge_confidence_tables.py --help`
- Example smoke runs for Foundry/MPNN, AlphaFold Multimer environment checks,
  Rosetta relaxation, and confidence-table merge.
