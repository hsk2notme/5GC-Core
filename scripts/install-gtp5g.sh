#!/usr/bin/env bash
# Build và cài gtp5g v0.10.2 trên kernel 7.0 (a2a19e2 + bản vá sock->sk)
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd ~ && rm -rf gtp5g
git clone https://github.com/free5gc/gtp5g.git
cd gtp5g
git checkout "$(cat "$REPO_DIR/patches/gtp5g-base-commit.txt")"
git apply "$REPO_DIR/patches/gtp5g-kernel7.patch"
make clean && make
sudo make install
modinfo gtp5g | grep -i ^version
