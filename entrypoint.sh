#!/bin/bash
set -e
set -x

ZWIFT_HOME="$HOME/.wine/drive_c/Program Files (x86)/Zwift"

mkdir -p "$ZWIFT_HOME"
cd "$ZWIFT_HOME"

function get_current_version() {
    CUR_FILENAME=$(cat Zwift_ver_cur_filename.txt)
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
    get_current_version
    get_latest_version
    if [ "$ZWIFT_VERSION_CURRENT" = "$ZWIFT_VERSION_LATEST" ]
    then
        echo "already at latest version..."
        exit 0
    fi

    wine64 start ZwiftLauncher.exe SilentLaunch
    until [ "$ZWIFT_VERSION_CURRENT" = "$ZWIFT_VERSION_LATEST" ]
    do
        echo "updating in progress..."
        sleep 5
        get_current_version
    done

    echo "updating done, waiting 5 seconds..."
    sleep 5
}

if [ "$1" = "update" ]
then
    wait_for_zwift_game_update

    wineserver -k
    exit 0
fi

if [ ! "$(ls -A .)" ] # is directory empty?
then
    #install dotnet > 4.7.2
    winetricks --unattended dotnet48 win10

    #prevents warning when starting zwift for the first time
    winetricks --unattended dotnet20 win10

    #workaround crash issue 1.21
    winetricks --unattended d3dcompiler_47

    #install zwift
    wget https://cdn.zwift.com/app/ZwiftSetup.exe
    wine64 ZwiftSetup.exe /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL
    sleep 30

    # Wait for Zwift to fully install and then restart container
    until ! pgrep ZwiftLauncher.exe
    do
        echo "updating in progress..."
        sleep 5
    done

    # Restart updates in background
    pkill ZwiftLauncher || true
    wait_for_zwift_game_update

    wineserver -k
    exit 0
fi

echo "starting zwift..."
wine64 start ZwiftLauncher.exe SilentLaunch

LAUNCHER_PID_HEX=$(winedbg --command "info proc" | grep -P "ZwiftLauncher.exe" | grep -oP "^\s\K.+?(?=\s)")
LAUNCHER_PID=$((16#$LAUNCHER_PID_HEX))

if [[ -f "/home/user/Zwift/.zwift-credentials" ]]
then
    echo "authenticating with zwift..."
    wine64 start /exec /bin/runfromprocess-rs.exe $LAUNCHER_PID ZwiftApp.exe --token=$(zwift-auth)
else
    wine64 start /exec /bin/runfromprocess-rs.exe $LAUNCHER_PID ZwiftApp.exe
fi

sleep 3

until pgrep ZwiftApp.exe &> /dev/null
do
    echo "Waiting for zwift to start ..."
    sleep 1
done

echo "Killing uneccesary applications"
pkill ZwiftLauncher
pkill ZwiftWindowsCra

wineserver -w
