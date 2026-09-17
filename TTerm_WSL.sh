#!/bin/bash
TTERM="/mnt/c/Program Files (x86)/teraterm/ttermpro.exe"
COM=3; BAUD=115200
LOG_WIN='C:\temp\serial.log'
LOG_WSL='/mnt/c/temp/serial.log'

mkdir -p /mnt/c/temp
"$TTERM" /C=$COM /BAUD=$BAUD /L="$LOG_WIN" &
sleep 2
tail -f "$LOG_WSL" | tr -d '\r'
