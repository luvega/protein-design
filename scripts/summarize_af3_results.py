#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import csv
import json
from pathlib import Path


BASE_COLUMNS = [
    "job_name",
    "seed",
    "sample",
    "ranking_score",
    "ptm",
    "iptm",
    "has_clash",
    "fraction_disordered",
    "chain_ptm",
    "chain_iptm",
    "chain_pair_iptm",
    "chain_pair_pae_min",
    "output_dir",
    "model_cif",
    "sample_model_cif",
    "summary_json",
    "ranking_csv",
]


def load_json(path: Path):
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def json_text(value):
    if value is None:
        return ""
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def parse_float(value):
    if value in {None, ""}:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def score_for_sort(row):
    value = parse_float(row.get("ranking_score"))
    return value if value is not None else float("-inf")


def discover_job_dirs(root_dir: Path):
    dirs = set()
    for ranking_csv in root_dir.rglob("*_ranking_scores.csv"):
        dirs.add(ranking_csv.parent)
    for summary_json in root_dir.rglob("*_summary_confidences.json"):
        if not summary_json.parent.name.startswith("seed-"):
            dirs.add(summary_json.parent)
    return sorted(dirs)


def first_match(directory: Path, pattern: str):
    matches = sorted(directory.glob(pattern))
    return matches[0] if matches else None


def ranking_rows(ranking_csv: Path):
    if not ranking_csv:
        return [{}]
    with open(ranking_csv, "r", encoding="utf-8-sig", newline="") as handle:
        rows = list(csv.DictReader(handle))
    return rows or [{}]


def summarize_job(job_dir: Path):
    job_name = job_dir.name
    summary_json = first_match(job_dir, "*_summary_confidences.json")
    ranking_csv = first_match(job_dir, "*_ranking_scores.csv")
    model_cif = first_match(job_dir, "*_model.cif")
    summary = load_json(summary_json) if summary_json else {}

    rows = []
    for ranking in ranking_rows(ranking_csv):
        seed = ranking.get("seed", "")
        sample = ranking.get("sample", "")
        sample_model = ""
        if seed != "" and sample != "":
            sample_model_path = job_dir / f"seed-{seed}_sample-{sample}" / f"{job_name}_seed-{seed}_sample-{sample}_model.cif"
            if sample_model_path.exists():
                sample_model = str(sample_model_path)

        row = {
            "job_name": job_name,
            "seed": seed,
            "sample": sample,
            "ranking_score": ranking.get("ranking_score") or summary.get("ranking_score", ""),
            "ptm": summary.get("ptm", ""),
            "iptm": summary.get("iptm", ""),
            "has_clash": summary.get("has_clash", ""),
            "fraction_disordered": summary.get("fraction_disordered", ""),
            "chain_ptm": json_text(summary.get("chain_ptm")),
            "chain_iptm": json_text(summary.get("chain_iptm")),
            "chain_pair_iptm": json_text(summary.get("chain_pair_iptm")),
            "chain_pair_pae_min": json_text(summary.get("chain_pair_pae_min")),
            "output_dir": str(job_dir),
            "model_cif": str(model_cif) if model_cif else "",
            "sample_model_cif": sample_model,
            "summary_json": str(summary_json) if summary_json else "",
            "ranking_csv": str(ranking_csv) if ranking_csv else "",
        }
        rows.append(row)
    return rows


def build_parser():
    parser = argparse.ArgumentParser(
        description="Summarize AlphaFold 3 output folders into a ranked CSV table."
    )
    parser.add_argument(
        "--root-dir",
        required=True,
        help="Directory containing AF3 job output folders.",
    )
    parser.add_argument(
        "--out-csv",
        default="af3_summary.csv",
        help="Output CSV path. Relative paths are resolved under --root-dir.",
    )
    parser.add_argument(
        "--top",
        type=int,
        default=0,
        help="Print the top N rows after writing the CSV. 0 disables printing.",
    )
    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()

    root_dir = Path(args.root_dir)
    if not root_dir.exists():
        raise SystemExit(f"root directory does not exist: {root_dir}")

    out_csv = Path(args.out_csv)
    if not out_csv.is_absolute():
        out_csv = root_dir / out_csv
    out_csv.parent.mkdir(parents=True, exist_ok=True)

    rows = []
    for job_dir in discover_job_dirs(root_dir):
        rows.extend(summarize_job(job_dir))
    rows.sort(key=score_for_sort, reverse=True)

    with open(out_csv, "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=BASE_COLUMNS)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} row(s) to {out_csv}")
    if args.top > 0:
        for row in rows[: args.top]:
            print(
                f"{row['job_name']}\tseed={row['seed']}\tsample={row['sample']}\t"
                f"ranking_score={row['ranking_score']}\tptm={row['ptm']}"
            )


if __name__ == "__main__":
    main()
