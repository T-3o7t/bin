sudo apt update;
sudo apt install qemu-system-misc;
sudo apt install u-boot-qemu;
wget https://cdimage.ubuntu.com/releases/24.04/release/ubuntu-24.04.4-preinstalled-server-riscv64.img.xz;
xz -dk ubuntu-24.04.4-preinstalled-server-riscv64.img.xz;
qemu-img info ubuntu-24.04.4-preinstalled-server-riscv64.img;
qemu-img resize ubuntu-24.04.4-preinstalled-server-riscv64.img +10G;
sudo apt install qemu-user-static binfmt-support

