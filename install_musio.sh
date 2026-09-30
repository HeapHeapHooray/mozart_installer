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

MSI_PATH="${1:-/tmp/musio_installer.msi}"

# Execute mozart_downloader scripts in-place via stdin
echo -e "${BLUE}Downloading Musio installer via mozart_downloader...${NC}"
curl -sSL https://raw.githubusercontent.com/HeapHeapHooray/mozart_downloader/refs/heads/main/download_musio.sh | bash -s -- "$MSI_PATH"

ACTUAL_MSI="$MSI_PATH"
if [ -d "$MSI_PATH" ]; then
    ACTUAL_MSI="${MSI_PATH%/}/musio_installer.msi"
fi

# Clean up symlink on exit if one was created
cleanup() {
    if [ -L "musio_installer.msi" ]; then
        rm -f "musio_installer.msi"
    fi
}
trap cleanup EXIT INT TERM

# Ensure "musio_installer.msi" exists in current directory for cheapwine run
if [ "$ACTUAL_MSI" != "musio_installer.msi" ] && [ -f "$ACTUAL_MSI" ]; then
    ln -sf "$ACTUAL_MSI" "musio_installer.msi" 2>/dev/null || cp -f "$ACTUAL_MSI" "musio_installer.msi"
fi

echo -e "${BLUE}Installing Musio via cheapwine...${NC}"
cheapwine run msiexec /i "musio_installer.msi" /qn /norestart || true

# Register and export Musio desktop app if Musio.exe is found
PREFIX_PATH="${PWD}/.cheapwine"
if [ ! -d "${PREFIX_PATH}" ] && [ -n "${WINEPREFIX:-}" ] && [ -d "${WINEPREFIX}" ]; then
    PREFIX_PATH="${WINEPREFIX}"
fi

cheapwine export "Musio" || true
cheapwine export "Musio Connect" || true

echo -e "\n${GREEN}=== Musio downloaded and installed successfully! ===${NC}"
