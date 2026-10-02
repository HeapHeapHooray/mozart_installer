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

INSTALLER_PATH="${1:-/tmp/flstudio_win64.exe}"

# Execute mozart_downloader scripts in-place via stdin
echo -e "${BLUE}Downloading FL Studio installer via mozart_downloader...${NC}"
curl -sSL https://raw.githubusercontent.com/HeapHeapHooray/mozart_downloader/main/download_flstudio.sh | bash -s -- "$INSTALLER_PATH"

echo -e "${BLUE}Installing FL Studio...${NC}"
cheapwine run "$INSTALLER_PATH" "/S" || true

# Apply EDIROL Orchestral Registry Patch if EDIROL assets exist
PREFIX_PATH="${PWD}/.cheapwine"
if [ ! -d "${PREFIX_PATH}" ] && [ -n "${WINEPREFIX:-}" ] && [ -d "${WINEPREFIX}" ]; then
    PREFIX_PATH="${WINEPREFIX}"
fi

PARAM_PATH=$(find "${PREFIX_PATH}/drive_c" -type f -name "param.dat" -print -quit 2>/dev/null || true)

if [ -n "${PARAM_PATH}" ]; then
    VST_DIR=$(dirname "${PARAM_PATH}")
    echo -e "\n${BLUE}Applying EDIROL Orchestral Registry Patch...${NC}"
    echo "Found EDIROL Orchestral assets in: ${VST_DIR}"

    WINE_VST_DIR_RAW="${VST_DIR#"${PREFIX_PATH}/drive_c/"}"
    WINE_VST_DIR_RAW="${WINE_VST_DIR_RAW#"${PREFIX_PATH}/drive_c"}"
    WINE_VST_DIR="C:\\\\${WINE_VST_DIR_RAW//\//\\\\}"

    echo "Wine-internal VST path: ${WINE_VST_DIR}"

    REG_FILE=$(mktemp /tmp/orchestral_fix.XXXXXX.reg)

    cat <<EOF > "${REG_FILE}"
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\\SOFTWARE\\EDIROL\\Orchestral VST]
"BaseDataFile"="${WINE_VST_DIR}\\\\param.dat"
"HelpIndex"="${WINE_VST_DIR}\\\\HELP\\\\index_e.htm"
"InstallPath"="${WINE_VST_DIR}"
"ModuleDestinations"="C:\\\\Program Files\\\\Steinberg\\\\Vstplugins\\\\EDIROL;"
"ProductID"="NO-SERIAL-HERE-IM-AFRAID"
"ProductName"="Orchestral VST Version 1.03"
"SeriesName"="High Quality Software Synthesizer"
"UserChorus"="${WINE_VST_DIR}\\\\UserChorus"
"UserOption"="${WINE_VST_DIR}\\\\UserOption"
"UserPatch"="${WINE_VST_DIR}\\\\UserPatchBank"
"UserReverb"="${WINE_VST_DIR}\\\\UserReverb"
"UserRhythm"="${WINE_VST_DIR}\\\\UserRhythmBank"
"VstAutomation"=dword:00000001

[HKEY_LOCAL_MACHINE\\SOFTWARE\\EDIROL\\Orchestral VST\\1.01]
@=""

[HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\EDIROL\\Orchestral VST]
"BaseDataFile"="${WINE_VST_DIR}\\\\param.dat"
"HelpIndex"="${WINE_VST_DIR}\\\\HELP\\\\index_e.htm"
"InstallPath"="${WINE_VST_DIR}"
"ModuleDestinations"="C:\\\\Program Files\\\\Steinberg\\\\Vstplugins\\\\EDIROL;"
"ProductID"="NO-SERIAL-HERE-IM-AFRAID"
"ProductName"="Orchestral VST Version 1.03"
"SeriesName"="High Quality Software Synthesizer"
"UserChorus"="${WINE_VST_DIR}\\\\UserChorus"
"UserOption"="${WINE_VST_DIR}\\\\UserOption"
"UserPatch"="${WINE_VST_DIR}\\\\UserPatchBank"
"UserReverb"="${WINE_VST_DIR}\\\\UserReverb"
"UserRhythm"="${WINE_VST_DIR}\\\\UserRhythmBank"
"VstAutomation"=dword:00000001

[HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\EDIROL\\Orchestral VST\\1.01]
@=""

[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion]
"ProductID"="1"

[HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion]
"ProductID"="1"

[HKEY_CURRENT_USER\\Software\\Image-Line\\Shared\\Plugins\\Fruity Wrapper\\Plugins\\EDIROL]
"BridgedExternalWindow"=dword:00000001
"UseFixedBuffers"=dword:00000001

[HKEY_CURRENT_USER\\Software\\Image-Line\\Shared\\Plugins\\Fruity Wrapper\\Plugins\\Orchestral]
"BridgedExternalWindow"=dword:00000001
"UseFixedBuffers"=dword:00000001

[HKEY_CURRENT_USER\\Software\\Image-Line\\Shared\\Plugins\\Fruity Wrapper\\Plugins\\EDIROL\\Orchestral]
"BridgedExternalWindow"=dword:00000001
"UseFixedBuffers"=dword:00000001

[HKEY_CURRENT_USER\\Software\\Image-Line\\Shared\\Plugins\\Fruity Wrapper\\Plugins\\VST\\Orchestral]
"BridgedExternalWindow"=dword:00000001
"UseFixedBuffers"=dword:00000001
EOF

    WINE_REG_FILE="Z:\\\\${REG_FILE//\//\\\\}"
    cheapwine wine reg import "${WINE_REG_FILE}"
    rm -f "${REG_FILE}"
    echo -e "${GREEN}✅ Success! EDIROL Orchestral registry patch applied.${NC}"
fi

cheapwine add "FL Studio" FL64
cheapwine export "FL Studio"

cheapwine add "FL Cloud Plugins" --uri-scheme "fl-cloud-plugins"
cheapwine export "FL Cloud Plugins"

echo -e "\n${GREEN}=== FL Studio installed and exported successfully! ===${NC}"
