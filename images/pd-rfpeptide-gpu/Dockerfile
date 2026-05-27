FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

SHELL ["/bin/bash", "-lc"]

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV CONDA_DIR=/opt/conda
ENV PATH=${CONDA_DIR}/bin:${PATH}

# 系统依赖
RUN apt-get update && apt-get install -y \
    wget \
    git \
    curl \
    ca-certificates \
    bzip2 \
    build-essential \
    vim \
    libglib2.0-0 \
    libxext6 \
    libsm6 \
    libxrender1 \
    && rm -rf /var/lib/apt/lists/*

# Miniconda
RUN wget -qO /tmp/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash /tmp/miniconda.sh -b -p ${CONDA_DIR} && \
    rm -f /tmp/miniconda.sh

# 接受 defaults ToS
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

RUN conda clean -afy || true

# 干净 GPU 环境
RUN source /opt/conda/etc/profile.d/conda.sh && \
    conda create -y -n SE3cuda -c defaults python=3.10 && \
    conda clean -afy

# GPU PyTorch
RUN source /opt/conda/etc/profile.d/conda.sh && \
    conda activate SE3cuda && \
    pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir \
      torch torchvision torchaudio \
      --index-url https://download.pytorch.org/whl/cu121

# 基础 Python 依赖
RUN source /opt/conda/etc/profile.d/conda.sh && \
    conda activate SE3cuda && \
    pip install --no-cache-dir \
      numpy \
      scipy \
      pandas \
      pyyaml \
      omegaconf \
      hydra-core \
      networkx \
      einops \
      biopython \
      scikit-learn \
      tqdm \
      pydantic \
      opt_einsum \
      icecream \
      dm-tree \
      e3nn \
      lie_learn \
      pyrsistent \
      torchdata==0.7.1

# DGL 必须固定为 CUDA wheel
RUN source /opt/conda/etc/profile.d/conda.sh && \
    conda activate SE3cuda && \
    pip install --no-cache-dir \
      dgl==1.1.3+cu121 \
      -f https://data.dgl.ai/wheels/cu121/repo.html

# 构建期 GPU 自检
RUN source /opt/conda/etc/profile.d/conda.sh && \
    conda activate SE3cuda && \
    python - <<'PY' \
import torch, dgl; \
print("torch=", torch.__version__); \
print("cuda=", torch.version.cuda); \
print("cuda_ok=", torch.cuda.is_available()); \
print("dgl=", dgl.__version__); \
PY

# 获取 RFdiffusion
WORKDIR /opt
RUN rm -rf /opt/RFdiffusion && \
    git clone --depth 1 https://github.com/RosettaCommons/RFdiffusion.git

# 先装 RFdiffusion 本体，但跳过自动依赖解析
RUN source /opt/conda/etc/profile.d/conda.sh && \
    conda activate SE3cuda && \
    cd /opt/RFdiffusion && \
    pip install --no-cache-dir -e . --no-deps

# 安装本地 SE3Transformer
RUN source /opt/conda/etc/profile.d/conda.sh && \
    conda activate SE3cuda && \
    if [ -d /opt/RFdiffusion/env/SE3Transformer ]; then \
      cd /opt/RFdiffusion/env/SE3Transformer && pip install --no-cache-dir -e . ; \
    elif [ -d /opt/RFdiffusion/SE3Transformer ]; then \
      cd /opt/RFdiffusion/SE3Transformer && pip install --no-cache-dir -e . ; \
    else \
      echo "SE3Transformer local source not found" && exit 1 ; \
    fi

# 常用自检脚本
RUN cat > /usr/local/bin/rfpeptide-check <<'EOF' && chmod +x /usr/local/bin/rfpeptide-check
#!/bin/bash
set -e
source /opt/conda/etc/profile.d/conda.sh
conda activate SE3cuda
python - <<'PY'
import torch, dgl
print("torch:", torch.__version__, torch.version.cuda, torch.cuda.is_available())
print("dgl:", dgl.__version__)
g = dgl.graph(([0,1],[1,2])).to("cuda")
src, dst = g.edges()
print("graph device:", g.device)
print("edges ok:", src.device, dst.device, src.tolist(), dst.tolist())
PY
EOF

RUN cat > /usr/local/bin/rfpeptide-smoketest <<'EOF' && chmod +x /usr/local/bin/rfpeptide-smoketest
#!/bin/bash
set -e
source /opt/conda/etc/profile.d/conda.sh
conda activate SE3cuda
cd /opt/RFdiffusion/examples
bash design_macrocyclic_monomer.sh
EOF

WORKDIR /workspace
CMD ["/bin/bash"]
