#! /bin/bash

set -ex

sudo apt update
sudo apt install -y build-essential \
        bison flex bc libncurses-dev \
        libssl-dev openssl uuid-dev \
        device-tree-compiler pkg-config \
        lz4 lzma lzma-alone swig \
        python3 python3-pyelftools \
        gcc gcc-riscv64-linux-gnu g++-riscv64-linux-gnu \
        binutils-riscv64-linux-gnu libc6-dev-riscv64-cross
