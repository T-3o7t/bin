#!/usr/bin/env bash
#
# start_qemu_and_telnet.sh
#
# 1. buildroot ディレクトリに移動して start-qemu.sh を起動
# 2. Normal World の Linux コンソール (telnet 127.0.0.1 64320) に
#    別ターミナルで自動接続する
#
# 使い方:
#   ./start_qemu_and_telnet.sh
#
set -euo pipefail

BUILDROOT_DIR="$HOME/kpro/riscv-optee/buildroot"
QEMU_SCRIPT="./output/images/start-qemu.sh"
TELNET_HOST="127.0.0.1"
TELNET_PORT="64320"
LOG_FILE="/tmp/start-qemu.log"
WAIT_TIMEOUT=60   # ポートが開くまで待つ最大秒数

# --- 1. buildroot ディレクトリへ移動して QEMU を起動 -----------------------

if [ ! -d "$BUILDROOT_DIR" ]; then
    echo "エラー: ディレクトリが見つかりません: $BUILDROOT_DIR" >&2
    exit 1
fi

cd "$BUILDROOT_DIR"

if [ ! -x "$QEMU_SCRIPT" ]; then
    echo "エラー: $QEMU_SCRIPT が見つからない、または実行権限がありません" >&2
    exit 1
fi

echo "[1/2] QEMU を起動しています: $BUILDROOT_DIR/$QEMU_SCRIPT"
echo "      ログ出力先: $LOG_FILE"

# QEMU をバックグラウンドで起動（現在の端末は占有しない）
nohup "$QEMU_SCRIPT" > "$LOG_FILE" 2>&1 &
QEMU_PID=$!

echo "      QEMU PID: $QEMU_PID"

# --- telnet ポートが開くまで待機 -------------------------------------------

echo "      telnet ポート (${TELNET_HOST}:${TELNET_PORT}) の起動を待っています..."

elapsed=0
until (exec 3<>"/dev/tcp/${TELNET_HOST}/${TELNET_PORT}") 2>/dev/null; do
    exec 3<&- 2>/dev/null || true
    exec 3>&- 2>/dev/null || true
    sleep 1
    elapsed=$((elapsed + 1))
    if [ "$elapsed" -ge "$WAIT_TIMEOUT" ]; then
        echo "警告: ${WAIT_TIMEOUT}秒待ちましたがポートが開きませんでした。"
        echo "       QEMU のログを確認してください: $LOG_FILE"
        break
    fi
    # QEMU が途中で終了していないか確認
    if ! kill -0 "$QEMU_PID" 2>/dev/null; then
        echo "エラー: QEMU プロセスが終了しました。ログを確認してください: $LOG_FILE" >&2
        exit 1
    fi
done
exec 3<&- 2>/dev/null || true
exec 3>&- 2>/dev/null || true

echo "      ポートが利用可能になりました（または待機を終了しました）。"

# --- 2. 別ターミナルで telnet 接続 ------------------------------------------

echo "[2/2] 別ターミナルで Normal World の Linux コンソールに接続します。"

TELNET_CMD="telnet ${TELNET_HOST} ${TELNET_PORT}"

if command -v gnome-terminal >/dev/null 2>&1; then
    gnome-terminal -- bash -c "${TELNET_CMD}; exec bash"
elif command -v konsole >/dev/null 2>&1; then
    konsole -e bash -c "${TELNET_CMD}; exec bash" &
elif command -v xfce4-terminal >/dev/null 2>&1; then
    xfce4-terminal -e "bash -c '${TELNET_CMD}; exec bash'" &
elif command -v xterm >/dev/null 2>&1; then
    xterm -e bash -c "${TELNET_CMD}; exec bash" &
elif command -v osascript >/dev/null 2>&1; then
    # macOS
    osascript -e "tell application \"Terminal\" to do script \"${TELNET_CMD}\""
else
    echo "対応するターミナルエミュレータが見つかりませんでした。"
    echo "手動で以下を別ターミナルから実行してください:"
    echo "  ${TELNET_CMD}"
    exit 0
fi

echo "完了しました。"
