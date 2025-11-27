#!/usr/bin/env bash
set -x

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
ZWIFT_UID=$(id -u)
ZWIFT_GID=$(id -g)

# Use podman if available
if [[ ! $CONTAINER_TOOL ]]; then
    if [[ -x "$(command -v podman)" ]]; then
        CONTAINER_TOOL="podman"
    else
        CONTAINER_TOOL="docker"
    fi
fi

# Update information based on Container Tool
if [[ "$CONTAINER_TOOL" == "podman" ]]; then
    BUILD_NAME="zwift"
    IMAGE="localhost/zwift"
else
    BUILD_NAME="netbrain/zwift"
    IMAGE="netbrain/zwift"
fi

GENERAL_FLAGS=(
    -it
    --network bridge
    --name zwift
    --security-opt label=type:container_runtime_t
    --device /dev/dri
    --hostname "$HOSTNAME"

    -e DISPLAY="$DISPLAY"
    -e CONTAINER="$CONTAINER_TOOL"
    -e WINE_EXPERIMENTAL_WAYLAND=1
    -e XDG_RUNTIME_DIR="/run/user/$ZWIFT_UID"
    -e WAYLAND_DISPLAY="$WAYLAND_DISPLAY"

    -v /run/user/$UID:"/run/user/$ZWIFT_UID"
    -v "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY":"$XDG_RUNTIME_DIR/$ZWIFT_UID/$WAYLAND_DISPLAY"
)

# Check for proprietary nvidia driver and set correct device to use
if [[ -f "/proc/driver/nvidia/version" ]]; then
    if [[ $CONTAINER_TOOL == "podman" ]]; then
        VGA_DEVICE_FLAG=("--device=nvidia.com/gpu=all")
    else
        VGA_DEVICE_FLAG=("--gpus=all")
    fi
else
    VGA_DEVICE_FLAG=("--device=/dev/dri:/dev/dri")
fi

# Initiate podman Volume with correct permissions
if [[ "$CONTAINER_TOOL" == "podman" ]]; then
    # Add ipc host to deal with an SHM issue on some machines.
    PODMAN_FLAGS=(--userns "keep-id:uid=$ZWIFT_UID,gid=$ZWIFT_GID")
fi

# Cleanup on error
trap cleanup ERR
cleanup()
{
    $CONTAINER_TOOL container rm zwift
    exit
}

$CONTAINER_TOOL build --force-rm -t "$BUILD_NAME" "$SCRIPT_DIR/../."
$CONTAINER_TOOL run "${GENERAL_FLAGS[@]}" \
    "${VGA_DEVICE_FLAG[@]}" \
    "${PODMAN_FLAGS[@]}" \
    "$IMAGE:latest" \
    "$@"
$CONTAINER_TOOL commit zwift "$BUILD_NAME:latest"
$CONTAINER_TOOL container rm zwift

export IMAGE="$IMAGE"
export DONT_PULL=1
export WINE_EXPERIMENTAL_WAYLAND=1
"$SCRIPT_DIR/../zwift.sh"
