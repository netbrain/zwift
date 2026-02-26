#!/usr/bin/env bash
set -uo pipefail

readonly DEBUG="${DEBUG:-0}"
if [[ ${DEBUG} -eq 1 ]]; then set -x; fi

readonly CONTAINER_TOOL="${CONTAINER_TOOL:?}"
readonly ZWIFT_USERNAME="${ZWIFT_USERNAME:-}"
readonly ZWIFT_PASSWORD="${ZWIFT_PASSWORD:-}"
readonly ZWIFT_OVERRIDE_RESOLUTION="${ZWIFT_OVERRIDE_RESOLUTION:-}"
readonly ZWIFT_NO_GAMEMODE="${ZWIFT_NO_GAMEMODE:-0}"

readonly WINE_USER_HOME="/home/user/.wine/drive_c/users/user"
readonly ZWIFT_HOME="/home/user/.wine/drive_c/Program Files (x86)/Zwift"
readonly ZWIFT_DOCS="${WINE_USER_HOME}/AppData/Local/Zwift"
readonly ZWIFT_PREFS="${ZWIFT_DOCS}/prefs.xml"

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

###########################
##### Configure Zwift #####

if [[ ! -d ${ZWIFT_HOME} ]] || ! cd "${ZWIFT_HOME}"; then
    msgbox error "Directory ${ZWIFT_HOME} does not exist. Has Zwift been installed?"
    exit 1
fi

if [[ -n ${ZWIFT_OVERRIDE_RESOLUTION} ]]; then
    if [[ -f ${ZWIFT_PREFS} ]]; then
        msgbox info "Setting zwift resolution to ${ZWIFT_OVERRIDE_RESOLUTION}."
        updated_prefs="$(awk -v resolution="${ZWIFT_OVERRIDE_RESOLUTION}" '{
            gsub(/<USER_RESOLUTION_PREF>.*<\/USER_RESOLUTION_PREF>/,
                 "<USER_RESOLUTION_PREF>" resolution "</USER_RESOLUTION_PREF>")
        } 1' "${ZWIFT_PREFS}")"
        echo "${updated_prefs}" > "${ZWIFT_PREFS}"
    else
        msgbox warning "Preferences file does not exist yet. Resolution ${ZWIFT_OVERRIDE_RESOLUTION} cannot be set."
    fi
fi

#########################################
##### Automatically cleanup on exit #####

cleanup_invoked=0
cleanup() {
    if [[ ${cleanup_invoked} -ne 1 ]]; then
        msgbox info "Cleanup: Killing unnecessary applications"
        pkill ZwiftLauncher || true
        pkill ZwiftWindowsCra || true
        pkill -f MicrosoftEdgeUpdate || true
        cleanup_invoked=1
    fi
}

trap cleanup EXIT

###########################################
##### Start Zwift Launcher using wine #####

if ! wine start ZwiftLauncher.exe SilentLaunch; then
    msgbox error "Failed to start Zwift launcher using wine!"
    exit 1
fi

if ! launcher_pid_hex="$(winedbg --command "info proc" | grep -P "ZwiftLauncher.exe" | grep -oP "^\s\K.+?(?=\s)")"; then
    msgbox error "Unable to get launcher process id. Did it crash?"
    exit 1
fi

msgbox ok "Zwift launcher started using wine"

launcher_pid="$((16#${launcher_pid_hex}))"

##################################
##### Start Zwift using wine #####

declare -a wine_cmd
wine_cmd=(wine start /exec /bin/runfromprocess-rs.exe "${launcher_pid}" ZwiftApp.exe)

if [[ -n ${ZWIFT_USERNAME} ]] && [[ -n ${ZWIFT_PASSWORD} ]]; then
    msgbox info "Authenticating with zwift"
    if token="$(zwift-auth)"; then
        wine_cmd+=(--token="${token}")
    else
        msgbox warning "Authentication failed, manual login will be required"
    fi
fi

msgbox info "Starting Zwift using wine"
if ! "${wine_cmd[@]}"; then
    msgbox error "Failed to start Zwift using wine!"
    exit 1
fi

sleep 3

counter=1
until pgrep -f ZwiftApp.exe > /dev/null 2>&1; do
    msgbox info "Waiting for zwift to start... (${counter})"
    sleep 1
    ((counter++))
done

msgbox ok "Zwift started using wine"

cleanup # important, wine server will not stop if launcher etc keep running

#############################
##### Start wine server #####

declare -a wineserver_cmd
wineserver_cmd=(wineserver -w)

if [[ ${ZWIFT_NO_GAMEMODE} -ne 1 ]]; then
    wineserver_cmd=(/usr/games/gamemoderun "${wineserver_cmd[@]}")
fi

msgbox info "Launching wine server"
if ! "${wineserver_cmd[@]}"; then
    msgbox error "Failed to launch wine server!"
    exit 1
fi

msgbox ok "Zwift closed, exiting"
