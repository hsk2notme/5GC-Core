#!/usr/bin/env bash
# Chạy MongoDB bằng Docker, chỉ mở cổng 27017 cho chính máy này (127.0.0.1).
# MongoDB 5.0 trở lên cần CPU có AVX; nếu không có AVX thì dùng bản 4.4.
set -euo pipefail
if docker ps -a --format '{{.Names}}' | grep -qx open5gs-mongo; then
  docker start open5gs-mongo >/dev/null
  echo "Đã bật lại container open5gs-mongo."
  exit 0
fi
if grep -q avx /proc/cpuinfo; then IMAGE=mongo:8.0; else IMAGE=mongo:4.4; fi
echo "Dùng image $IMAGE"
docker run -d --name open5gs-mongo --restart unless-stopped \
  -p 127.0.0.1:27017:27017 -v open5gs-mongo-data:/data/db "$IMAGE"
