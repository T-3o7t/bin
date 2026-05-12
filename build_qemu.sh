mkdir -p ~/build_qemu;
cd ~/build_qemu;

../qemu/configure \
--prefix=/home/user/qemu-riscv \
--target-list=riscv64-linux-user,riscv64-softmmu,x86_64-softmmu,x86_64\
-linux-user \
--enable-tpm    \
--enable-slirp  \
--enable-virtfs \
--enable-kvm \
--enable-keyring \
--enable-attr \
--enable-auth-pam \
--enable-curses \
--enable-fuse \
--enable-fuse-lseek \
--enable-gnutls \
--enable-linux-io-uring \
--enable-numa \
--enable-qcow1 \
--enable-rdma \
--enable-seccomp \
--enable-selinux \
--enable-virtfs \
--enable-vmdk \
--enable-pie

