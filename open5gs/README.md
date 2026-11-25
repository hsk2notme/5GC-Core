# Open5GS: 5G Core viết bằng C

Thư mục này hướng dẫn cài [Open5GS](https://github.com/open5gs/open5gs) từ mã nguồn, chạy 5G Core trên một máy
(Ubuntu, kernel 7.0), rồi đọc mã nguồn C để hiểu các NF làm việc với nhau thế nào.

Open5GS và free5GC làm cùng một việc: hiện thực 5G Core theo 3GPP. Khác nhau ở cách viết và cách chạy:

| | free5GC (thư mục gốc của repo) | Open5GS (thư mục này) |
| --- | --- | --- |
| Ngôn ngữ | Go | C |
| Cách chạy ở đây | Docker, mỗi NF một container | Mỗi NF một tiến trình `open5gs-<nf>d` |
| UPF chở gói | Module kernel `gtp5g` | Giao diện ảo TUN `ogstun`, không cần module kernel |
| Địa chỉ các NF | Mạng Docker `10.100.200.0/24` | Loopback `127.0.0.x` |
| Dải IP cấp cho UE | `10.60.0.0/16` | `10.45.0.0/16` |
| PLMN mặc định | `208/93` | `999/70` |
| WebUI | `http://localhost:5000`, admin / free5gc | `http://localhost:9999`, admin / 1423 |
| Có thêm | — | Cả EPC 4G (MME, SGW, HSS…), chạy được NSA lẫn SA |

---

## Mục lục

1. [Chuẩn bị](#1-chuẩn-bị)
2. [Cài đặt](#2-cài-đặt)
3. [Chạy và kiểm tra](#3-chạy-và-kiểm-tra)
4. [Thêm thuê bao](#4-thêm-thuê-bao)
5. [Đọc mã nguồn: đi theo một UE vào mạng](#5-đọc-mã-nguồn-đi-theo-một-ue-vào-mạng)
6. [Bài tập: tự sửa mã và quan sát](#6-bài-tập-tự-sửa-mã-và-quan-sát)
7. [Dừng, dọn dẹp, xử lý sự cố](#7-dừng-dọn-dẹp-xử-lý-sự-cố)

---

## 1. Chuẩn bị

Máy ảo 5 GB RAM chỉ nên chạy **một** 5G Core một lúc. Tắt free5GC trước:

```bash
cd ~/free5gc-compose && docker compose stop
```

Các script nằm trong `open5gs/scripts/`. Đường dẫn mã nguồn mặc định là `~/open5gs` và phiên bản là `v2.8.0`;
muốn đổi thì sửa `scripts/env.sh`.

```bash
cd ~/5gc-lab/open5gs/scripts
```

## 2. Cài đặt

**Bước 1: MongoDB.** PCF và UDR lưu dữ liệu thuê bao trong MongoDB. Chạy bằng Docker để khỏi cài trên Ubuntu:

```bash
./1-mongo-up.sh
```

Script tự chọn `mongo:8.0` nếu CPU có AVX, nếu không thì dùng `mongo:4.4`.

**Bước 2: Thư viện để biên dịch.**

```bash
./2-install-deps.sh
```

**Bước 3: Tải mã nguồn, biên dịch, cài đặt.** Lần đầu mất khoảng 10–20 phút.

```bash
./3-build.sh
```

Kết quả: các chương trình `open5gs-nrfd`, `open5gs-amfd`… nằm trong `~/open5gs/install/bin`, file cấu hình trong
`~/open5gs/install/etc/open5gs/`, log trong `~/open5gs/install/var/log/open5gs/`.

**Bước 4: Giao diện ogstun và NAT.** UPF dùng `ogstun` để trao gói giữa UE và Internet. Lệnh này mất tác dụng
sau khi khởi động lại máy, nên mỗi lần bật máy chạy lại một lần:

```bash
./4-netconf.sh
```

**Kiểm tra nhanh bằng chương trình thử có sẵn** (chạy khi các NF *chưa* bật, vì chương trình thử tự dựng NF riêng):

```bash
cd ~/open5gs && ./build/tests/registration/registration
```

Thấy các dòng kết thúc bằng `SUCCESS` là bản build chạy được.

## 3. Chạy và kiểm tra

```bash
cd ~/5gc-lab/open5gs/scripts
./run-5gc.sh      # bật NRF, SCP, AMF, SMF, AUSF, UDM, PCF, NSSF, BSF, UDR và UPF (UPF cần sudo)
./status.sh       # xem lại bất cứ lúc nào
```

`status.sh` cho thấy ba điều, đúng ba khái niệm của Stage 1:

| Dòng in ra | Ý nghĩa |
| --- | --- |
| Mỗi NF `chạy` | Mỗi NF là một chương trình riêng |
| `NF registered [Heartbeat:…s]` trong log của từng NF | NF đã đăng ký với NRF và gửi heartbeat định kỳ |
| `PFCP associated` trong log SMF và UPF | SMF (control plane) đã bắt tay UPF (user plane) qua N4 |

Mỗi NF lắng nghe trên một địa chỉ loopback riêng. Một số địa chỉ chính:

| NF | Địa chỉ | Dùng cho |
| --- | --- | --- |
| NRF | 127.0.0.10:7777 | SBI |
| SCP | 127.0.0.200:7777 | SBI (các NF gọi nhau qua SCP) |
| AMF | 127.0.0.5:7777 · 127.0.0.5:38412 | SBI · N2 (NGAP) |
| SMF | 127.0.0.4:7777 · 127.0.0.4:8805 | SBI · N4 (PFCP) |
| UPF | 127.0.0.7:8805 · 127.0.0.7:2152 | N4 (PFCP) · N3 (GTP-U) |

Đọc log trực tiếp:

```bash
tail -f ~/open5gs/install/var/log/open5gs/amf.log
```

## 4. Thêm thuê bao

WebUI cần Node.js 20:

```bash
sudo apt install -y ca-certificates curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update && sudo apt install -y nodejs

cd ~/open5gs/webui && npm ci
npm run dev        # để cửa sổ này chạy
```

Mở `http://localhost:9999`, đăng nhập **admin / 1423**, chọn **Subscriber → +**, điền rồi **SAVE**.
Giá trị gợi ý (khớp file mẫu `open5gs-ue.yaml` của UERANSIM, dùng ở Stage 4; kiểm tra lại khi tới lúc dùng):

| Trường | Giá trị |
| --- | --- |
| IMSI | `999700000000001` |
| Subscriber Key (K) | `465B5CE8B199B49FAA5F0A2EE238A6BC` |
| OPc | `E8ED289DEBA952E4283B54E88E6183CA` |

Thuê bao thêm qua WebUI có hiệu lực ngay. Nếu *sửa* thuê bao đã có, phải khởi động lại AMF.

## 5. Đọc mã nguồn: đi theo một UE vào mạng

Mã nguồn chia theo NF: `src/amf`, `src/smf`, `src/upf`, `src/nrf`… Phần dùng chung nằm ở `lib/`
(`lib/sbi` cho HTTP/2, `lib/pfcp` cho N4, `lib/nas`, `lib/ngap`). Trong mỗi NF, tên file theo quy ước:

| Đuôi tên file | Nội dung |
| --- | --- |
| `*-sm.c` | Máy trạng thái (state machine): NF đang ở trạng thái nào, nhận sự kiện gì thì chuyển đi đâu |
| `*-handler.c` | Xử lý một bản tin nhận được |
| `*-build.c` | Dựng một bản tin để gửi đi |
| `n<nf>-*.c`, ví dụ `nausf-build.c` | Gọi service của NF khác qua SBI (ở đây là AUSF) |

Mở mã nguồn rồi đi theo các hàm dưới đây (dùng `grep -n "tên_hàm" -r src lib` để nhảy tới):

**a) NF đăng ký với NRF**

| Bước | File | Hàm / chuỗi log |
| --- | --- | --- |
| NF gửi NFRegister, nhận kết quả | `lib/sbi/nf-sm.c` | log `NF registered [Heartbeat:…]` |
| NRF xử lý đăng ký | `src/nrf/nnrf-handler.c` | `nrf_nnrf_handle_nf_register()` |
| NRF theo dõi trạng thái từng NF | `src/nrf/nf-sm.c` | `nrf_nf_state_registered()` |

**b) UE đăng ký (Registration) – trong AMF**

| Bước 3GPP (TS 23.502 4.2.2.2) | File | Hàm |
| --- | --- | --- |
| gNB chuyển bản tin đầu tiên của UE (N2) | `src/amf/ngap-handler.c` | `ngap_handle_initial_ue_message()` |
| AMF đọc Registration Request (N1, NAS) | `src/amf/gmm-handler.c` | `gmm_handle_registration_request()` |
| Máy trạng thái của UE trong AMF | `src/amf/gmm-sm.c` | `gmm_state_de_registered()` → `gmm_state_authentication()` → `gmm_state_security_mode()` → `gmm_state_initial_context_setup()` → `gmm_state_registered()` |
| Nhờ AUSF xác thực (5G-AKA) | `src/amf/nausf-build.c` | `amf_nausf_auth_build_authenticate()` |
| Đăng ký với UDM, lấy hồ sơ | `src/amf/nudm-build.c` | `amf_nudm_uecm_build_registration()`, `amf_nudm_sdm_build_get()` |

**c) Mở PDU Session: control plane cài luật xuống user plane**

| Bước | File | Hàm |
| --- | --- | --- |
| AMF gọi SMF (Nsmf_PDUSession_CreateSMContext) | `src/amf/nsmf-build.c` | `amf_nsmf_pdusession_build_create_sm_context()` |
| SMF gửi N4 Session Establishment | `src/smf/pfcp-path.c`, `src/smf/n4-build.c` | `smf_5gc_pfcp_send_session_establishment_request()`, `smf_n4_build_session_establishment_request()` |
| UPF nhận và cài PDR/FAR/QER/URR | `src/upf/n4-handler.c` | `upf_n4_handle_session_establishment_request()` |
| UPF nhận gói uplink từ gNB (N3, GTP-U) | `src/upf/gtp-path.c` | `_gtpv1_u_recv_cb()` |
| UPF nhận gói downlink từ Internet qua `ogstun` | `src/upf/gtp-path.c` | `_gtpv1_tun_recv_cb()` |
| UPF so gói với PDR | `src/upf/rule-match.c` | — |

## 6. Bài tập: tự sửa mã và quan sát

Thêm một dòng log khi AMF nhận Registration Request, biên dịch lại, rồi chạy chương trình thử:

1. Mở `src/amf/gmm-handler.c`, tìm hàm `gmm_handle_registration_request()`.
2. Thêm ngay đầu thân hàm:

   ```c
   ogs_info("[BAI TAP] AMF nhan Registration Request");
   ```

3. Biên dịch và cài lại (chỉ phần thay đổi được biên dịch, rất nhanh):

   ```bash
   cd ~/open5gs && ninja -C build && ninja -C build install
   ```

4. Tắt các NF (`./stop-5gc.sh`), chạy `./build/tests/registration/registration`, và tìm dòng `[BAI TAP]` trên màn hình.

Muốn bắt gói cùng lúc: mở Wireshark trên giao diện `lo` với bộ lọc
`ngap || pfcp || gtp || http2.headers || http2.data.data`.

## 7. Dừng, dọn dẹp, xử lý sự cố

```bash
./stop-5gc.sh                     # tắt mọi NF
docker stop open5gs-mongo         # tắt MongoDB
cd ~/free5gc-compose && docker compose start   # quay lại free5GC
```

| Hiện tượng | Cách xử lý |
| --- | --- |
| `2-install-deps.sh` báo không tìm thấy gói | Bản Ubuntu mới có thể đổi tên gói: `apt search <tên>` để tìm tên mới, sửa trong script |
| `meson` báo thiếu thư viện | Đọc tên thư viện trong thông báo, cài gói `lib<tên>-dev` tương ứng |
| PCF/UDR thoát ngay, log nói không kết nối được DB | MongoDB chưa chạy: `./1-mongo-up.sh`, `docker ps` |
| Container `open5gs-mongo` thoát ngay | CPU không có AVX mà đang dùng mongo 8.0: `docker rm open5gs-mongo`, sửa script dùng `mongo:4.4` |
| UPF thoát, log nhắc `ogstun` | Chưa chạy `./4-netconf.sh` sau khi khởi động lại máy |
| Chương trình thử báo lỗi bind địa chỉ | Các NF đang chạy chiếm cổng: `./stop-5gc.sh` rồi chạy lại |
| `status.sh` chưa thấy `NF registered` | Đợi vài giây; NF chỉ đăng ký sau khi NRF đã lên. Xem `tail ~/open5gs/install/var/log/open5gs/<nf>.log` |

Tài liệu gốc: `docs/_docs/guide/01-quickstart.md` và `02-building-open5gs-from-sources.md` trong mã nguồn Open5GS.
