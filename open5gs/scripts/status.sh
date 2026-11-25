#!/usr/bin/env bash
# Kiểm tra 3 điều: NF còn chạy, NF đã tự ghi danh với NRF, SMF và UPF đã nối N4
source "$(dirname "$0")/env.sh"
echo "== Tiến trình =="
for nf in $NFS_5GC upf; do
  if pgrep -f "open5gs-${nf}d" >/dev/null; then echo "  $nf  chạy"; else echo "  $nf  KHÔNG chạy"; fi
done
echo "== Tự ghi danh với NRF (NF instance ID) =="
for nf in $NFS_5GC; do
  [ "$nf" = nrf ] && continue
  line=$(grep -h "NF registered \[Heartbeat" "$LOG/$nf.log" 2>/dev/null | tail -1)
  if [ -z "$line" ]; then echo "  $nf: chưa thấy"; continue; fi
  id=$(echo "$line" | grep -o '[0-9a-f]\{8\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{12\}' | head -1)
  printf "  %-5s %s  lúc %s\n" "$nf" "$id" "$(echo "$line" | cut -d' ' -f1-2 | tr -d ':' | sed 's/\(..\)\(..\)\(..\)\..*/\1:\2:\3/')"
done
echo "== N4 (PFCP) giữa SMF và UPF, lần gần nhất =="
echo "  smf: $(grep -h 'PFCP associated' "$LOG/smf.log" 2>/dev/null | tail -1 | cut -d' ' -f1-2,5-7)"
echo "  upf: $(grep -h 'PFCP associated' "$LOG/upf.log" 2>/dev/null | tail -1 | cut -d' ' -f1-2,5-7)"
