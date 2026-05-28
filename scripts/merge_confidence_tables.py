#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import json
from pathlib import Path
import numpy as np
import pandas as pd

DEFAULT_ROOT_DIR = "/data/outputs/AAAWZY/0326-gamma-Lmpnn-rf3"
DEFAULT_OUT_CSV = "summarize/final_merged_confidence_table.csv"
DEFAULT_OUT_XLSX = "summarize/final_merged_confidence_table.xlsx"
DEFAULT_SORT_BY = ["ranking_score", "overall_plddt", "mean_atom_plddt"]
DEFAULT_ASCENDING = [False, False, False]
DEFAULT_LOW_THRESHOLDS = [0.7, 0.5]
DEFAULT_HIGH_THRESHOLDS = [0.8, 0.9]


def threshold_suffix(threshold):
    return f"{threshold:g}".replace(".", "_")


def load_json(path: Path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def longest_run(mask):
    best = 0
    cur = 0
    for x in mask:
        if x:
            cur += 1
            if cur > best:
                best = cur
        else:
            cur = 0
    return best


def parse_location(json_path: Path, root_dir: Path):
    rel_parts = json_path.relative_to(root_dir).parts
    group_folder = rel_parts[0] if len(rel_parts) >= 1 else ""
    sample_folder = rel_parts[1] if len(rel_parts) >= 3 else "ROOT"
    return group_folder, sample_folder, str(json_path.relative_to(root_dir))


def summarize_summary_json(json_path: Path, root_dir: Path):
    data = load_json(json_path)
    group_folder, sample_folder, rel_path = parse_location(json_path, root_dir)

    return {
        "group_folder": group_folder,
        "sample_folder": sample_folder,
        "summary_json_file": json_path.name,
        "summary_relative_path": rel_path,
        "overall_plddt": data.get("overall_plddt"),
        "overall_pde": data.get("overall_pde"),
        "overall_pae": data.get("overall_pae"),
        "ptm": data.get("ptm"),
        "iptm": data.get("iptm"),
        "has_clash": data.get("has_clash"),
        "ranking_score": data.get("ranking_score"),
        "chain_ptm": json.dumps(data.get("chain_ptm"), ensure_ascii=False),
        "chain_pair_pae_min": json.dumps(data.get("chain_pair_pae_min"), ensure_ascii=False),
        "chain_pair_pde_min": json.dumps(data.get("chain_pair_pde_min"), ensure_ascii=False),
    }


def summarize_atom_conf_json(json_path: Path, root_dir: Path, low_thresholds, high_thresholds):
    data = load_json(json_path)
    group_folder, sample_folder, rel_path = parse_location(json_path, root_dir)

    atom_plddts = data.get("atom_plddts", [])
    atom_chain_ids = data.get("atom_chain_ids", [])

    if not atom_plddts:
        return {
            "group_folder": group_folder,
            "sample_folder": sample_folder,
            "atom_json_file": json_path.name,
            "atom_relative_path": rel_path,
        }

    atom_plddts = np.array(atom_plddts, dtype=float)
    if atom_chain_ids and len(atom_chain_ids) == len(atom_plddts):
        atom_chain_ids = np.array(atom_chain_ids, dtype=object)
    else:
        atom_chain_ids = np.array(["UNK"] * len(atom_plddts), dtype=object)

    row = {
        "group_folder": group_folder,
        "sample_folder": sample_folder,
        "atom_json_file": json_path.name,
        "atom_relative_path": rel_path,
        "n_atoms": int(len(atom_plddts)),
        "n_chains": int(len(set(atom_chain_ids.tolist()))),
        "chains": ",".join(sorted(set(atom_chain_ids.tolist()))),

        "mean_atom_plddt": float(np.mean(atom_plddts)),
        "median_atom_plddt": float(np.median(atom_plddts)),
        "std_atom_plddt": float(np.std(atom_plddts)),
        "min_atom_plddt": float(np.min(atom_plddts)),
        "max_atom_plddt": float(np.max(atom_plddts)),
        "p10_atom_plddt": float(np.quantile(atom_plddts, 0.10)),
        "p25_atom_plddt": float(np.quantile(atom_plddts, 0.25)),
        "p75_atom_plddt": float(np.quantile(atom_plddts, 0.75)),
        "p90_atom_plddt": float(np.quantile(atom_plddts, 0.90)),
    }

    for t in high_thresholds:
        suffix = threshold_suffix(t)
        row[f"frac_atom_plddt_ge_{suffix}"] = float(np.mean(atom_plddts >= t))
    for t in low_thresholds:
        suffix = threshold_suffix(t)
        row[f"frac_atom_plddt_lt_{suffix}"] = float(np.mean(atom_plddts < t))
        row[f"longest_run_atom_plddt_lt_{suffix}"] = int(longest_run(atom_plddts < t))

    for chain in sorted(set(atom_chain_ids.tolist())):
        mask = atom_chain_ids == chain
        vals = atom_plddts[mask]
        cname = str(chain).replace(" ", "_")

        row[f"n_atoms_chain_{cname}"] = int(np.sum(mask))
        row[f"mean_atom_plddt_chain_{cname}"] = float(np.mean(vals))
        row[f"median_atom_plddt_chain_{cname}"] = float(np.median(vals))
        row[f"min_atom_plddt_chain_{cname}"] = float(np.min(vals))
        row[f"max_atom_plddt_chain_{cname}"] = float(np.max(vals))
        for t in low_thresholds:
            suffix = threshold_suffix(t)
            row[f"frac_atom_plddt_lt_{suffix}_chain_{cname}"] = float(np.mean(vals < t))

    return row


def is_root_level(path: Path, root_dir: Path):
    rel_parts = path.relative_to(root_dir).parts
    return len(rel_parts) == 2


def is_sample_level(path: Path, root_dir: Path):
    rel_parts = path.relative_to(root_dir).parts
    return len(rel_parts) >= 3


def parse_csv_floats(value):
    try:
        return [float(item.strip()) for item in value.split(",") if item.strip()]
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"invalid comma-separated float list: {value}") from exc


def parse_csv_strings(value):
    return [item.strip() for item in value.split(",") if item.strip()]


def parse_csv_bools(value):
    bools = []
    for item in parse_csv_strings(value):
        normalized = item.lower()
        if normalized in {"1", "true", "yes", "asc", "ascending"}:
            bools.append(True)
        elif normalized in {"0", "false", "no", "desc", "descending"}:
            bools.append(False)
        else:
            raise argparse.ArgumentTypeError(f"invalid sort direction: {item}")
    return bools


def resolve_output_path(root_dir: Path, output_path: str):
    path = Path(output_path).expanduser()
    if path.is_absolute():
        return path
    return root_dir / path


def validate_thresholds(label, thresholds):
    if not thresholds:
        raise argparse.ArgumentTypeError(f"{label} must include at least one threshold")
    invalid = [t for t in thresholds if t < 0 or t > 1]
    if invalid:
        raise argparse.ArgumentTypeError(
            f"{label} values must be between 0 and 1: {','.join(map(str, invalid))}"
        )


def build_parser():
    parser = argparse.ArgumentParser(
        description="Merge *_summary_confidences.json and *_confidences.json files into ranked tables."
    )
    parser.add_argument(
        "--root-dir",
        default=DEFAULT_ROOT_DIR,
        help=f"Directory to scan. Default: {DEFAULT_ROOT_DIR}",
    )
    parser.add_argument(
        "--out-csv",
        default=DEFAULT_OUT_CSV,
        help=f"CSV output path. Relative paths are resolved under --root-dir. Default: {DEFAULT_OUT_CSV}",
    )
    parser.add_argument(
        "--out-xlsx",
        default=DEFAULT_OUT_XLSX,
        help=f"XLSX output path. Relative paths are resolved under --root-dir. Default: {DEFAULT_OUT_XLSX}",
    )
    parser.add_argument(
        "--no-xlsx",
        action="store_true",
        help="Skip XLSX output and write CSV only.",
    )
    parser.add_argument(
        "--exclude-root-level",
        action="store_true",
        help="Skip files directly under each group folder.",
    )
    parser.add_argument(
        "--sort-by",
        type=parse_csv_strings,
        default=DEFAULT_SORT_BY,
        help="Comma-separated sort columns. Missing columns are ignored.",
    )
    parser.add_argument(
        "--ascending",
        type=parse_csv_bools,
        default=DEFAULT_ASCENDING,
        help="Comma-separated sort directions matching --sort-by. Use true/false or asc/desc.",
    )
    parser.add_argument(
        "--low-thresholds",
        type=parse_csv_floats,
        default=DEFAULT_LOW_THRESHOLDS,
        help="Comma-separated atom pLDDT low thresholds. Default: 0.7,0.5",
    )
    parser.add_argument(
        "--high-thresholds",
        type=parse_csv_floats,
        default=DEFAULT_HIGH_THRESHOLDS,
        help="Comma-separated atom pLDDT high thresholds. Default: 0.8,0.9",
    )
    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()
    try:
        validate_thresholds("--low-thresholds", args.low_thresholds)
        validate_thresholds("--high-thresholds", args.high_thresholds)
    except argparse.ArgumentTypeError as exc:
        parser.error(str(exc))

    root_dir = Path(args.root_dir).expanduser()
    if not root_dir.exists():
        raise FileNotFoundError(f"目录不存在: {root_dir}")

    # summary 文件
    summary_files = sorted(root_dir.rglob("*_summary_confidences.json"))

    # atom 文件，排除 summary
    atom_files = sorted(
        p for p in root_dir.rglob("*_confidences.json")
        if not p.name.endswith("_summary_confidences.json")
    )

    summary_rows = []
    for path in summary_files:
        if is_root_level(path, root_dir) and args.exclude_root_level:
            continue
        if is_root_level(path, root_dir) or is_sample_level(path, root_dir):
            try:
                summary_rows.append(summarize_summary_json(path, root_dir))
            except Exception as e:
                print(f"[跳过 summary] {path} | {e}")

    atom_rows = []
    for path in atom_files:
        if is_root_level(path, root_dir) and args.exclude_root_level:
            continue
        if is_root_level(path, root_dir) or is_sample_level(path, root_dir):
            try:
                atom_rows.append(
                    summarize_atom_conf_json(path, root_dir, args.low_thresholds, args.high_thresholds)
                )
            except Exception as e:
                print(f"[跳过 atom] {path} | {e}")

    df_summary = pd.DataFrame(summary_rows)
    df_atom = pd.DataFrame(atom_rows)

    if df_summary.empty and df_atom.empty:
        print("没有找到可处理的 json 文件。")
        return

    if df_summary.empty:
        df_final = df_atom.copy()
    elif df_atom.empty:
        df_final = df_summary.copy()
    else:
        df_final = pd.merge(
            df_summary,
            df_atom,
            on=["group_folder", "sample_folder"],
            how="outer",
            validate="one_to_one"
        )

    preferred_cols = [
        "group_folder",
        "sample_folder",
        "ranking_score",
        "overall_plddt",
        "ptm",
        "iptm",
        "overall_pae",
        "overall_pde",
        "has_clash",
        "mean_atom_plddt",
        "median_atom_plddt",
        "std_atom_plddt",
        "min_atom_plddt",
        "max_atom_plddt",
        "frac_atom_plddt_ge_0_8",
        "frac_atom_plddt_ge_0_9",
        "frac_atom_plddt_lt_0_7",
        "frac_atom_plddt_lt_0_5",
        "longest_run_atom_plddt_lt_0_7",
        "longest_run_atom_plddt_lt_0_5",
        "chains",
        "n_atoms",
        "n_chains",
        "summary_relative_path",
        "atom_relative_path",
    ]

    existing_preferred = [c for c in preferred_cols if c in df_final.columns]
    remaining_cols = [c for c in df_final.columns if c not in existing_preferred]
    df_final = df_final[existing_preferred + remaining_cols]

    valid_sort_cols = [c for c in args.sort_by if c in df_final.columns]
    if valid_sort_cols:
        asc = args.ascending[:len(valid_sort_cols)]
        if len(asc) < len(valid_sort_cols):
            asc.extend([False] * (len(valid_sort_cols) - len(asc)))
        df_final = df_final.sort_values(by=valid_sort_cols, ascending=asc, na_position="last")

    out_csv = resolve_output_path(root_dir, args.out_csv)
    out_csv.parent.mkdir(parents=True, exist_ok=True)
    df_final.to_csv(out_csv, index=False, encoding="utf-8-sig")

    xlsx_ok = False
    out_xlsx = None
    if not args.no_xlsx:
        out_xlsx = resolve_output_path(root_dir, args.out_xlsx)
        out_xlsx.parent.mkdir(parents=True, exist_ok=True)
        try:
            df_final.to_excel(out_xlsx, index=False)
            xlsx_ok = True
        except Exception as e:
            print(f"[提示] xlsx 输出失败，仅保留 csv: {e}")

    print(f"总记录数: {len(df_final)}")
    print(f"CSV 已保存: {out_csv}")
    if xlsx_ok:
        print(f"XLSX 已保存: {out_xlsx}")

    preview_cols = [c for c in [
        "group_folder", "sample_folder",
        "ranking_score", "overall_plddt", "ptm", "iptm",
        "mean_atom_plddt", "frac_atom_plddt_lt_0_7", "has_clash"
    ] if c in df_final.columns]

    print("\n=== 前20行预览 ===")
    print(df_final[preview_cols].head(20).to_string(index=False))


if __name__ == "__main__":
    main()
