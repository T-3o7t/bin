#!/bin/bash
# backup_thesis.sh で取った OneDrive 上のバックアップから ~/tex_thesis へ復元する。
# 復元で上書き・削除されるローカルのファイルは ~/tex_thesis_restore_history/<日時>/ に退避するので、
# 復元をやり直したくなっても戻せる。ビルド生成物 (out/) は触らない。
#
# Usage: restore_thesis.sh [-n] [--delete] [-t <日時>] [file ...]
#        restore_thesis.sh -l
#        restore_thesis.sh -h
#   -n, --dry-run  何が復元されるかを表示するだけで、実際にはコピーしない
#   --delete       バックアップに無いローカルのファイルを消す (消したものは restore_history に残る)
#   -t <日時>      最新のバックアップではなく latex_thesis_history/<日時>/ から復元する。
#                  そこにあるのは「その日時の backup_thesis.sh で上書き・削除される前」の版
#   -l             latex_thesis_history の日時と中身の一覧を表示する
#   -h, --help     このヘルプを表示する
#   file ...       指定したファイル (tex_thesis からの相対パス) だけを復元する。省略時は全体
#
# Env overrides: SRC (復元先 = 作業ディレクトリ), DEST (OneDrive 上のバックアップ。backup_thesis.sh と同じもの)
set -e

SRC="${SRC:-$HOME/tex_thesis}"
DEST="${DEST:-/mnt/c/Users/Lab_stndents/OneDrive - Akita Prefectural University/Lab/thesis/latex_thesis}"
HISTORY_ROOT="$(dirname "${DEST}")/latex_thesis_history"
LOCAL_HISTORY="${HOME}/tex_thesis_restore_history/$(date +%Y%m%d-%H%M%S)"

# 冒頭のコメント (このファイルの説明) をそのままヘルプとして表示する
show_help() {
    sed -n '2,/^set -e/{/^#/s/^# \{0,1\}//p}' "$0"
}

usage() {
    echo "usage: $(basename "$0") [-n] [--delete] [-t <日時>] [file ...]" >&2
    echo "       $(basename "$0") -l" >&2
    echo "詳しくは $(basename "$0") -h" >&2
    exit 1
}

opts=()
files=()
from="${DEST}"
while [ $# -gt 0 ]; do
    case "$1" in
        -n|--dry-run) opts+=(--dry-run) ;;
        --delete)     opts+=(--delete) ;;
        -t)
            [ -n "$2" ] || { echo "error: -t には日時を指定する (-l で一覧)" >&2; usage; }
            from="${HISTORY_ROOT}/$2"
            shift
            ;;
        -l)
            if [ ! -d "${HISTORY_ROOT}" ]; then
                echo "履歴はまだありません (${HISTORY_ROOT})"
                exit 0
            fi
            for d in "${HISTORY_ROOT}"/*/; do
                echo "$(basename "${d}"):"
                (cd "${d}" && find . -type f | sed 's|^\./|    |' | sort)
            done
            exit 0
            ;;
        -h|--help) show_help; exit 0 ;;
        -*) echo "error: 不明なオプション: $1" >&2; usage ;;
        *) files+=("$1") ;;
    esac
    shift
done

if [ ! -d "${from}" ]; then
    echo "error: ${from} not found (-l で履歴の日時を確認、OneDrive 側でフォルダを移動した場合は DEST を直す)" >&2
    exit 1
fi
mkdir -p "${SRC}"

# 履歴には変更のあったファイルしか無いので、-t で全体を --delete 復元すると大半が消える。それを防ぐ
if [ "${from}" != "${DEST}" ] && [[ " ${opts[*]} " == *" --delete "* ]]; then
    echo "error: -t と --delete は同時に使えない (履歴に無いファイルまで消えるため)" >&2
    exit 1
fi

# 指定ファイルだけ復元する場合は --files-from で絞る
if [ ${#files[@]} -gt 0 ]; then
    for f in "${files[@]}"; do
        if [ ! -e "${from}/${f}" ]; then
            echo "error: ${from}/${f} not found" >&2
            exit 1
        fi
    done
    list="$(mktemp)"
    trap 'rm -f "${list}"' EXIT
    printf '%s\n' "${files[@]}" > "${list}"
    opts+=(--files-from="${list}")
fi

# backup_thesis.sh と同じく中身で比較し、変わったファイルだけ戻す
rsync -rtc --itemize-changes \
    --exclude 'out/' \
    --backup --backup-dir="${LOCAL_HISTORY}" \
    "${opts[@]}" \
    "${from}/" "${SRC}/"

if [ -d "${LOCAL_HISTORY}" ]; then
    echo "復元前のローカルのファイル: ${LOCAL_HISTORY}"
fi
echo "restore done: ${from} -> ${SRC}"
