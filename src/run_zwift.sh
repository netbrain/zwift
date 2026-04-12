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

readonly VERBOSITY="${VERBOSITY:-1}"
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
    local type="${1:?}" # Type: info, ok, warning, error, debug
    local msg="${2:?}"  # Message: the message to display

    local timestamp=""
    [[ ${VERBOSITY} -ge 2 ]] && printf -v timestamp '%(%T)T|' -1

    case ${type} in
        info) [[ ${VERBOSITY} -ge 1 ]] && echo -e "${COLOR_BLUE}[${CONTAINER_TOOL}|${timestamp}*] ${msg}${RESET_STYLE}" ;;
        ok) echo -e "${COLOR_GREEN}[${CONTAINER_TOOL}|${timestamp}✓] ${msg}${RESET_STYLE}" ;;
        warning) echo -e "${COLOR_YELLOW}[${CONTAINER_TOOL}|${timestamp}!] ${msg}${RESET_STYLE}" ;;
        error) echo -e "${COLOR_RED}[${CONTAINER_TOOL}|${timestamp}✗] ${msg}${RESET_STYLE}" >&2 ;;
        debug) [[ ${VERBOSITY} -ge 3 ]] && echo -e "${COLOR_WHITE}[${CONTAINER_TOOL}|${timestamp}◉] ${msg}${RESET_STYLE}" ;;
        *) echo "msgbox - unknown type ${type}" >&2 && exit 1 ;;
    esac
}

wine_task_info() {
    local task_name="${1:?}"
    local filter="${2:-IMAGENAME}"
    wine tasklist /fo list /fi "${filter} eq ${task_name}"
}

wine_task_pid() {
    local task_name="${1:?}"
    wine_task_info "${task_name}" | grep -m1 -Po '^PID:[\t ]*\K[0-9]+'
}

is_wine_task_running() {
    local task_name="${1:?}"
    [[ -n $(wine_task_info "${task_name}" || true) ]]
}

is_wine_window_open() {
    local window_title="${1:?}"
    [[ -n $(wine_task_info "${window_title}" WINDOWTITLE || true) ]]
}

kill_wine_task() {
    for task in "${@}"; do
        msgbox debug "Killing wine task '${task}'"
        wine taskkill /f /im "${task}" > /dev/null 2>&1 || true
    done
}

###########################
##### Configure Zwift #####

# Create array for zwift arguments
declare -a zwift_args
zwift_args=()

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

if [[ -n ${ZWIFT_USERNAME} ]] && [[ -n ${ZWIFT_PASSWORD} ]]; then
    msgbox info "Authenticating with Zwift"
    if auth_token="$(zwift-auth)"; then
        zwift_args+=(--token="${auth_token}")
    else
        msgbox warning "Authentication failed, manual login will be required"
    fi
fi

######################################################
##### Start (and automatically stop) wine server #####

cleanup() {
    msgbox info "Stopping wine server"
    wineserver -k || true
}

trap cleanup EXIT

msgbox info "Launching wine server"

declare -a wineserver_cmd
wineserver_cmd=(wineserver)

if [[ ${ZWIFT_NO_GAMEMODE} -eq 1 ]]; then
    msgbox warning "Not using gamemode"
else
    msgbox info "Using gamemode"
    wineserver_cmd=(/usr/games/gamemoderun "${wineserver_cmd[@]}")
fi

if "${wineserver_cmd[@]}"; then
    msgbox ok "Launched wine server"
else
    msgbox error "Failed to launch wine server!"
    exit 1
fi

##################################
##### Start Zwift using wine #####

msgbox info "Starting Zwift launcher using wine"

if ! wine start ZwiftLauncher.exe SilentLaunch; then
    msgbox error "Failed to start Zwift launcher using wine!"
    exit 1
fi

if ! launcher_pid="$(wine_task_pid ZwiftLauncher.exe)"; then
    msgbox error "Unable to get launcher process id. Did it crash?"
    exit 1
fi

msgbox ok "Zwift launcher started using wine"
msgbox info "Starting Zwift using wine"

declare -a wine_cmd
wine_cmd=(wine start /exec /bin/runfromprocess-rs.exe "${launcher_pid}" ZwiftApp.exe "${zwift_args[@]}")

if ! "${wine_cmd[@]}"; then
    msgbox error "Failed to start Zwift using wine!"
    exit 1
fi

# Wait for Zwift to start
counter=1
max_iterations=10
while ! is_wine_window_open Zwift && [[ ${counter} -le ${max_iterations} ]]; do
    msgbox info "Waiting for Zwift to start... (${counter}/${max_iterations})"
    sleep 0.5
    ((counter++))
done
if ! is_wine_window_open Zwift; then
    msgbox error "Zwift has not started yet, giving up!"
    exit 1
fi

# Kill launcher as soon as possible to prevent it from updating Zwift
msgbox info "Killing Zwift launcher and background tasks"
kill_wine_task ZwiftLauncher.exe ZwiftWindowsCrashHandler.exe MicrosoftEdgeUpdate.exe

msgbox ok "Zwift started using wine"

##################################
##### Wait for Zwift to exit #####

while is_wine_task_running ZwiftApp.exe; do
    msgbox debug "Waiting for Zwift to exit..."
    sleep 5
done

msgbox info "Zwift closed, exiting"
