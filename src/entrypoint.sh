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
readonly WINE_EXPERIMENTAL_WAYLAND="${WINE_EXPERIMENTAL_WAYLAND:-0}"
readonly CONTAINER_TOOL="${CONTAINER_TOOL:?}"

readonly ZWIFT_HOME="/home/user/.wine/drive_c/Program Files (x86)/Zwift"

msgbox() {
    local type="${1:?}" # Type: info, ok, warning, error, debug
    local msg="${2:?}"  # Message: the message to display

    make_timestamp() {
        if [[ ${VERBOSITY} -ge 2 ]]; then
            printf '%(%T)T|' -1
        else
            printf ''
        fi
    }

    local timestamp
    timestamp="$(make_timestamp)"

    case ${type} in
        info) [[ ${VERBOSITY} -ge 1 ]] && echo -e "${COLOR_BLUE}[${CONTAINER_TOOL}|${timestamp}*] ${msg}${RESET_STYLE}" ;;
        ok) echo -e "${COLOR_GREEN}[${CONTAINER_TOOL}|${timestamp}✓] ${msg}${RESET_STYLE}" ;;
        warning) echo -e "${COLOR_YELLOW}[${CONTAINER_TOOL}|${timestamp}!] ${msg}${RESET_STYLE}" ;;
        error) echo -e "${COLOR_RED}[${CONTAINER_TOOL}|${timestamp}✗] ${msg}${RESET_STYLE}" >&2 ;;
        debug) [[ ${VERBOSITY} -ge 3 ]] && echo -e "${COLOR_WHITE}[${CONTAINER_TOOL}|${timestamp}◉] ${msg}${RESET_STYLE}" ;;
        *) echo "msgbox - unknown type ${type}" >&2 && exit 1 ;;
    esac
}

is_user_root() {
    [[ ${EUID} -eq 0 ]]
}

is_empty_directory() {
    local directory="${1:?}"
    if [[ ! -d ${directory} ]]; then
        msgbox error "${directory} is not a directory"
        exit 1
    fi
    local contents
    ! contents="$(ls -A "${directory}" 2> /dev/null)" || [[ -z ${contents} ]]
}

#########################################
##### Launch update or start script #####

msgbox info "Starting or installing Zwift"

actual_user="$(whoami)"
actual_uid="$(id -u "${actual_user}")"
actual_gid="$(id -g "${actual_user}")"
msgbox debug "Running as ${actual_user} (uid=${actual_uid}, gid=${actual_gid})"

if is_user_root; then
    msgbox error "Cannot run or install Zwift as root!"
    exit 1
fi

if ! mkdir -p "${ZWIFT_HOME}" || ! cd "${ZWIFT_HOME}"; then
    msgbox error "Zwift home directory '${ZWIFT_HOME}' does not exist or is not accessible!"
    exit 1
fi

# If Wayland Experimental need to blank DISPLAY here to enable Wayland.
# NOTE: DISPLAY must be unset here before run_zwift to work
#       Registry entries are set in the container install or won't work.
if [[ ${WINE_EXPERIMENTAL_WAYLAND} -eq 1 ]]; then
    msgbox info "Using Wayland, unsetting DISPLAY environment variable"
    unset DISPLAY
fi

declare -a startup_cmd
startup_cmd=(/bin/run_zwift.sh)

if is_empty_directory "${ZWIFT_HOME}"; then
    startup_cmd=(/bin/update_zwift.sh --install)
elif [[ ${1:-} == "--update" ]]; then
    startup_cmd=(/bin/update_zwift.sh)
fi

"${startup_cmd[@]}"
