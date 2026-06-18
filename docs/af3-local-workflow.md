# AlphaFold 3 Local Workflow

This document records the local AlphaFold 3 image, model-file layout, runtime
mounts, and example commands used by this project.

本文记录本项目中的 AlphaFold 3 本地镜像、权重文件位置、运行时挂载和示例命令。

## Scope / 范围

AlphaFold 3 is an independent validation service in this repository. It is not
part of the AlphaFold 2 Multimer image.

AlphaFold 3 是本仓库中的独立验证服务，不属于 AlphaFold 2 Multimer 镜像。

| Item / 项目 | AlphaFold 3 | AlphaFold 2 Multimer |
| --- | --- | --- |
| Image / 镜像 | `pd-af3-gpu:v3.0.2` | `pd-af2multimer-gpu:fixed` |
| Compose service / Compose 服务 | `pd-af3-gpu` | `pd-af2multimer-gpu` |
| Profiles / 配置组 | `af3`, `validate` | `af2`, `multimer` |
| Model/database path / 模型与数据库路径 | `/mnt/ssd4t/protein-design/data/alphafold3/` | `data/alphafold_db/` |
| Input format / 输入格式 | AF3 JSON | FASTA |

## Local Assets / 本地资源

| Host path / 宿主机路径 | Container path / 容器内路径 | Purpose / 用途 |
| --- | --- | --- |
| `/mnt/ssd4t/protein-design/data/alphafold3/models/af3.bin.zst` | `/root/models/af3.bin.zst` | AF3 model file / AF3 权重 |
| `/mnt/ssd4t/protein-design/data/alphafold3/public_databases/` | `/root/public_databases/` | AF3 sequence/template databases / AF3 数据库 |
| `/mnt/ssd4t/protein-design/data/alphafold3/jax_cache/` | `/data/alphafold3/jax_cache/` | JAX compilation cache / JAX 编译缓存 |
| `data/inputs/` | `/data/inputs/` | User inputs / 用户输入 |
| `data/outputs/` | `/data/outputs/` | Results / 结果 |
| `examples/` | `/workspace/examples/` | Tracked examples / 示例 |

The model file is a real file in
`/mnt/ssd4t/protein-design/data/alphafold3/models/`, not a symlink.

权重文件是 `/mnt/ssd4t/protein-design/data/alphafold3/models/` 下的真实文件，不是
软链接。

## Image Build Notes / 镜像构建说明

The local image was built from the official AlphaFold 3 `v3.0.2` source under
`/mnt/ssd4t/protein-design/data/src/alphafold3`.

本地镜像来自 `/mnt/ssd4t/protein-design/data/src/alphafold3` 下的官方 AlphaFold 3
`v3.0.2` 源码。

The tracked build notes are in [images/pd-af3-gpu/README.md](../images/pd-af3-gpu/README.md).

可进入 Git 的构建说明见 [images/pd-af3-gpu/README.md](../images/pd-af3-gpu/README.md)。

Docker packaging, image archive, and restore instructions are tracked in
[docker-packaging.md](docker-packaging.md).

Docker 封装、镜像归档和恢复说明见 [docker-packaging.md](docker-packaging.md)。

The build uses a local wheelhouse for the slow NVIDIA cuBLAS wheel:

构建中使用本地 wheelhouse 加速较慢的 NVIDIA cuBLAS wheel：

```text
/mnt/ssd4t/protein-design/data/src/alphafold3/wheelhouse/nvidia_cublas_cu12-12.9.1.4-py3-none-manylinux_2_27_x86_64.whl
```

Rebuild command / 重新构建命令:

```bash
docker build -t pd-af3-gpu:v3.0.2 \
  -f /mnt/ssd4t/protein-design/data/src/alphafold3/docker/Dockerfile \
  /mnt/ssd4t/protein-design/data/src/alphafold3
```

## Quick Check / 快速检查

Run the AF3 smoke check:

运行 AF3 烟测：

```bash
./scripts/smoke-test.sh af3
```

Or run the example wrapper:

也可以运行示例脚本：

```bash
./examples/af3/run-check-or-full.sh
```

Expected output includes:

预期输出包含：

```text
jax 0.9.1
devices [CudaDevice(id=0)]
alphafold3 ok
```

## Database Preparation / 数据库准备

The project uses the official AlphaFold 3 database script from
`/mnt/ssd4t/protein-design/data/src/alphafold3/fetch_databases.sh`. The source,
model file, public databases, JAX cache, and AF3 image archive are kept together
on the SSD mounted at `/mnt/ssd4t`:

本项目使用 `/mnt/ssd4t/protein-design/data/src/alphafold3/fetch_databases.sh`
中的官方 AlphaFold 3 数据库脚本。源码、权重、公共数据库、JAX 缓存和 AF3 镜像归档
统一保存在挂载到 `/mnt/ssd4t` 的 SSD 上：

```text
/mnt/ssd4t/protein-design/data/alphafold3/public_databases/
```

Start the official script in the background through the project wrapper:

通过项目封装脚本在后台启动官方脚本：

```bash
./scripts/fetch-af3-databases.sh start
```

Check progress:

查看进度：

```bash
./scripts/fetch-af3-databases.sh status
du -sh /mnt/ssd4t/protein-design/data/alphafold3/public_databases
tail -f data/outputs/logs/af3-fetch-databases-*.log
```

The wrapper only handles process detaching, logging, and paths. Database
versions and filenames still come from the official script.

封装脚本只处理后台运行、日志和路径；数据库版本和文件名仍由官方脚本决定。

Current local status on 2026-05-29: the official database fetch finished
successfully. Before SSD migration, `data/alphafold3/public_databases/` used
about `627G`, and `mmcif_files/` contained `195859` files. After migration, the
same database is stored at
`/mnt/ssd4t/protein-design/data/alphafold3/public_databases/`.

2026-05-29 当前本机状态：官方数据库下载已经成功完成。
SSD 迁移前 `data/alphafold3/public_databases/` 约 `627G`，`mmcif_files/` 中有
`195859` 个文件。迁移后同一数据库保存在
`/mnt/ssd4t/protein-design/data/alphafold3/public_databases/`。

If you want to run the official script directly in the foreground:

如果希望前台直接运行官方脚本：

```bash
cd /mnt/ssd4t/protein-design/data/src/alphafold3
PATH=/home/a/anaconda3/bin:$PATH \
./fetch_databases.sh /mnt/ssd4t/protein-design/data/alphafold3/public_databases
```

The migration script for this machine is:

本机迁移脚本为：

```bash
sudo scripts/migrate-af3-to-ssd4t.sh
```

It does not create symlinks. `compose/docker-compose.yml` mounts the SSD paths
directly.

该脚本不创建软链接。`compose/docker-compose.yml` 直接挂载 SSD 绝对路径。

## Full Run / 完整运行

Full AF3 runs require databases under
`/mnt/ssd4t/protein-design/data/alphafold3/public_databases/`.

完整 AF3 运行需要先准备
`/mnt/ssd4t/protein-design/data/alphafold3/public_databases/` 数据库。

Example:

示例：

```bash
RUN_FULL=1 ./examples/af3/run-check-or-full.sh
```

## Verified Full Example / 已验证完整示例

The minimal example was run successfully on 2026-05-29:

最小示例已于 2026-05-29 成功运行：

```bash
RUN_FULL=1 ./examples/af3/run-check-or-full.sh
```

Observed runtime before SSD migration on the old HDD-backed database layout:

SSD 迁移前，旧机械硬盘数据库布局下观察到的耗时：

| Stage / 阶段 | Runtime / 耗时 |
| --- | --- |
| Protein MSA search / 蛋白 MSA 检索 | about 1506 s / 约 1506 秒 |
| Template search / 模板检索 | about 2 s / 约 2 秒 |
| Model inference / 模型推理 | about 79 s / 约 79 秒 |

The same example was rerun after moving AF3 source, databases, model weights,
JAX cache, image archive, and Docker data-root to `/mnt/ssd4t`:

AF3 源码、数据库、权重、JAX 缓存、镜像归档和 Docker data-root 迁移到 `/mnt/ssd4t`
后，已重新运行同一示例：

```bash
RUN_FULL=1 OUTPUT_DIR=/data/outputs/examples/af3-ssd-test-20260618 \
  /usr/bin/time -p ./examples/af3/run-check-or-full.sh
```

Observed runtime after SSD migration on 2026-06-18:

2026-06-18 SSD 迁移后观察到的耗时：

| Stage / 阶段 | Runtime / 耗时 |
| --- | ---: |
| Protein MSA search / 蛋白 MSA 检索 | 554.46 s |
| Template search / 模板检索 | 1.70 s |
| Model inference / 模型推理 | 16.44 s |
| End-to-end `real` time / 端到端 `real` 耗时 | 593.62 s |

Compared with the old HDD baseline, the MSA stage improved from about `1506 s`
to `554.46 s`, and model inference improved from about `79 s` to `16.44 s`.

与旧机械硬盘基线相比，MSA 阶段从约 `1506 s` 降至 `554.46 s`，模型推理从约 `79 s`
降至 `16.44 s`。

Output directory:

输出目录：

```text
data/outputs/examples/af3-example/example_peptide/
data/outputs/examples/af3-ssd-test-20260618/example_peptide/
```

Important output files:

主要输出文件：

| File / 文件 | Purpose / 用途 |
| --- | --- |
| `example_peptide_model.cif` | predicted model / 预测结构 |
| `example_peptide_confidences.json` | residue-level confidence values / 残基层置信度 |
| `example_peptide_summary_confidences.json` | summary confidence metrics / 汇总置信度指标 |
| `example_peptide_ranking_scores.csv` | seed/sample ranking table / seed 与 sample 排名表 |
| `example_peptide_data.json` | processed AF3 model input / 处理后的 AF3 模型输入 |

The observed ranking score was `0.8828493945547446`, with `ptm` `0.38`. The
SSD-backed rerun produced the same `ranking_score`.
Because this is a single short peptide example, these numbers should be treated
as runtime validation outputs, not as a scientifically meaningful benchmark.

本次观察到的 `ranking_score` 为 `0.8828493945547446`，`ptm` 为 `0.38`。SSD 迁移后
重跑得到相同的 `ranking_score`。由于该示例只是单条短肽，这些数值只用于确认运行流程，
不应作为有科学意义的性能基准。

Use your own input JSON:

使用自己的输入 JSON：

```bash
mkdir -p data/inputs/af3
cp my_af3_input.json data/inputs/af3/

JSON_PATH=/data/inputs/af3/my_af3_input.json \
OUTPUT_DIR=/data/outputs/my_project/af3_run_001 \
RUN_FULL=1 \
./examples/af3/run-check-or-full.sh
```

The wrapper uses conservative defaults for local testing:

示例脚本使用偏保守的本地测试默认值：

| Variable / 变量 | Default / 默认值 |
| --- | --- |
| `NUM_DIFFUSION_SAMPLES` | `1` |
| `NUM_RECYCLES` | `3` |
| `JAX_CACHE_DIR` | `/data/alphafold3/jax_cache` |

For production-quality validation, increase samples/recycles as needed and
record the exact settings with each output directory.

正式验证时可按需要提高 samples/recycles，并在每个输出目录记录具体参数。
