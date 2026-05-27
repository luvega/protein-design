FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONUNBUFFERED=1 \
    ROSETTA_VERSION=rosetta.source.release-408 \
    ROSETTA_ROOT=/opt/rosetta_src/rosetta.source.release-408 \
    ROSETTA3_DB=/opt/rosetta_db

SHELL ["/bin/bash", "-lc"]
    
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    g++ \
    gcc \
    gfortran \
    make \
    python3 \
    python3-dev \
    python3-pip \
    zlib1g-dev \
    libbz2-dev \
    libsqlite3-dev \
    libffi-dev \
    ca-certificates \
    wget \
    bzip2 \
    patch \
    rsync \
    vim \
    less \
    openmpi-bin \
    libopenmpi-dev \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 1000 appuser && \
    useradd -m -u 1000 -g 1000 -s /bin/bash appuser

RUN ln -sf /usr/bin/python3 /usr/bin/python

WORKDIR /opt
COPY rosetta_src/ /opt/rosetta_src/

WORKDIR ${ROSETTA_ROOT}/main/source

RUN python3 ./scons.py -c bin mode=release || true
RUN python3 ./scons.py -j"$(nproc --all)" mode=release bin extras=cxx11thread
RUN python3 ./scons.py -j"$(nproc --all)" mode=release bin extras=mpi

RUN mkdir -p /opt/rosetta_bin/threaded /opt/rosetta_bin/mpi && \
    find ${ROSETTA_ROOT}/main/source/build/src/release -type f -name "*.cxx11thread.linuxgccrelease" -exec ln -sf {} /opt/rosetta_bin/threaded/ \; && \
    find ${ROSETTA_ROOT}/main/source/build/src/release -type f -name "*.mpi.linuxgccrelease" -exec ln -sf {} /opt/rosetta_bin/mpi/ \;

ENV PATH=/opt/rosetta_bin/threaded:/opt/rosetta_bin/mpi:${ROSETTA_ROOT}/main/source/bin:$PATH

WORKDIR /workspace
CMD ["bash"]
