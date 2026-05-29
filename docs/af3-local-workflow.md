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
| Model/database path / 模型与数据库路径 | `data/alphafold3/` | `data/alphafold_db/` |
| Input format / 输入格式 | AF3 JSON | FASTA |

## Local Assets / 本地资源

| Host path / 宿主机路径 | Container path / 容器内路径 | Purpose / 用途 |
| --- | --- | --- |
| `data/alphafold3/models/af3.bin.zst` | `/root/models/af3.bin.zst` | AF3 model file / AF3 权重 |
| `data/alphafold3/public_databases/` | `/root/public_databases/` | AF3 sequence/template databases / AF3 数据库 |
| `data/alphafold3/jax_cache/` | `/data/alphafold3/jax_cache/` | JAX compilation cache / JAX 编译缓存 |
| `data/inputs/` | `/data/inputs/` | User inputs / 用户输入 |
| `data/outputs/` | `/data/outputs/` | Results / 结果 |
| `examples/` | `/workspace/examples/` | Tracked examples / 示例 |

The model file is a real file in `data/alphafold3/models/`, not a symlink.

权重文件是 `data/alphafold3/models/` 下的真实文件，不是软链接。

## Image Build Notes / 镜像构建说明

The local image was built from the official AlphaFold 3 `v3.0.2` source under
`data/src/alphafold3`.

本地镜像来自 `data/src/alphafold3` 下的官方 AlphaFold 3 `v3.0.2` 源码。

The tracked build notes are in [images/pd-af3-gpu/README.md](../images/pd-af3-gpu/README.md).

可进入 Git 的构建说明见 [images/pd-af3-gpu/README.md](../images/pd-af3-gpu/README.md)。

Docker packaging, image archive, and restore instructions are tracked in
[docker-packaging.md](docker-packaging.md).

Docker 封装、镜像归档和恢复说明见 [docker-packaging.md](docker-packaging.md)。

The build uses a local wheelhouse for the slow NVIDIA cuBLAS wheel:

构建中使用本地 wheelhouse 加速较慢的 NVIDIA cuBLAS wheel：

```text
data/src/alphafold3/wheelhouse/nvidia_cublas_cu12-12.9.1.4-py3-none-manylinux_2_27_x86_64.whl
```

Rebuild command / 重新构建命令:

```bash
docker build -t pd-af3-gpu:v3.0.2 \
  -f data/src/alphafold3/docker/Dockerfile \
  data/src/alphafold3
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
`data/src/alphafold3/fetch_databases.sh`. The target directory is currently on
the local HDD:

本项目使用 `data/src/alphafold3/fetch_databases.sh` 中的官方 AlphaFold 3
数据库脚本。当前目标目录位于本机机械硬盘：

```text
data/alphafold3/public_databases/
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
du -sh data/alphafold3/public_databases
tail -f data/outputs/logs/af3-fetch-databases-*.log
```

The wrapper only handles process detaching, logging, and paths. Database
versions and filenames still come from the official script.

封装脚本只处理后台运行、日志和路径；数据库版本和文件名仍由官方脚本决定。

Current local status on 2026-05-29: the official database fetch finished
successfully. `data/alphafold3/public_databases/` uses about `627G`, and
`mmcif_files/` contains `195859` files.

2026-05-29 当前本机状态：官方数据库下载已经成功完成。
`data/alphafold3/public_databases/` 约 `627G`，`mmcif_files/` 中有
`195859` 个文件。

If you want to run the official script directly in the foreground:

如果希望前台直接运行官方脚本：

```bash
cd data/src/alphafold3
PATH=/home/a/anaconda3/bin:$PATH \
./fetch_databases.sh /data/protein-design/data/alphafold3/public_databases
```

After an SSD is added, migrate the whole project directory together instead of
moving only the database subdirectory. Keeping the relative paths unchanged
means the Compose mounts and example scripts keep working.

后续加装 SSD 后，建议整体迁移整个项目目录，而不是只移动数据库子目录。相对路径保持不变后，
Compose 挂载和示例脚本无需调整。

## Full Run / 完整运行

Full AF3 runs require databases under `data/alphafold3/public_databases/`.

完整 AF3 运行需要先准备 `data/alphafold3/public_databases/` 数据库。

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

Observed runtime on the current HDD-backed database layout:

当前机械硬盘数据库布局下观察到的耗时：

| Stage / 阶段 | Runtime / 耗时 |
| --- | --- |
| Protein MSA search / 蛋白 MSA 检索 | about 1506 s / 约 1506 秒 |
| Template search / 模板检索 | about 2 s / 约 2 秒 |
| Model inference / 模型推理 | about 79 s / 约 79 秒 |

Output directory:

输出目录：

```text
data/outputs/examples/af3-example/example_peptide/
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

The observed ranking score was `0.8828493945547446`, with `ptm` `0.38`.
Because this is a single short peptide example, these numbers should be treated
as runtime validation outputs, not as a scientifically meaningful benchmark.

本次观察到的 `ranking_score` 为 `0.8828493945547446`，`ptm` 为 `0.38`。由于该
示例只是单条短肽，这些数值只用于确认运行流程，不应作为有科学意义的性能基准。

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
