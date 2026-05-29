#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import csv
import json
import re
from pathlib import Path

STANDARD_AA = set("ACDEFGHIKLMNPQRSTVWY")
NAME_RE = re.compile(r"[^A-Za-z0-9_.-]+")
CHAIN_RE = re.compile(r"chain_([A-Za-z0-9]+)_sequence$")


def read_rows(path: Path, delimiter: str):
    with open(path, "r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle, delimiter=delimiter)
        if not reader.fieldnames:
            raise SystemExit(f"input table has no header: {path}")
        for row in reader:
            if any((value or "").strip() for value in row.values()):
                yield {key.strip(): (value or "").strip() for key, value in row.items() if key}


def normalize_name(value: str):
    value = NAME_RE.sub("_", value.strip())
    value = value.strip("._-")
    if not value:
        raise ValueError("empty candidate name after sanitizing")
    return value


def normalize_sequence(value: str, allow_ambiguous: bool):
    sequence = re.sub(r"\s+", "", value).upper()
    if not sequence:
        raise ValueError("empty sequence")
    allowed = set("ABCDEFGHIJKLMNOPQRSTUVWXYZ") if allow_ambiguous else STANDARD_AA
    bad = sorted(set(sequence) - allowed)
    if bad:
        raise ValueError(f"unsupported residue code(s): {''.join(bad)}")
    return sequence


def candidate_name(row: dict, row_number: int):
    for key in ("name", "candidate", "candidate_id", "id"):
        if row.get(key):
            return normalize_name(row[key])
    return f"candidate_{row_number:03d}"


def collect_chains(row: dict, default_chain_id: str, allow_ambiguous: bool):
    chains = []

    if row.get("sequence"):
        chains.append(
            {
                "id": row.get("chain_id") or default_chain_id,
                "sequence": normalize_sequence(row["sequence"], allow_ambiguous),
            }
        )
        return chains

    paired_columns = [
        ("target_sequence", "target_id", "A"),
        ("peptide_sequence", "peptide_id", "B"),
        ("binder_sequence", "binder_id", "B"),
    ]
    for seq_key, id_key, fallback_id in paired_columns:
        if row.get(seq_key):
            chains.append(
                {
                    "id": row.get(id_key) or fallback_id,
                    "sequence": normalize_sequence(row[seq_key], allow_ambiguous),
                }
            )

    for key, value in sorted(row.items()):
        match = CHAIN_RE.match(key)
        if match and value:
            chains.append(
                {
                    "id": match.group(1).upper(),
                    "sequence": normalize_sequence(value, allow_ambiguous),
                }
            )

    if not chains:
        raise ValueError(
            "missing sequence column; use sequence, target_sequence/peptide_sequence, "
            "or chain_<id>_sequence"
        )

    seen = set()
    for chain in chains:
        chain_id = chain["id"]
        if chain_id in seen:
            raise ValueError(f"duplicate chain id: {chain_id}")
        seen.add(chain_id)

    return chains


def write_af3_json(path: Path, name: str, chains: list, seed: int):
    payload = {
        "name": name,
        "sequences": [
            {
                "protein": {
                    "id": chain["id"],
                    "sequence": chain["sequence"],
                }
            }
            for chain in chains
        ],
        "modelSeeds": [seed],
        "dialect": "alphafold3",
        "version": 1,
    }
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)
        handle.write("\n")


def to_container_path(path: Path, repo_root: Path):
    resolved = path.resolve()
    try:
        rel = resolved.relative_to(repo_root.resolve())
    except ValueError:
        return str(path)
    parts = rel.parts
    if parts and parts[0] == "data":
        return "/" + str(rel)
    if parts and parts[0] == "examples":
        return "/workspace/" + str(rel)
    return str(path)


def build_parser():
    parser = argparse.ArgumentParser(
        description="Convert a peptide candidate table into AlphaFold 3 JSON inputs."
    )
    parser.add_argument("--input-csv", required=True, help="Candidate CSV/TSV table.")
    parser.add_argument("--out-dir", required=True, help="Output directory for AF3 JSON files.")
    parser.add_argument(
        "--manifest",
        default="manifest.csv",
        help="Manifest CSV path. Bare filenames are resolved under --out-dir.",
    )
    parser.add_argument("--seed", type=int, default=1, help="AF3 model seed. Default: 1.")
    parser.add_argument("--chain-id", default="A", help="Default chain id for one-chain rows.")
    parser.add_argument(
        "--delimiter",
        default="auto",
        help="Input delimiter: auto, comma, tab, or a single character. Default: auto.",
    )
    parser.add_argument(
        "--allow-ambiguous",
        action="store_true",
        help="Allow non-standard uppercase residue letters instead of only the 20 standard amino acids.",
    )
    parser.add_argument("--force", action="store_true", help="Overwrite existing JSON files.")
    return parser


def resolve_delimiter(path: Path, value: str):
    if value == "auto":
        return "\t" if path.suffix.lower() in {".tsv", ".tab"} else ","
    if value == "comma":
        return ","
    if value == "tab":
        return "\t"
    if len(value) != 1:
        raise SystemExit(f"delimiter must be auto, comma, tab, or one character: {value}")
    return value


def main():
    parser = build_parser()
    args = parser.parse_args()

    input_csv = Path(args.input_csv)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    manifest_path = Path(args.manifest)
    if not manifest_path.is_absolute() and manifest_path.parent == Path("."):
        manifest_path = out_dir / manifest_path

    repo_root = Path(__file__).resolve().parents[1]
    delimiter = resolve_delimiter(input_csv, args.delimiter)

    manifest_rows = []
    for row_number, row in enumerate(read_rows(input_csv, delimiter), start=1):
        try:
            name = candidate_name(row, row_number)
            chains = collect_chains(row, args.chain_id, args.allow_ambiguous)
        except ValueError as exc:
            raise SystemExit(f"{input_csv}:{row_number + 1}: {exc}") from exc

        json_path = out_dir / f"{name}.json"
        if json_path.exists() and not args.force:
            raise SystemExit(f"refusing to overwrite existing file without --force: {json_path}")

        write_af3_json(json_path, name, chains, args.seed)
        manifest_rows.append(
            {
                "name": name,
                "host_json_path": str(json_path),
                "container_json_path": to_container_path(json_path, repo_root),
                "num_chains": len(chains),
                "total_length": sum(len(chain["sequence"]) for chain in chains),
                "chain_ids": ";".join(chain["id"] for chain in chains),
                "description": row.get("description", ""),
            }
        )

    with open(manifest_path, "w", encoding="utf-8", newline="") as handle:
        fieldnames = [
            "name",
            "host_json_path",
            "container_json_path",
            "num_chains",
            "total_length",
            "chain_ids",
            "description",
        ]
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(manifest_rows)

    print(f"Wrote {len(manifest_rows)} AF3 JSON file(s) to {out_dir}")
    print(f"Manifest: {manifest_path}")


if __name__ == "__main__":
    main()
