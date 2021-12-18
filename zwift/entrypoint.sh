#!/bin/bash
set -e
set -x

ZWIFT_HOME="$HOME/.wine/drive_c/Program Files (x86)/Zwift"

mkdir -p "$ZWIFT_HOME"
cd "$ZWIFT_HOME"

if [ "$1" = "update" ]
then
	echo "updating zwift..."
	wine64 start ZwiftLauncher.exe
	wineserver -w
	exit 0
fi

if [ ! "$(ls -A .)" ] # is directory empty?
then
	echo "installing zwift..."
        wget https://www.nirsoft.net/utils/runfromprocess.zip
	unzip runfromprocess.zip	
	wget https://cdn.zwift.com/app/ZwiftSetup.exe
	winetricks --unattended dotnet45 win10
	wine64 ZwiftSetup.exe /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL
	# Wait for Zwift to fully install and then restart container
	wineserver -w
	exit 0
fi

echo "starting zwift..."
wine64 start ZwiftLauncher.exe
wine64 start RunFromProcess-x64.exe ZwiftLauncher.exe ZwiftApp.exe
sleep 1
bash -c "ps aux | grep ZwiftLauncher | head -n 1 | awk '{print \$2}' | xargs kill"
wineserver -w
