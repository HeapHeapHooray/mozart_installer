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

INSTALLER_PATH="${1:-/tmp/ace_installer.exe}"

# Execute mozart_downloader scripts in-place via stdin
echo -e "${BLUE}Downloading ACE Studio installer via mozart_downloader...${NC}"
curl -sSL https://raw.githubusercontent.com/HeapHeapHooray/mozart_downloader/refs/heads/main/download_ace.sh | bash -s -- "$INSTALLER_PATH"

ACTUAL_INSTALLER="$INSTALLER_PATH"
if [ -d "$INSTALLER_PATH" ]; then
    ACTUAL_INSTALLER=$(find "$INSTALLER_PATH" -maxdepth 1 -type f -iname "*ace*.exe" -print -quit 2>/dev/null || true)
fi

echo -e "${BLUE}Installing ACE Studio via cheapwine...${NC}"
cheapwine run "$ACTUAL_INSTALLER" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /NOCANCEL || true

# Register and export ACE Studio desktop app if found
PREFIX_PATH="${PWD}/.cheapwine"
if [ ! -d "${PREFIX_PATH}" ] && [ -n "${WINEPREFIX:-}" ] && [ -d "${WINEPREFIX}" ]; then
    PREFIX_PATH="${WINEPREFIX}"
fi

cheapwine export "ACE Studio" || true

echo -e "\n${GREEN}=== ACE Studio downloaded and installed successfully! ===${NC}"
