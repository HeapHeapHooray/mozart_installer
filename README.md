# Mozart Installer

A collection of lightweight, modular shell scripts for downloading, extracting, installing, and configuring Windows virtual instruments (VSTs), DAWs, and sample library managers for use with **Cheapwine / Wine on Linux**.

## 🎯 Purpose

While installer frameworks like [getfruity](https://github.com/HeapHeapHooray/getfruity) provide complete out-of-the-box setups with Wine prefix initialization, **Mozart Installer** provides standalone, modular scripts to install individual applications and plugins directly into an existing Wine prefix (powered by **Cheapwine**).

Each script handles:
- Fetching Windows installers on-the-fly via [Mozart Downloader](https://github.com/HeapHeapHooray/mozart_downloader).
- Unpacking archives (`.zip`, `.rar`, `.7z`) silently.
- Running Windows setups silently with optimal parameters.
- Applying necessary Wine registry patches and wrappers (such as for EDIROL Orchestral).
- Registering launchers and exporting desktop menu entries where applicable.

---

## 📦 Shell Scripts

All scripts can run with zero arguments (using default `/tmp` cache paths) or accept a custom target installer/archive path as `$1`.

### 1. FL Studio Windows Installer (`install_flstudio.sh`)
Downloads and installs **FL Studio** into the active Wine prefix silently (`/S`), automatically applies the EDIROL Orchestral compatibility patch if assets are present, registers `FL64`, and exports the Linux desktop launcher.

```bash
# Install using default temporary download path
./install_flstudio.sh

# Or install from/to a specific installer path
./install_flstudio.sh /path/to/flstudio_win64.exe
```

### 2. EDIROL Orchestral VST (`install_edirol.sh`)
Downloads the classic **EDIROL Orchestral VST** archive, extracts it, executes its silent setup, and automatically applies the registry compatibility patch and FL Studio Fruity Wrapper optimizations (`UseFixedBuffers=1`, `BridgedExternalWindow=1`).

```bash
# Install using default download path
./install_edirol.sh

# Or install from/to a specific archive path
./install_edirol.sh /path/to/edirol_orchestral.rar
```

### 3. Copycat Melody Plugin (`install_copycat.sh`)
Downloads and unzips the **Copycat** plugin installer from GitHub Releases and runs silent setup (`--silent`) under Wine.

```bash
# Install using default download path
./install_copycat.sh

# Or install from/to a specific zip path
./install_copycat.sh /path/to/copycat-windows.zip
```

### 4. Synful Orchestra (`install_synful_orchestra.sh` / `install_synful.sh`)
Downloads and extracts the latest **Synful Orchestra** Windows setup package and installs it completely silently (`/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-`).

```bash
# Install using default download path
./install_synful_orchestra.sh

# Or install from/to a specific zip path
./install_synful_orchestra.sh /path/to/synful_orchestra.zip
```

### 5. Native Access 2 & NTK Daemon (`install_native_access.sh`)
Downloads the **Native Access 2** Windows installer, extracts core payloads (`app-64.7z`), installs and configures the background **NTK Daemon**, creates a dedicated launcher batch script with daemon auto-start and window redraw workarounds, extracts the application icon, and exports the desktop menu entry.

```bash
# Install using default download path
./install_native_access.sh

# Or install from/to a specific installer path
./install_native_access.sh /path/to/native_access_setup.exe
```

### 6. Musio (`install_musio.sh`)
Downloads the **Musio** Windows installer package to `/tmp/`, installs it silently using Wine's Windows Installer service (`cheapwine run msiexec /i "musio_installer.msi" /qn /norestart`), and registers/exports the application launcher via Cheapwine if present.

```bash
# Install using default download path (/tmp/musio_installer.msi)
./install_musio.sh

# Or install from/to a specific installer path
./install_musio.sh /path/to/musio_installer.msi
```

### 7. LibreWave Rhapsody (`install_rhapsody.sh`)
Downloads the **LibreWave Rhapsody** sample player Windows installer from LibreWave / GitHub Releases, installs it silently (`cheapwine run "$INSTALLER_PATH" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-`), and registers/exports the application launcher via Cheapwine if present.

```bash
# Install using default download path (/tmp/rhapsody_installer.exe)
./install_rhapsody.sh

# Or install from/to a specific installer path
./install_rhapsody.sh /path/to/rhapsody_installer.exe
```

### 8. ACE Studio (`install_ace.sh`)
Downloads the **ACE Studio** Windows installer (`.exe`) via Mozart Downloader, installs it silently (`cheapwine run "$INSTALLER_PATH" /SILENT /SUPPRESSMSGBOXES /NORESTART /SP- /NOCANCEL`), and registers/exports the application launcher via Cheapwine if present.

```bash
# Install using default download path (/tmp/ace_installer.exe)
./install_ace.sh

# Or install from/to a specific installer path
./install_ace.sh /path/to/ace_installer.exe
```

---

## ⚡ Features

- **No Prefix Re-initialization**: Designed to run inside an existing `cheapwine` project or configured `WINEPREFIX` without re-initializing wine runners, winetricks, or prefix overrides.
- **Automated Downloads via Mozart Downloader**: Installer binaries are fetched seamlessly from upstream GitHub scripts.
- **Silent & Unattended**: All installers are pre-configured to execute silently with proper CLI flags.
- **System Integration**: Generates desktop shortcuts and icons for standalone software via `cheapwine export`.

---

## 🚀 Quick Start

1. Ensure `cheapwine` is installed in your PATH (e.g. via `uv tool install cheapwine`).
2. Navigate to your cheapwine project directory (where `.cheapwine` or `distillery.json` resides).
3. Make the scripts executable:
   ```bash
   chmod +x *.sh
   ```
4. Run any installer script:
   ```bash
   ./install_flstudio.sh
   ```
