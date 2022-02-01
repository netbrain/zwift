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
	#install dotnet > 4.7.2
	winetricks --unattended dotnet48 win10
	
	#prevents warning when starting zwift for the first time
	winetricks --unattended dotnet20 win10

	#workaround crash issue 1.21
	winetricks --unattended d3dcompiler_47
	
	#install msedge
	wget https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/d1b0e946-e654-4d81-a42a-d581b8f3c40c/MicrosoftEdgeWebView2RuntimeInstallerX64.exe
	wine64 MicrosoftEdgeWebview2RuntimeInstallerX64.exe /silent /install

	#install zwift
        wget https://www.nirsoft.net/utils/runfromprocess.zip
	unzip runfromprocess.zip
	wget https://cdn.zwift.com/app/ZwiftSetup.exe
	wine64 ZwiftSetup.exe /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL

	# Wait for Zwift to fully install and then restart container
	wineserver -w
	exit 0
fi
echo "starting zwift..."
wine64 start ZwiftLauncher.exe
wine64 start RunFromProcess-x64.exe ZwiftLauncher.exe ZwiftApp.exe
until pgrep ZwiftApp.exe &> /dev/null
do
    echo "Waiting for zwift to start ..."
    sleep 1
done

echo "Killing uneccesary applications"
pkill ZwiftLauncher
pkill MicrosoftEdgeUp
pkill ZwiftWindowsCra

wineserver -w
