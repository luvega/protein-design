# pd-af3-gpu

Local AlphaFold 3 runtime image.

本目录记录本项目中 `pd-af3-gpu:v3.0.2` 镜像的本地构建方式。实际构建上下文是
`/mnt/ssd4t/protein-design/data/src/alphafold3` 下的官方 AlphaFold 3 源码；该目录不进入
Git。

## Source / 源码

```bash
git clone --branch v3.0.2 https://github.com/google-deepmind/alphafold3.git \
  /mnt/ssd4t/protein-design/data/src/alphafold3
```

## Local Wheelhouse / 本地 wheelhouse

`nvidia-cublas-cu12==12.9.1.4` is slow to download during Docker builds on this
machine, so it is downloaded once into:

本机 Docker 构建时下载 `nvidia-cublas-cu12==12.9.1.4` 较慢，因此先单独下载到：

```text
/mnt/ssd4t/protein-design/data/src/alphafold3/wheelhouse/
```

Download command / 下载命令:

```bash
python3 -m pip download --only-binary=:all: \
  --dest /mnt/ssd4t/protein-design/data/src/alphafold3/wheelhouse \
  --index-url https://pypi.tuna.tsinghua.edu.cn/simple \
  nvidia-cublas-cu12==12.9.1.4
```

## Local Dockerfile Adjustments / 本地 Dockerfile 调整

The official `/mnt/ssd4t/protein-design/data/src/alphafold3/docker/Dockerfile`
was adjusted locally so that the dependency layer:

官方 `/mnt/ssd4t/protein-design/data/src/alphafold3/docker/Dockerfile` 在本机做了以下调整：

- installs `nvidia-cublas-cu12==12.9.1.4` from the local wheelhouse first;
- runs `uv sync` with `UV_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple`;
- sets `UV_HTTP_TIMEOUT=900` and `UV_CONCURRENT_DOWNLOADS=1`;
- sets `CMAKE_TLS_VERIFY=0` for the CCD download step;
- runs `uv run --no-sync build_data` after dependencies are installed.

## Build / 构建

```bash
docker build -t pd-af3-gpu:v3.0.2 \
  -f /mnt/ssd4t/protein-design/data/src/alphafold3/docker/Dockerfile \
  /mnt/ssd4t/protein-design/data/src/alphafold3
```

## Runtime / 运行

Runtime is managed by the `pd-af3-gpu` service in
`compose/docker-compose.yml`. The AF3 model file is mounted from:

运行由 `compose/docker-compose.yml` 中的 `pd-af3-gpu` 服务管理。AF3 权重文件位于：

```text
/mnt/ssd4t/protein-design/data/alphafold3/models/af3.bin.zst
```

The AF3 databases are mounted from:

AF3 数据库挂载自：

```text
/mnt/ssd4t/protein-design/data/alphafold3/public_databases/
```

Neither the model file nor the public databases are baked into this image.

权重文件和公共数据库都不打入该镜像。

## Archive / 归档

The local image archive created on 2026-05-29 is:

2026-05-29 已生成本地镜像归档：

```text
/mnt/ssd4t/protein-design/releases/pd-af3-gpu_v3.0.2_20260529.tar
```

Checksum / 校验和:

```text
sha256 aed72560055a05a1d8c92610f882f9e36bde65a309004b8957850c91e5664fa1
```

Export and restore commands:

导出和恢复命令：

```bash
docker save -o /mnt/ssd4t/protein-design/releases/pd-af3-gpu_v3.0.2_20260529.tar pd-af3-gpu:v3.0.2
docker load -i /mnt/ssd4t/protein-design/releases/pd-af3-gpu_v3.0.2_20260529.tar
```

For the complete packaging policy, see
[docs/docker-packaging.md](../../docs/docker-packaging.md).
