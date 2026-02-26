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
    if [[ -f Zwift_ver_cur_filename.txt ]]; then
        # If Zwift_ver_cur_filename.txt exists, use it
        # Remove Null to remove warning.
        version_filename="$(tr '\0' '\n' < Zwift_ver_cur_filename.txt)"
    else
        # Default to Zwift_ver_cur.xml if Zwift_ver_cur_filename.txt doesn't exist
        version_filename="Zwift_ver_cur.xml"
    fi

    if grep -q sversion "${version_filename}"; then
        zwift_current_version="$(grep -oP 'sversion="\K.*?(?=\s)' "${version_filename}" | cut -f 1 -d ' ')"
    else
        # Basic install only, needs initial update
        zwift_current_version="0.0.0"
    fi
}

get_latest_version() {
    # Don't cache so we don't pick old versions.
    zwift_latest_version="$(wget --no-cache --quiet -O - http://cdn.zwift.com/gameassets/Zwift_Updates_Root/Zwift_ver_cur.xml | grep -oP 'sversion="\K.*?(?=")' | cut -f 1 -d ' ')"
}

wait_for_zwift_game_update() {
    vercomp() {
        # Return 0 if =, 1 if > and 2 if <
        if [[ ${1} == "${2}" ]]; then
            return 0
        fi

        local IFS=.
        local i ver1 ver2
        read -ra ver1 <<< "${1}"
        read -ra ver2 <<< "${2}"
        # fill empty fields in ver1 with zeros
        for ((i = ${#ver1[@]}; i < ${#ver2[@]}; i++)); do
            ver1[i]=0
        done
        for ((i = 0; i < ${#ver1[@]}; i++)); do
            if [[ -z ${ver2[i]} ]]; then
                # fill empty fields in ver2 with zeros
                ver2[i]=0
            fi
            if ((10#${ver1[i]} > 10#${ver2[i]})); then
                return 1
            fi
            if ((10#${ver1[i]} < 10#${ver2[i]})); then
                return 2
            fi
        done
        return 0
    }

    echo "updating zwift..."
    get_current_version
    get_latest_version

    vercomp "${zwift_current_version}" "${zwift_latest_version}"
    result=$?
    if [[ ${result} -ne 2 ]]; then
        echo "already at latest version..."
        exit 0
    fi

    wine ZwiftLauncher.exe SilentLaunch &
    until [[ ${result} -ne 2 ]]; do
        echo "updating in progress..."
        sleep 5
        get_current_version

        vercomp "${zwift_current_version}" "${zwift_latest_version}"
        result=$?
    done

    echo "updating done, waiting 5 seconds..."
    sleep 5

    # Remove as causes PODMAN Save Permisison issues.
    rm -rf "${ZWIFT_DOCS_OLD}" # TODO is this needed? remove when no longer needed  (301)
    rm -rf "${ZWIFT_DOCS}"     # TODO is this needed?
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

    # Prevent Wine from trying to install a different mono version
    WINEDLLOVERRIDES="mscoree,mshtml=" wineboot -u

    winetricks -q dotnet20    # install dotnet 20 (to prevent error dialog with CloseLauncher.exe)
    winetricks -q dotnet48    # install dotnet48 for zwift
    winetricks d3dcompiler_47 # install D3D Compiler to allow Vulkan Shaders

    # install webview 2
    wget -O webview2-setup.exe https://go.microsoft.com/fwlink/p/?LinkId=2124703
    wine webview2-setup.exe /silent /install

    # enable Wayland support, still requires DISPLAY to be blank to use Wayland
    wine reg.exe add HKCU\\Software\\Wine\\Drivers /v Graphics /d x11,wayland

    # install zwift
    wget https://cdn.zwift.com/app/ZwiftSetup.exe
    wine ZwiftSetup.exe /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL

    # wait until the updater starts
    sleep 5

    wine ZwiftLauncher.exe SilentLaunch # TODO launcher started twice, remove this call?

    wait_for_zwift_game_update
}

update_zwift() {
    wait_for_zwift_game_update
}

if ! mkdir -p "${ZWIFT_HOME}" || ! cd "${ZWIFT_HOME}"; then
    msgbox error "Zwift home directory '${ZWIFT_HOME}' does not exist or is not accessible!"
    exit 1
fi

case ${1:-} in
    install) install_zwift ;;
    update) update_zwift ;;
    *) msgbox error "Invalid script argument '${1:-}', should be either 'install' or 'update'" ;;
esac

wineserver -k
