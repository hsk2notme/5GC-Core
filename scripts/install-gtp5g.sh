#!/usr/bin/env bash
# Build và cài gtp5g trên kernel 7.0 (dùng nhánh master + bản vá 1 dòng)
set -euo pipefail
cd ~ && rm -rf gtp5g
git clone https://github.com/free5gc/gtp5g.git
cd gtp5g
git checkout "$(cat "$(dirname "$0")/../patches/gtp5g-base-commit.txt")"
git apply "$(dirname "$0")/../patches/gtp5g-kernel7.patch"
make clean && make
sudo make install
lsmod | grep gtp
