#!/usr/bin/env bash

readonly DEBUG="${DEBUG:-0}"
if [[ ${DEBUG} -eq 1 ]]; then set -x; fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
ZWIFT_UID="$(id -u)"
ZWIFT_GID="$(id -g)"
readonly SCRIPT_DIR ZWIFT_UID ZWIFT_GID

# Use podman if available
if [[ -z ${CONTAINER_TOOL} ]]; then
    if [[ -x "$(command -v podman)" ]]; then
        CONTAINER_TOOL="podman"
    else
        CONTAINER_TOOL="docker"
    fi
fi
readonly CONTAINER_TOOL

# Update information based on Container Tool
if [[ ${CONTAINER_TOOL} == "podman" ]]; then
    readonly BUILD_NAME="zwift"
    readonly IMAGE="localhost/zwift"
else
    readonly BUILD_NAME="netbrain/zwift"
    readonly IMAGE="netbrain/zwift"
fi

declare -a container_args
container_args=(
    -it
    --network bridge
    --name zwift
    --security-opt label=type:container_runtime_t
    --device /dev/dri
    --hostname "${HOSTNAME}"

    -e DISPLAY="${DISPLAY}"
    -e XAUTHORITY="${XAUTHORITY}"
    -e CONTAINER_TOOL="${CONTAINER_TOOL}"

    -v /tmp/.X11-unix:/tmp/.X11-unix
    -v "/run/user/${UID}:/run/user/${ZWIFT_UID}"
)

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

# Initiate podman volume with correct permissions
if [[ ${CONTAINER_TOOL} == "podman" ]]; then
    # Add ipc host to deal with an SHM issue on some machines.
    container_args+=(--userns "keep-id:uid=${ZWIFT_UID},gid=${ZWIFT_GID}")
fi

# Cleanup on error
trap cleanup ERR
cleanup() {
    ${CONTAINER_TOOL} container rm zwift
    exit 1
}

${CONTAINER_TOOL} build --force-rm -t "${BUILD_NAME}" "${SCRIPT_DIR}"
${CONTAINER_TOOL} run "${container_args[@]}" "${IMAGE}:latest" "${@}"
${CONTAINER_TOOL} commit zwift "${BUILD_NAME}:latest"
${CONTAINER_TOOL} container rm zwift

export IMAGE
export DONT_CHECK=1
export DONT_PULL=1
"${SCRIPT_DIR}/zwift.sh"
