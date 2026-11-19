#!/usr/bin/env bash
# Kiểm tra các NF đang chạy và đã đăng ký với NRF
docker ps --format "table {{.Names}}\t{{.Status}}"
echo "--- NRF register log ---"
docker logs nrf 2>&1 | grep -i regist
