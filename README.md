# 🚀 VPN Gate Smart Router (`vpngate-smart`)

A lightweight, selective split-tunneling VPN router written in Go for **VPN Gate** relay servers on Windows. Designed to route targeted IP ranges or specific applications through a VPN tunnel without hijacking the system-wide default gateway or disrupting unrelated background traffic.

---

## 🌟 Key Features

1. **Zero Client Bloat (Self-Contained Engine)**:
   - Operates directly via `openvpn.exe` and the user-space `wintun.dll` driver—eliminating the need to install bulky VPN Gate or SoftEther desktop clients.
   - Automatically fetches and initializes required runtime binaries on first launch without manual Device Manager configuration.

2. **Granular Selective Routing (Split Tunneling)**:
   - **Per-IP / CIDR Mode**: Injects targeted host or subnet routes (`route add <Target_IP> mask <Subnet_Mask> <VPN_Gateway>`) directly into the Windows routing table, leaving all other network traffic on your native ISP interface.
   - **Per-Process Mode (via SOCKS5)**: Spawns a local SOCKS5 proxy (`127.0.0.1:1080`) bound exclusively to the active VPN interface, allowing isolated routing for specific executables.
   - **SOCKS5 Proxy-Only Mode**: Exposes a standalone local SOCKS5 endpoint for custom integration with browsers, CLI tools, or automated scripts.

3. **Fail-Safe Gateway Protection & Graceful Cleanup**:
   - Dynamically injects `route-nopull` and strips `redirect-gateway` directives from fetched `.ovpn` profiles to prevent the VPN server from overriding the system default route (`0.0.0.0/0`).
   - Intercepts termination signals (`Ctrl + C` / exit events) to automatically flush injected routes, terminate background OpenVPN processes, and restore clean network state.

4. **Interactive Terminal UI (TUI)**:
   - Real-time server discovery, filtering by country, and multi-criteria sorting (Ping, Throughput Speed, Active Sessions).
   - Live connection telemetry displaying assigned tunnel IP, gateway metrics, and session uptime.

---

## 📦 Project Architecture

```text
vpngate-smart/
├── main.go                     # Entry point, Administrator privilege check & graceful lifecycle
├── vpngate-smart.exe           # Compiled standalone Windows binary
├── go.mod / go.sum             # Go module dependencies
└── internal/
    ├── api/                    # VPN Gate CSV feed parser & Base64 .ovpn config decoder
    ├── cleanup/                # Signal handling, routing table rollback & process teardown
    ├── deps/                   # Automated dependency bootstrapper (openvpn.exe, wintun.dll, WinDivert)
    ├── process/                # Windows process enumeration via Win32 API
    ├── router/                 # Windows IP route manager & interface-bound SOCKS5 proxy server
    ├── tui/                    # Interactive Terminal User Interface components
    └── tunnel/                 # Split-tunnel .ovpn sanitizer & OpenVPN subprocess controller
```

---

## 🛠 Usage Guide

### 1. System Requirements
- **OS**: Windows 10 / 11 (64-bit)
- **Privileges**: **Administrator** rights are required to initialize the `wintun` virtual adapter and modify the Windows IP routing table.

### 2. Quick Start
Open **PowerShell** or **Command Prompt** as **Administrator**, navigate to the binary directory, and launch:

```powershell
cd <PATH_TO_VPNGATE_SMART>
.\vpngate-smart.exe
```

### 3. Interactive Workflow
1. **Dependency Bootstrap**: On initial run, the application automatically downloads and verifies `openvpn.exe`, `wintun.dll`, and `WinDivert`.
2. **Server Selection**:
   - Navigate the server list using `j` / `k` or the `Up` / `Down` arrow keys.
   - Press `/` to filter servers by country name (e.g., `Japan`, `Korea`, `US`).
   - Press `s` to cycle sorting criteria (`Speed`, `Ping`, `Country`).
   - Press `Enter` to establish a tunnel with the selected relay.
3. **Routing Mode Selection**:
   - `[1] Per-IP`: Specify a target IPv4 address or CIDR block to route through the VPN (e.g., `1.1.1.1` or `104.16.0.0/16`).
   - `[2] Per-Process`: Target a specific executable (e.g., `chrome.exe`) and point its proxy settings to `127.0.0.1:1080` (SOCKS5).
   - `[3] SOCKS5 Proxy Only`: Run the tunnel-bound SOCKS5 proxy in standalone mode.
4. **Disconnect & Rollback**:
   - Press `Enter` or `Ctrl + C` at any time to cleanly tear down the tunnel and automatically revert all routing table modifications.
