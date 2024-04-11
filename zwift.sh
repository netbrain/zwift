#!/usr/bin/env bash
set -x

### DEFAULT CONFIGURATION ###

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

# Check for proprietary nvidia driver and set correct device to use
if [[ -f "/proc/driver/nvidia/version" ]]
then
    if [[ $CONTAINER_TOOL == "podman" ]]
    then
        VGA_DEVICE_FLAG="--device=nvidia.com/gpu=all"
    else 
        VGA_DEVICE_FLAG="--gpus all"
    fi
else
    VGA_DEVICE_FLAG="--device /dev/dri:/dev/dri"
fi

### OVERRIDE CONFIGURATION FROM FILE ###

# Check for other zwift configuration, sourced here and passed on to container aswell
if [[ -f "$HOME/.config/zwift/config" ]]
then
    ZWIFT_CONFIG_FLAG="--env-file $HOME/.config/zwift/config"
    source $HOME/.config/zwift/config
fi

# Check for $USER specific zwift configuration, sourced here and passed on to container aswell
if [[ -f "$HOME/.config/zwift/$USER-config" ]]
then
    ZWIFT_USER_CONFIG_FLAG="--env-file $HOME/.config/zwift/config"
    source $HOME/.config/zwift/config
fi

# Check for updated zwift.sh
if [[ ! $DONT_CHECK ]]
then
    REMOTE_SUM=$(curl -s https://raw.githubusercontent.com/netbrain/zwift/master/zwift.sh | sha256sum | awk '{print $1}')
    THIS_SUM=$(sha256sum $0 | awk '{print $1}')

    # Compare the checksums
    if [ "$REMOTE_SUM" = "$THIS_SUM" ]; then
        echo "You are running latest zwift.sh 👏"
    else
        echo "You are not running the latest zwift.sh 😭, please update!"
    fi
fi

# Check for updated container image
if [[ ! $DONT_PULL ]]
then
    $CONTAINER_TOOL pull $IMAGE:$VERSION
fi

### START ###

# Start the zwift container
CONTAINER=$($CONTAINER_TOOL run \
    -d \
    --rm \
    --privileged \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v /run/user/$UID/pulse:/run/user/1000/pulse \
    -v zwift-$USER:/home/user/.wine/drive_c/users/user/Documents/Zwift \
    $([ "$CONTAINER_TOOL" = "podman" ] && echo '--userns=keep-id') \
    $ZWIFT_CONFIG_FLAG \
    $ZWIFT_USER_CONFIG_FLAG \
    $VGA_DEVICE_FLAG \
    $IMAGE:$VERSION)

if [[ -z $WAYLAND_DISPLAY ]]
then
    # Allow container to connect to X
    xhost +local:$($CONTAINER_TOOL inspect --format='{{ .Config.Hostname  }}' $CONTAINER)
fi
