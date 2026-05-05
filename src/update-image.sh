#!/usr/bin/env bash
set -uo pipefail

readonly DEBUG="${DEBUG:-0}"
if [[ ${DEBUG} -eq 1 ]]; then set -x; fi

if [[ -t 1 ]]; then
    readonly COLOR_WHITE="\033[0;37m"
    readonly COLOR_RED="\033[0;31m"
    readonly COLOR_GREEN="\033[0;32m"
    readonly COLOR_BLUE="\033[0;34m"
    readonly COLOR_YELLOW="\033[0;33m"
    readonly STYLE_BOLD="\033[1m"
    readonly STYLE_UNDERLINE="\033[4m"
    readonly RESET_STYLE="\033[0m"
else
    readonly COLOR_WHITE=""
    readonly COLOR_RED=""
    readonly COLOR_GREEN=""
    readonly COLOR_BLUE=""
    readonly COLOR_YELLOW=""
    readonly STYLE_BOLD=""
    readonly STYLE_UNDERLINE=""
    readonly RESET_STYLE=""
fi

readonly VERBOSITY="${VERBOSITY:-1}"

msgbox() {
    local type="${1:?}" # Type: info, ok, warning, error, debug
    local msg="${2:?}"  # Message: the message to display

    local timestamp=""
    [[ ${VERBOSITY} -ge 2 ]] && printf -v timestamp '%(%T)T|' -1

    case ${type} in
        info) [[ ${VERBOSITY} -ge 1 ]] && echo -e "${COLOR_BLUE}[${timestamp}*] ${msg}${RESET_STYLE}" ;;
        ok) echo -e "${COLOR_GREEN}[${timestamp}✓] ${msg}${RESET_STYLE}" ;;
        warning) echo -e "${COLOR_YELLOW}[${timestamp}!] ${msg}${RESET_STYLE}" ;;
        error) echo -e "${COLOR_RED}[${timestamp}✗] ${msg}${RESET_STYLE}" >&2 ;;
        debug) [[ ${VERBOSITY} -ge 3 ]] && echo -e "${COLOR_WHITE}[${timestamp}◉] ${msg}${RESET_STYLE}" ;;
        *) echo "msgbox - unknown type ${type}" >&2 && exit 1 ;;
    esac
}

command_exists() {
    local cmd="${1:?}"
    local cmd_path
    cmd_path="$(command -v "${cmd}" 2> /dev/null)" && [[ -x ${cmd_path} ]]
}

echo -e "${COLOR_YELLOW}[!] ${STYLE_BOLD}Easily Zwift on linux!${RESET_STYLE}"
echo -e "${COLOR_YELLOW}[!] ${STYLE_UNDERLINE}https://github.com/netbrain/zwift${RESET_STYLE}"

msgbox info "Preparing to update scripts in Zwift image"

################################
##### Initialize variables #####

# Initialize CONTAINER_TOOL: Use podman if available
msgbox info "Looking for container tool"
CONTAINER_TOOL="${CONTAINER_TOOL:-}"
if [[ -z ${CONTAINER_TOOL} ]]; then
    if command_exists podman; then
        CONTAINER_TOOL="podman"
    else
        CONTAINER_TOOL="docker"
    fi
fi
readonly CONTAINER_TOOL
if command_exists "${CONTAINER_TOOL}"; then
    msgbox ok "Found container tool: ${CONTAINER_TOOL}"
else
    msgbox error "Container tool ${CONTAINER_TOOL} not found"
    msgbox error "  To install podman, see: https://podman.io/docs/installation"
    msgbox error "  To install docker, see: https://docs.docker.com/get-started/get-docker/"
    exit 1
fi

# Initialize IMAGE and VERSION based on container tool
IMAGE="${IMAGE:-}"
if [[ -z ${IMAGE} ]]; then
    if [[ ${CONTAINER_TOOL} == "podman" ]]; then
        IMAGE="localhost/zwift"
    else
        IMAGE="netbrain/zwift"
    fi
fi
readonly IMAGE
readonly VERSION="${VERSION:-latest}"
msgbox info "Updating image ${IMAGE}:${VERSION}"

# Initialize script constants
readonly TEMP_CONTAINER_NAME="zwift-update-image"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
readonly SCRIPT_DIR
declare -A SCRIPTS_MAP
SCRIPTS_MAP["/bin/entrypoint"]="${SCRIPT_DIR}/entrypoint.sh"
SCRIPTS_MAP["/bin/zwift-auth"]="${SCRIPT_DIR}/zwift-auth.sh"
SCRIPTS_MAP["/bin/update_zwift.sh"]="${SCRIPT_DIR}/update_zwift.sh"
SCRIPTS_MAP["/bin/run_zwift.sh"]="${SCRIPT_DIR}/run_zwift.sh"
readonly SCRIPTS_MAP

###################################
##### Update scripts in image #####

temp_dir=""
cleanup_invoked=0
any_script_updated=0

cleanup() {
    if [[ ${cleanup_invoked} -ne 1 ]]; then
        msgbox info "Checking for temporary container"
        if ${CONTAINER_TOOL} rm "${TEMP_CONTAINER_NAME}" > /dev/null 2>&1; then
            msgbox ok "Removed temporary container"
        else
            msgbox info "No temporary container to remove"
        fi

        if [[ -n ${temp_dir} ]] && [[ -d ${temp_dir} ]]; then
            msgbox info "Removing temporary directory"
            rm -rf -- "${temp_dir}" || true
        fi

        cleanup_invoked=1
    fi
}

trap cleanup EXIT

msgbox info "Creating temporary directory"
if temp_dir="$(mktemp -d "/tmp/${TEMP_CONTAINER_NAME}-XXXXXXXXXX")"; then
    msgbox ok "Created temporary directory"
    msgbox debug "Temporary directory: ${temp_dir}"
else
    msgbox error "Failed to create temporary directory"
    exit 1
fi

msgbox info "Creating temporary container to update image scripts"
if ${CONTAINER_TOOL} create --name "${TEMP_CONTAINER_NAME}" "${IMAGE}:${VERSION}"; then
    msgbox ok "Created temporary container"
    msgbox debug "Temporary container: ${TEMP_CONTAINER_NAME}"
else
    msgbox error "Failed to create temporary container"
    exit 1
fi

for container_path in "${!SCRIPTS_MAP[@]}"; do
    msgbox info "Checking if ${container_path} is up-to-date"
    host_path="${SCRIPTS_MAP[${container_path}]}"
    if ! ${CONTAINER_TOOL} cp "${TEMP_CONTAINER_NAME}:${container_path}" "${temp_dir}/container_script"; then
        msgbox error "Failed to copy ${container_path} from container to host"
        exit 1
    fi
    container_sum="$(sha256sum "${temp_dir}/container_script" | awk '{print $1}')"
    host_sum="$(sha256sum "${host_path}" | awk '{print $1}')"
    msgbox debug "Checksum: ${container_sum} (${TEMP_CONTAINER_NAME}:${container_path})"
    msgbox debug "Checksum: ${host_sum} (${host_path})"
    if [[ ${container_sum} == "${host_sum}" ]]; then
        msgbox ok "${container_path} in container is up-to-date"
        continue
    fi
    msgbox info "${container_path} is not up-to-date, updating script in container"
    if ${CONTAINER_TOOL} cp "${host_path}" "${TEMP_CONTAINER_NAME}:${container_path}"; then
        msgbox ok "Copied ${host_path} to ${container_path} in temporary container"
    else
        msgbox info "Failed to copy ${host_path} to ${container_path} in temporary container"
        exit 1
    fi
    any_script_updated=1
done

if [[ ${any_script_updated} -eq 1 ]]; then
    msgbox info "Some scripts were updated"
    msgbox info "Updating image with changes from temporary container"
    if ${CONTAINER_TOOL} commit "${TEMP_CONTAINER_NAME}" "${IMAGE}:${VERSION}"; then
        msgbox ok "Tagged Zwift container as ${IMAGE}:${VERSION}"
    else
        msgbox error "Failed to commit container changes to image"
        exit 1
    fi
else
    msgbox ok "Scripts in ${IMAGE}:${VERSION} are already up-to-date"
fi

cleanup

########################
##### Launch Zwift #####

export IMAGE
export VERSION
export DONT_CHECK=1
export DONT_PULL=1
export ZWIFT_FG=1

"${SCRIPT_DIR}/zwift.sh"
