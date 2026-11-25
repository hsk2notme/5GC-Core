#!/usr/bin/env bash
# Tạo giao diện ogstun cho UPF và cho phép UE ra Internet (NAT). Mất sau khi khởi động lại máy.
set -euo pipefail
if ! ip link show ogstun >/dev/null 2>&1; then
  sudo ip tuntap add name ogstun mode tun
fi
sudo ip addr replace 10.45.0.1/16 dev ogstun
sudo sysctl -w net.ipv6.conf.ogstun.disable_ipv6=0 >/dev/null
sudo ip addr replace 2001:db8:cafe::1/48 dev ogstun
sudo ip link set ogstun up
sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null
if ! sudo iptables -t nat -C POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE 2>/dev/null; then
  sudo iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE
fi
ip -brief addr show ogstun
