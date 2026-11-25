#!/usr/bin/env bash
# Thư viện cần để build Open5GS (theo docs/_docs/guide/02-building-open5gs-from-sources.md).
set -euo pipefail
sudo apt update
sudo apt install -y python3-pip python3-setuptools python3-wheel ninja-build build-essential \
  flex bison git cmake libsctp-dev libc-ares-dev libgnutls28-dev libgcrypt-dev libssl-dev \
  libmongoc-dev libbson-dev libyaml-dev libnghttp2-dev libmicrohttpd-dev libcurl4-gnutls-dev \
  libtins-dev libtalloc-dev meson
# Tên gói libidn khác nhau tùy bản Ubuntu
if apt-cache show libidn-dev >/dev/null 2>&1; then
  sudo apt-get install -y --no-install-recommends libidn-dev
else
  sudo apt-get install -y --no-install-recommends libidn11-dev
fi
