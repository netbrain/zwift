#!/usr/bin/env bash
set -x

# Set the container image to use
IMAGE=${IMAGE:-docker.io/netbrain/zwift}

# The container version
VERSION=${VERSION:-latest}

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

# Check for updated container image
if [[ ! $DONT_PULL ]]
then
    $CONTAINER_TOOL pull $IMAGE:$VERSION
fi

# Check for proprietary nvidia driver and set correct device to use
if [[ -f "/proc/driver/nvidia/version" ]]
then
    VGA_DEVICE_FLAG="--gpus all"
else
    VGA_DEVICE_FLAG="--device /dev/dri:/dev/dri"
fi


# Start the zwift container
CONTAINER=$($CONTAINER_TOOL run \
    -d \
    --rm \
    --privileged \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v /run/user/$UID/pulse:/run/user/1000/pulse \
    -v zwift-$USER:/home/user/Zwift \
    $([ "$CONTAINER_TOOL" = "podman" ] && echo '--userns=keep-id') \
    $VGA_DEVICE_FLAG \
    $IMAGE:$VERSION)

if [[ -z $WAYLAND_DISPLAY ]]
then
    # Allow container to connect to X
    xhost +local:$($CONTAINER_TOOL inspect --format='{{ .Config.Hostname  }}' $CONTAINER)
fi
