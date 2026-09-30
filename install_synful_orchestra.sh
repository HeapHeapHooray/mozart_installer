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

ZIP_PATH="${1:-/tmp/synful_orchestra.zip}"
EXTRACT_DIR="/tmp/synful_installer"

# Execute mozart_downloader scripts in-place via stdin
echo -e "${BLUE}Downloading Synful Orchestra installer via mozart_downloader...${NC}"
curl -sSL https://raw.githubusercontent.com/HeapHeapHooray/mozart_downloader/main/download_synful_orchestra.sh | bash -s -- "$ZIP_PATH"

echo -e "${BLUE}Extracting Synful Orchestra zip archive...${NC}"
mkdir -p "$EXTRACT_DIR"
if command -v unzip &> /dev/null; then
    unzip -o "$ZIP_PATH" -d "$EXTRACT_DIR"
elif command -v 7z &> /dev/null; then
    7z x -y -o"$EXTRACT_DIR" "$ZIP_PATH"
else
    echo -e "${RED}Error: Neither unzip nor 7z was found to extract the zip archive.${NC}"
    exit 1
fi

echo -e "${BLUE}Installing Synful Orchestra via cheapwine...${NC}"
INSTALLER_EXE=$(find "$EXTRACT_DIR" -type f -iname "*synful*.exe" -print -quit 2>/dev/null || true)
if [ -z "$INSTALLER_EXE" ]; then
    INSTALLER_EXE="$EXTRACT_DIR/SynfulOrchestraSetup.exe"
fi

cheapwine run "$INSTALLER_EXE" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- || true

echo -e "\n${GREEN}=== Synful Orchestra downloaded and installed successfully! ===${NC}"
