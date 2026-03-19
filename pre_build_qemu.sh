#!/bin/bash
sudo apt update;
sudo apt upgrade -y;
sudo apt install -y liburing-dev \
libseccomp-dev \
python3-docutils \
gnutls-bin \
pkg-config libgnutls28-dev \
libpam0g-dev \
libnuma-dev \
librdmacm-dev libibverbs-dev \
libfuse3-dev \
libbpf-dev libelf-dev zlib1g-dev

