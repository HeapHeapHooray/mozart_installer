#!/usr/bin/env bash
set -e

# Colors for terminal output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure user binary paths are in PATH
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Check for cheapwine
if ! command -v cheapwine &> /dev/null; then
    echo -e "${RED}Error: cheapwine is not installed or not in PATH.${NC}"
    echo -e "Please ensure cheapwine is installed before running this script."
    exit 1
fi

# Check for 7z (required for extraction)
if ! command -v 7z &> /dev/null; then
    echo -e "${RED}Error: 7z (7-zip) is required to extract Native Access files.${NC}"
    exit 1
fi

PREFIX_PATH="${PWD}/.cheapwine"
if [ ! -d "${PREFIX_PATH}" ] && [ -n "${WINEPREFIX:-}" ] && [ -d "${WINEPREFIX}" ]; then
    PREFIX_PATH="${WINEPREFIX}"
fi

SETUP_PATH="${1:-/tmp/native_access_setup.exe}"
EXTRACT_DIR="/tmp/native_access_extracted"

# Execute mozart_downloader scripts in-place via stdin
echo -e "${BLUE}Downloading Native Access installer via mozart_downloader...${NC}"
curl -sSL https://raw.githubusercontent.com/HeapHeapHooray/mozart_downloader/main/download_native_access.sh | bash -s -- "$SETUP_PATH"

echo -e "${BLUE}Extracting Native Access installer...${NC}"
mkdir -p "$EXTRACT_DIR"
7z x -y -o"$EXTRACT_DIR" "$SETUP_PATH"
PLUGINS_DIR=$(find "$EXTRACT_DIR/" -type d -name "\$PLUGINSDIR" -print -quit 2>/dev/null || echo "$EXTRACT_DIR/\$PLUGINSDIR")
if [ -f "${PLUGINS_DIR}/app-64.7z" ]; then
    (cd "${PLUGINS_DIR}" && 7z x -y app-64.7z)
fi

# Windows has C:\Users\Public\Downloads but Wine prefixes don't create it.
# The NTK Daemon expects it as its default download location (otherwise it
# logs "Required part of default location does not exist" on startup).
mkdir -p "${PREFIX_PATH}/drive_c/users/Public/Downloads"

NA_INSTALL_DIR="${PREFIX_PATH}/drive_c/Program Files/Native Instruments/Native Access"
mkdir -p "${NA_INSTALL_DIR}"
if [ -d "${PLUGINS_DIR}" ]; then
    cp -r "${PLUGINS_DIR}"/* "${NA_INSTALL_DIR}/" 2>/dev/null || true
fi

NTK_EXE=$(find "${NA_INSTALL_DIR}/resources/daemon" -type f -name "*.exe" ! -path "*/__MACOSX/*" ! -name "._*" -print -quit 2>/dev/null || true)
if [ -n "${NTK_EXE}" ] && [ -f "${NTK_EXE}" ]; then
    echo -e "${BLUE}Installing NTK Daemon...${NC}"
    # Kill stale daemons from previous sessions first, otherwise the freshly
    # started daemon dies with "Address in use" (ports 5146/5563/7865 squatted)
    pkill -f NTKDaemon.exe 2>/dev/null || true
    # The silent installer can die instantly on a freshly-created prefix
    # (wineserver still initializing), leaving nothing behind. Verify via
    # install.json and retry a few times instead of trusting the exit code.
    NTK_INSTALL_JSON="${PREFIX_PATH}/drive_c/users/Public/Documents/Native Instruments/NTK/install.json"
    ntk_attempt=0
    while [ ! -f "${NTK_INSTALL_JSON}" ] && [ "${ntk_attempt}" -lt 3 ]; do
        ntk_attempt=$((ntk_attempt+1))
        cheapwine run "${NTK_EXE}" /S SILENT=TRUE || true
        sleep 3
    done
    # Native Access refuses to start without this file (falls into the broken
    # elevated-reinstall path -> "Please grant permission..." dialog)
    if [ -f "${NTK_INSTALL_JSON}" ]; then
        echo -e "${GREEN}NTK Daemon installed (install.json present, attempt ${ntk_attempt}).${NC}"
    else
        echo -e "${RED}⚠️ Error: NTK Daemon install failed after ${ntk_attempt} attempts (install.json missing). Native Access will not start.${NC}"
    fi
fi

# Write Native Access launcher batch script
# Native Access cannot start NTKDaemonService itself under Wine (its elevation
# goes through a PowerShell stub), and it STOPS the service whenever it cannot
# reach it. So the launcher must guarantee the daemon is RUNNING before the app
# starts. The retry loop covers cold wineserver boots, where the first service
# start can die on a control handshake timeout (sc query exit code 1077).
NATIVE_ACCESS_BAT="${PREFIX_PATH}/drive_c/launch_native_access.bat"
echo -e "\n${BLUE}Generating Native Access launcher script (NTK Daemon service)...${NC}"
cat << 'EOF' > "${NATIVE_ACCESS_BAT}"
@echo off
rem Start NTKDaemonService and wait until it is actually RUNNING.
rem The first start on a cold wineserver boot can fail (service control
rem handshake timeout while services.exe is still initializing), so retry.
setlocal
set /a tries=0
:retry
net start NTKDaemonService >nul 2>&1
set /a waits=0
:waitrun
sc query NTKDaemonService | find "RUNNING" >nul && goto running
ping -n 3 127.0.0.1 >nul
set /a waits+=1
if %waits% lss 25 goto waitrun
set /a tries+=1
if %tries% lss 4 goto retry
:running
rem give the daemon a few seconds to bind its IPC ports
ping -n 4 127.0.0.1 >nul
start "" "C:\Program Files\Native Instruments\Native Access\Native Access.exe" %*
rem Resize Native Access window up by 10% when it opens, forcing a redraw so the interface shows up, known Wine bug.
start /b powershell -NoProfile -ExecutionPolicy Bypass -Command "$code = 'using System; using System.Runtime.InteropServices; public class Win32 { [DllImport(\"user32.dll\")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect); [DllImport(\"user32.dll\")] public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint); } [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }'; Add-Type -TypeDefinition $code; $hwnd = [IntPtr]::Zero; for ($i = 0; $i -lt 40; $i++) { Start-Sleep -Milliseconds 500; $procs = Get-Process -Name 'Native Access' -ErrorAction SilentlyContinue; foreach ($p in $procs) { if ($p.MainWindowHandle -ne [IntPtr]::Zero) { $hwnd = $p.MainWindowHandle; break } }; if ($hwnd -ne [IntPtr]::Zero) { break } }; if ($hwnd -ne [IntPtr]::Zero) { $rect = New-Object RECT; if ([Win32]::GetWindowRect($hwnd, [ref]$rect)) { $w = $rect.Right - $rect.Left; $h = $rect.Bottom - $rect.Top; $nw = [int]($w * 1.10); $nh = [int]($h * 1.10); [Win32]::MoveWindow($hwnd, $rect.Left, $rect.Top, $nw, $nh, $true) } }"
endlocal
EOF
# CRLF line endings are required for cmd label/goto parsing
sed -i 's/$/\r/' "${NATIVE_ACCESS_BAT}"
cp "${NATIVE_ACCESS_BAT}" "${PREFIX_PATH}/launch_native_access.bat"

echo -e "${BLUE}Registering and exporting Native Access...${NC}"
ICON_PATH="${PREFIX_PATH}/drive_c/native_access_icon.ico"
cheapwine extract_icon "C:\Program Files\Native Instruments\Native Access\Native Access.exe" "${ICON_PATH}" || true
cheapwine add "Native Access" "C:\launch_native_access.bat" --icon "${ICON_PATH}" || true
cheapwine export "Native Access" || true

echo -e "\n${GREEN}=== Native Access downloaded, installed, and exported successfully! ===${NC}"
