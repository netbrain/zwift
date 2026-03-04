#!/usr/bin/env bash
set -uo pipefail

readonly DEBUG="${DEBUG:-0}"
if [[ ${DEBUG} -eq 1 ]]; then set -x; fi

readonly COLORED_OUTPUT="${COLORED_OUTPUT:-0}"
if [[ -t 1 ]] || [[ ${COLORED_OUTPUT} -eq 1 ]]; then
    readonly COLOR_WHITE="\033[0;37m"
    readonly COLOR_RED="\033[0;31m"
    readonly COLOR_GREEN="\033[0;32m"
    readonly COLOR_BLUE="\033[0;34m"
    readonly COLOR_YELLOW="\033[0;33m"
    readonly RESET_STYLE="\033[0m"
else
    readonly COLOR_WHITE=""
    readonly COLOR_RED=""
    readonly COLOR_GREEN=""
    readonly COLOR_BLUE=""
    readonly COLOR_YELLOW=""
    readonly RESET_STYLE=""
fi

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
        info) echo -e "${COLOR_BLUE}[${CONTAINER_TOOL}|*] ${msg}${RESET_STYLE}" ;;
        ok) echo -e "${COLOR_GREEN}[${CONTAINER_TOOL}|✓] ${msg}${RESET_STYLE}" ;;
        warning) echo -e "${COLOR_YELLOW}[${CONTAINER_TOOL}|!] ${msg}${RESET_STYLE}" ;;
        error) echo -e "${COLOR_RED}[${CONTAINER_TOOL}|✗] ${msg}${RESET_STYLE}" >&2 ;;
        *) echo -e "${COLOR_WHITE}[${CONTAINER_TOOL}|*] ${msg}${RESET_STYLE}" ;;
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
        msgbox info "Killing unnecessary applications"
        pkill ZwiftLauncher || true
        pkill ZwiftWindowsCra || true
        pkill -f MicrosoftEdgeUpdate || true
        cleanup_invoked=1
    fi
}

trap cleanup EXIT

###########################################
##### Start Zwift Launcher using wine #####

msgbox info "Starting Zwift launcher using wine"

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
    msgbox info "Authenticating with Zwift"
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

# important, without this sleep Zwift gets stuck in the launcher!
for i in $(seq 3 -1 1); do
    msgbox info "Waiting for Zwift to start... (${i})"
    sleep 1
done
if ! pgrep -f ZwiftApp.exe > /dev/null 2>&1; then
    msgbox error "Zwift has not yet started, giving up!"
    exit 1
fi

msgbox ok "Zwift started using wine"

#############################
##### Start wine server #####

cleanup # important, wine server will not stop if launcher etc keep running

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
