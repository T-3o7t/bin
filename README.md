# bin
shellscript

# installation
```bash
sudo apt update
sudo apt install -y \
build-essential \
python4-venv \
ninja-build \
libglib2.0-dev \
libncurses5-dev libncursesw5-dev \
swtpm \
qemu-system-riscv-hwe \



```

# usage
- you need to chenge "user" to your "user name" on build_qemu.sh
- Use shell scripts execute_qemu.sh and execute_qemu_tpm.sh depending on whether or not TPM is used

```bash
./pre_build_qemu.sh
./git_qemu.sh
./build_qemu.sh
mkdir image
cd !$
./kernel_image.sh
./execute_qemu.sh or ./execute_qemu_tpm.sh
```
