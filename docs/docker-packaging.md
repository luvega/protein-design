# Docker Packaging and Image Archives

This document records how Docker images are packaged, archived, restored, and
connected to the large local assets in this workbench.

本文记录本项目 Docker 镜像的封装、归档、恢复方式，以及镜像与大型本地数据资产之间的
连接关系。

## Packaging Principle / 封装原则

Docker images should contain software environments, command-line tools,
runtime libraries, and small reference files required by those tools. Large
scientific assets stay on the host under `data/` and are mounted at runtime by
`compose/docker-compose.yml`.

Docker 镜像只封装软件环境、命令行工具、运行时库和必要的小型参考文件。大型科学数据
保留在宿主机 `data/` 目录下，并由 `compose/docker-compose.yml` 在运行时挂载。

This keeps images portable and rebuildable while avoiding multi-hundred-GB
image layers. It also lets the project move to a future SSD by moving the whole
project directory without changing Compose paths.

这样可以让镜像保持可迁移和可重建，同时避免出现数百 GB 的镜像层。后续加装 SSD 时，
整体迁移项目目录即可保持 Compose 路径不变。

## Current AF3 Package / 当前 AF3 封装

The local AlphaFold 3 image is:

当前 AlphaFold 3 本地镜像为：

```text
pd-af3-gpu:v3.0.2
```

The local archive created on 2026-05-29 is:

2026-05-29 已生成本地归档：

```text
releases/pd-af3-gpu_v3.0.2_20260529.tar
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
| `data/alphafold3/models/af3.bin.zst` | `/root/models/af3.bin.zst` | no / 否 |
| `data/alphafold3/public_databases/` | `/root/public_databases/` | no / 否 |
| `data/alphafold3/jax_cache/` | `/data/alphafold3/jax_cache/` | no / 否 |
| `data/inputs/` | `/data/inputs/` | no / 否 |
| `data/outputs/` | `/data/outputs/` | no / 否 |

The local AF3 database fetch has completed. The database directory currently
uses about `627G`, and `mmcif_files/` contains `195859` files.

本地 AF3 数据库下载已经完成。当前数据库目录约 `627G`，`mmcif_files/` 中有
`195859` 个文件。

## Export / 导出镜像

Use `docker save` to export a Docker image into `releases/`.

使用 `docker save` 将 Docker 镜像导出到 `releases/`：

```bash
docker save -o releases/pd-af3-gpu_v3.0.2_20260529.tar pd-af3-gpu:v3.0.2
sha256sum releases/pd-af3-gpu_v3.0.2_20260529.tar
```

Do not commit files under `releases/`; the directory is intentionally ignored
by Git.

不要把 `releases/` 下的文件提交到 Git；该目录按设计被 Git 忽略。

## Restore / 恢复镜像

On the same machine after cleanup, or on another compatible Linux host, restore
the image with:

在本机清理后或另一台兼容 Linux 主机上，可用以下命令恢复镜像：

```bash
docker load -i releases/pd-af3-gpu_v3.0.2_20260529.tar
docker image ls --format '{{.Repository}}:{{.Tag}} {{.ID}} {{.Size}}' | grep pd-af3-gpu
```

If the restored image has the correct image ID but not the expected tag, apply
the tag explicitly:

如果恢复后的镜像 ID 正确但缺少预期 tag，可手动打 tag：

```bash
docker tag <image-id> pd-af3-gpu:v3.0.2
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

On the current HDD-backed database layout, the MSA stage took about `1506 s`
and model inference took about `79 s`. This confirms that the archived image,
mounted model file, mounted databases, and Compose service are connected
correctly.

在当前机械硬盘数据库布局下，MSA 阶段约 `1506 s`，模型推理约 `79 s`。这确认了已归档
镜像、挂载权重、挂载数据库和 Compose 服务之间的连接是可用的。

## Archive Priority / 归档优先级

Archive images that are expensive to rebuild or depend on fragile external
downloads first. The current priority is:

优先归档重建成本高或依赖不稳定外部下载的镜像。当前优先级为：

| Priority / 优先级 | Image / 镜像 | Reason / 原因 |
| --- | --- | --- |
| 1 | `pd-af3-gpu:v3.0.2` | official AF3 build plus local wheelhouse dependency / 官方 AF3 构建与本地 wheelhouse 依赖 |
| 2 | `pd-rosetta-cpu-parallel:latest` | large local Rosetta build context / 大型本地 Rosetta 构建环境 |
| 3 | `pd-bindcraft-gpu:installed` | installed runtime state and model mounts / 已安装运行状态与模型挂载 |
| 4 | `pd-pepmimic-gpu:latest` | large GPU software environment / 大型 GPU 软件环境 |

`pd-af2multimer-gpu` and `pd-af3-gpu` remain separate images and use separate
database directories. AF3 does not use `data/alphafold_db`, and AF2 Multimer
does not use `data/alphafold3/`.

`pd-af2multimer-gpu` 与 `pd-af3-gpu` 是独立镜像，并使用不同数据库目录。AF3 不使用
`data/alphafold_db`，AF2 Multimer 不使用 `data/alphafold3/`。
