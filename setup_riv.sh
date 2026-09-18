#!/usr/bin/env bash
#
# setup_riscv_optee_buildroot.sh
#
# riscv-optee-x86_64-manual-setup.md の 1〜5 章に対応。
# Ubuntu 24.04 LTS (x86_64) 上に RISE RISC-V OP-TEE の
# Buildroot ビルド環境を構築し、QEMU 起動直前まで進める。
#
# 対応範囲:
#   1. ホスト環境の確認
#   2. 必要パッケージのインストール
#   3. Buildroot 統合環境の取得（指定コミットへ固定）
#   4. x86_64 ホスト向け defconfig の適用
#   5. ビルド
#
# QEMU の起動および telnet 接続は別スクリプト
# (start_qemu_and_telnet.sh) で行う。
#
set -euo pipefail

# ---------------------------------------------------------------------------
# 設定
# ---------------------------------------------------------------------------

WORK_ROOT="$HOME/kpro/riscv-optee"
REPO_URL="https://gitlab.com/riseproject/riscv-optee/buildroot.git"
BRANCH="dev-optee-mpxy-v9"
COMMIT="b5e20ca925d0784473c854fae92c3fc5931802ee"
DEFCONFIG="qemu_riscv64_virt_optee_defconfig"
BUILDROOT_DIR="${WORK_ROOT}/buildroot"

# make -j の並列数（環境変数 JOBS で上書き可能。デフォルトは nproc）
JOBS="${JOBS:-$(nproc)}"

APT_PACKAGES=(
    build-essential git ca-certificates curl wget rsync file
    bc bison flex gawk cpio unzip zip xz-utils zstd lz4 patch diffutils
    perl python3 python3-venv python3-pip python3-setuptools
    ninja-build meson pkg-config autoconf automake libtool texinfo
    libssl-dev libncurses-dev libglib2.0-dev libpixman-1-dev
    libfdt-dev zlib1g-dev libslirp-dev device-tree-compiler
    socat telnet netcat-openbsd expect tmux jq time
    gdb-multiarch strace lsof swig libgnutls28-dev
)

log()  { echo -e "\n[INFO] $*"; }
warn() { echo -e "\n[WARN] $*" >&2; }
die()  { echo -e "\n[ERROR] $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 1. ホスト環境の確認
# ---------------------------------------------------------------------------

log "1. Ubuntuホストを確認しています"

ARCH="$(uname -m)"
echo "  uname -m: ${ARCH}"
if [ "${ARCH}" != "x86_64" ]; then
    die "このスクリプトは x86_64 ホスト専用です（検出値: ${ARCH}）"
fi

if [ -r /etc/os-release ]; then
    . /etc/os-release
    echo "  VERSION_ID: ${VERSION_ID:-unknown}"
    if [ "${VERSION_ID:-}" != "24.04" ]; then
        warn "VERSION_ID が 24.04 ではありません（検出値: ${VERSION_ID:-unknown}）。続行しますが動作保証外です。"
    fi
else
    warn "/etc/os-release が見つかりません。OSバージョンを確認できませんでした。"
fi

echo "  --- メモリ ---"
free -h
echo "  --- ディスク ($HOME) ---"
df -h "$HOME"
echo "  --- CPU数 ---"
echo "  nproc: $(nproc)  (今回のビルドで使用する並列数: ${JOBS})"

log "目安: メモリ4GiB以上 / 空きディスク80GiB以上。上記を目視で確認してください。"

# ---------------------------------------------------------------------------
# 2. 必要なパッケージをインストールする
# ---------------------------------------------------------------------------

log "2. 必要なパッケージをインストールしています"

sudo apt-get update

sudo apt-get install -y --no-install-recommends "${APT_PACKAGES[@]}"

log "時刻同期 (systemd-timesyncd) を有効化しています"
sudo systemctl enable --now systemd-timesyncd
if systemctl is-active --quiet systemd-timesyncd; then
    echo "  systemd-timesyncd: active (running)"
else
    warn "systemd-timesyncd が active になっていません。'systemctl status systemd-timesyncd' で確認してください。"
fi

log "GitLabへのHTTPS接続を確認しています"
if curl --fail --location --head --silent --show-error https://gitlab.com/ > /dev/null; then
    echo "  https://gitlab.com/ へ接続できました"
else
    die "https://gitlab.com/ に接続できませんでした。ネットワーク設定を確認してください。"
fi

# ---------------------------------------------------------------------------
# 3. Buildroot統合環境を取得する
# ---------------------------------------------------------------------------

log "3. Buildroot統合環境を取得しています"

mkdir -p "${WORK_ROOT}"
cd "${WORK_ROOT}"

if [ -d "${BUILDROOT_DIR}/.git" ]; then
    warn "既に ${BUILDROOT_DIR} が存在します。clone をスキップします。"
else
    git clone --branch "${BRANCH}" --single-branch "${REPO_URL}" buildroot
fi

cd "${BUILDROOT_DIR}"

log "検証対象コミットへ切り替えています: ${COMMIT}"
git switch --detach "${COMMIT}"

CURRENT_COMMIT="$(git rev-parse HEAD)"
echo "  現在のコミット: ${CURRENT_COMMIT}"
if [ "${CURRENT_COMMIT}" != "${COMMIT}" ]; then
    die "コミットハッシュが一致しません。期待値: ${COMMIT} / 実際: ${CURRENT_COMMIT}"
fi

GIT_STATUS="$(git status --porcelain)"
if [ -n "${GIT_STATUS}" ]; then
    die "作業ツリーがクリーンではありません。'git status' を確認してください。"
fi
echo "  git status: nothing to commit, working tree clean"

# ---------------------------------------------------------------------------
# 4. x86_64ホスト向け標準構成を適用する
# ---------------------------------------------------------------------------

log "4. defconfig (${DEFCONFIG}) を適用しています"

echo "  現在位置: $(pwd)"

make "${DEFCONFIG}"

log "ツールチェーン設定を確認しています"
TOOLCHAIN_CHECK="$(grep -E \
    '^BR2_TOOLCHAIN_EXTERNAL=y$|^BR2_TOOLCHAIN_EXTERNAL_BOOTLIN=y$|^BR2_TOOLCHAIN_EXTERNAL_DOWNLOAD=y$|^BR2_TOOLCHAIN_EXTERNAL_BOOTLIN_RISCV64_LP64D_GLIBC_.*=y$' \
    .config || true)"

echo "${TOOLCHAIN_CHECK}"

for required in \
    '^BR2_TOOLCHAIN_EXTERNAL=y$' \
    '^BR2_TOOLCHAIN_EXTERNAL_BOOTLIN=y$' \
    '^BR2_TOOLCHAIN_EXTERNAL_DOWNLOAD=y$'
do
    if ! echo "${TOOLCHAIN_CHECK}" | grep -qE "${required}"; then
        die "ツールチェーン設定 (${required}) が .config に見つかりません。ビルドを中止します。"
    fi
done

if ! echo "${TOOLCHAIN_CHECK}" | grep -qE '^BR2_TOOLCHAIN_EXTERNAL_BOOTLIN_RISCV64_LP64D_GLIBC_.*=y$'; then
    die "RISC-V用Bootlinツールチェーン設定が .config に見つかりません。ビルドを中止します。"
fi

# ---------------------------------------------------------------------------
# 5. ビルドする
# ---------------------------------------------------------------------------

log "5. ビルドを開始します (make -j${JOBS})"
echo "  ビルドには時間がかかります。しばらくお待ちください。"

make -j"${JOBS}"

log "生成物を確認しています"
ls -lh output/images/

REQUIRED_IMAGES=(
    start-qemu.sh
    Image
    qemu_rv64_virt_domain.dtb
    fw_jump.elf
    tee.bin
    rootfs.ext2
)

for f in "${REQUIRED_IMAGES[@]}"; do
    if [ ! -e "output/images/${f}" ]; then
        die "必要なファイルが見つかりません: output/images/${f}"
    fi
done
echo "  必要な生成物はすべて揃っています。"

if [ ! -e output/host/bin/qemu-system-riscv64 ]; then
    die "QEMU本体が見つかりません: output/host/bin/qemu-system-riscv64"
fi
ls -lh output/host/bin/qemu-system-riscv64

log "ビルドが完了しました。"
echo "次のステップ: ${BUILDROOT_DIR} で start_riv.sh を実行してください。"
