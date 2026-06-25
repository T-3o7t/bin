export WORKSPACE=`pwd` && \
        export GCC_RISCV64_PREFIX=/usr/bin/riscv64-linux-gnu- && \
        export PACKAGES_PATH=$WORKSPACE/edk2 && \
        export EDK_TOOLS_PATH=$WORKSPACE/edk2/BaseTools && \
        source edk2/edksetup.sh --reconfig && \
        make -C edk2/BaseTools && \
        source edk2/edksetup.sh BaseTools && \
         build -a RISCV64 --buildtarget DEBUG -p OvmfPkg/RiscVVirt/RiscVVirtQemu.dsc \
                 -t GCC \
                -DSECURE_BOOT_ENABLE=TRUE -DTPM2_ENABLE=TRUE -DTPM2_CONFIG_ENABLE=TRUE \
                -DRISCVVIRT_PEI_BOOTING=TRUE
