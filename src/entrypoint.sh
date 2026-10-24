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
readonly WINE_DISABLE_EGL="${WINE_DISABLE_EGL:-0}"
readonly XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-x11}"
readonly CONTAINER_TOOL="${CONTAINER_TOOL:?}"
readonly ZWIFT_VOLUME="${ZWIFT_VOLUME:-}"

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

command_exists() {
    local cmd="${1:?}"
    local cmd_path
    cmd_path="$(command -v "${cmd}" 2> /dev/null)" && [[ -x ${cmd_path} ]]
}

nvidia_proprietary_driver() {
    local nvidia_gpus
    command_exists nvidia-smi && nvidia_gpus="$(nvidia-smi -L)" && [[ -n ${nvidia_gpus} ]]
}

declare -a run_as=()

######################################
##### Change ownership if needed #####

if [[ ${CONTAINER_TOOL} == "docker" ]]; then
    # with docker the container is launched as root
    # here we update ids and ownership so zwift can be launched as user instead

    container_uid="$(id -u user)"
    container_gid="$(id -g user)"

    should_change_user_ids() {
        # ids should be updated if HOST_UID:HOST_GID is different from from user uid:gid
        # returns 0 if ids should be changed, 1 if not, so it can be used in an if

        local result=1

        if [[ ! ${HOST_UID} =~ ^[0-9]+$ ]]; then
            msgbox warning "Ignoring HOST_UID '${HOST_UID}' because it is not a number"
        elif [[ ${container_uid} -ne ${HOST_UID} ]]; then
            container_uid="${HOST_UID}"
            result=0
        fi

        if [[ ! ${HOST_GID} =~ ^[0-9]+$ ]]; then
            msgbox warning "Ignoring HOST_GID '${HOST_GID}' because it is not a number"
        elif [[ ${container_gid} -ne ${HOST_GID} ]]; then
            container_gid="${HOST_GID}"
            result=0
        fi

        return "${result}"
    }

    change_user_ids() {
        usermod -ou "${container_uid}" user || return 1
        groupmod -og "${container_gid}" user || return 1
    }

    ownership_needs_update() {
        # Quick check: if the top-level directory is already owned by user:user, assume everything is fine
        # This avoids a costly recursive find on every normal startup
        local target="${1:?}"
        local result
        [[ -d ${target} ]] && result="$(find "${target}" -maxdepth 1 \( ! -user user -o ! -group user \) -print 2> /dev/null)" && [[ -n ${result} ]]
    }

    update_ownership() {
        local target="${ZWIFT_VOLUME}"

        if [[ -z ${target} ]] || ! ownership_needs_update "${target}"; then
            msgbox ok "Ownership already correct, skipping"
            return 0
        fi

        # Only chown files that actually need it, rather than blindly recursing everything
        msgbox info "Updating ownership of files in ${target} (this may take a while on first run)..."
        find "${target}" \( ! -user user -o ! -group user \) -exec chown user:user {} + || return 1
    }

    if should_change_user_ids; then
        msgbox info "Changing user ids to ${container_uid}:${container_gid}"
        if change_user_ids; then
            msgbox ok "Changed user ids"
        else
            msgbox error "Failed to change user ids"
            exit 1
        fi
    fi

    msgbox info "Checking file ownership"
    if update_ownership; then
        msgbox ok "File ownership is correct"
    else
        msgbox error "Failed to update file ownership"
        exit 1
    fi

    run_as=(gosu user:user)
fi

#####################################
##### Configure graphics driver #####

if [[ ${XDG_SESSION_TYPE} == "wayland" ]]; then
    msgbox info "Enabling native Wayland"
    unset DISPLAY # DISPLAY variable needs to be empty for wine to use native wayland
elif [[ ${WINE_DISABLE_EGL} -eq 1 ]]; then
    msgbox info "Disabling EGL (using GLX instead)"
    "${run_as[@]}" wine reg.exe add 'HKCU\Software\Wine\X11 Driver' /f /v UseEGL /d N > /dev/null 2>&1 || exit 1
elif nvidia_proprietary_driver; then
    msgbox info "Detected nvidia graphics, performing EGL vendor library workaround"
    export __EGL_VENDOR_LIBRARY_FILENAMES=""
else
    msgbox debug "Using X11 with EGL on non-nvidia system"
fi

#########################################
##### Launch update or start script #####

msgbox debug "Entrypoint script invoked with arguments: ${*:-none}"

declare -a startup_cmd=("${run_as[@]}")

if [[ ${1:-} == "--install" ]] || [[ ${1:-} == "--update" ]]; then
    startup_cmd+=(/bin/update_zwift.sh "${1:-}")
else
    startup_cmd+=(/bin/run_zwift.sh)
fi

"${startup_cmd[@]}"
