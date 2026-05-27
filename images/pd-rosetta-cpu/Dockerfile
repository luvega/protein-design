FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    zlib1g-dev \
    libbz2-dev \
    python3 \
    python3-pip \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --upgrade pip setuptools wheel
RUN pip3 install \
    biopython \
    numpy \
    scipy \
    pandas \
    matplotlib

WORKDIR /workspace

CMD ["/bin/bash"]
