FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV CONDA_DIR=/opt/conda
ENV PATH=${CONDA_DIR}/bin:${PATH}
ENV FOUNDRY_CHECKPOINT_DIRS=/data/foundry_checkpoints
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    ca-certificates \
    git \
    bzip2 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 用 Miniforge 提供 Python 3.12，避免 Ubuntu 22.04 自带 Python 3.10
RUN wget -qO /tmp/miniforge.sh \
    https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh && \
    bash /tmp/miniforge.sh -b -p ${CONDA_DIR} && \
    rm /tmp/miniforge.sh

RUN conda config --system --set auto_update_conda false && \
    conda create -y -n foundry python=3.12 pip && \
    conda clean -afy

SHELL ["conda", "run", "-n", "foundry", "/bin/bash", "-lc"]

RUN python -m pip install --upgrade pip setuptools wheel

# 先安装最小可用 Foundry CLI，先把环境跑通
RUN python -m pip install \
    rc-foundry \
    biopython \
    numpy \
    scipy \
    pandas \
    matplotlib \
    jupyterlab

WORKDIR /workspace

CMD ["/bin/bash"]
