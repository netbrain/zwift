#!/usr/bin/env bash
set -uo pipefail

readonly DEBUG="${DEBUG:-0}"
if [[ ${DEBUG} -eq 1 ]]; then set -x; fi

readonly COLORED_OUTPUT="${COLORED_OUTPUT:-0}"
if [[ -t 1 ]] || [[ ${COLORED_OUTPUT} -eq 1 ]]; then
    readonly COLOR_WHITE="\033[0;37m"
    readonly COLOR_RED="\033[0;31m"
    readonly COLOR_GREEN="\033[0;32m"
    readonly COLOR_BLUE="\033[0;34m"
    readonly COLOR_YELLOW="\033[0;33m"
    readonly RESET_STYLE="\033[0m"
else
    readonly COLOR_WHITE=""
    readonly COLOR_RED=""
    readonly COLOR_GREEN=""
    readonly COLOR_BLUE=""
    readonly COLOR_YELLOW=""
    readonly RESET_STYLE=""
fi

readonly VERBOSITY="${VERBOSITY:-1}"
readonly CONTAINER_TOOL="nix-fhs"
readonly ZWIFT_USERNAME="${ZWIFT_USERNAME:-}"
readonly ZWIFT_PASSWORD="${ZWIFT_PASSWORD:-}"
readonly ZWIFT_OVERRIDE_RESOLUTION="${ZWIFT_OVERRIDE_RESOLUTION:-}"
readonly ZWIFT_NO_GAMEMODE="${ZWIFT_NO_GAMEMODE:-0}"
readonly WINEPREFIX="${WINEPREFIX:-${HOME}/.wine-zwift}"
readonly ZWIFT_HOME="${WINEPREFIX}/drive_c/Program Files (x86)/Zwift"

msgbox() {
    local type="${1:?}" # Type: info, ok, warning, error, debug
    local msg="${2:?}"  # Message: the message to display

    local timestamp=""
    [[ ${VERBOSITY} -ge 2 ]] && printf -v timestamp '%(%T)T|' -1

    case ${type} in
        info) [[ ${VERBOSITY} -ge 1 ]] && echo -e "${COLOR_BLUE}[${CONTAINER_TOOL}|${timestamp}*] ${msg}${RESET_STYLE}" ;;
        ok) echo -e "${COLOR_GREEN}[${CONTAINER_TOOL}|${timestamp}✓] ${msg}${RESET_STYLE}" ;;
        warning) echo -e "${COLOR_YELLOW}[${CONTAINER_TOOL}|${timestamp}!] ${msg}${RESET_STYLE}" ;;
        error) echo -e "${COLOR_RED}[${CONTAINER_TOOL}|${timestamp}✗] ${msg}${RESET_STYLE}" >&2 ;;
        debug) [[ ${VERBOSITY} -ge 3 ]] && echo -e "${COLOR_WHITE}[${CONTAINER_TOOL}|${timestamp}◉] ${msg}${RESET_STYLE}" ;;
        *) echo "msgbox - unknown type ${type}" >&2 && exit 1 ;;
    esac
}

if ! TMPDIR=$(mktemp -d); then
    msgbox error "Could not create temp dir"
    exit 1
fi
readonly TMPDIR

wine_task_info() {
    local task_name="${1:?}"
    wine tasklist /fo list /fi "IMAGENAME eq ${task_name}"
}

is_wine_task_running() {
    local task_name="${1:?}"
    [[ -n $(wine_task_info "${task_name}" || true) ]]
}

wait_until() {
    local condition="${1:?}"
    local timeout="${2:-20}"
    local delay="${3:-0.1}"
    local counter=1

    while ! eval "${condition}" && [[ ${counter} -le ${timeout} ]]; do
        msgbox debug "Waiting... (${counter}/${timeout})"
        sleep "${delay}"
        ((counter++))
    done

    eval "${condition}"
}

wait_until_wine_task_started() {
    local task_name="${1:?}"
    msgbox info "Waiting for ${task_name} to start..."
    wait_until "is_wine_task_running ${task_name}"
}

install_zwift() {
    # prevent wine from installing mono and gecko
    msgbox info "Initializing wine"
    WINEDLLOVERRIDES="mscoree,mshtml=" wineboot -u || return 1

    msgbox info "Installing prerequisites using winetricks"
    winetricks -q corefonts dotnet48 d3dcompiler_47 || return 1

    msgbox info "Downloading and installing webview2"
    wget -O "${TMPDIR}/webview2-setup.exe" https://go.microsoft.com/fwlink/p/?LinkId=2124703 || return 1
    wine "${TMPDIR}/webview2-setup.exe" /silent /install || return 1

    msgbox info "Enabling Wayland support"
    wine reg.exe add HKCU\\Software\\Wine\\Drivers /v Graphics /d x11,wayland || return 1

    msgbox info "Downloading and installing Zwift"
    wget -O "${TMPDIR}/ZwiftSetup.exe" https://cdn.zwift.com/app/ZwiftSetup.exe || return 1
    wine "${TMPDIR}/ZwiftSetup.exe" /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL || return 1
}

##########################################
##### Automatically stop wine server #####

cleanup() {
    msgbox info "Stopping wine server"
    wineserver -k || true

    msgbox info "Removing temp dir"
    rm -rf "${TMPDIR}" || true
}

trap cleanup EXIT

if [[ ! -d ${ZWIFT_HOME} ]]; then
    msgbox info "Zwift is not installed. Running installation first..."
    if ! install_zwift; then
        msgbox error "Failed to install Zwift!"
        exit 1
    fi
fi

if ! cd "${ZWIFT_HOME}"; then
    msgbox error "Could not go into ${ZWIFT_HOME}. Zwift installation seems to have failed."
    exit 1
fi

msgbox info "Starting Zwift launcher using wine"

if ! wine start ZwiftLauncher.exe || ! wait_until_wine_task_started ZwiftLauncher.exe; then
    msgbox error "Failed to start Zwift launcher using wine!"
    exit 1
fi

msgbox ok "Zwift launcher started using wine"

counter=1
while is_wine_task_running ZwiftLauncher.exe; do
    msgbox debug "Waiting for Zwift Launcher to exit... ($((counter++)))"
    sleep 5
done
