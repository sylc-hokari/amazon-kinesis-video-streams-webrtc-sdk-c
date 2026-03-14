FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        ccache \
        cmake \
        curl \
        file \
        g++ \
        g++-aarch64-linux-gnu \
        gcc \
        gcc-aarch64-linux-gnu \
        git \
        make \
        m4 \
        ninja-build \
        openssh-client \
        perl \
        pkg-config \
        python3 \
        rsync \
        xz-utils && \
    rm -rf /var/lib/apt/lists/*

ENV CCACHE_DIR=/work/.ccache
ENV PATH=/usr/lib/ccache:${PATH}

WORKDIR /work

CMD ["/bin/bash"]
