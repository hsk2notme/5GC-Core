#!/usr/bin/env bash
# Bật toàn bộ 5G Core ở chế độ chạy nền. Log ghi vào $LOG/<nf>.log
set -euo pipefail
source "$(dirname "$0")/env.sh"
mkdir -p "$LOG"
for nf in $NFS_5GC; do
  if pgrep -f "open5gs-${nf}d" >/dev/null; then echo "$nf: đang chạy"; continue; fi
  nohup "$BIN/open5gs-${nf}d" >/dev/null 2>&1 &
  echo "$nf: đã bật (pid $!)"
  [ "$nf" = nrf ] && sleep 1      # NRF lên trước để các NF khác đăng ký
done
if ! pgrep -f open5gs-upfd >/dev/null; then
  sudo -b nohup "$BIN/open5gs-upfd" >/dev/null 2>&1
  echo "upf: đã bật (sudo)"
fi
sleep 3
bash "$(dirname "$0")/status.sh"
