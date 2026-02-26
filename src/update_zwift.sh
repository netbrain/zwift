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
    # If Zwift_ver_cur_filename.txt exists, it holds the true current version filename
    # If it does not exist, use Zwift_ver_cur.xml as fallback

    local version_filename="Zwift_ver_cur.xml"
    if [[ -f Zwift_ver_cur_filename.txt ]]; then
        version_filename="$(tr '\0' '\n' < Zwift_ver_cur_filename.txt)"
    fi

    local current_version
    if ! current_version="$(grep -oP 'sversion="\K.*?(?=\s)' "${version_filename}" 2> /dev/null | cut -f 1 -d ' ')"; then
        current_version="0.0.0"
    fi

    echo "${current_version}"
}

get_latest_version() {
    local latest_version
    latest_version="$(wget --no-cache --quiet -O - http://cdn.zwift.com/gameassets/Zwift_Updates_Root/Zwift_ver_cur.xml | grep -oP 'sversion="\K.*?(?=")' | cut -f 1 -d ' ')" || return 1
    echo "${latest_version}"
}

wait_for_zwift_game_update() {
    vercomp() {
        # returns 0 if first == second, 1 if first > second, 2 if first < second

        local first="${1:?}"
        local second="${2:?}"

        [[ ${first} == "${second}" ]] && return 0

        local IFS=. ver1 ver2 i
        read -ra ver1 <<< "${first}"
        read -ra ver2 <<< "${second}"

        for i in $(seq "${#ver1[@]}" "${#ver2[@]}"); do
            ver1[i]=0
        done

        for i in $(seq 0 "${#ver1[@]}"); do
            [[ -z ${ver2[i]} ]] && ver2[i]=0
            [[ $((10#${ver1[i]})) -gt $((10#${ver2[i]})) ]] && return 1
            [[ $((10#${ver1[i]})) -lt $((10#${ver2[i]})) ]] && return 2
        done

        return 0
    }

    local zwift_latest_version
    if ! zwift_latest_version="$(get_latest_version)"; then
        msgbox error "Unable to retrieve latest Zwift version number"
        return 1
    fi

    local zwift_current_version
    zwift_current_version="$(get_current_version)"
    if vercomp "${zwift_current_version}" "${zwift_latest_version}"; then
        msgbox info "Nothing to do, already at latest version ${zwift_latest_version}"
        return 0
    else
        msgbox info "Updating Zwift from version ${zwift_current_version} to ${zwift_latest_version}"
    fi

    msgbox info "Starting Zwift launcher using wine"
    wine ZwiftLauncher.exe SilentLaunch &

    counter=1
    until vercomp "${zwift_current_version}" "${zwift_latest_version}"; do
        msgbox info "Updating Zwift... (${counter})"
        sleep 5
        zwift_current_version="$(get_current_version)"
        ((counter++))
    done

    msgbox info "Updating done, waiting 5 seconds"
    sleep 5

    # remove as causes podman save permission issues
    rm -rf "${ZWIFT_DOCS_OLD}" || true # TODO remove when no longer needed  (301)
    rm -rf "${ZWIFT_DOCS}" || true
}

install_zwift() {
    cleanup() {
        msgbox info "Removing installation artifacts"
        rm "${ZWIFT_HOME}/ZwiftSetup.exe" || true
        rm "${ZWIFT_HOME}/webview2-setup.exe" || true
        rm -rf "${WINE_USER_HOME}/Downloads/Zwift" || true
        rm -rf "/home/user/.cache/wine*" || true
    }
    trap cleanup EXIT

    msgbox info "Installing Zwift..."

    # prevent Wine from trying to install a different mono version
    WINEDLLOVERRIDES="mscoree,mshtml=" wineboot -u

    winetricks -q dotnet20       # install dotnet 20 (to prevent error dialog with CloseLauncher.exe)
    winetricks -q dotnet48       # install dotnet48 for zwift
    winetricks -q d3dcompiler_47 # install D3D Compiler to allow Vulkan Shaders

    # install webview 2
    wget -O webview2-setup.exe https://go.microsoft.com/fwlink/p/?LinkId=2124703
    wine webview2-setup.exe /silent /install

    # enable Wayland support, still requires DISPLAY to be blank to use Wayland
    wine reg.exe add HKCU\\Software\\Wine\\Drivers /v Graphics /d x11,wayland

    # install zwift
    wget https://cdn.zwift.com/app/ZwiftSetup.exe
    wine ZwiftSetup.exe /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL
}

if ! mkdir -p "${ZWIFT_HOME}" || ! cd "${ZWIFT_HOME}"; then
    msgbox error "Zwift home directory '${ZWIFT_HOME}' does not exist or is not accessible!"
    exit 1
fi

case ${1:-} in
    install) install_zwift ;;
    update) msgbox info "Updating Zwift..." ;;
    *) msgbox error "Invalid script argument '${1:-}', should be either 'install' or 'update'" ;;
esac

msgbox info "Waiting for Zwift to finish updating"
if ! wait_for_zwift_game_update; then
    msgbox error "Failed to update Zwift!"
    exit 1
fi

msgbox info "Launching wine server"
if ! wineserver -k; then
    msgbox error "Failed to launch wine server!"
    exit 1
fi
