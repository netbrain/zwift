#!/usr/bin/env bash
set -uo pipefail

readonly DEBUG="${DEBUG:-0}"
if [[ ${DEBUG} -eq 1 ]]; then set -x; fi

readonly ZWIFT_USERNAME="${ZWIFT_USERNAME:-}"
readonly ZWIFT_PASSWORD="${ZWIFT_PASSWORD:-}"
readonly ZWIFT_OVERRIDE_RESOLUTION="${ZWIFT_OVERRIDE_RESOLUTION:-}"
readonly ZWIFT_NO_GAMEMODE="${ZWIFT_NO_GAMEMODE:-0}"

readonly WINE_USER_HOME="/home/user/.wine/drive_c/users/user"
readonly ZWIFT_HOME="/home/user/.wine/drive_c/Program Files (x86)/Zwift"
readonly ZWIFT_DOCS="${WINE_USER_HOME}/AppData/Local/Zwift"
readonly ZWIFT_PREFS="${ZWIFT_DOCS}/prefs.xml"

if [[ ! -d ${ZWIFT_HOME} ]]; then
    echo "Directory ${ZWIFT_HOME} does not exist.  Has Zwift been installed?" >&2
    exit 1
fi

if [[ -n ${ZWIFT_OVERRIDE_RESOLUTION} ]]; then
    if [[ -f ${ZWIFT_PREFS} ]]; then
        echo "Setting zwift resolution to ${ZWIFT_OVERRIDE_RESOLUTION}."
        updates_prefs="$(awk -v resolution="${ZWIFT_OVERRIDE_RESOLUTION}" '{
            gsub(/<USER_RESOLUTION_PREF>.*<\/USER_RESOLUTION_PREF>/,
                 "<USER_RESOLUTION_PREF>" resolution "</USER_RESOLUTION_PREF>")
        } 1' "${ZWIFT_PREFS}")"
        echo "${updates_prefs}" > "${ZWIFT_PREFS}"
    else
        echo "Warning: Preferences file does not exist yet. Resolution ${ZWIFT_OVERRIDE_RESOLUTION} cannot be set."
    fi
fi

cd "${ZWIFT_HOME}"

echo "Starting zwift..."
wine start ZwiftLauncher.exe SilentLaunch

launcher_pid_hex="$(winedbg --command "info proc" | grep -P "ZwiftLauncher.exe" | grep -oP "^\s\K.+?(?=\s)")"
launcher_pid="$((16#${launcher_pid_hex}))"

wine_cmd=(wine start /exec /bin/runfromprocess-rs.exe "${launcher_pid}" ZwiftApp.exe)

if [[ -n ${ZWIFT_USERNAME} ]] && [[ -n ${ZWIFT_PASSWORD} ]]; then
    echo "Authenticating with zwift"
    if token="$(zwift-auth)"; then
        wine_cmd+=(--token="${token}")
    else
        echo "Authentication failed, manual login will be required"
    fi
fi

"${wine_cmd[@]}"

sleep 3

until pgrep -f ZwiftApp.exe &> /dev/null; do
    echo "Waiting for zwift to start ..."
    sleep 1
done

echo "Killing unnecessary applications"
# ZwiftLauncher can exit on it's own before getting this far, so try to kill it
# and then always return 0 so the script does not exit non 0 here and cause the
# container to exit.  See https://github.com/netbrain/zwift/issues/210
pkill ZwiftLauncher || true
pkill ZwiftWindowsCra
pkill -f MicrosoftEdgeUpdate

if [[ ${ZWIFT_NO_GAMEMODE} -ne 1 ]]; then
    /usr/games/gamemoderun wineserver -w
else
    wineserver -w
fi
