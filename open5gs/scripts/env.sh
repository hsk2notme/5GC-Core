# Biến dùng chung cho các script. Đổi ở đây nếu bạn đặt mã nguồn chỗ khác.
OPEN5GS_DIR="${OPEN5GS_DIR:-$HOME/open5gs}"
OPEN5GS_TAG="${OPEN5GS_TAG:-v2.8.0}"
BIN="$OPEN5GS_DIR/install/bin"
LOG="$OPEN5GS_DIR/install/var/log/open5gs"
# Các NF của 5G Core (không gồm SEPP vì chỉ dùng khi roaming). UPF chạy riêng vì cần quyền root.
NFS_5GC="nrf scp amf smf ausf udm pcf nssf bsf udr"
