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

NETWORKING=${NETWORKING:-bridge}

# If we are running wayland and ZWIFT_UID provided exit
if [ ! -z $ZWIFT_UID ] || [ ! -z $ZWIFT_GID ]; then
    if [ ! -z $WAYLAND_DISPLAY ]; then 
        echo "Wayland not supported with ZWIFT_UID/ ZWIFT_GID"
        exit 0
    fi
fi

ZWIFT_UID=${ZWIFT_UID:-$(id -u)}
ZWIFT_GID=${ZWIFT_GID:-$(id -g)}

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

# Define Base Container Parameters
GENERAL_FLAGS=(
    -d
    --rm
    --privileged
    --network $NETWORKING
    --name zwift-$USER
    --security-opt label=disable

    -e DISPLAY=$DISPLAY
    -e WINE_EXPERIMENTAL_WAYLAND=$WINE_EXPERIMENTAL_WAYLAND
    -e ZWIFT_UID=$ZWIFT_UID
    -e ZWIFT_GID=$ZWIFT_GID
    -e XAUTHORITY=$(echo $XAUTHORITY | sed 's/'$UID'/'$ZWIFT_UID'/')

    -v /tmp/.X11-unix:/tmp/.X11-unix
    -v /run/user/$UID/pulse:/run/user/$ZWIFT_UID/pulse
    -v zwift-$USER:/home/user/.wine/drive_c/users/user/Documents/Zwift
)

### UPD SCRIPTS and CONTAINER ###
# Check for updated zwift.sh
if [[ ! $DONT_CHECK ]]
then
    REMOTE_SUM=$(curl -s https://raw.githubusercontent.com/netbrain/zwift/master/zwift.sh | sha256sum | awk '{print $1}')
    THIS_SUM=$(sha256sum $0 | awk '{print $1}')

    # Compare the checksums
    if [ "$REMOTE_SUM" = "$THIS_SUM" ]; then
        echo "You are running latest zwift.sh 👏"
    else
        RED='\033[0;31m'
        NC='\033[0m'
        BOLD='\033[1m'
        UNDERLINE='\033[4m'
        echo -e "${RED}${BOLD}${UNDERLINE}You are not running the latest zwift.sh 😭, please update!${NC}"
        sleep 5
    fi
fi

# Check for updated container image
if [[ ! $DONT_PULL ]]
then
    $CONTAINER_TOOL pull $IMAGE:$VERSION
fi


### SPECIFIC CONFIGURATIONS ###

# Check for proprietary nvidia driver and set correct device to use
if [[ -f "/proc/driver/nvidia/version" ]]
then
    if [[ $CONTAINER_TOOL == "podman" ]]
    then
    	VGA_DEVICE_FLAG="--device=nvidia.com/gpu=all"
    else
    	VGA_DEVICE_FLAG="--gpus=all"
    fi
else
    VGA_DEVICE_FLAG="--device=/dev/dri:/dev/dri"
fi

if [[ -n "$DBUS_SESSION_BUS_ADDRESS" ]]
then
    [[ $DBUS_SESSION_BUS_ADDRESS =~ ^unix:path=([^,]+) ]]

    DBUS_UNIX_SOCKET=${BASH_REMATCH[1]}
    if [[ -n "$DBUS_UNIX_SOCKET" ]]
    then
        DBUS_CONFIG_FLAGS=(
            -e DBUS_SESSION_BUS_ADDRESS=$(echo $DBUS_SESSION_BUS_ADDRESS | sed 's/'$UID'/'$ZWIFT_UID'/')
            -v $DBUS_UNIX_SOCKET:$(echo $DBUS_UNIX_SOCKET | sed 's/'$UID'/'$ZWIFT_UID'/')
        )
    fi
fi

# Setup Wayland Usage.
if [[ ! -z $WAYLAND_DISPLAY ]]
then
    if [[ ! -z $WINE_EXPERIMENTAL_WAYLAND ]]
    then
        # Using Experimental Wayland, setup required parameters
        # To force wayland DISPLAY must be blank.
        WAYLAND_FLAGS=(
            -e XDG_RUNTIME_DIR=/run/user/$ZWIFT_UID 
            -e PULSE_SERVER=/run/user/$ZWIFT_UID/pulse/native
            -e WINE_EXPERIMENTAL_WAYLAND=1
        )
    else

        WAYLAND_FLAGS=(
            -e PULSE_SERVER=/run/user/$ZWIFT_UID/pulse/native
            -v $XAUTHORITY:$(echo $XAUTHORITY | sed 's/'$UID'/'$ZWIFT_UID'/')
        )
    fi
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
        --userns keep-id:uid=$ZWIFT_UID,gid=$ZWIFT_GID
    )
fi

CONTAINER=$($CONTAINER_TOOL run ${GENERAL_FLAGS[@]} \
        $ZWIFT_CONFIG_FLAG \
        $ZWIFT_USER_CONFIG_FLAG \
        $VGA_DEVICE_FLAG \
        ${DBUS_CONFIG_FLAGS[@]} \
        ${WAYLAND_FLAGS[@]} \
        ${PODMAN_FLAGS[@]} \
        $IMAGE:$VERSION $@
)

# Allow container to connect to X, has to be set for different UID
if [[ -z $WAYLAND_DISPLAY && $ZWIFT_UID -ne $(id -u) ]]
then
    xhost +local:$($CONTAINER_TOOL inspect --format='{{ .Config.Hostname  }}' $CONTAINER)
fi
