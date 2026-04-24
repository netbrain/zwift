#!/usr/bin/env bash
set -uo pipefail

# shellcheck source=./lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

readonly WINEPREFIX="${WINEPREFIX:-$HOME/.wine-zwift}"
readonly ZWIFT_HOME="${WINEPREFIX}/drive_c/Program Files (x86)/Zwift"

msgbox info "Installing Zwift to ${WINEPREFIX}"

export WINEARCH=win64
export WINEPREFIX
export WINEDEBUG="${WINEDEBUG:--all}"

# Find the actual wine binary (not the wrapper script) for winetricks detection.
# NixOS wraps wine in a shell script, but winetricks needs the ELF binary for arch detection.
wine_wrapper="$(command -v wine)"
if [[ -f "${wine_wrapper}" ]] && head -1 "${wine_wrapper}" | grep -q "^#!"; then
    wine_bindir="$(dirname "${wine_wrapper}")"
    if [[ -f "${wine_bindir}/.wine" ]]; then
        export WINELOADER="${wine_bindir}/.wine"
    fi
fi

# Clean up any existing broken prefix
if [[ -d "${WINEPREFIX}" ]] && [[ ! -f "${WINEPREFIX}/system.reg" ]]; then
    msgbox warning "Removing incomplete Wine prefix..."
    rm -rf "${WINEPREFIX}"
fi

# Initialize Wine prefix
msgbox info "Initializing Wine prefix..."

# Prevent Wine from trying to install mono/gecko (we'll use winetricks for .NET).
# Use inline form (not export) so this only applies to wineboot, not later commands.
# ZwiftLauncher.exe is an IL-only .NET binary that needs mscoree.dll — exporting this
# override would prevent it from loading.
WINEDLLOVERRIDES="mscoree,mshtml=" wineboot -u || {
    msgbox error "Failed to initialize Wine prefix"
    exit 1
}

msgbox info "Waiting for Wine to settle..."
wineserver -w
sleep 2

msgbox info "Verifying Wine installation..."
if ! wine cmd.exe /c "echo Wine is working" > /dev/null 2>&1; then
    msgbox error "Wine is not responding correctly"
    exit 1
fi
wineserver -w
msgbox ok "Wine prefix initialized"

# Install prerequisites using winetricks.
# dotnet48: required by Zwift
# d3dcompiler_47: required for Vulkan shaders
# Note: dotnet20 skipped - it's only to prevent a dialog with CloseLauncher.exe
# and causes issues with winetricks on NixOS
msgbox info "Installing prerequisites using winetricks..."
export W_OPT_UNATTENDED=1
export W_ARCH=win64

winetricks -q dotnet48 d3dcompiler_47 || {
    msgbox error "Failed to install .NET prerequisites"
    exit 1
}
wineserver -w
msgbox ok "Prerequisites installed"

# Download and install WebView2.
# Note: WebView2 spawns MicrosoftEdgeUpdate background processes that keep wineserver alive.
# We use timeout and kill those processes to prevent hanging.
msgbox info "Downloading and installing WebView2..."
webview_installer="$(mktemp --suffix=.exe)"

wget -O "${webview_installer}" https://go.microsoft.com/fwlink/p/?LinkId=2124703 || {
    msgbox error "Failed to download WebView2 installer"
    rm -f "${webview_installer}"
    exit 1
}

timeout 120 wine "${webview_installer}" /silent /install || {
    msgbox warning "WebView2 installation timed out or returned non-zero, continuing anyway..."
}

pkill -f MicrosoftEdgeUpdate 2>/dev/null || true
pkill -f EdgeUpdate 2>/dev/null || true
sleep 2
wineserver -k 2>/dev/null || true
sleep 1

rm -f "${webview_installer}"
msgbox ok "WebView2 installed"

# Enable Wayland support in Wine registry
msgbox info "Enabling Wayland support in Wine..."
wine reg.exe add 'HKCU\Software\Wine\Drivers' /v Graphics /d x11,wayland /f || {
    msgbox warning "Failed to set Wayland registry entry"
}
wineserver -w

# Download and install Zwift
msgbox info "Downloading Zwift installer..."
zwift_installer="$(mktemp --suffix=.exe)"

wget -O "${zwift_installer}" https://cdn.zwift.com/app/ZwiftSetup.exe || {
    msgbox error "Failed to download Zwift installer"
    rm -f "${zwift_installer}"
    exit 1
}

msgbox info "Installing Zwift..."
wine "${zwift_installer}" /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL || {
    msgbox error "Zwift installation failed"
    rm -f "${zwift_installer}"
    exit 1
}
wineserver -w

rm -f "${zwift_installer}"
msgbox ok "Zwift launcher installed"

# Run the launcher to download the actual game files
msgbox info "Downloading Zwift game files (this may take a while)..."

cd "${ZWIFT_HOME}" || {
    msgbox error "Cannot access Zwift directory"
    exit 1
}

zwift_latest_version="$(wget --no-cache --quiet -O - http://cdn.zwift.com/gameassets/Zwift_Updates_Root/Zwift_ver_cur.xml \
    | grep -oP 'sversion="\K.*?(?=")' | cut -f 1 -d ' ')" || {
    msgbox error "Failed to get latest Zwift version"
    exit 1
}
msgbox info "Latest Zwift version: ${zwift_latest_version}"

get_current_version() {
    local version_filename="Zwift_ver_cur.xml"
    if [[ -f "${ZWIFT_HOME}/Zwift_ver_cur_filename.txt" ]]; then
        version_filename="$(tr '\0' '\n' < "${ZWIFT_HOME}/Zwift_ver_cur_filename.txt")"
    fi
    grep -oP 'sversion="\K.*?(?=\s)' "${ZWIFT_HOME}/${version_filename}" 2>/dev/null | cut -f 1 -d ' ' || echo "0.0.0"
}

msgbox info "Starting ZwiftLauncher.exe from $(pwd)..."
launcher_log="$(mktemp --suffix=.zwift-launcher.log)"
WINEDEBUG="+err" wine ZwiftLauncher.exe SilentLaunch > "${launcher_log}" 2>&1 &
sleep 5

if ! pgrep -f ZwiftLauncher.exe > /dev/null 2>&1; then
    msgbox warning "Launcher process not detected after 5 seconds"
    if [[ -s "${launcher_log}" ]]; then
        msgbox info "Wine error output (last 30 lines):"
        tail -30 "${launcher_log}" >&2
    fi
    rm -f "${launcher_log}"
    msgbox error "ZwiftLauncher.exe failed to start - check wine errors above"
    exit 1
fi

counter=1
zwift_current_version="$(get_current_version)"
while [[ "${zwift_current_version}" != "${zwift_latest_version}" ]] && pgrep -f ZwiftLauncher.exe > /dev/null 2>&1; do
    msgbox info "Downloading Zwift... (${counter}) - current: ${zwift_current_version}, target: ${zwift_latest_version}"
    sleep 5
    zwift_current_version="$(get_current_version)"
    ((counter++))
done
rm -f "${launcher_log}"

if [[ "${zwift_current_version}" != "${zwift_latest_version}" ]]; then
    msgbox error "Launcher exited before download completed"
    exit 1
fi

msgbox ok "Zwift ${zwift_latest_version} downloaded successfully!"

sleep 5
pkill -f ZwiftLauncher.exe 2>/dev/null || true
wineserver -k 2>/dev/null || true
sleep 2

msgbox info "Cleaning up installation artifacts..."
rm -f "${ZWIFT_HOME}/ZwiftSetup.exe" 2>/dev/null || true
rm -f "${ZWIFT_HOME}/webview2-setup.exe" 2>/dev/null || true

msgbox ok "Installation complete!"
msgbox info "You can now run Zwift with: zwift"
