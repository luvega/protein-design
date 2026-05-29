#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import csv
import os
from pathlib import Path
import subprocess


def read_manifest(path: Path):
    with open(path, "r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        required = {"name", "container_json_path"}
        missing = required - set(reader.fieldnames or [])
        if missing:
            raise SystemExit(f"manifest is missing column(s): {', '.join(sorted(missing))}")
        for row in reader:
            if row.get("name") and row.get("container_json_path"):
                yield row


def build_parser():
    parser = argparse.ArgumentParser(
        description="Run AF3 full predictions for every JSON listed in a prepared manifest."
    )
    parser.add_argument("--manifest", required=True, help="Manifest from prepare_af3_batch.py.")
    parser.add_argument(
        "--output-dir",
        default="/data/outputs/af3-batch",
        help="Container output root passed to AF3. Default: /data/outputs/af3-batch",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Run only the first N manifest rows. 0 means all rows.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Print commands without running AF3.")
    parser.add_argument(
        "--continue-on-error",
        action="store_true",
        help="Continue with later candidates if one AF3 run fails.",
    )
    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[1]
    af3_wrapper = repo_root / "examples" / "af3" / "run-check-or-full.sh"
    rows = list(read_manifest(Path(args.manifest)))
    if args.limit > 0:
        rows = rows[: args.limit]
    if not rows:
        raise SystemExit("manifest has no runnable rows")

    failures = []
    for index, row in enumerate(rows, start=1):
        name = row["name"]
        json_path = row["container_json_path"]
        env = os.environ.copy()
        env.update(
            {
                "RUN_FULL": "1",
                "JSON_PATH": json_path,
                "OUTPUT_DIR": args.output_dir,
            }
        )
        printable = (
            f"RUN_FULL=1 JSON_PATH={json_path} OUTPUT_DIR={args.output_dir} "
            f"{af3_wrapper}"
        )
        print(f"[{index}/{len(rows)}] {name}")
        print(printable)
        if args.dry_run:
            continue

        result = subprocess.run([str(af3_wrapper)], cwd=repo_root, env=env)
        if result.returncode != 0:
            failures.append((name, result.returncode))
            if not args.continue_on_error:
                raise SystemExit(result.returncode)

    if failures:
        details = ", ".join(f"{name}:{code}" for name, code in failures)
        raise SystemExit(f"AF3 batch completed with failures: {details}")


if __name__ == "__main__":
    main()
