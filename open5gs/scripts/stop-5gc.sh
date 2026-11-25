#!/usr/bin/env bash
# Tắt toàn bộ NF của Open5GS
pkill -f 'install/bin/open5gs-' 2>/dev/null || true
sudo pkill -f 'install/bin/open5gs-upfd' 2>/dev/null || true
sleep 1
pgrep -fl 'open5gs-' || echo "Đã tắt hết."
