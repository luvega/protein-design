FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV CONDA_DIR=/opt/conda
ENV PATH=${CONDA_DIR}/bin:${PATH}

RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    ca-certificates \
    bzip2 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO /tmp/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash /tmp/miniconda.sh -b -p ${CONDA_DIR} && \
    rm /tmp/miniconda.sh

WORKDIR /opt
RUN git clone https://github.com/martinpacesa/BindCraft.git

WORKDIR /opt/BindCraft
RUN chmod +x install_bindcraft.sh

WORKDIR /workspace

CMD ["/bin/bash"]
