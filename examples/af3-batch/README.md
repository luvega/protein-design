# AF3 Batch Peptide Example

This example shows how to turn a small peptide candidate table into AlphaFold 3
JSON inputs, optionally run them as a batch, and summarize AF3 confidence
outputs.

本示例展示如何把一个小型多肽候选表转换成 AlphaFold 3 JSON 输入，按需批量运行 AF3，
并汇总 AF3 置信度结果。

## Input Table / 输入表

The example table is:

示例表格为：

```text
examples/af3-batch/peptide_candidates.csv
```

Required columns:

必需列：

| Column / 列 | Meaning / 含义 |
| --- | --- |
| `name` | Candidate name and AF3 job name / 候选名称和 AF3 任务名 |
| `sequence` | Peptide amino acid sequence / 多肽氨基酸序列 |

For target-peptide complexes, use `target_sequence` and `peptide_sequence`
instead of `sequence`.

如果要验证靶蛋白-多肽复合物，可用 `target_sequence` 和 `peptide_sequence` 替代
`sequence`。

## Prepare JSON Only / 只准备 JSON

```bash
./examples/af3-batch/run-peptide-batch.sh
```

This writes:

该命令会写出：

```text
data/inputs/af3-batch/example-peptides/*.json
data/inputs/af3-batch/example-peptides/manifest.csv
```

It also prints the AF3 commands that would be run. No AF3 prediction is started
unless `RUN_FULL=1` is set.

除非设置 `RUN_FULL=1`，否则不会启动真正的 AF3 预测，只会打印将要运行的命令。

## Run the Batch / 批量运行

```bash
RUN_FULL=1 ./examples/af3-batch/run-peptide-batch.sh
```

For a quick first pass, run only one row:

如果只想先测试第一条：

```bash
BATCH_LIMIT=1 RUN_FULL=1 ./examples/af3-batch/run-peptide-batch.sh
```

Outputs are written under:

输出目录为：

```text
data/outputs/af3-batch/
```

The script summarizes results into:

脚本会汇总结果到：

```text
data/outputs/af3-batch/af3_summary.csv
```
