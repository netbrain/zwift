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

msgbox() {
    local type="${1:?}" # Type: info, ok, warning, error
    local msg="${2:?}"  # Message: the message to display

    case ${type} in
        info) echo -e "${COLOR_BLUE}[*] ${msg}${RESET_STYLE}" ;;
        ok) echo -e "${COLOR_GREEN}[✓] ${msg}${RESET_STYLE}" ;;
        warning) echo -e "${COLOR_YELLOW}[!] ${msg}${RESET_STYLE}" ;;
        error) echo -e "${COLOR_RED}[✗] ${msg}${RESET_STYLE}" >&2 ;;
        *) echo -e "${COLOR_WHITE}[*] ${msg}${RESET_STYLE}" ;;
    esac
}

command_exists() {
    local cmd="${1:?}"
    local cmd_path
    cmd_path="$(command -v "${cmd}" 2> /dev/null)" && [[ -x ${cmd_path} ]]
}

echo -e "${COLOR_YELLOW}[!] ${STYLE_BOLD}Easily Zwift on linux!${RESET_STYLE}"
echo -e "${COLOR_YELLOW}[!] ${STYLE_UNDERLINE}https://github.com/netbrain/zwift${RESET_STYLE}"

msgbox info "Preparing to build Zwift image"

################################
##### Initialize variables #####

# Initialize system environment variables
readonly DISPLAY="${DISPLAY:-}"
readonly XAUTHORITY="${XAUTHORITY:-}"

# Initialize script constants
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
ZWIFT_UID="${UID}"
ZWIFT_GID="$(id -g)"
readonly SCRIPT_DIR ZWIFT_UID ZWIFT_GID

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

# Update information based on container tool
if [[ ${CONTAINER_TOOL} == "podman" ]]; then
    readonly BUILD_NAME="zwift"
    readonly IMAGE="localhost/zwift"
else
    readonly BUILD_NAME="netbrain/zwift"
    readonly IMAGE="netbrain/zwift"
fi
msgbox info "Image will be called ${IMAGE}"

###############################
##### Basic configuration #####

# Create array for container arguments
declare -a container_args
container_args=(
    -it
    --network bridge
    --name zwift
    --security-opt label=type:container_runtime_t
    --hostname "${HOSTNAME}"

    -e DEBUG="${DEBUG}"
    -e COLORED_OUTPUT="1"
    -e DISPLAY="${DISPLAY}"
    -e CONTAINER_TOOL="${CONTAINER_TOOL}"
    -e ZWIFT_UID="${ZWIFT_UID}"
    -e ZWIFT_GID="${ZWIFT_GID}"

    -v /tmp/.X11-unix:/tmp/.X11-unix
    -v "/run/user/${UID}:/run/user/${ZWIFT_UID}"
)

if [[ ${CONTAINER_TOOL} == "podman" ]]; then
    container_args+=(--userns "keep-id:uid=${ZWIFT_UID},gid=${ZWIFT_GID}")
fi

if [[ -n ${XAUTHORITY} ]]; then
    container_args+=(-e XAUTHORITY="${XAUTHORITY}")
fi

# Check for proprietary nvidia driver and set correct device to use
if [[ -f "/proc/driver/nvidia/version" ]]; then
    if [[ ${CONTAINER_TOOL} == "podman" ]]; then
        container_args+=(--device="nvidia.com/gpu=all")
    else
        container_args+=(--gpus="all")
    fi
else
    container_args+=(--device="/dev/dri:/dev/dri")
fi

#############################################
##### Build container and install Zwift #####

cleanup_invoked=0
cleanup() {
    if [[ ${cleanup_invoked} -ne 1 ]]; then
        msgbox info "Checking for temporary container"
        if ${CONTAINER_TOOL} container rm zwift > /dev/null 2>&1; then
            msgbox ok "Removed temporary container"
        else
            msgbox info "No temporary container to remove"
        fi
        cleanup_invoked=1
    fi
}

trap cleanup EXIT

msgbox info "Building image ${IMAGE}"
if ${CONTAINER_TOOL} build --force-rm -t "${BUILD_NAME}" "${SCRIPT_DIR}"; then
    msgbox ok "Successfully built image ${IMAGE}"
else
    msgbox error "Failed to build image"
    exit 1
fi

msgbox info "Launching temporary container to install Zwift"
if ${CONTAINER_TOOL} run "${container_args[@]}" "${IMAGE}:latest" "${@}"; then
    msgbox ok "Successfully installed Zwift in container"
else
    msgbox error "Failed to start container"
    exit 1
fi

msgbox info "Updating image with changes from temporary container"
if ${CONTAINER_TOOL} commit zwift "${BUILD_NAME}:latest"; then
    msgbox ok "Tagged Zwift container as ${IMAGE}:latest"
else
    msgbox error "Failed to commit container changes to image"
    exit 1
fi

cleanup

########################
##### Launch Zwift #####

export IMAGE
export DONT_CHECK=1
export DONT_PULL=1
export ZWIFT_FG=1

"${SCRIPT_DIR}/zwift.sh"
