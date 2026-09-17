#!/bin/bash
# --- 設定 ---
TTERM="/mnt/c/Program Files (x86)/teraterm/ttermpro.exe"
COM=3          # デバイスマネージャで確認したCOM番号
BAUD=115200
BIN="C:/Users/Lab_student/Desktop/bootloader_addr5_secboot.bin"

# 1. Tera Termでシリアルポートを開く（usbipd attach / minicom は不要）
"$TTERM" /C=$COM /BAUD=$BAUD &

# 2. binファイルをD:へ書き込み（リセットによる切断は無視）
powershell.exe -Command "try { Copy-Item '$BIN' -Destination 'D:/' -ErrorAction Stop } catch { Write-Host 'Copy triggered device reset (expected)' }"
