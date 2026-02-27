#!/usr/bin/env bash
set -uo pipefail

readonly DEBUG="${DEBUG:-0}"
if [[ ${DEBUG} -eq 1 ]]; then set -x; fi

readonly ZWIFT_UID="${ZWIFT_UID:-$(id -u user)}"
readonly ZWIFT_GID="${ZWIFT_GID:-$(id -g user)}"
readonly WINE_EXPERIMENTAL_WAYLAND="${WINE_EXPERIMENTAL_WAYLAND:-0}"
readonly CONTAINER_TOOL="${CONTAINER_TOOL:?}"

readonly WINE_USER_HOME="/home/user/.wine/drive_c/users/user"
readonly ZWIFT_HOME="/home/user/.wine/drive_c/Program Files (x86)/Zwift"
readonly ZWIFT_DOCS="${WINE_USER_HOME}/AppData/Local/Zwift"
readonly ZWIFT_DOCS_OLD="${WINE_USER_HOME}/Documents/Zwift" # TODO remove when no longer needed (301)

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
update_required=0

if is_empty_directory "${ZWIFT_HOME}"; then
    startup_cmd=(/bin/update_zwift.sh install)
    update_required=1
elif [[ ${1:-} == "update" ]]; then
    startup_cmd=(/bin/update_zwift.sh)
    update_required=1
fi

######################################
##### Change ownership if needed #####

if [[ ${CONTAINER_TOOL} == "docker" ]]; then
    # with docker the container is launched as root
    # here we update ids and ownership so zwift can be launched as user instead

    user_uid="$(id -u user)"
    user_gid="$(id -g user)"

    should_change_user_ids() {
        # ids should be updated if ZWIFT_UID:ZWIFT_GID is different from from user uid:gid
        # returns 0 if ids should be changed, 1 if not, so it can be used in an if

        local result=1

        if [[ ! ${ZWIFT_UID} =~ ^[0-9]+$ ]]; then
            msgbox warning "Ignoring ZWIFT_UID '${ZWIFT_UID}' because it is not a number"
        elif [[ ${user_uid} -ne ${ZWIFT_UID} ]]; then
            user_uid="${ZWIFT_UID}"
            result=0
        fi

        if [[ ! ${ZWIFT_GID} =~ ^[0-9]+$ ]]; then
            msgbox warning "Ignoring ZWIFT_GID '${ZWIFT_GID}' because it is not a number"
        elif [[ ${user_gid} -ne ${ZWIFT_GID} ]]; then
            user_gid="${ZWIFT_GID}"
            result=0
        fi

        return "${result}"
    }

    change_user_ids() {
        usermod -ou "${user_uid}" user || return 1
        groupmod -og "${user_gid}" user || return 1
        mkdir -p "/run/user/${user_uid}" || return 1
        chown -R user:user "/run/user/${user_uid}" || return 1
        sed -i "s/1000/${user_uid}/g" /etc/pulse/client.conf || return 1
    }

    update_ownership() {
        if [[ ${update_required} -eq 1 ]]; then
            chown -R user:user /home/user || return 1
        else
            chown -R user:user "${ZWIFT_DOCS}" || return 1
            chown -R user:user "${ZWIFT_DOCS_OLD}" || return 1 # TODO remove when no longer needed (301)
        fi
    }

    if should_change_user_ids; then
        msgbox info "Changing user ids to ${user_uid}:${user_gid}"
        if change_user_ids; then
            msgbox ok "Changed user ids"
        else
            msgbox error "Failed to change user ids"
            exit 1
        fi
    fi

    msgbox info "Changing ownership from root to user"
    if update_ownership; then
        msgbox ok "Changed ownership to user"
    else
        msgbox error "Failed to change owership from root to user"
        exit 1
    fi

    startup_cmd=(gosu user:user "${startup_cmd[@]}")
fi

#########################################
##### Launch update or start script #####

"${startup_cmd[@]}"
