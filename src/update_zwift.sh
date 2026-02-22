#!/usr/bin/env bash
set -euo pipefail

readonly DEBUG="${DEBUG:-0}"
if [[ ${DEBUG} -eq 1 ]]; then set -x; fi

readonly WINE_USER_HOME="/home/user/.wine/drive_c/users/user"
readonly ZWIFT_HOME="/home/user/.wine/drive_c/Program Files (x86)/Zwift"
readonly ZWIFT_DOCS="${WINE_USER_HOME}/AppData/Local/Zwift"
readonly ZWIFT_DOCS_OLD="${WINE_USER_HOME}/Documents/Zwift" # TODO remove when no longer needed (301)

mkdir -p "${ZWIFT_HOME}"
cd "${ZWIFT_HOME}"

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
    cd "${ZWIFT_HOME}"
    get_current_version
    get_latest_version

    # Disable ERR Trap so return works.
    set +e
    vercomp "${zwift_current_version}" "${zwift_latest_version}"
    result=$?
    set -e
    if [[ ${result} -ne 2 ]]; then
        echo "already at latest version..."
        exit 0
    fi

    wine ZwiftLauncher.exe SilentLaunch &
    until [[ ${result} -ne 2 ]]; do
        echo "updating in progress..."
        sleep 5
        get_current_version

        set +e
        vercomp "${zwift_current_version}" "${zwift_latest_version}"
        result=$?
        set -e
    done

    echo "updating done, waiting 5 seconds..."
    sleep 5

    # Remove as causes PODMAN Save Permisison issues.
    rm -rf "${ZWIFT_DOCS_OLD}" # TODO is this needed? remove when no longer needed  (301)
    rm -rf "${ZWIFT_DOCS}"     # TODO is this needed?
}

if [[ -z "$(ls -A .)" ]]; then # is directory empty?
    # Prevent Wine from trying to install a different mono version
    WINEDLLOVERRIDES="mscoree,mshtml=" wineboot -u

    # install dotnet 20 (to prevent error dialog with CloseLauncher.exe)
    winetricks -q dotnet20

    # install dotnet48 for zwift
    winetricks -q dotnet48

    # Install D3D Compiler to allow Vulkan Shaders.
    winetricks d3dcompiler_47

    # install webview 2
    wget -O webview2-setup.exe https://go.microsoft.com/fwlink/p/?LinkId=2124703
    wine webview2-setup.exe /silent /install

    # Enable Wayland Support, still requires DISPLAY to be blank to use Wayland.
    wine reg.exe add HKCU\\Software\\Wine\\Drivers /v Graphics /d x11,wayland

    # install zwift
    wget https://cdn.zwift.com/app/ZwiftSetup.exe
    wine ZwiftSetup.exe /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL

    # Sleep 5 seconds fully start the update or just stops.
    sleep 5

    wine ZwiftLauncher.exe SilentLaunch

    # update game through zwift launcher
    wait_for_zwift_game_update
    wineserver -k

    # cleanup
    rm "${ZWIFT_HOME}/ZwiftSetup.exe"
    rm "${ZWIFT_HOME}/webview2-setup.exe"
    rm -rf "${WINE_USER_HOME}/Downloads/Zwift"
    rm -rf "/home/user/.cache/wine*"
    exit 0
fi

if [[ ${1} == "update" ]]; then
    wait_for_zwift_game_update

    wineserver -k
    exit 0
fi
