FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV CONDA_DIR=/opt/conda
ENV PATH=${CONDA_DIR}/bin:${PATH}
ENV PYTHONUNBUFFERED=1
ENV CONDA_PLUGINS_AUTO_ACCEPT_TOS=yes
ENV PIP_NO_BUILD_ISOLATION=1

RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    ca-certificates \
    bzip2 \
    build-essential \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO /tmp/miniforge.sh \
    https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh && \
    bash /tmp/miniforge.sh -b -p ${CONDA_DIR} && \
    rm /tmp/miniforge.sh

RUN conda install -n base -y -c conda-forge mamba yq && \
    conda clean -afy

WORKDIR /opt
RUN git clone https://github.com/kxz18/PepMimic.git

WORKDIR /opt/PepMimic

# 去掉 yaml 里的 pip 段，先只创建 conda 部分环境
RUN python - <<'PY'
from pathlib import Path
src = Path('env_cu124.yaml').read_text().splitlines()
out = []
skip = False
for line in src:
    if line.strip() == '- pip:':
        skip = True
        continue
    if skip:
        # pip 段中的子项一般以 4 个空格缩进；遇到新的顶层项就结束跳过
        if line.startswith('  - ') or (line and not line.startswith('    ')):
            skip = False
        else:
            continue
    if not skip:
        out.append(line)
Path('env_cu124_nopip.yaml').write_text('\n'.join(out) + '\n')
print('written env_cu124_nopip.yaml')
PY

RUN mamba env create -f env_cu124_nopip.yaml

SHELL ["conda", "run", "-n", "pepmimic", "/bin/bash", "-lc"]

RUN python -m pip install --upgrade pip setuptools wheel

# 先装除 torch-scatter 外的 pip 依赖
RUN python -m pip install \
    biopython==1.80 \
    rdkit-pypi==2022.3.5 \
    sympy \
    easydict \
    scipy \
    freesasa \
    tensorboard \
    pyyaml \
    tqdm \
    ray \
    munkres \
    matplotlib==3.8.2 \
    seaborn==0.12.0

# torch-scatter 单独装，禁用 build isolation，并优先尝试 PyG wheel
RUN python -m pip install --no-build-isolation \
    -f https://data.pyg.org/whl/torch-2.5.1+cu124.html \
    torch-scatter==2.1.2 || \
    python -m pip install --no-build-isolation torch-scatter==2.1.2

WORKDIR /workspace

CMD ["/bin/bash"]
