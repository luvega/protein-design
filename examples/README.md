# Runnable Workflow Examples

These examples are host-side wrappers around the Compose services. Run them from
any directory; each script resolves the repository root, starts the matching
container, reads inputs from `data/inputs`, and writes outputs under
`data/outputs/examples`.

示例脚本在宿主机执行，通过 Docker Compose 进入对应容器。输入默认来自
`data/inputs`，输出默认写入 `data/outputs/examples`。

## Quick Validation / 快速验证

```bash
./scripts/smoke-test.sh all
```

## Examples / 示例

| Service / 服务 | Script / 脚本 | What it does / 作用 |
| --- | --- | --- |
| Foundry MPNN | `examples/foundry/run-mpnn-pdl1.sh` | Runs one ProteinMPNN batch on `data/inputs/PDL1.pdb`. |
| BindCraft | `examples/bindcraft/run-cd47-peptide.sh` | Runs the CD47 peptide binder example with a small tracked settings file. |
| AF2 Multimer | `examples/af2multimer/run-check-or-full.sh` | Checks JAX GPU by default; full AlphaFold run is gated by `RUN_FULL=1`. |
| AF3 | `examples/af3/run-check-or-full.sh` | Checks the independent AlphaFold 3 image and model mount; full runs are gated by `RUN_FULL=1`. |
| AF3 batch | `examples/af3-batch/run-peptide-batch.sh` | Converts peptide candidate CSV rows to AF3 JSON, previews batch commands, and can run/summarize AF3 jobs. |
| Rosetta | `examples/rosetta/run-relax-pdl1.sh` | Runs one Rosetta relax trajectory on `data/inputs/PDL1.pdb`. |
| PepMimic | `examples/pepmimic/run-cd38-example.sh` | Runs PepMimic on its bundled CD38 example data and mounted checkpoint. |
| RFpeptide | `examples/rfpeptide/run-macrocycle-smoke.sh` | Runs a one-design RFdiffusion cyclic peptide example. |
| Confidence table | `examples/confidence/run-merge-srcr.sh` | Merges SRCR confidence JSON files into a ranked CSV. |

Some scientific runs are intentionally small but still GPU-heavy. Use the smoke
test first before starting full design jobs.

部分科学流程即使示例规模较小也会占用 GPU。建议先运行烟测，再启动完整设计任务。

## Parameter Pattern / 参数模式

Most scripts use environment variables for simple customization. For example:

大多数脚本用环境变量覆盖默认输入和输出。例如：

```bash
INPUT_PDB=/data/inputs/my_project/target.pdb \
OUTPUT_DIR=/data/outputs/my_project/mpnn_run_001 \
./examples/foundry/run-mpnn-pdl1.sh
```

The `/data/...` paths are paths inside the container. Common input/output paths
map to this repository's `data/...` directories on the host. AlphaFold 3 model,
database, and cache paths map directly to `/mnt/ssd4t/protein-design`.

`/data/...` 是容器内路径。常规输入输出路径对应宿主机本仓库里的 `data/...` 目录；
AlphaFold 3 权重、数据库和缓存路径直接对应 `/mnt/ssd4t/protein-design`。

AlphaFold 3 uses a separate image and asset layout from AlphaFold 2 Multimer.
Its model file is mounted from
`/mnt/ssd4t/protein-design/data/alphafold3/models/af3.bin.zst` to
`/root/models/af3.bin.zst`, and databases should be placed under
`/mnt/ssd4t/protein-design/data/alphafold3/public_databases`.

AlphaFold 3 与 AlphaFold 2 Multimer 使用不同镜像和资源目录。AF3 权重文件从
`/mnt/ssd4t/protein-design/data/alphafold3/models/af3.bin.zst` 挂载到容器内
`/root/models/af3.bin.zst`，数据库放在
`/mnt/ssd4t/protein-design/data/alphafold3/public_databases`。

AF3 batch validation starts from a CSV table:

AF3 批量验证从 CSV 候选表开始：

```bash
./examples/af3-batch/run-peptide-batch.sh
```

The command above prepares JSON inputs and prints the full-run commands. Set
`RUN_FULL=1` only when you are ready to scan the AF3 databases.

上面的命令只准备 JSON 并打印完整运行命令。确认路径无误、准备占用 GPU 后，再设置
`RUN_FULL=1`。

For a fuller Chinese explanation of Linux commands, shell scripts, parameters,
and peptide design workflow choices, read:

更详细的中文说明见：

```text
docs/undergrad-guide-zh.md
```
