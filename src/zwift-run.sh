#!/usr/bin/env bash
set -uo pipefail

# shellcheck source=./lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

readonly WINEPREFIX="${WINEPREFIX:-$HOME/.wine-zwift}"
readonly ZWIFT_HOME="${WINEPREFIX}/drive_c/Program Files (x86)/Zwift"
readonly WINE_USER_HOME="${WINEPREFIX}/drive_c/users/${USER}"
readonly ZWIFT_DOCS="${WINE_USER_HOME}/AppData/Local/Zwift"
readonly ZWIFT_PREFS="${ZWIFT_DOCS}/prefs.xml"

readonly ZWIFT_USERNAME="${ZWIFT_USERNAME:-}"
readonly ZWIFT_PASSWORD="${ZWIFT_PASSWORD:-}"
readonly ZWIFT_OVERRIDE_RESOLUTION="${ZWIFT_OVERRIDE_RESOLUTION:-}"
readonly ZWIFT_NO_GAMEMODE="${ZWIFT_NO_GAMEMODE:-0}"
readonly WINE_EXPERIMENTAL_WAYLAND="${WINE_EXPERIMENTAL_WAYLAND:-0}"

export WINEPREFIX
export WINEARCH=win64

if [[ ! -d "${ZWIFT_HOME}" ]]; then
    msgbox error "Zwift is not installed. Run 'zwift --install' first."
    exit 1
fi

cd "${ZWIFT_HOME}" || {
    msgbox error "Cannot access Zwift directory: ${ZWIFT_HOME}"
    exit 1
}

if [[ -n "${ZWIFT_OVERRIDE_RESOLUTION}" ]]; then
    if [[ -f "${ZWIFT_PREFS}" ]]; then
        msgbox info "Setting Zwift resolution to ${ZWIFT_OVERRIDE_RESOLUTION}"
        updated_prefs="$(awk -v resolution="${ZWIFT_OVERRIDE_RESOLUTION}" '{
            gsub(/<USER_RESOLUTION_PREF>.*<\/USER_RESOLUTION_PREF>/,
                 "<USER_RESOLUTION_PREF>" resolution "</USER_RESOLUTION_PREF>")
        } 1' "${ZWIFT_PREFS}")"
        echo "${updated_prefs}" > "${ZWIFT_PREFS}"
    else
        msgbox warning "Preferences file does not exist yet. Resolution cannot be set."
    fi
fi

if [[ "${WINE_EXPERIMENTAL_WAYLAND}" -eq 1 ]]; then
    msgbox info "Using experimental Wayland mode"
    unset DISPLAY
fi

cleanup_invoked=0
cleanup() {
    if [[ ${cleanup_invoked} -ne 1 ]]; then
        msgbox info "Cleaning up..."
        pkill ZwiftLauncher 2>/dev/null || true
        pkill ZwiftWindowsCra 2>/dev/null || true
        pkill -f MicrosoftEdgeUpdate 2>/dev/null || true
        cleanup_invoked=1
    fi
}
trap cleanup EXIT

msgbox info "Starting Zwift launcher..."

if ! wine start ZwiftLauncher.exe SilentLaunch; then
    msgbox error "Failed to start Zwift launcher"
    exit 1
fi

sleep 2
if ! launcher_pid_hex="$(winedbg --command "info proc" 2>/dev/null | grep -P "ZwiftLauncher.exe" | grep -oP "^\s*\K[0-9a-fA-F]+(?=\s)")"; then
    msgbox error "Unable to get launcher process ID. Did it crash?"
    exit 1
fi

launcher_pid="$((16#${launcher_pid_hex}))"
msgbox ok "Zwift launcher started (PID: ${launcher_pid})"

declare -a wine_cmd
wine_cmd=(wine start /exec "Z:\\usr\\bin\\runfromprocess-rs.exe" "${launcher_pid}" ZwiftApp.exe)

if [[ -n "${ZWIFT_USERNAME}" ]] && [[ -n "${ZWIFT_PASSWORD}" ]]; then
    msgbox info "Authenticating with Zwift..."
    if token="$(zwift-auth 2>/dev/null)"; then
        wine_cmd+=(--token="${token}")
        msgbox ok "Authentication successful"
    else
        msgbox warning "Authentication failed, manual login will be required"
    fi
fi

msgbox info "Starting ZwiftApp..."
if ! "${wine_cmd[@]}"; then
    msgbox error "Failed to start ZwiftApp"
    exit 1
fi

for i in $(seq 3 -1 1); do
    msgbox info "Waiting for Zwift to start... (${i})"
    sleep 1
done

if ! pgrep -f ZwiftApp.exe > /dev/null 2>&1; then
    msgbox error "ZwiftApp has not started!"
    exit 1
fi

msgbox ok "Zwift started successfully!"

cleanup

declare -a wineserver_cmd
wineserver_cmd=(wineserver -w)

if [[ "${ZWIFT_NO_GAMEMODE}" -ne 1 ]] && command -v gamemoderun &>/dev/null; then
    msgbox info "Running with GameMode enabled"
    wineserver_cmd=(gamemoderun "${wineserver_cmd[@]}")
fi

msgbox info "Waiting for Zwift to close..."
"${wineserver_cmd[@]}" || true

msgbox ok "Zwift closed, exiting"
