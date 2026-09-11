#!/bin/bash
# 1. USBデバイスをWSLにアタッチ（管理者権限が必要なため昇格して実行）
powershell.exe -Command "Start-Process powershell -Verb RunAs -ArgumentList '-Command usbipd attach --wsl --busid 3-1; usbipd list'"

# 2. シリアル通信
sudo minicom

# 3. ファイルコピー
# powershell.exe -Command "Copy-Item 'C:/Users/Lab_student/Desktop/bootloader_addr5_secboot.bin' -Destination 'D:/'"
powershell.exe -Command "try { Copy-Item 'C:/Users/Lab_student/Desktop/bootloader_addr5_secboot.bin' -Destination 'D:/' -ErrorAction Stop } catch { Write-Host 'Copy triggered device reset (expected)' }"
