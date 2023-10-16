#!/usr/bin/env bash
set -x

# zoffline IP
ZOFFLINE_IP="127.0.0.1"

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
    --add-host="cdn.zwift.com:$ZOFFLINE_IP" \
    --add-host="secure.zwift.com:$ZOFFLINE_IP" \
    --add-host="us-or-rly101.zwift.com:$ZOFFLINE_IP" \
    --add-host="launcher.zwift.com:$ZOFFLINE_IP" \
    --network=host \
    $([ "$CONTAINER_TOOL" = "podman" ] && echo '--userns=keep-id') \
    $VGA_DEVICE_FLAG \
    zoffline-client)

if [[ -z $WAYLAND_DISPLAY ]]
then
    # Allow container to connect to X
    xhost +local:$($CONTAINER_TOOL inspect --format='{{ .Config.Hostname  }}' $CONTAINER)
fi
