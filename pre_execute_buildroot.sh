#!/bin/bash

set -x

ATTEST_DIR=$HOME/attest
GITHUB_DIR=$HOME/github

RUN_MK=keystone/mkutils/plat/generic/run.mk
QEMU_MK=keystone/buildroot/package/qemu/qemu.mk
VIRT_C=keystone/build-generic64/buildroot.build/build/host-qemu-7.2.1/hw/riscv/virt.c
VIRT_H=keystone/build-generic64/buildroot.build/build/host-qemu-7.2.1/include/hw/riscv/virt.h


if [ ! -f $GITHUB_DIR/${RUN_MK}_ORG ]; then
    mv $GITHUB_DIR/$RUN_MK $GITHUB_DIR/${RUN_MK}_ORG
    cp $ATTEST_DIR/$RUN_MK $GITHUB_DIR/$RUN_MK
fi

if [ ! -f $GITHUB_DIR/${QEMU_MK}_ORG ]; then
    mv $GITHUB_DIR/$QEMU_MK $GITHUB_DIR/${QEMU_MK}_ORG
    cp $ATTEST_DIR/$QEMU_MK $GITHUB_DIR/$QEMU_MK
fi

if [ ! -f $GITHUB_DIR/${VIRT_C}_ORG ]; then
    mv $GITHUB_DIR/$VIRT_C $GITHUB_DIR/${VIRT_C}_ORG
    cp $ATTEST_DIR/$VIRT_C $GITHUB_DIR/$VIRT_C
fi

if [ ! -f $GITHUB_DIR/${VIRT_H}_ORG ]; then
    mv $GITHUB_DIR/$VIRT_H $GITHUB_DIR/${VIRT_H}_ORG
    cp $ATTEST_DIR/$VIRT_H $GITHUB_DIR/$VIRT_H
fi

cd $HOME/github/keystone/build-generic64/buildroot.build

KEYSTONE=$HOME/github/keystone \
KEYSTONE_BOOTROM=$HOME/github/keystone/bootrom \
KEYSTONE_SM=$HOME/github/keystone/sm \
KEYSTONE_SDK=$HOME/github/keystone/sdk \
KEYSTONE_RUNTIME=$HOME/github/keystone/runtime \
KEYSTONE_DRIVER=$HOME/github/keystone/linux-keystone-driver \
KEYSTONE_EXAMPLES=$HOME/github/keystone/examples \
make host-qemu-rebuild V=1 2>&1 | tee host-qemu-rebuild.log

cd ~/github/keystone/build-generic64/buildroot.build
cp -a host/bin/qemu-system-riscv64 host/bin/qemu-system-riscv64.bak-$(date +%Y%m%d-%H%M%S)
cp -a per-package/host-qemu/host/bin/qemu-system-riscv64 host/bin/qemu-system-riscv64
