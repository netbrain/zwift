#!/usr/bin/env bash
if [ ! -z $DEBUG ]; then set -x; fi

# Message Box to simplify errors/ and questions.
msgbox() {
    TYPE=$1             # Type, info, warning or error
    MSG="$2"            # Message to Display
    TIMEOUT=${3:-0}     # Timeout for message, default no timeout.

    RED='\033[0;31m'
    NC='\033[0m'
    BOLD='\033[1m'
    UNDERLINE='\033[4m'

    case $1 in
        error) echo -e "${RED}${BOLD}${UNDERLINE}Error - $MSG${NC}";;
        warning) echo -e "${BOLD}${UNDERLINE}Warning - $MSG${NC}";;
        question)
            if [ $TIMEOUT -ne 0 ]; then TIMEOUT="-t $TIMEOUT"; else TIMEOUT=""; fi

            echo -n -e "${RED}${BOLD}${UNDERLINE}Question - $MSG (y/n)${NC}"
            read $TIMEOUT -n 1 -p " " yn
            echo
            case $yn in 
                y) return 0;;
                n) return 1;;
                *) return 5;;
            esac
        ;;
        *) echo "$MSG";;
    esac
    if [ $TIMEOUT -eq 0 ]; then
        read -p "Press key to continue.. " -n1 -s
    else
        sleep $TIMEOUT
    fi
}

#########################################################
# Config early to allow setting of startup env files.
# More ease of use starting from desktop icon.

# Check for other zwift configuration, sourced here and passed on to container aswell
if [[ -f "$HOME/.config/zwift/config" ]]
then
    ZWIFT_CONFIG_FLAG="--env-file $HOME/.config/zwift/config"
    source $HOME/.config/zwift/config
fi

# Check for $USER specific zwift configuration, sourced here and passed on to container aswell
if [[ -f "$HOME/.config/zwift/$USER-config" ]]
then
    ZWIFT_USER_CONFIG_FLAG="--env-file $HOME/.config/zwift/$USER-config"
    source $HOME/.config/zwift/$USER-config
fi

########################################
###### Default Setup and Settings ######
WINDOW_MANAGER="Other"                      # XOrg, XWayland, Wayland, Other
IMAGE=${IMAGE:-docker.io/netbrain/zwift}    # Set the container image to use
VERSION=${VERSION:-latest}                  # The container version
NETWORKING=${NETWORKING:-bridge}            # Default Docker Network is Bridge

# CONTAINER_TOOL, Use podman if available
if [ ! $CONTAINER_TOOL ]; then
    if [ -x "$(command -v podman)" ]; then
        CONTAINER_TOOL=podman
    else
        CONTAINER_TOOL=docker
    fi
fi

ZWIFT_UID=${ZWIFT_UID:-$(id -u)}
ZWIFT_GID=${ZWIFT_GID:-$(id -g)}

########################################
###### OS and WM Manager Settings ######
case "$XDG_SESSION_TYPE" in
    "wayland")
        WINDOW_MANAGER="Wayland"
    ;;
    "x11")
        WINDOW_MANAGER="XOrg"
    ;;
    *)
        if [ ! -z $WAYLAND_DISPLAY ]; then
            WINDOW_MANAGER="Wayland"
        elif [ ! -z $DISPLAY ]; then
            WINDOW_MANAGER="XOrg"
        fi
    ;;
esac

# Verify which system we are using for wayland and some checks.
if [ "$WINDOW_MANAGER" = "Wayland" ]; then
    # System is using wayland or xwayland.
    if [ -z $WINE_EXPERIMENTAL_WAYLAND ]; then 
        WINDOW_MANAGER="XWayland"
    else
        WINDOW_MANAGER="Wayland"
    fi

    # ZWIFT_UID does not work on XWayland, show warning
    if [ $ZWIFT_UID -ne $(id -u) ]; then
        msgbox warning "Wayland does not support ZWIFT_UID different to your id of $(id -u), may not start." 5
    fi
fi

#######################################
###### UPD SCRIPTS and CONTAINER ######

# Check for updated zwift.sh
if [[ ! $DONT_CHECK ]]
then
    REMOTE_SUM=$(curl -s https://raw.githubusercontent.com/netbrain/zwift/master/zwift.sh | sha256sum | awk '{print $1}')
    THIS_SUM=$(sha256sum $0 | awk '{print $1}')

    # Compare the checksums
    if [ "$REMOTE_SUM" = "$THIS_SUM" ]; then
        echo "You are running latest zwift.sh 👏"
    else
        # Ask with Timeout, default is do not update.
        msgbox question "You are not running the latest zwift.sh 😭, (Default no in 5 seconds)" 5
        if [ $? -eq 0 ]; then
            pkexec env PATH=$PATH bash -c "$(curl -fsSL https://raw.githubusercontent.com/netbrain/zwift/master/bin/install.sh)"
            exec "$0" "${@}"
        fi
    fi
fi

# Check for updated container image
if [[ ! $DONT_PULL ]]
then
    $CONTAINER_TOOL pull $IMAGE:$VERSION
fi

#############################
##### PREPARE ALL FLAGS #####

# Define Base Container Parameters
GENERAL_FLAGS=(
    -d
    --rm
    --privileged
    --network $NETWORKING
    --name zwift-$USER
    --security-opt label=disable
    --hostname $HOSTNAME

    -e DISPLAY=$DISPLAY
    -e ZWIFT_UID=$ZWIFT_UID
    -e ZWIFT_GID=$ZWIFT_GID
    -e PULSE_SERVER=/run/user/$ZWIFT_UID/pulse/native

    -v zwift-$USER:/home/user/.wine/drive_c/users/user/Documents/Zwift
    -v /run/user/$UID/pulse:/run/user/$ZWIFT_UID/pulse
)

###################################
##### SPECIFIC CONFIGURATIONS #####

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

# Setup Flags for Window Managers
if [ $WINDOW_MANAGER == "Wayland" ]; then
    WM_FLAGS=(
        -e WINE_EXPERIMENTAL_WAYLAND=1
        -e XDG_RUNTIME_DIR=/run/user/$ZWIFT_UID
        -e $WAYLAND_DISPLAY=$WAYLAND_DISPLAY

        -v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:$(echo $XDG_RUNTIME_DIR | sed 's/'$UID'/'$ZWIFT_UID'/')/$WAYLAND_DISPLAY
    )
fi

if [ $WINDOW_MANAGER == "XWayland" ] || [ $WINDOW_MANAGER == "XOrg" ]; then
    # If not XAuthority set then don't pass, hyprland is one that does not use it.
    if [ -z $XAUTHORITY ]; then
        WM_FLAGS=(
            -v /tmp/.X11-unix:/tmp/.X11-unix
        )
    else
        WM_FLAGS=(
            -e XAUTHORITY=$(echo $XAUTHORITY | sed 's/'$UID'/'$ZWIFT_UID'/')

            -v /tmp/.X11-unix:/tmp/.X11-unix
            -v $XAUTHORITY:$(echo $XAUTHORITY | sed 's/'$UID'/'$ZWIFT_UID'/')
        )
    fi
fi

if [ $WINDOW_MANAGER == "XOrg" ]; then
    unset WINE_EXPERIMENTAL_WAYLAND
fi

# Initiate podman Volume with correct permissions
if [ $CONTAINER_TOOL == "podman" ]; then
    # Create a volume if not already exists, this is done now as
    # if left to the run command the directory can get the wrong permissions
    if [[ -z $(podman volume ls | grep zwift-$USER) ]]; then
        $CONTAINER_TOOL volume create zwift-$USER
    fi

    PODMAN_FLAGS=(
        --userns keep-id:uid=$ZWIFT_UID,gid=$ZWIFT_GID
    )
fi

#########################
##### RUN CONTAINER #####
CONTAINER=$($CONTAINER_TOOL run ${GENERAL_FLAGS[@]} \
        $ZWIFT_CONFIG_FLAG \
        $ZWIFT_USER_CONFIG_FLAG \
        $VGA_DEVICE_FLAG \
        ${DBUS_CONFIG_FLAGS[@]} \
        ${WM_FLAGS[@]} \
        ${PODMAN_FLAGS[@]} \
        $IMAGE:$VERSION $@
)
if [ $? -ne 0 ]; then
    msgbox error "Error can't run zwift, check variables!" 10
    exit 0
fi

# Allow container to connect to X, has to be set for different UID
if [ -x "$(command -v xhost)" ] && [ $ZWIFT_UID -ne $(id -u) ] && [ -z $WINE_EXPERIMENTAL_WAYLAND ]; then
    xhost +local:$($CONTAINER_TOOL inspect --format='{{ .Config.Hostname  }}' $CONTAINER)
fi
