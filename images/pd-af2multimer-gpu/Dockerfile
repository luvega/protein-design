FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    aria2 \
    rsync \
    hmmer \
    kalign \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN git clone https://github.com/google-deepmind/alphafold.git

WORKDIR /opt/alphafold
RUN python3 -m pip install --upgrade pip setuptools wheel

# 先按官方 requirements 安装
RUN pip3 install -r requirements.txt

# 再按官方 Dockerfile 思路显式 pin JAX / jaxlib，避免版本漂移
RUN pip3 install --upgrade \
    jax==0.4.26 \
    jaxlib==0.4.26+cuda12.cudnn89 \
    -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html

WORKDIR /workspace

RUN pip3 install typing_extensions

RUN mkdir -p /opt/pyfix && cat > /opt/pyfix/sitecustomize.py <<'PY'
import typing
try:
    typing.dataclass_transform
except AttributeError:
    from typing_extensions import dataclass_transform
    typing.dataclass_transform = dataclass_transform
PY

RUN mkdir -p /opt/openmm_plugins_empty

CMD ["/bin/bash"]
