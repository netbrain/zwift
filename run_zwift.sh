#!/bin/bash
set -e
set -x

ZWIFT_HOME="$HOME/.wine/drive_c/Program Files (x86)/Zwift"
ZWIFT_PREFS="$HOME/.wine/drive_c/users/user/Documents/Zwift/prefs.xml"

if [ ! -d "$ZWIFT_HOME" ]; then
    echo "Directory $ZWIFT_HOME does not exist.  Has Zwift been installed?"
    exit 1
fi

if [ ! -z $ZWIFT_OVERRIDE_RESOLUTION ]; then
    echo "Setting zwift resolution to $ZWIFT_OVERRIDE_RESOLUTION."
    TMP_PREFS_FILE="/tmp/zwift_prefs.xml"
    awk -v resolution="$ZWIFT_OVERRIDE_RESOLUTION" '{
        gsub(/<USER_RESOLUTION_PREF>.*<\/USER_RESOLUTION_PREF>/,
             "<USER_RESOLUTION_PREF>" resolution "</USER_RESOLUTION_PREF>")
    } 1' "$ZWIFT_PREFS" > "$TMP_PREFS_FILE"
    mv "$TMP_PREFS_FILE" "$ZWIFT_PREFS"
fi

cd "$ZWIFT_HOME"

echo "starting zwift..."
wine start ZwiftLauncher.exe SilentLaunch

LAUNCHER_PID_HEX=$(winedbg --command "info proc" | grep -P "ZwiftLauncher.exe" | grep -oP "^\s\K.+?(?=\s)")
LAUNCHER_PID=$((16#$LAUNCHER_PID_HEX))

if [[ ! -z "$ZWIFT_USERNAME" ]] && [[ ! -z "$ZWIFT_PASSWORD" ]];
then
    echo "authenticating with zwift..."
    wine start /exec /bin/runfromprocess-rs.exe $LAUNCHER_PID ZwiftApp.exe --token=$(zwift-auth)
else
    wine start /exec /bin/runfromprocess-rs.exe $LAUNCHER_PID ZwiftApp.exe
fi

sleep 3

until pgrep -f ZwiftApp.exe &> /dev/null
do
    echo "Waiting for zwift to start ..."
    sleep 1
done

echo "Killing uneccesary applications"
# ZwiftLauncher can exit on it's own before getting this far, so try to kill it
# and then always return 0 so the script does not exit non 0 here and cause the
# container to exit.  See https://github.com/netbrain/zwift/issues/210
pkill ZwiftLauncher || true
pkill ZwiftWindowsCra
pkill -f MicrosoftEdgeUpdate

[ -z "$ZWIFT_NO_GAMEMODE" ] && /usr/games/gamemoderun wineserver -w || wineserver -w
