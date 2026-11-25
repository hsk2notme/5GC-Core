#!/usr/bin/env bash
# Tải mã nguồn đúng bản phát hành, biên dịch và cài vào $OPEN5GS_DIR/install
set -euo pipefail
source "$(dirname "$0")/env.sh"
if [ ! -d "$OPEN5GS_DIR/.git" ]; then
  git clone https://github.com/open5gs/open5gs "$OPEN5GS_DIR"
fi
cd "$OPEN5GS_DIR"
git fetch --tags
git checkout "$OPEN5GS_TAG"
[ -d build ] || meson setup build --prefix="$(pwd)/install"
ninja -C build
ninja -C build install
echo "Xong. Chương trình nằm trong $BIN"
