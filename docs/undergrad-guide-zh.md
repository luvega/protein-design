# 药学本科生入门说明：多肽生成与改造工作台

本文面向普通药学方向本科生，假设你熟悉蛋白、多肽、受体、结合、构象等基础概念，但不假设你熟悉 Linux、Docker 或命令行。本项目的目标是把常见的多肽生成、序列改造、结构验证和结果筛选工具整理成可重复运行的本地流程。

## 1. 这个项目主要做什么

本项目是一个本地蛋白/多肽设计工作台，主要服务于以下任务：

- 多肽生成：例如使用 RFpeptide/RFdiffusion 生成环肽或结合肽候选结构。
- 多肽改造：例如在给定骨架或复合物结构上，用 ProteinMPNN/LigandMPNN 改造序列。
- 结合肽设计：例如用 BindCraft 针对受体表面生成 binder 或 peptide binder。
- 结构验证：例如用 AlphaFold Multimer 或 AlphaFold 3 检查候选多肽和靶蛋白复合物是否稳定。
- 后处理和打分：例如用 Rosetta relax 优化结构，用 confidence table 汇总 pLDDT、pTM、ipTM、PAE 等指标。

本项目不是一个网页软件。它更像一个“实验台”：你把输入文件放到 `data/inputs/`，用脚本启动对应工具，结果写到 `data/outputs/`，最后用表格脚本筛选候选分子。

## 2. 项目目录怎么理解

常用目录如下：

| 路径 | 用途 |
| --- | --- |
| `README.md` | 项目总览，适合快速知道有哪些工具。 |
| `docs/` | 更详细说明文档。本文就在这里。 |
| `compose/docker-compose.yml` | Docker Compose 服务配置，定义每个容器怎么启动、挂载哪些目录。 |
| `images/` | 每个 Docker 镜像的构建文件。普通使用者通常不需要修改。 |
| `examples/` | 可运行示例脚本。建议从这里开始。 |
| `scripts/` | 通用工具脚本，例如环境烟测和 confidence table 合并。 |
| `data/inputs/` | 输入结构、FASTA、JSON 配置等。 |
| `data/outputs/` | 运行结果、结构文件、打分表等。 |
| `data/*_models`、`data/*_checkpoints` | 模型参数和 checkpoint。不要随意移动。 |
| `data/alphafold3/models/` | AlphaFold 3 权重文件目录，当前应包含 `af3.bin.zst`。 |
| `data/alphafold3/public_databases/` | AlphaFold 3 数据库目录。完整运行 AF3 前需要准备。 |
| `data/alphafold3/jax_cache/` | AlphaFold 3 的 JAX 编译缓存目录。 |
| `.Trash/` | 本工作区的回收站。清理文件时先移动到这里，不直接删除。 |

`data/` 下大多数内容不进入 Git，因为模型和输出文件通常很大。不要用 Git 管理实验结果，除非明确知道自己在做什么。

## 3. Linux 最基础命令

### 3.1 先确认你在哪里

命令行最容易出错的地方是“当前目录不对”。进入项目后先运行：

```bash
pwd
```

如果输出不是：

```text
/data/protein-design
```

就先进入项目目录：

```bash
cd /data/protein-design
```

### 3.2 查看文件和目录

```bash
ls
ls -la
ls data/inputs
```

解释：

- `ls`：列出当前目录内容。
- `ls -la`：显示隐藏文件、权限、大小、修改时间。
- `ls data/inputs`：查看输入目录。

### 3.3 进入目录和返回上一级

```bash
cd examples
cd ..
cd /data/protein-design
```

解释：

- `cd examples`：进入 `examples`。
- `cd ..`：回到上一级。
- `cd /data/protein-design`：进入绝对路径。

### 3.4 查看文本文件

```bash
less README.md
sed -n '1,80p' examples/README.md
head -20 data/outputs/AAAWZY/srcr-lmpnn.csv
```

解释：

- `less`：分页查看文件，按 `q` 退出。
- `sed -n '1,80p' file`：查看第 1 到 80 行。
- `head -20 file`：查看前 20 行。

### 3.5 查找文件

```bash
find data/inputs -maxdepth 3 -type f
find data/outputs -name '*_summary_confidences.json'
```

解释：

- `find data/inputs -maxdepth 3 -type f`：在输入目录里找 3 层以内的文件。
- `find data/outputs -name '*_summary_confidences.json'`：找 AlphaFold/Foundry 类输出里的 summary confidence JSON。

### 3.6 搜索关键词

```bash
rg "ranking_score" data/outputs
rg "PDL1" examples scripts README.md
```

解释：

- `rg` 是 ripgrep，比传统 `grep` 快。
- 第一个命令搜索所有包含 `ranking_score` 的文件。
- 第二个命令搜索示例和脚本里哪里用到了 `PDL1`。

### 3.7 复制、移动、创建目录

```bash
mkdir -p data/inputs/my_project
cp data/inputs/PDL1.pdb data/inputs/my_project/
mv old_name.pdb new_name.pdb
```

解释：

- `mkdir -p`：创建目录，如果上级目录不存在也一起创建。
- `cp`：复制文件。
- `mv`：移动或改名。

本项目约定：不要直接 `rm` 删除文件。需要清理时移动到 `.Trash/`：

```bash
mkdir -p .Trash/manual-cleanup
mv some_file .Trash/manual-cleanup/
```

### 3.8 查看磁盘占用

```bash
du -sh data/outputs
du -sh data/outputs/*
df -h
```

解释：

- `du -sh`：查看某个目录占用多大。
- `df -h`：查看磁盘剩余空间。

蛋白设计输出可能很快变大，尤其是大量 PDB/CIF、JSON、trajectory 和模型文件。

## 4. 路径、文件名和常见格式

### 4.1 绝对路径和相对路径

绝对路径从 `/` 开始：

```bash
/data/protein-design/data/inputs/PDL1.pdb
```

相对路径从当前目录开始：

```bash
data/inputs/PDL1.pdb
```

如果你已经在 `/data/protein-design`，上面两个路径指向同一个文件。

### 4.2 本项目常见文件格式

| 后缀 | 含义 | 常见用途 |
| --- | --- | --- |
| `.pdb` | 蛋白结构文件 | Rosetta relax、BindCraft 输入、结构查看 |
| `.cif` | 结构文件，常用于预测结构 | Foundry/MPNN/AF2/AF3 输出 |
| `.fasta`、`.fa` | 序列文件 | AlphaFold、MPNN 序列输出 |
| `.json` | 配置或结果 | BindCraft 设置、confidence JSON |
| `.csv` | 表格 | 候选排序、打分汇总 |
| `.sh` | shell 脚本 | 一键运行某个流程 |
| `.pt`、`.ckpt`、`.npz` | 模型权重 | 不要手动编辑 |

## 5. Docker 和 Compose 的最小概念

本项目把复杂软件装在 Docker 镜像里。你不需要在宿主机直接安装每个软件，只需要启动对应容器。

关键命令格式：

```bash
docker compose -f compose/docker-compose.yml --profile foundry run --rm pd-foundry-gpu
```

拆开看：

- `docker compose`：用 Compose 启动服务。
- `-f compose/docker-compose.yml`：指定 Compose 配置文件。
- `--profile foundry`：选择 Foundry 这组服务。
- `run`：临时运行一个容器。
- `--rm`：运行结束后删除临时容器，不删除输出文件。
- `pd-foundry-gpu`：服务名。

常用 profile 和服务：

| 任务 | Profile | Service |
| --- | --- | --- |
| Foundry/RFD3/MPNN | `foundry` | `pd-foundry-gpu` |
| BindCraft | `bindcraft` | `pd-bindcraft-gpu` |
| AlphaFold Multimer | `af2` | `pd-af2multimer-gpu` |
| AlphaFold 3 | `af3` | `pd-af3-gpu` |
| Rosetta | `rosetta` | `pd-rosetta-cpu-parallel` |
| PepMimic | `pepmimic` | `pd-pepmimic-gpu` |
| RFpeptide/RFdiffusion | `rfpeptide` | `pd-rfpeptide-gpu` |

## 6. 第一次运行前先做环境检查

先检查 Compose 配置：

```bash
./scripts/smoke-test.sh compose
```

检查 GPU：

```bash
./scripts/smoke-test.sh host-gpu
```

检查所有环境：

```bash
./scripts/smoke-test.sh all
```

如果 `all` 太慢，可以只检查当前要用的工具：

```bash
./scripts/smoke-test.sh foundry
./scripts/smoke-test.sh bindcraft
./scripts/smoke-test.sh af2
./scripts/smoke-test.sh af3
./scripts/smoke-test.sh rosetta
./scripts/smoke-test.sh pepmimic
./scripts/smoke-test.sh rfpeptide
```

`smoke-test.sh` 只是确认环境能启动，不代表每个科学任务的参数都合理。正式运行前仍要检查输入结构、链 ID、热点残基和输出目录。

## 7. `.sh` 脚本怎么读

以 `examples/foundry/run-mpnn-pdl1.sh` 为例：

```bash
#!/usr/bin/env bash
set -euo pipefail
```

解释：

- `#!/usr/bin/env bash`：说明这个文件用 Bash 运行。
- `set -euo pipefail`：更严格的错误处理。命令失败、变量未定义、管道失败时立刻停止。

脚本里常见这种写法：

```bash
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE=(docker compose -f "$ROOT_DIR/compose/docker-compose.yml")
```

意思是：无论你从哪里运行脚本，它都会自动找到项目根目录，并使用本项目的 Compose 文件。

脚本里还常见这种写法：

```bash
INPUT_PDB="${INPUT_PDB:-/data/inputs/PDL1.pdb}"
```

意思是：

- 如果你没有设置 `INPUT_PDB`，就使用默认值 `/data/inputs/PDL1.pdb`。
- 如果你运行前设置了 `INPUT_PDB=...`，脚本就用你指定的路径。

例如：

```bash
INPUT_PDB=/data/inputs/my_project/target.pdb ./examples/foundry/run-mpnn-pdl1.sh
```

注意：这里的 `/data/inputs/...` 是容器内部路径。宿主机对应的是项目里的 `data/inputs/...`。

## 8. 多肽生成和改造示例

所有示例都放在 `examples/`。建议从短流程开始，不要一上来跑大量设计。

### 8.1 Foundry MPNN：基于结构改造序列

脚本：

```bash
./examples/foundry/run-mpnn-pdl1.sh
```

用途：对 `data/inputs/PDL1.pdb` 运行一次 ProteinMPNN，生成候选序列 FASTA。

默认输入和输出：

| 变量 | 默认值 | 含义 |
| --- | --- | --- |
| `INPUT_PDB` | `/data/inputs/PDL1.pdb` | 输入结构。 |
| `OUTPUT_DIR` | `/data/outputs/examples/foundry-mpnn-pdl1` | 输出目录。 |
| `CHECKPOINT` | `/data/foundry_checkpoints/proteinmpnn_v_48_020.pt` | ProteinMPNN 权重。 |

脚本内部关键参数：

| 参数 | 含义 |
| --- | --- |
| `--model_type protein_mpnn` | 使用 ProteinMPNN 模型。 |
| `--checkpoint_path` | 指定模型权重。 |
| `--is_legacy_weights True` | 当前权重格式需要这个参数。 |
| `--structure_path` | 输入 PDB/CIF 结构。 |
| `--batch_size 1` | 每批生成 1 个样本。 |
| `--number_of_batches 1` | 只跑 1 批，适合示例。 |
| `--write_fasta True` | 输出序列 FASTA。 |
| `--write_structures False` | 不输出结构，减少示例输出。 |

换成自己的结构：

```bash
cp my_target.pdb data/inputs/my_project/
INPUT_PDB=/data/inputs/my_project/my_target.pdb \
OUTPUT_DIR=/data/outputs/my_project/mpnn_test \
./examples/foundry/run-mpnn-pdl1.sh
```

### 8.2 BindCraft：针对靶点设计结合肽

脚本：

```bash
./examples/bindcraft/run-cd47-peptide.sh
```

用途：使用 CD47 示例结构和一个小型 JSON 设置，运行 peptide binder 设计。

默认参数：

| 变量 | 默认值 | 含义 |
| --- | --- | --- |
| `SETTINGS` | `/workspace/examples/bindcraft/CD47_peptide_quick.json` | 目标、链、输出目录、长度等基础设置。 |
| `FILTERS` | `/opt/BindCraft/settings_filters/peptide_filters.json` | 过滤规则。 |
| `ADVANCED` | `/opt/BindCraft/settings_advanced/peptide_3stage_multimer_mpnn.json` | 高级设计策略。 |

`CD47_peptide_quick.json` 重要字段：

| 字段 | 含义 |
| --- | --- |
| `design_path` | 输出目录。 |
| `binder_name` | 生成结构和表格中的候选名前缀。 |
| `starting_pdb` | 靶蛋白或复合物结构。 |
| `chains` | 参与设计的靶链 ID。 |
| `target_hotspot_residues` | 希望多肽重点结合的残基，空字符串表示不指定。 |
| `lengths` | 设计多肽长度范围。 |
| `number_of_final_designs` | 希望最终接受多少个候选。示例设为 1，正式任务可增大。 |
| `peptide_mode` | 使用 peptide 设计模式。 |

改成自己的靶点时，最容易出错的是链 ID 和热点残基编号。先用 PyMOL、ChimeraX 或结构文件检查链名。

### 8.3 RFpeptide/RFdiffusion：生成环肽或柔性多肽

脚本：

```bash
./examples/rfpeptide/run-macrocycle-smoke.sh
```

用途：运行一个小型 RFdiffusion cyclic peptide 示例，生成环肽候选。

默认变量：

| 变量 | 默认值 | 含义 |
| --- | --- | --- |
| `OUTPUT_PREFIX` | `/data/outputs/examples/rfpeptide-macrocycle/uncond_cycpep` | 输出文件名前缀。 |
| `NUM_DESIGNS` | `1` | 生成设计数量。 |

脚本内部关键参数：

| 参数 | 含义 |
| --- | --- |
| `--config-name base` | 使用基础推理配置。 |
| `inference.output_prefix` | 输出前缀。 |
| `inference.num_designs` | 生成候选数量。 |
| `contigmap.contigs=[12-18]` | 生成 12 到 18 个残基长度的片段。 |
| `inference.input_pdb` | 示例参考结构。 |
| `inference.cyclic=True` | 生成环状多肽。 |
| `diffuser.T=50` | 扩散步数。越大通常越慢。 |
| `inference.cyc_chains='a'` | 指定环化链。 |

增加生成数量：

```bash
NUM_DESIGNS=5 ./examples/rfpeptide/run-macrocycle-smoke.sh
```

正式任务中，`contigmap.contigs` 是核心参数，决定设计对象的链、残基范围、是否添加新 binder、长度范围等。不要在未理解 contig 语法时直接大规模运行。

### 8.4 PepMimic：肽模拟/肽改造

脚本：

```bash
./examples/pepmimic/run-cd38-example.sh
```

用途：运行 PepMimic 自带 CD38 示例数据，生成 peptide mimicry 候选。

默认变量：

| 变量 | 默认值 | 含义 |
| --- | --- | --- |
| `CONFIG` | `/opt/PepMimic/example_data/CD38/config.yaml` | PepMimic 测试配置。 |
| `CKPT` | `/opt/PepMimic/checkpoints/model.ckpt` | PepMimic checkpoint。 |
| `OUTPUT_DIR` | `/data/outputs/examples/pepmimic-cd38` | 输出目录。 |
| `GPU` | `0` | 使用第 0 张 GPU。 |
| `N_CPU` | `4` | 保存和后处理使用的 CPU 数量。 |

参数含义：

| 参数 | 含义 |
| --- | --- |
| `--config` | 指定设计任务配置。 |
| `--ckpt` | 指定模型权重。 |
| `--save_dir` | 保存输出。 |
| `--gpu` | 选择 GPU，`-1` 表示 CPU。 |
| `--n_cpu` | 并行处理 CPU 数。 |

## 9. 结构验证和后处理示例

### 9.1 AlphaFold Multimer：复合物验证

脚本：

```bash
./examples/af2multimer/run-check-or-full.sh
```

默认行为只检查 JAX 是否能看到 GPU，不跑完整 AlphaFold：

```bash
./examples/af2multimer/run-check-or-full.sh
```

完整运行需要设置：

```bash
RUN_FULL=1 ./examples/af2multimer/run-check-or-full.sh
```

默认变量：

| 变量 | 默认值 | 含义 |
| --- | --- | --- |
| `FASTA` | `/workspace/examples/af2multimer/example_heteromer.fasta` | 多链 FASTA 输入。 |
| `OUTPUT_DIR` | `/data/outputs/examples/af2multimer-example` | 输出目录。 |
| `MAX_TEMPLATE_DATE` | `2026-05-28` | 模板搜索日期上限。 |

关键 AlphaFold 参数：

| 参数 | 含义 |
| --- | --- |
| `--fasta_paths` | 输入 FASTA。不同链用不同 FASTA entry。 |
| `--output_dir` | 输出目录。 |
| `--data_dir` | AlphaFold 数据库和参数目录。 |
| `--model_preset=multimer` | 使用复合物模型。 |
| `--db_preset=reduced_dbs` | 使用 reduced database 配置。 |
| `--max_template_date` | 允许使用的模板日期上限。 |

验证多肽-靶蛋白复合物时，重点看：

- `ranking_score`：综合排序分数。
- `iptm`：链间相互作用可信度。多肽结合任务中很重要。
- `ptm`：整体折叠可信度。
- `pae`/`interface PAE`：链间相对位置是否可靠。
- 是否有明显链间穿插、断裂、远离靶点等结构异常。

### 9.2 AlphaFold 3：更通用的复合物验证

脚本：

```bash
./examples/af3/run-check-or-full.sh
```

默认行为只检查 AF3 镜像、权重挂载和 JAX 运行环境，不跑完整预测：

```bash
./examples/af3/run-check-or-full.sh
```

完整预测前需要先准备 AF3 数据库。当前数据库目录放在机械硬盘上的项目目录中：

```text
data/alphafold3/public_databases/
```

本项目的准备脚本会调用官方 AlphaFold 3 源码中的
`data/src/alphafold3/fetch_databases.sh`，只是额外处理后台运行、日志和路径：

```bash
./scripts/fetch-af3-databases.sh start
```

查看下载状态：

```bash
./scripts/fetch-af3-databases.sh status
du -sh data/alphafold3/public_databases
tail -f data/outputs/logs/af3-fetch-databases-*.log
```

如果之后加装 SSD，建议把整个 `/data/protein-design` 项目目录整体迁移到 SSD，
不要只移动数据库目录。这样 `compose/docker-compose.yml` 里的相对挂载路径仍然有效。

完整运行需要设置：

```bash
RUN_FULL=1 ./examples/af3/run-check-or-full.sh
```

默认变量：

| 变量 | 默认值 | 含义 |
| --- | --- | --- |
| `JSON_PATH` | `/workspace/examples/af3/example_peptide.json` | AF3 输入 JSON。 |
| `OUTPUT_DIR` | `/data/outputs/examples/af3-example` | 输出目录。 |
| `MODEL_DIR` | `/root/models` | 容器内 AF3 权重目录。 |
| `DB_DIR` | `/root/public_databases` | 容器内 AF3 数据库目录。 |
| `JAX_CACHE_DIR` | `/data/alphafold3/jax_cache` | JAX 编译缓存目录。 |
| `NUM_DIFFUSION_SAMPLES` | `1` | 示例中只生成 1 个 diffusion sample，正式任务可调高。 |
| `NUM_RECYCLES` | `3` | 示例中只做 3 次 recycle，正式任务可调高。 |

关键 AF3 参数：

| 参数 | 含义 |
| --- | --- |
| `--json_path` | 输入 JSON，AF3 不使用 AF2 的多链 FASTA 入口。 |
| `--model_dir` | 权重目录，当前容器内为 `/root/models`，其中包含 `af3.bin.zst`。 |
| `--db_dir` | AF3 数据库目录，来自宿主机 `data/alphafold3/public_databases`。 |
| `--output_dir` | 输出目录。 |
| `--jax_compilation_cache_dir` | JAX 编译缓存，重复运行相似长度输入时可减少编译时间。 |
| `--num_diffusion_samples` | 生成结构样本数。越大越慢。 |
| `--num_recycles` | 模型 recycle 次数。越大通常越慢。 |

AF3 与 AF2 Multimer 是两个独立服务：

- AF3 镜像是 `pd-af3-gpu:v3.0.2`。
- AF2 Multimer 镜像是 `pd-af2multimer-gpu:fixed`。
- AF3 使用 `data/alphafold3/models/af3.bin.zst` 和 `data/alphafold3/public_databases`。
- AF2 Multimer 使用 `data/alphafold_db`。
- 不要把 AF3 权重放进 AF2 目录，也不要把 AF2 数据库当作 AF3 数据库使用。

用自己的 AF3 输入时，建议先把 JSON 放到 `data/inputs/af3/`：

```bash
mkdir -p data/inputs/af3
cp my_af3_input.json data/inputs/af3/
JSON_PATH=/data/inputs/af3/my_af3_input.json \
OUTPUT_DIR=/data/outputs/my_project/af3_run_001 \
RUN_FULL=1 \
./examples/af3/run-check-or-full.sh
```

### 9.3 Rosetta relax：结构放松

脚本：

```bash
./examples/rosetta/run-relax-pdl1.sh
```

用途：对输入 PDB 做一次 Rosetta relax，降低局部不合理构象，输出 relaxed PDB 和 score 文件。

默认变量：

| 变量 | 默认值 | 含义 |
| --- | --- | --- |
| `INPUT_PDB` | `/data/inputs/PDL1.pdb` | 输入结构。 |
| `OUTPUT_DIR` | `/data/outputs/examples/rosetta-relax-pdl1` | 输出目录。 |
| `NSTRUCT` | `1` | 输出几个 relaxed 结构。 |

脚本内部 Rosetta 参数：

| 参数 | 含义 |
| --- | --- |
| `-database /opt/rosetta_db` | Rosetta 数据库位置。 |
| `-s` | 输入 PDB。 |
| `-nstruct` | 生成结构数量。 |
| `-out:path:all` | 输出目录。 |
| `-out:suffix _relaxed` | 输出文件名后缀。 |
| `-overwrite` | 同名输出可覆盖。 |

换成自己的结构：

```bash
INPUT_PDB=/data/inputs/my_project/candidate.pdb \
OUTPUT_DIR=/data/outputs/my_project/relax_candidate \
NSTRUCT=3 \
./examples/rosetta/run-relax-pdl1.sh
```

## 10. 结果表格合并和筛选

脚本：

```bash
./examples/confidence/run-merge-srcr.sh
```

用途：把一批 `*_summary_confidences.json` 和 `*_confidences.json` 合成一个排序 CSV。

默认变量：

| 变量 | 默认值 | 含义 |
| --- | --- | --- |
| `ROOT_INPUT` | `data/outputs/AAAWZY/srcr-rf3` | 要扫描的结果根目录。 |
| `OUT_CSV` | `data/outputs/examples/confidence/srcr-rf3-confidence.csv` | 输出 CSV。 |

直接使用底层脚本：

```bash
python3 scripts/merge_confidence_tables.py \
  --root-dir data/outputs/AAAWZY/srcr-rf3 \
  --out-csv /tmp/srcr-rf3-confidence.csv \
  --no-xlsx
```

重要参数：

| 参数 | 含义 |
| --- | --- |
| `--root-dir` | 扫描哪个输出目录。 |
| `--out-csv` | CSV 输出位置。相对路径会放到 `--root-dir` 下。 |
| `--out-xlsx` | XLSX 输出位置。 |
| `--no-xlsx` | 不输出 XLSX，只输出 CSV。 |
| `--exclude-root-level` | 跳过每个 group 目录直属的 ROOT 结果，只看 sample 子目录。 |
| `--sort-by` | 排序列，例如 `ranking_score,overall_plddt,mean_atom_plddt`。 |
| `--ascending` | 排序方向，例如 `desc,desc,desc` 或 `false,false,false`。 |
| `--low-thresholds` | 低 pLDDT 阈值，用于统计低可信原子比例。 |
| `--high-thresholds` | 高 pLDDT 阈值，用于统计高可信原子比例。 |

表格中常见列：

| 列名 | 解释 |
| --- | --- |
| `group_folder` | 候选所属组。 |
| `sample_folder` | 样本目录，`ROOT` 表示组级结果。 |
| `ranking_score` | 综合排序分数，通常越高越好。 |
| `overall_plddt` | 整体 pLDDT，反映模型对局部结构的信心。 |
| `ptm` | predicted TM-score，反映整体拓扑可信度。 |
| `iptm` | interface pTM，多链相互作用可信度。 |
| `overall_pae` | 预测对齐误差，通常越低越好。 |
| `has_clash` | 是否有明显原子冲突。 |
| `mean_atom_plddt` | 原子层面平均 pLDDT。 |
| `frac_atom_plddt_lt_0_7` | pLDDT 低于 0.7 的原子比例。 |
| `longest_run_atom_plddt_lt_0_7` | 连续低可信区域长度，过长可能提示柔性或错误折叠。 |

药学筛选时不要只看一个分数。建议同时看：

- `ranking_score` 高。
- `iptm` 较高，特别是多肽和靶蛋白界面。
- `has_clash` 为 `False`。
- 低 pLDDT 区域不要集中在结合界面关键片段。
- 结构可视化确认多肽确实接近目标位点。

## 11. 推荐工作流

### 11.1 从已有结构改造序列

1. 把 PDB/CIF 放入 `data/inputs/my_project/`。
2. 用 MPNN 示例生成候选序列。
3. 对候选序列建模或复合物验证。
4. 用 Rosetta relax 优化结构。
5. 用 confidence table 或 Rosetta score 筛选。

### 11.2 设计靶点结合多肽

1. 准备靶蛋白结构，确认链 ID 和热点残基。
2. 修改 BindCraft JSON：`starting_pdb`、`chains`、`target_hotspot_residues`、`lengths`。
3. 小规模运行，先把 `number_of_final_designs` 设为 1 到 5。
4. 检查输出 PDB、trajectory 和 CSV。
5. 对候选做 AF2 Multimer 或 AF3 复合物验证，再做 Rosetta relax。

### 11.3 生成环肽

1. 从 RFpeptide 示例开始。
2. 小规模调整 `NUM_DESIGNS`。
3. 理解 `contigmap.contigs` 后再修改长度和链约束。
4. 对候选进行结构质量和结合模式验证，可根据任务选择 AF2 Multimer 或 AF3。

## 12. 常见错误和处理

### 12.1 `permission denied while trying to connect to the docker API`

说明当前用户没有 Docker socket 权限，或当前环境需要提升权限。处理方式：

- 确认 Docker 服务正在运行。
- 在本机终端中确认当前用户能运行 `docker ps`。
- 如果是在受控环境里运行，让管理员或操作者授予 Docker 权限。

### 12.2 `No such file or directory`

常见原因：

- 当前目录不是 `/data/protein-design`。
- 宿主机路径和容器路径混淆。
- 输入文件没有放到 `data/inputs`。

先检查：

```bash
pwd
ls data/inputs
```

### 12.3 找不到模型权重

例如缺少 `.pt`、`.ckpt`、`.npz` 或 AF3 的 `af3.bin.zst`。这些文件在
`data/*_models`、`data/*_checkpoints` 或 `data/alphafold3/models` 下，不进入
Git。不要从 README 复制路径后随意改名。

### 12.4 GPU 不可用

先运行：

```bash
nvidia-smi
./scripts/smoke-test.sh host-gpu
```

如果宿主机能看到 GPU，但容器看不到，通常是 Docker NVIDIA runtime 配置问题。

### 12.5 输出目录已有旧结果

很多脚本会继续写入同一个目录。为避免混淆，可以换一个输出目录：

```bash
OUTPUT_DIR=/data/outputs/my_project/run_001 ./examples/foundry/run-mpnn-pdl1.sh
```

### 12.6 不知道脚本会做什么

先用 `sed` 看脚本前 120 行：

```bash
sed -n '1,120p' examples/foundry/run-mpnn-pdl1.sh
```

重点找这些内容：

- 默认输入变量：如 `INPUT_PDB=...`
- 默认输出变量：如 `OUTPUT_DIR=...`
- Docker service：如 `pd-foundry-gpu`
- 真正运行的程序：如 `mpnn`、`bindcraft.py`、`run_alphafold.py`

## 13. 安全和记录习惯

- 不要把模型、输出、`.pdb`、`.cif`、`.pt`、`.ckpt`、`.npz` 提交到 Git。
- 不要直接删除文件；先移动到 `.Trash/`。
- 每次正式运行前记录：输入文件、脚本、参数、输出目录、日期。
- 不要在同一个输出目录反复跑不同参数，容易混淆结果。
- 药学解释必须结合结构可视化和实验背景，不能只依赖模型分数。

一个简单记录模板：

```text
项目: my_peptide_project
日期: 2026-05-28
输入结构: data/inputs/my_project/target.pdb
脚本: examples/foundry/run-mpnn-pdl1.sh
主要参数: batch_size=1, number_of_batches=1
输出目录: data/outputs/my_project/mpnn_run_001
筛选标准: ranking_score, iptm, has_clash, interface pLDDT
备注:
```

## 14. 最小上手路线

如果你完全没有 Linux 基础，按这个顺序做：

1. 进入项目：

   ```bash
   cd /data/protein-design
   ```

2. 看项目文件：

   ```bash
   ls
   ```

3. 跑环境检查：

   ```bash
   ./scripts/smoke-test.sh compose
   ./scripts/smoke-test.sh host-gpu
   ```

4. 跑一个不会启动完整大任务的 AF2 检查：

   ```bash
   ./examples/af2multimer/run-check-or-full.sh
   ```

5. 跑一个 MPNN 小示例：

   ```bash
   ./examples/foundry/run-mpnn-pdl1.sh
   ```

6. 合并已有 confidence 表：

   ```bash
   ./examples/confidence/run-merge-srcr.sh
   ```

7. 查看输出：

   ```bash
   find data/outputs/examples -maxdepth 3 -type f
   ```

完成这些后，再开始修改输入结构、JSON 配置和输出目录。
