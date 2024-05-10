#!/bin/bash
set -e
set -x

ZWIFT_HOME="$HOME/.wine/drive_c/Program Files (x86)/Zwift"

mkdir -p "$ZWIFT_HOME"
cd "$ZWIFT_HOME"

function get_current_version() {
    if [ -f Zwift_ver_cur_filename.txt ]; then
        # If Zwift_ver_cur_filename.txt exists, use it
        CUR_FILENAME=$(cat Zwift_ver_cur_filename.txt)
    else
        # Default to Zwift_ver_cur.xml if Zwift_ver_cur_filename.txt doesn't exist
        CUR_FILENAME="Zwift_ver_cur.xml"
    fi

    if grep -q sversion $CUR_FILENAME; then
        ZWIFT_VERSION_CURRENT=$(cat $CUR_FILENAME | grep -oP 'sversion="\K.*?(?=\s)' | cut -f 1 -d ' ')
    else
        # Basic install only, needs initial update
        ZWIFT_VERSION_CURRENT="0.0.0"
    fi
}

function get_latest_version() {
    ZWIFT_VERSION_LATEST=$(wget --quiet -O - http://cdn.zwift.com/gameassets/Zwift_Updates_Root/Zwift_ver_cur.xml | grep -oP 'sversion="\K.*?(?=")' | cut -f 1 -d ' ')
}

function wait_for_zwift_game_update() {
    echo "updating zwift..."
    cd "${ZWIFT_HOME}"
    get_current_version
    get_latest_version
    if [ "$ZWIFT_VERSION_CURRENT" = "$ZWIFT_VERSION_LATEST" ]
    then
        echo "already at latest version..."
        exit 0
    fi

    wine ZwiftLauncher.exe SilentLaunch &
    until [ "$ZWIFT_VERSION_CURRENT" = "$ZWIFT_VERSION_LATEST" ]
    do
        echo "updating in progress..."
        sleep 5
        get_current_version
    done

    echo "updating done, waiting 5 seconds..."
    sleep 5

    # Remove as causes PODMAN Save Permisison issues.
    rm -rf "$HOME/.wine/drive_c/users/user/Documents/Zwift"
}

if [ "$1" = "update" ]
then
    wait_for_zwift_game_update

    wineserver -k
    exit 0
fi

if [ ! "$(ls -A .)" ] # is directory empty?
then
    # install dotnet 20 (to prevent error dialog with CloseLauncher.exe)
    winetricks -q dotnet20

    # install dotnet48 for zwift
    winetricks -q dotnet48
        
    # install webview 2
    wget -O webview2-setup.exe https://go.microsoft.com/fwlink/p/?LinkId=2124703
    wine webview2-setup.exe /silent /install

    # install zwift
    wget https://cdn.zwift.com/app/ZwiftSetup.exe
    wine ZwiftSetup.exe /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL
    wine ZwiftLauncher.exe SilentLaunch

    # update game through zwift launcher
    wait_for_zwift_game_update
    wineserver -k
    
    # cleanup
    rm "$ZWIFT_HOME/ZwiftSetup.exe"
    rm "$ZWIFT_HOME/webview2-setup.exe"
    rm -rf "$HOME/.wine/drive_c/users/user/Downloads/Zwift"
    rm -rf "$HOME/.cache/wine*"
    exit 0
fi
