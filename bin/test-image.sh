#!/usr/bin/env bash
set -x
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Use podman if available
if [[ ! $CONTAINER_TOOL ]]
then
    if [[ -x "$(command -v podman)" ]]
    then
        CONTAINER_TOOL=podman
    else
        CONTAINER_TOOL=docker
    fi
fi

GENERAL_FLAGS=(
    -it
    --privileged
    --network bridge
    --name zwift
    --security-opt label=disable

    -e DISPLAY=$DISPLAY
    -e XAUTHORITY=$XAUTHORITY

    -v /tmp/.X11-unix:/tmp/.X11-unix
)


# Check for proprietary nvidia driver and set correct device to use
if [[ -f "/proc/driver/nvidia/version" ]]
then
    VGA_DEVICE_FLAG="--gpus all"
else
    VGA_DEVICE_FLAG="--device /dev/dri:/dev/dri"
fi

# Initiate podman Volume with correct permissions
if [[ "$CONTAINER_TOOL" == "podman" ]]
then
    # Create a volume if not already exists, this is done now as
    # if left to the run command the directory can get the wrong permissions
    if [[ -z $(podman volume ls | grep zwift-$USER) ]]
    then
        $CONTAINER_TOOL volume create zwift-$USER 
    fi
    
    PODMAN_FLAGS=(
        --userns keep-id
    )
fi

$CONTAINER_TOOL build --force-rm -t zwift $SCRIPT_DIR/../.
$CONTAINER_TOOL run ${GENERAL_FLAGS[@]} \
    $VGA_DEVICE_FLAG \
    ${PODMAN_FLAGS[@]} \
    localhost/zwift:latest

$CONTAINER_TOOL commit zwift zwift:latest
