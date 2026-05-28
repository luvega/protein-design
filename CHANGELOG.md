# Changelog

## Unreleased

No unreleased changes.

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
