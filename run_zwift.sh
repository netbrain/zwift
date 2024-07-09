#!/bin/bash
set -e
set -x

# Test Update
ZWIFT_HOME="$HOME/.wine/drive_c/Program Files (x86)/Zwift"

if [ ! -d "$ZWIFT_HOME" ]; then
  echo "Directory $ZWIFT_HOME does not exist.  Has Zwift been installed?"
  exit 1
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
pkill ZwiftLauncher
pkill ZwiftWindowsCra
pkill -f MicrosoftEdgeUpdate

/usr/games/gamemoderun wineserver -w
