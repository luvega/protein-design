# Changelog

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
