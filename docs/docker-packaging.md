# Docker Packaging and Image Archives

This document records how Docker images are packaged, archived, restored, and
connected to the large local assets in this workbench.

本文记录本项目 Docker 镜像的封装、归档、恢复方式，以及镜像与大型本地数据资产之间的
连接关系。

## Packaging Principle / 封装原则

Docker images should contain software environments, command-line tools,
runtime libraries, and small reference files required by those tools. Large
scientific assets stay on the host and are mounted at runtime by
`compose/docker-compose.yml`. AlphaFold 3 source, model weights, public
databases, JAX cache, and the local AF3 image archive are kept together under
`/mnt/ssd4t/protein-design`.

Docker 镜像只封装软件环境、命令行工具、运行时库和必要的小型参考文件。大型科学数据
保留在宿主机上，并由 `compose/docker-compose.yml` 在运行时挂载。AlphaFold 3 源码、
权重、公共数据库、JAX 缓存和本地 AF3 镜像归档统一保存在
`/mnt/ssd4t/protein-design` 下。

This keeps images portable and rebuildable while avoiding multi-hundred-GB
image layers. AF3 runtime mounts use deterministic SSD absolute paths instead
of symlinks.

这样可以让镜像保持可迁移和可重建，同时避免出现数百 GB 的镜像层。AF3 运行时挂载使用
确定的 SSD 绝对路径，不使用软链接。

## Current AF3 Package / 当前 AF3 封装

The local AlphaFold 3 image is:

当前 AlphaFold 3 本地镜像为：

```text
pd-af3-gpu:v3.0.2
```

The local archive created on 2026-05-29 is:

2026-05-29 已生成本地归档：

```text
/mnt/ssd4t/protein-design/releases/pd-af3-gpu_v3.0.2_20260529.tar
```

Archive size and checksum:

归档大小和校验和：

```text
size: 8.2G
sha256: aed72560055a05a1d8c92610f882f9e36bde65a309004b8957850c91e5664fa1
```

The archive contains the AF3 software runtime image only. It does not contain
the AF3 model file or public databases.

该归档只包含 AF3 软件运行环境镜像，不包含 AF3 权重文件或公共数据库。

## AF3 Runtime Assets / AF3 运行时资产

AF3 uses the following host-mounted assets:

AF3 使用以下宿主机挂载资产：

| Host path / 宿主机路径 | Container path / 容器内路径 | In image? / 是否在镜像内 |
| --- | --- | --- |
| `/mnt/ssd4t/protein-design/data/alphafold3/models/af3.bin.zst` | `/root/models/af3.bin.zst` | no / 否 |
| `/mnt/ssd4t/protein-design/data/alphafold3/public_databases/` | `/root/public_databases/` | no / 否 |
| `/mnt/ssd4t/protein-design/data/alphafold3/jax_cache/` | `/data/alphafold3/jax_cache/` | no / 否 |
| `data/inputs/` | `/data/inputs/` | no / 否 |
| `data/outputs/` | `/data/outputs/` | no / 否 |

The local AF3 database fetch has completed. Before SSD migration, the database
directory used about `627G`, and `mmcif_files/` contained `195859` files. After
migration, the database lives at
`/mnt/ssd4t/protein-design/data/alphafold3/public_databases/`.

本地 AF3 数据库下载已经完成。SSD 迁移前数据库目录约 `627G`，`mmcif_files/` 中有
`195859` 个文件。迁移后数据库位于
`/mnt/ssd4t/protein-design/data/alphafold3/public_databases/`。

## Export / 导出镜像

Use `docker save` to export a Docker image into `releases/`.

使用 `docker save` 将 Docker 镜像导出到 `releases/`：

```bash
docker save -o /mnt/ssd4t/protein-design/releases/pd-af3-gpu_v3.0.2_20260529.tar pd-af3-gpu:v3.0.2
sha256sum /mnt/ssd4t/protein-design/releases/pd-af3-gpu_v3.0.2_20260529.tar
```

Do not commit files under `releases/`; the directory is intentionally ignored
by Git.

不要把 `releases/` 下的文件提交到 Git；该目录按设计被 Git 忽略。

## Restore / 恢复镜像

On the same machine after cleanup, or on another compatible Linux host, restore
the image with:

在本机清理后或另一台兼容 Linux 主机上，可用以下命令恢复镜像：

```bash
docker load -i /mnt/ssd4t/protein-design/releases/pd-af3-gpu_v3.0.2_20260529.tar
docker image ls --format '{{.Repository}}:{{.Tag}} {{.ID}} {{.Size}}' | grep pd-af3-gpu
```

If the restored image has the correct image ID but not the expected tag, apply
the tag explicitly:

如果恢复后的镜像 ID 正确但缺少预期 tag，可手动打 tag：

```bash
docker tag <image-id> pd-af3-gpu:v3.0.2
```

## Current Local Archives / 当前本地归档

The following local image archives are available under `releases/`:

当前 `releases/` 下已有以下本地镜像归档：

| Image / 镜像 | Archive / 归档文件 | Size / 大小 | SHA256 |
| --- | --- | --- | --- |
| `pd-af3-gpu:v3.0.2` | `pd-af3-gpu_v3.0.2_20260529.tar` | 8.2G | `aed72560055a05a1d8c92610f882f9e36bde65a309004b8957850c91e5664fa1` |
| `pd-bindcraft-gpu:installed` | `pd-bindcraft-gpu_installed_20260529.tar` | 22G | `09ff19cdaa14ab33accde1ed997d2d28a3599f569100963046e711cec5b5f61c` |
| `pd-pepmimic-gpu:latest` | `pd-pepmimic-gpu_latest_20260529.tar` | 24G | `693855f7f8776de4ae14870267b37683744106f66764b5162250c46fe53e2de5` |
| `pd-rfpeptide-gpu:fixed` | `pd-rfpeptide-gpu_fixed_20260529.tar` | 11G | `1401377f34b9809691bcd90c6e8f87f8c924aca2d401d9234e71369217238dd5` |
| `pd-rosetta-cpu-parallel:latest` | `pd-rosetta-cpu-parallel_20260404.tar` | 23G | not recorded / 未记录 |

Verify a saved archive before loading:

加载前先校验归档：

```bash
sha256sum -c releases/pd-bindcraft-gpu_installed_20260529.tar.sha256
sha256sum -c releases/pd-pepmimic-gpu_latest_20260529.tar.sha256
sha256sum -c releases/pd-rfpeptide-gpu_fixed_20260529.tar.sha256
```

Restore a saved image:

恢复镜像：

```bash
docker load -i releases/pd-bindcraft-gpu_installed_20260529.tar
docker load -i releases/pd-pepmimic-gpu_latest_20260529.tar
docker load -i releases/pd-rfpeptide-gpu_fixed_20260529.tar
```

## Validation / 验证

After building or restoring the image, validate the Compose wiring and AF3
runtime:

构建或恢复镜像后，验证 Compose 挂载和 AF3 运行环境：

```bash
docker compose -f compose/docker-compose.yml config --quiet
./scripts/smoke-test.sh af3
./examples/af3/run-check-or-full.sh
```

After the AF3 databases are present, run a minimal full example when GPU time
is available:

AF3 数据库准备完成后，在 GPU 时间允许时运行最小完整示例：

```bash
RUN_FULL=1 ./examples/af3/run-check-or-full.sh
```

Local validation on 2026-05-29 completed successfully and wrote:

2026-05-29 本机完整验证已成功完成，输出目录为：

```text
data/outputs/examples/af3-example/example_peptide/
```

Before SSD migration, the HDD-backed database layout gave an MSA stage of about
`1506 s` and model inference of about `79 s`. After migration, the archived AF3
image tar, source, model file, mounted databases, and JAX cache live together
under `/mnt/ssd4t/protein-design`.

SSD 迁移前，在机械硬盘数据库布局下，MSA 阶段约 `1506 s`，模型推理约 `79 s`。迁移后
AF3 镜像归档、源码、权重、挂载数据库和 JAX 缓存统一位于
`/mnt/ssd4t/protein-design`。

After moving Docker data-root to `/mnt/ssd4t/docker`, the same AF3 image and
minimal example were validated again on 2026-06-18:

Docker data-root 迁移到 `/mnt/ssd4t/docker` 后，2026-06-18 已再次验证同一 AF3 镜像和
最小示例：

```bash
RUN_FULL=1 OUTPUT_DIR=/data/outputs/examples/af3-ssd-test-20260618 \
  /usr/bin/time -p ./examples/af3/run-check-or-full.sh
```

| Stage / 阶段 | HDD baseline / 机械硬盘基线 | SSD run / SSD 后运行 |
| --- | ---: | ---: |
| Protein MSA search / 蛋白 MSA 检索 | about 1506 s / 约 1506 秒 | 554.46 s |
| Template search / 模板检索 | about 2 s / 约 2 秒 | 1.70 s |
| Model inference / 模型推理 | about 79 s / 约 79 秒 | 16.44 s |
| End-to-end `real` time / 端到端 `real` 耗时 | not recorded / 未记录 | 593.62 s |

The SSD output directory is
`data/outputs/examples/af3-ssd-test-20260618/example_peptide/`; its
`ranking_score` was `0.8828493945547446`, matching the earlier HDD-backed run.

SSD 输出目录为 `data/outputs/examples/af3-ssd-test-20260618/example_peptide/`；
`ranking_score` 为 `0.8828493945547446`，与之前机械硬盘布局下的运行一致。

## Docker Data Root / Docker 存储根目录

The AF3 image archive path above controls where the exported tar file lives. The
Docker daemon stores runnable image layers under Docker Root Dir, which was
`/var/lib/docker` before SSD migration. To guarantee runnable Docker image
layers also live on the 4 TB SSD, run:

上面的 AF3 镜像归档路径只决定导出的 tar 文件存放位置。Docker daemon 中可运行的镜像层
由 Docker Root Dir 管理，SSD 迁移前为 `/var/lib/docker`。如果要保证可运行镜像层也在
4TB SSD 上，运行：

```bash
sudo MIGRATE_DOCKER_ROOT=1 scripts/migrate-af3-to-ssd4t.sh
```

This changes Docker's global data-root to `/mnt/ssd4t/docker` and affects all
local Docker images and containers.

这会把 Docker 全局 data-root 改为 `/mnt/ssd4t/docker`，影响本机所有 Docker 镜像和
容器。

## Archive Priority / 归档优先级

Archive images that are expensive to rebuild or depend on fragile external
downloads first. The current priority is:

优先归档重建成本高或依赖不稳定外部下载的镜像。当前优先级为：

| Priority / 优先级 | Image / 镜像 | Reason / 原因 |
| --- | --- | --- |
| 1 | `pd-af3-gpu:v3.0.2` | archived / 已归档 |
| 2 | `pd-rosetta-cpu-parallel:latest` | archived from April build / 已归档 4 月构建版本 |
| 3 | `pd-bindcraft-gpu:installed` | archived / 已归档 |
| 4 | `pd-pepmimic-gpu:latest` | archived / 已归档 |
| 5 | `pd-rfpeptide-gpu:fixed` | archived / 已归档 |
| 6 | `pd-foundry-gpu:latest` | not yet archived; rebuildable from tracked Docker context plus mounted checkpoints / 尚未归档，可由跟踪的 Docker 构建上下文和挂载 checkpoint 重建 |

`pd-af2multimer-gpu` and `pd-af3-gpu` remain separate images and use separate
database directories. AF3 does not use `data/alphafold_db`, and AF2 Multimer
does not use `/mnt/ssd4t/protein-design/data/alphafold3/`.

`pd-af2multimer-gpu` 与 `pd-af3-gpu` 是独立镜像，并使用不同数据库目录。AF3 不使用
`data/alphafold_db`，AF2 Multimer 不使用
`/mnt/ssd4t/protein-design/data/alphafold3/`。
