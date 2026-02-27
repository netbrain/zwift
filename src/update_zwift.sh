#!/usr/bin/env bash
set -uo pipefail

readonly DEBUG="${DEBUG:-0}"
if [[ ${DEBUG} -eq 1 ]]; then set -x; fi

readonly CONTAINER_TOOL="${CONTAINER_TOOL:?}"

readonly WINE_USER_HOME="/home/user/.wine/drive_c/users/user"
readonly ZWIFT_HOME="/home/user/.wine/drive_c/Program Files (x86)/Zwift"
readonly ZWIFT_DOCS="${WINE_USER_HOME}/AppData/Local/Zwift"
readonly ZWIFT_DOCS_OLD="${WINE_USER_HOME}/Documents/Zwift" # TODO remove when no longer needed (301)

msgbox() {
    local type="${1:?}" # Type: info, ok, warning, error
    local msg="${2:?}"  # Message: the message to display

    case ${type} in
        info) echo -e "[${CONTAINER_TOOL}|*] ${msg}" ;;
        ok) echo -e "[${CONTAINER_TOOL}|✓] ${msg}" ;;
        warning) echo -e "[${CONTAINER_TOOL}|!] ${msg}" ;;
        error) echo -e "[${CONTAINER_TOOL}|✗] ${msg}" >&2 ;;
        *) echo -e "[${CONTAINER_TOOL}|*] ${msg}" ;;
    esac
}

get_current_version() {
    # if Zwift_ver_cur_filename.txt exists, it holds the true current version filename
    # if it does not exist, use Zwift_ver_cur.xml as fallback
    # if neither exist or contain a valid version, use 0.0.0 (Zwift not installed)

    local version_filename="Zwift_ver_cur.xml"
    if [[ -f Zwift_ver_cur_filename.txt ]]; then
        version_filename="$(tr '\0' '\n' < Zwift_ver_cur_filename.txt)"
    fi

    grep -oP 'sversion="\K.*?(?=\s)' "${version_filename}" 2> /dev/null | cut -f 1 -d ' ' || echo "0.0.0"
}

get_latest_version() {
    wget --no-cache --quiet -O - http://cdn.zwift.com/gameassets/Zwift_Updates_Root/Zwift_ver_cur.xml \
        | grep -oP 'sversion="\K.*?(?=")' | cut -f 1 -d ' ' \
        || return 1
}

update_zwift_using_launcher() {
    local zwift_latest_version
    if ! zwift_latest_version="$(get_latest_version)"; then
        msgbox error "Unable to retrieve latest Zwift version number"
        return 1
    fi

    local zwift_current_version
    zwift_current_version="$(get_current_version)"
    if [[ ${zwift_current_version} == "${zwift_latest_version}" ]]; then
        msgbox ok "Nothing to do, already at latest version ${zwift_latest_version}"
        return 0
    else
        msgbox info "Updating Zwift from version ${zwift_current_version} to ${zwift_latest_version}"
    fi

    msgbox info "Starting Zwift launcher using wine"
    if ! wine start ZwiftLauncher.exe SilentLaunch; then
        msgbox error "Failed to start Zwift launcher using wine!"
        return 1
    fi
    msgbox ok "Zwift launcher started using wine"

    counter=1
    # also stop if launcher exits before update finishes, so we don't hang forever
    while [[ ${zwift_current_version} != "${zwift_latest_version}" ]] && pgrep -f ZwiftLauncher.exe > /dev/null 2>&1; do
        msgbox info "Updating Zwift... (${counter})"
        sleep 5
        zwift_current_version="$(get_current_version)"
        ((counter++))
    done

    # if launcher exited unexpectedly, Zwift is still at the old version
    if [[ ${zwift_current_version} != "${zwift_latest_version}" ]]; then
        msgbox error "Launcher exited unexpectedly, update did not complete"
        return 1
    fi

    # give launcher a bit of time to complete everything
    msgbox info "Waiting 5 seconds to allow update to complete..."
    sleep 5

    msgbox ok "Zwift updated to version ${zwift_latest_version}"
}

install_zwift() {
    # prevent wine from trying to install a different mono version
    msgbox info "Starting wine with custom mono version"
    WINEDLLOVERRIDES="mscoree,mshtml=" wineboot -u || return 1

    # install prerequisites using winetricks
    # dotnet20: to prevent error dialog with CloseLauncher.exe
    # dotnet48: required by Zwift
    # d3dcompiler_47: required for Vulkan shaders
    msgbox info "Installing prerequisites using winetricks"
    winetricks -q dotnet20 dotnet48 d3dcompiler_47 || return 1

    # download and install webview 2
    msgbox info "Downloading and installing webview2"
    wget -O webview2-setup.exe https://go.microsoft.com/fwlink/p/?LinkId=2124703 || return 1
    wine webview2-setup.exe /silent /install || return 1

    # enable Wayland support, requires DISPLAY to be blank to use Wayland
    msgbox info "Enabling Wayland support"
    wine reg.exe add HKCU\\Software\\Wine\\Drivers /v Graphics /d x11,wayland || return 1

    # download and install zwift
    msgbox info "Downloading and installing Zwift"
    wget https://cdn.zwift.com/app/ZwiftSetup.exe || return 1
    wine ZwiftSetup.exe /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL || return 1
}

###########################
##### Configure Zwift #####

if ! mkdir -p "${ZWIFT_HOME}" || ! cd "${ZWIFT_HOME}"; then
    msgbox error "Zwift home directory '${ZWIFT_HOME}' does not exist or is not accessible!"
    exit 1
fi

#########################################
##### Automatically cleanup on exit #####

cleanup() {
    msgbox info "Stopping wine server"
    wineserver -k || true # important, Zwift launcher won't stop until wine server is killed

    msgbox info "Removing installation artifacts"
    # remove downloads and cache
    rm "${ZWIFT_HOME}/ZwiftSetup.exe" || true
    rm "${ZWIFT_HOME}/webview2-setup.exe" || true
    rm -rf "${WINE_USER_HOME}/Downloads/Zwift" || true
    rm -rf "/home/user/.cache/wine*" || true
    # remove Zwift documents because it causes permission errors with podman
    rm -rf "${ZWIFT_DOCS}" || true
    rm -rf "${ZWIFT_DOCS_OLD}" || true # TODO remove when no longer needed  (301)
}

trap cleanup EXIT

###################################
##### Install or update Zwift #####

if [[ ${1:-} == "--install" ]]; then
    msgbox info "Installing Zwift..."
    if ! install_zwift; then
        msgbox error "Failed to install Zwift!"
        exit 1
    fi
else
    msgbox info "Updating Zwift..."
fi

if ! update_zwift_using_launcher; then
    msgbox error "Failed to update Zwift!"
    exit 1
fi
