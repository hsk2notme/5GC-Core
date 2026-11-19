# 5GC Lab – CCNlab labTrain 5G Core Platform

Ghi chép và bằng chứng lab của tôi, chạy free5GC (SA) trên máy ảo.

## Môi trường
- VMware Workstation, Ubuntu, kernel 7.0.0-43, 5 GB RAM, 2 CPU
- free5GC qua [free5gc-compose](https://github.com/free5gc/free5gc-compose) (commit: evidence/free5gc-compose-commit.txt)
- gtp5g nhánh master + bản vá `patches/gtp5g-kernel7.patch`

## Tiến độ
| Stage | Nội dung | Trạng thái |
|---|---|---|
| 1 | Kiến trúc 5GS: EPC→SBA, CUPS, SA/NSA, NF và sơ đồ | Báo cáo 21/11/2026 |
| 2 | Triển khai free5GC, các NF đăng ký NRF | Lab xong (evidence/) · lý thuyết TS 23.501 ch.6: đang học |
| 3 | Bắt gói SBI, PFCP heartbeat | Chưa |
| 4 | StormSIM: Registration + PDU Session | Chưa |
| 5 | Đồ án cuối | Chưa |

## Vấn đề gặp và cách xử lý
- gtp5g 0.9.5 không build trên kernel 7.0 (lỗi `genl.h`, rồi `setup_udp_tunnel_sock`, `udp_tunnel_xmit_skb`).
- Cách sửa: dùng nhánh master; sửa `src/gtpu/encap.c`: tham số thứ hai của `setup_udp_tunnel_sock` từ `sock` thành `sock->sk`.
- Kết quả: module nạp được, mọi container Up, UPF chạy ổn.

## Chạy lại
```bash
bash ~/5gc-lab/scripts/install-gtp5g.sh   # chỉ khi kernel thay đổi
cd ~/free5gc-compose && docker compose up -d
bash ~/5gc-lab/scripts/check-nf.sh
```
WebUI: http://localhost:5000 (admin / free5gc)
