#!/bin/bash
set -e

ROOT=$(pwd)

echo "[1/3] Patch run.mk"

grep -q "tpmdev emulator" mkutils/plat/generic/run.mk || \
sed -i '/-device virtio-rng-pci/a\
                -chardev socket,id=chrtpm,path=/tmp/emulated_tpm/swtpm-sock \\\
                -tpmdev emulator,id=tpm0,chardev=chrtpm' \
mkutils/plat/generic/run.mk

echo "[2/3] Patch linux64-defconfig"

CFG=overlays/keystone/configs/linux64-defconfig

grep -q "^CONFIG_TCG_TIS=y$" "$CFG" || \
sed -i '/CONFIG_HW_RANDOM_VIRTIO=y/a CONFIG_TCG_TIS=y' "$CFG"

grep -q "^CONFIG_SECURITY=y$" "$CFG" || \
sed -i '/CONFIG_9P_FS=y/a CONFIG_SECURITY=y\nCONFIG_IMA=y' "$CFG"

sed -i '/CONFIG_DEBUG_INFO=y/d' "$CFG"
sed -i '/CONFIG_STACKTRACE=y/d' "$CFG"

echo "[3/3] Patch riscv64_generic_defconfig"

CFG=overlays/keystone/configs/riscv64_generic_defconfig

sed -i '/BR2_TOOLCHAIN_BUILDROOT_GLIBC=y/d' "$CFG"
sed -i '/BR2_ROOTFS_OVERLAY="\/invalid"/d' "$CFG"

for pkg in \
    BR2_PACKAGE_GIT=y \
    BR2_PACKAGE_MAKE=y \
    BR2_PACKAGE_RTC_TOOLS=y \
    BR2_PACKAGE_CA_CERTIFICATES=y \
    BR2_PACKAGE_LIBOPENSSL_BIN=y \
    BR2_PACKAGE_LIBCAP=y \
    BR2_PACKAGE_NTP=y \
    BR2_PACKAGE_OPENSSH=y \
    BR2_PACKAGE_TPM2_TOOLS=y
do
    grep -q "^$pkg$" "$CFG" || \
    sed -i "/BR2_PACKAGE_BUSYBOX_SHOW_OTHERS=y/a $pkg" "$CFG"
done

echo "Done."
