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
readonly HOST_UID="${HOST_UID:-$(id -u user)}"
readonly HOST_GID="${HOST_GID:-$(id -g user)}"
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

is_empty_directory() {
    local directory="${1:?}"
    if [[ ! -d ${directory} ]]; then
        msgbox error "${directory} is not a directory"
        exit 1
    fi
    local contents
    ! contents="$(ls -A "${directory}" 2> /dev/null)" || [[ -z ${contents} ]]
}

###########################
##### Configure Zwift #####

if ! mkdir -p "${ZWIFT_HOME}" || ! cd "${ZWIFT_HOME}"; then
    msgbox error "Zwift home directory '${ZWIFT_HOME}' does not exist or is not accessible!"
    exit 1
fi

# If Wayland Experimental need to blank DISPLAY here to enable Wayland.
# NOTE: DISPLAY must be unset here before run_zwift to work
#       Registry entries are set in the container install or won't work.
if [[ ${WINE_EXPERIMENTAL_WAYLAND} -eq 1 ]]; then
    unset DISPLAY
fi

############################################
##### Clean install, update or launch? #####

declare -a startup_cmd
startup_cmd=(/bin/run_zwift.sh)

if is_empty_directory "${ZWIFT_HOME}"; then
    startup_cmd=(/bin/update_zwift.sh --install)
elif [[ ${1:-} == "--update" ]]; then
    startup_cmd=(/bin/update_zwift.sh)
fi

#################################################
##### Add container user to host user group #####

if [[ ${CONTAINER_TOOL} == "docker" ]]; then
    # docker does not support remapping container user to host user out of the box

    container_uid="$(id -u user)"
    container_gid="$(id -g user)"

    should_change_user_ids() {
        # ids should be updated if HOST_UID:HOST_GID is different from from user uid:gid
        # returns 0 if ids should be changed, 1 if not, so it can be used in an if

        local result=1

        if [[ ! ${HOST_UID} =~ ^[0-9]+$ ]]; then
            msgbox warning "Ignoring HOST_UID '${HOST_UID}' because it is not a number"
        elif [[ ${container_uid} -ne ${HOST_UID} ]]; then
            result=0
        fi

        if [[ ! ${HOST_GID} =~ ^[0-9]+$ ]]; then
            msgbox warning "Ignoring HOST_GID '${HOST_GID}' because it is not a number"
        elif [[ ${container_gid} -ne ${HOST_GID} ]]; then
            result=0
        fi

        return "${result}"
    }

    change_user_ids() {
        sudo usermod -ou "${HOST_UID}" user || return 1
        sudo groupmod -og "${HOST_GID}" user || return 1
        sudo mkdir -p "/run/user/${HOST_UID}" || return 1
        sudo chown -R user:user "/run/user/${HOST_UID}" || return 1
        sudo sed -i "s|/run/user/1000|/run/user/${user_uid}|g" /etc/pulse/client.conf || return 1
    }

    if should_change_user_ids; then
        msgbox info "Changing user ids to ${HOST_UID}:${HOST_GID}"
        if change_user_ids; then
            msgbox ok "Changed user ids"
        else
            msgbox error "Failed to change user ids"
            exit 1
        fi
    fi
fi

#########################################
##### Launch update or start script #####

actual_user="$(whoami)"
actual_uid="$(id -u "${actual_user}")"
actual_gid="$(id -g "${actual_user}")"
msgbox debug "Running as ${actual_user} (uid=${actual_uid}, gid=${actual_gid})"

"${startup_cmd[@]}"
