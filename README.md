# 🚀 VPN Gate Smart Router (`vpngate-smart`)

Tool kết nối và định tuyến chọn lọc qua hệ thống relay server của **VPN Gate**, không thay đổi gateway toàn hệ thống và không làm ảnh hưởng tới các kết nối/process khác trên máy tính.

---

## 🌟 Tính Năng Chính

1. **Không cần cài VPN Gate / SoftEther Client**:
   - Sử dụng trực tiếp engine `openvpn.exe` + driver `wintun.dll` (tự động giải nén/tải ở lần chạy đầu tiên, không cần cài đặt driver thủ công qua Device Manager).
2. **Định tuyến chọn lọc (Selective Routing)**:
   - **Chế độ Per-IP**: Thêm route đích (`route add <Target_IP> mask 255.255.255.255 <VPN_Gateway>`) đến IP hoặc subnet chỉ định. Toàn bộ traffic còn lại vẫn đi qua mạng gốc bình thường.
   - **Chế độ Per-Process (qua SOCKS5)**: Chạy proxy SOCKS5 nội bộ (`127.0.0.1:1080`) bind thẳng vào VPN tunnel. Thiết lập ứng dụng cần dùng VPN trỏ vào proxy này mà không làm ảnh hưởng tới các ứng dụng khác.
   - **Chế độ SOCKS5 Proxy Only**: Khởi tạo proxy cục bộ để dùng linh hoạt cho trình duyệt, bot hoặc công cụ tùy ý.
3. **Cơ chế an toàn**:
   - Tự động inject `route-nopull` và gỡ bỏ các chỉ thị `redirect-gateway` trong cấu hình `.ovpn` để ngăn VPN chiếm quyền kiểm soát gateway mặc định (`0.0.0.0/0`).
   - Tự dọn dẹp routing table và tắt tiến trình tunnel ngầm khi người dùng bấm thoát hoặc ngắt kết nối (graceful shutdown).
4. **Tích hợp TUI trực quan**:
   - Tìm kiếm, sắp xếp server theo Quốc gia, Ping, Tốc độ (Speed), Số lượng session.
   - Hiển thị thông số kết nối, IP nội bộ VPN và thời gian uptime thời gian thực.

---

## 📦 Cấu Trúc Dự Án

```text
vpngate-smart/
├── main.go                     # Điểm vào chính, kiểm tra quyền Administrator & graceful cleanup
├── vpngate-smart.exe           # File thực thi chính sau khi build
├── go.mod / go.sum
└── internal/
    ├── api/                    # Tải & phân tích danh sách máy chủ VPN Gate CSV, giải mã .ovpn
    ├── cleanup/                # Quản lý huỷ tác vụ, xóa route và ngắt tiến trình an toàn
    ├── deps/                   # Tự động tải/giải nén openvpn.exe, wintun.dll, WinDivert
    ├── process/                # Quét và truy xuất danh sách tiến trình trên Windows (Win32 API)
    ├── router/                 # Quản lý route table (Windows route) và server SOCKS5 bind VPN
    ├── tui/                    # Giao diện dòng lệnh tương tác (Terminal UI)
    └── tunnel/                 # Xử lý cấu hình .ovpn (split tunnel) và quản lý tiến trình OpenVPN
```

---

## 🛠 Hướng Dẫn Sử Dụng

### 1. Yêu cầu hệ thống
- Hệ điều hành: **Windows 10 / 11 (64-bit)**
- **Quyền Administrator**: Cần thiết để nạp driver `wintun` và thực thi lệnh thêm route trong Windows.

### 2. Khởi chạy
Chạy PowerShell hoặc CMD với quyền **Administrator**:

```powershell
cd h:\b\vpngate-smart
.\vpngate-smart.exe
```

### 3. Quy trình từng bước trên màn hình
1. **Kiểm tra phụ thuộc (Dependencies)**: Lần đầu tiên chạy, tool sẽ tự động tải các file cần thiết (`openvpn.exe`, `wintun.dll`, `WinDivert`).
2. **Chọn Server**:
   - Sử dụng phím `j`/`k` hoặc mũi tên để duyệt danh sách server.
   - Nhấn `/` để tìm kiếm theo tên quốc gia (VD: `Japan`, `Korea`, `US`).
   - Nhấn `s` để đổi tiêu chí sắp xếp (theo Speed, Ping, Country).
   - Nhấn `Enter` để chọn server.
3. **Chọn Chế độ định tuyến**:
   - `[1] Per-IP`: Nhập IP máy chủ đích cần đi qua VPN (hỗ trợ cả dải CIDR, ví dụ `104.16.0.0/16` hoặc IP đơn `1.1.1.1`).
   - `[2] Per-Process`: Nhập tên file thực thi (ví dụ `chrome.exe`) và cấu hình app dùng proxy SOCKS5 `127.0.0.1:1080`.
   - `[3] SOCKS5 Proxy Only`: Mở proxy trên máy để cấu hình thủ công.
4. **Ngắt kết nối**:
   - Bấm `Enter` hoặc tổ hợp phím `Ctrl + C` bất kỳ lúc nào để ngắt kết nối an toàn và tự động khôi phục mạng gốc.
