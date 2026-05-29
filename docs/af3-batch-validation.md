# AF3 Batch Validation for Peptide Candidates

This document explains the batch AlphaFold 3 workflow added for peptide design
screening. It is written for users who have drug-chemistry or biological
science backgrounds and want a practical path from designed peptide sequences
to AF3 confidence tables.

本文说明面向多肽设计筛选的 AlphaFold 3 批量验证流程，适合药物化学和生命科学背景的
研究生使用：从候选多肽序列表开始，生成 AF3 JSON，批量预测，再汇总成可筛选表格。

## What This Solves / 解决什么问题

After RFpeptide, Foundry/RFD3, ProteinMPNN, BindCraft, or manual sequence
editing, you often have many candidate peptide sequences. AF3 expects JSON
inputs, while users usually manage candidates in a table. The batch workflow
bridges that gap.

在 RFpeptide、Foundry/RFD3、ProteinMPNN、BindCraft 或人工改造后，用户通常得到的是
一批候选多肽序列；AF3 需要 JSON 输入，而研究人员更习惯用表格管理候选物。本流程
负责把两者连接起来。

## Files and Directories / 文件和目录

| Path / 路径 | Role / 作用 |
| --- | --- |
| `examples/af3-batch/peptide_candidates.csv` | Example peptide candidate table / 示例多肽候选表 |
| `scripts/prepare_af3_batch.py` | Convert candidate table to AF3 JSON / 将候选表转换成 AF3 JSON |
| `scripts/run_af3_batch.py` | Run AF3 for each manifest row / 按 manifest 逐条运行 AF3 |
| `scripts/summarize_af3_results.py` | Merge AF3 ranking and confidence files / 汇总 AF3 排名和置信度文件 |
| `data/inputs/af3-batch/` | Generated AF3 JSON inputs / 生成的 AF3 JSON 输入 |
| `data/outputs/af3-batch/` | AF3 batch outputs and summary table / AF3 批量输出和汇总表 |

## Candidate Table Format / 候选表格式

For single-chain peptide checks:

单条多肽验证使用：

```csv
name,sequence,description
example_peptide,GIGAVLKVLTTGLPALISWIKRKRQQ,Short peptide used for local AF3 validation
```

For target-peptide complex checks:

靶蛋白-多肽复合物验证使用：

```csv
name,target_sequence,peptide_sequence,description
target_peptide_001,MKT...,GIGAVLKVLTTGLPALISWIKRKRQQ,Target-peptide complex candidate
```

Use standard one-letter amino acid codes. Non-standard residues or chemical
modifications need separate modeling decisions and should not be silently
encoded as ordinary protein letters.

请使用标准单字母氨基酸代码。非天然氨基酸或化学修饰需要单独建模处理，不应直接当作
普通蛋白序列写入。

## Step 1: Prepare AF3 JSON / 第一步：准备 AF3 JSON

```bash
python3 scripts/prepare_af3_batch.py \
  --input-csv examples/af3-batch/peptide_candidates.csv \
  --out-dir data/inputs/af3-batch/example-peptides \
  --manifest data/inputs/af3-batch/example-peptides/manifest.csv \
  --force
```

This creates one AF3 JSON file per candidate and a `manifest.csv` recording the
host path and container path for each JSON.

该命令为每个候选物生成一个 AF3 JSON，并写出 `manifest.csv`，其中记录宿主机路径和
容器内路径。

## Step 2: Dry-Run the Batch / 第二步：批量命令预览

```bash
python3 scripts/run_af3_batch.py \
  --manifest data/inputs/af3-batch/example-peptides/manifest.csv \
  --dry-run
```

Dry-run mode prints the AF3 commands but does not start predictions. This is a
safe check before launching GPU jobs.

dry-run 只打印将要运行的 AF3 命令，不启动预测，适合在占用 GPU 前检查路径是否正确。

## Step 3: Run AF3 / 第三步：运行 AF3

```bash
RUN_FULL=1 ./examples/af3-batch/run-peptide-batch.sh
```

To test only the first candidate:

只测试第一条候选物：

```bash
BATCH_LIMIT=1 RUN_FULL=1 ./examples/af3-batch/run-peptide-batch.sh
```

The current database is on HDD, so the MSA stage can dominate runtime. This is
expected and will be revisited after SSD migration.

当前 AF3 数据库位于机械硬盘，MSA 检索可能是主要耗时来源。这是预期现象，SSD 到位后
再做性能优化。

## Step 4: Summarize AF3 Outputs / 第四步：汇总 AF3 输出

```bash
python3 scripts/summarize_af3_results.py \
  --root-dir data/outputs/af3-batch \
  --out-csv af3_summary.csv \
  --top 10
```

The summary table includes job name, seed, sample, `ranking_score`, `ptm`,
`iptm`, clash status, output directory, and CIF paths. It is intended as a
first-pass triage table. For scientific decisions, inspect the structures and
interfaces directly.

汇总表包含任务名、seed、sample、`ranking_score`、`ptm`、`iptm`、是否 clash、输出目录和
CIF 路径。它适合做第一轮筛选；真正做科学判断时，还需要打开结构并检查界面。

## One-Command Teaching Case / 一条命令教学案例

```bash
./examples/af3-batch/run-peptide-batch.sh
```

This prepares JSON and prints the full-run commands. Then run:

该命令会准备 JSON 并打印完整运行命令。确认无误后运行：

```bash
BATCH_LIMIT=1 RUN_FULL=1 ./examples/af3-batch/run-peptide-batch.sh
```

This verifies the whole path:

这会验证完整路径：

```text
candidate peptide table -> AF3 JSON -> pd-af3-gpu:v3.0.2 -> AF3 output folder -> summary CSV
候选多肽表 -> AF3 JSON -> pd-af3-gpu:v3.0.2 -> AF3 输出目录 -> 汇总 CSV
```
