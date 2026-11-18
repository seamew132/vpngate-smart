# Tu dong chay voi quyen Administrator (an cua so console)
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -WindowStyle Hidden
    exit
}

Set-Location -Path $PSScriptRoot

function Show-StartupOverlay($title, $msg) {
    $osdExe = Join-Path $PSScriptRoot "vpngate-osd.exe"
    if (-not (Test-Path $osdExe)) {
        $osdExe = Join-Path $PSScriptRoot "deps\vpngate-osd.exe"
    }
    if (Test-Path $osdExe) {
        Start-Process -FilePath $osdExe -ArgumentList @("waitpid", "loading", $title, $msg, "$PID") -WindowStyle Hidden
    }
}

Show-StartupOverlay "⏳ Đang Khởi Động VPN Gate Smart..." "Đang kiểm tra môi trường mạng ảo & nạp thư viện ngầm..."

# 1. Chuan bi thu muc deps va chep san file tu thu muc local .\deps (neu co)
$depsDir = Join-Path $env:LOCALAPPDATA "vpngate-smart\deps"
if (-not (Test-Path $depsDir)) {
    New-Item -ItemType Directory -Path $depsDir -Force | Out-Null
}

$localDeps = Join-Path $PSScriptRoot "deps"
if (Test-Path $localDeps) {
    Copy-Item "$localDeps\*" -Destination $depsDir -Force -ErrorAction SilentlyContinue
}

# 2. Kiem tra Card mang ao TAP-Windows & Wintun
$tapAdapter = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceDescription -match 'TAP-Windows' }
if (-not $tapAdapter) {
    Show-StartupOverlay "⏳ Đang Cài Đặt Card Mạng Ảo..." "Phát hiện máy mới: Đang tự động cài driver TAP-Windows / Wintun (khoảng 5 giây)..."

    $msiPath = Join-Path $PSScriptRoot "openvpn.msi"
    if (-not (Test-Path $msiPath)) {
        $msiPath = Join-Path $env:TEMP "openvpn.msi"
    }
    if (-not (Test-Path $msiPath)) {
        $msiUrl = "https://swupdate.openvpn.org/community/releases/OpenVPN-2.6.12-I001-amd64.msi"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing
    }

    Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait -WindowStyle Hidden

    # Kiem tra lai sau khi cai MSI, neu van chua co card TAP thi dung tapctl tao truc tiep
    $tapAdapter = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceDescription -match 'TAP-Windows' }
    $tapctlPath = "C:\Program Files\OpenVPN\bin\tapctl.exe"
    if (-not (Test-Path $tapctlPath)) {
        $tapctlPath = Join-Path $depsDir "tapctl.exe"
    }
    if ((-not $tapAdapter) -and (Test-Path $tapctlPath)) {
        Start-Process -FilePath $tapctlPath -ArgumentList 'create --hwid root\tap0901 --name "OpenVPN TAP-Windows6"' -Wait -WindowStyle Hidden
    }
}

# 3. Dam bao cac card mang ao khong bi Disabled
Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
    $_.InterfaceDescription -match 'TAP-Windows|Wintun|OpenVPN' -and $_.Status -eq 'Disabled'
} | Enable-NetAdapter -Confirm:$false -ErrorAction SilentlyContinue

# 4. Dong bo day du DLL va openvpn.exe tu Program Files (neu co) sang deps
if (Test-Path "C:\Program Files\OpenVPN\bin") {
    Copy-Item "C:\Program Files\OpenVPN\bin\*.dll" -Destination $depsDir -Force -ErrorAction SilentlyContinue
    Copy-Item "C:\Program Files\OpenVPN\bin\openvpn.exe" -Destination $depsDir -Force -ErrorAction SilentlyContinue
}

# 5. Khoi dong ung dung
if (Test-Path ".\VPN-Gate-Smart.exe") {
    Start-Process ".\VPN-Gate-Smart.exe"
} elseif (Test-Path ".\vpngate-smart.exe") {
    Start-Process ".\vpngate-smart.exe"
}
Start-Sleep -Milliseconds 700
