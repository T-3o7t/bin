#!/bin/bash
# Boot the qemu_riscv64_virt_optee_tpm Buildroot image (QEMU + swtpm + OP-TEE) from anywhere.
# Thin wrapper around board/qemu/riscv64-virt-optee-tpm/run-qemu.sh in the buildroot tree.
#
# Usage: run_buildroot_optee.sh [--tcp-serial] [--debug] [-- extra qemu args]
#   All arguments are passed through to run-qemu.sh.
#   Login: root / sifive, ssh: ssh -p ${SSH_PORT:-2200} root@localhost
#
# Env overrides: BR_DIR (buildroot tree), IMAGES, QEMU, TPM_DIR, SSH_PORT, QEMU_MEM, QEMU_SMP
set -e

BR_DIR="${BR_DIR:-$HOME/github/buildroot_optee}"
RUN_QEMU="${BR_DIR}/board/qemu/riscv64-virt-optee-tpm/run-qemu.sh"
IMAGES="${IMAGES:-${BR_DIR}/output/images}"

if [ ! -x "${RUN_QEMU}" ]; then
    echo "error: ${RUN_QEMU} not found (set BR_DIR to the buildroot_optee tree)" >&2
    exit 1
fi

for f in sdcard.img u-boot-spl u-boot.itb qemu_rv64_virt_domain.dtb; do
    if [ ! -e "${IMAGES}/${f}" ]; then
        echo "error: ${IMAGES}/${f} not found; build first:" >&2
        echo "  cd ${BR_DIR} && make qemu_riscv64_virt_optee_tpm_defconfig && make" >&2
        exit 1
    fi
done

export BR_DIR IMAGES
exec "${RUN_QEMU}" "$@"
