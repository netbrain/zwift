#!/usr/bin/env bash
if [ -n "${DEBUG}" ]; then set -x; fi

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
if [[ -f "$HOME/.config/zwift/config" ]]; then
    ZWIFT_CONFIG_FLAG="--env-file $HOME/.config/zwift/config"
    source $HOME/.config/zwift/config
fi

# Check for $USER specific zwift configuration, sourced here and passed on to container aswell
if [[ -f "$HOME/.config/zwift/$USER-config" ]]
then
    ZWIFT_USER_CONFIG_FLAG="--env-file $HOME/.config/zwift/$USER-config"
    source $HOME/.config/zwift/$USER-config
fi

# If a workout directory is specified then map to that directory.
if [[ ! -z $ZWIFT_WORKOUT_DIR ]]; then
    ZWIFT_WORKOUT_VOL="-v $ZWIFT_WORKOUT_DIR:/home/user/.wine/drive_c/users/user/Documents/Zwift/Workouts"
fi

# If an activity directory is specified then map to that directory.
if [[ ! -z $ZWIFT_ACTIVITY_DIR ]]; then
    ZWIFT_ACTIVITY_VOL="-v $ZWIFT_ACTIVITY_DIR:/home/user/.wine/drive_c/users/user/Documents/Zwift/Activities"
fi

# If a log directory is specified then map to that directory.
if [[ ! -z $ZWIFT_LOG_DIR ]]; then
    ZWIFT_LOG_VOL="-v $ZWIFT_LOG_DIR:/home/user/.wine/drive_c/users/user/Documents/Zwift/Logs"
fi

if [[ ! -z $ZWIFT_PROFILE_DIR ]]; then
    ZWIFT_PROFILE_DEST="/home/user/.wine/drive_c/Program\ Files\ \(x86\)/Zwift/data/configs"
    ZWIFT_PROFILE_VOL="--mount dst=$ZWIFT_PROFILE_DEST,volume-opt=device=$ZWIFT_PROFILE_DIR,type=volume,volume-driver=local,volume-opt=type=none,volume-opt=o=bind"
fi

########################################
###### Default Setup and Settings ######
WINDOW_MANAGER="Other"                      # XOrg, XWayland, Wayland, Other
IMAGE=${IMAGE:-docker.io/netbrain/zwift}    # Set the container image to use
VERSION=${VERSION:-latest}                  # The container version
NETWORKING=${NETWORKING:-bridge}            # Default Docker Network is Bridge

ZWIFT_UID=${ZWIFT_UID:-$(id -u)}
ZWIFT_GID=${ZWIFT_GID:-$(id -g)}

# CONTAINER_TOOL, Use podman if available
if [ -z "$CONTAINER_TOOL" ]; then
    if [ -x "$(command -v podman)" ]; then
        CONTAINER_TOOL=podman
    else
        CONTAINER_TOOL=docker
    fi
fi

# get password from SecretService (if username is set but not password)
if [ -n "${ZWIFT_USERNAME}" -a -z "${ZWIFT_PASSWORD}" -a -x "$(command -v secret-tool)" ]; then
    echo "Looking up Zwift password for ${ZWIFT_USERNAME}..."
    PASSWORD_SECRET_NAME="zwift-password-${ZWIFT_USERNAME}"

    secret-tool lookup application zwift username ${ZWIFT_USERNAME} | ${CONTAINER_TOOL} secret create $([ "${CONTAINER_TOOL}" == "podman" ] && echo "--replace=true") "${PASSWORD_SECRET_NAME}" - > /dev/null

    # secret will not be created if the password does not exist
    if ${CONTAINER_TOOL} secret exists "${PASSWORD_SECRET_NAME}"; then
        echo "Passing password to zwift container."
        ZWIFT_PASSWORD_SECRET="--secret ${PASSWORD_SECRET_NAME},type=env,target=ZWIFT_PASSWORD"
    else
        echo "Password not found in the SecretService keyring, you can store it with" \
             "\`secret-tool store --label \"Zwift password for ${ZWIFT_USERNAME}\" application zwift username ${ZWIFT_USERNAME}\`"
    fi
fi

if [ "$CONTAINER_TOOL" == "podman" ]; then
    # Podman has to use container id 1000
    # Local user is mapped to the container id
    LOCAL_UID=$ZWIFT_UID
    LOCAL_GID=$ZWIFT_GID
    CONTAINER_UID=1000
    CONTAINER_GID=1000
else
    # Docker will run as the id's provided.
    LOCAL_UID=$UID
    CONTAINER_UID=$ZWIFT_UID
    CONTAINER_GID=$ZWIFT_GID
fi

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
        msgbox question "You are not running the latest zwift.sh 😭, download? (Default no in 5 seconds)" 5
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
    --rm
    --privileged
    --network $NETWORKING
    --name zwift-$USER
    --security-opt label=disable
    --hostname $HOSTNAME

    -e DISPLAY=$DISPLAY
    -e ZWIFT_UID=$CONTAINER_UID
    -e ZWIFT_GID=$CONTAINER_GID
    -e PULSE_SERVER=/run/user/$CONTAINER_UID/pulse/native

    -v zwift-$USER:/home/user/.wine/drive_c/users/user/Documents/Zwift
    -v /run/user/$LOCAL_UID/pulse:/run/user/$CONTAINER_UID/pulse
)

###################################
##### SPECIFIC CONFIGURATIONS #####

# Check for proprietary nvidia driver and set correct device to use (respects existing VGA_DEVICE_FLAG)
if [[ -z "$VGA_DEVICE_FLAG" ]]; then
    if [[ -f "/proc/driver/nvidia/version" ]]; then
        if [[ $CONTAINER_TOOL == "podman" ]]; then
            VGA_DEVICE_FLAG="--device=nvidia.com/gpu=all"
        else
            VGA_DEVICE_FLAG="--gpus=all"
        fi
    else
        VGA_DEVICE_FLAG="--device=/dev/dri:/dev/dri"
    fi
fi

if [[ -n "$DBUS_SESSION_BUS_ADDRESS" ]]
then
    [[ $DBUS_SESSION_BUS_ADDRESS =~ ^unix:path=([^,]+) ]]

    DBUS_UNIX_SOCKET=${BASH_REMATCH[1]}
    if [[ -n "$DBUS_UNIX_SOCKET" ]]
    then
        DBUS_CONFIG_FLAGS=(
            -e DBUS_SESSION_BUS_ADDRESS=$(echo $DBUS_SESSION_BUS_ADDRESS | sed 's/'$LOCAL_UID'/'$CONTAINER_UID'/')
            -v $DBUS_UNIX_SOCKET:$(echo $DBUS_UNIX_SOCKET | sed 's/'$LOCAL_UID'/'$CONTAINER_UID'/')
        )
    fi
fi

# Setup foreground/background flag
if [[ $ZWIFT_FG -eq "1" ]]
then
    ZWIFT_FG_FLAG=() # run in fg
else
    ZWIFT_FG_FLAG=(-d) # run in bg
fi

# INTERACTIVE mode: force foreground and provide a shell entrypoint for debugging
if [[ -n "$INTERACTIVE" ]]
then
    ZWIFT_FG_FLAG=(-it)
    INTERACTIVE_FLAGS=(--entrypoint bash)
fi

# Setup Flags for Window Managers
if [ $WINDOW_MANAGER == "Wayland" ]; then
    WM_FLAGS=(
        -e WINE_EXPERIMENTAL_WAYLAND=1
        -e XDG_RUNTIME_DIR=/run/user/$CONTAINER_UID
        -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY

        -v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:$(echo $XDG_RUNTIME_DIR | sed 's/'$LOCAL_UID'/'$CONTAINER_UID'/')/$WAYLAND_DISPLAY
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
            -e XAUTHORITY=$(echo $XAUTHORITY | sed 's/'$LOCAL_UID'/'$CONTAINER_UID'/')

            -v /tmp/.X11-unix:/tmp/.X11-unix
            -v $XAUTHORITY:$(echo $XAUTHORITY | sed 's/'$LOCAL_UID'/'$CONTAINER_UID'/')
        )
    fi
fi

if [ $WINDOW_MANAGER == "XOrg" ]; then
    unset WINE_EXPERIMENTAL_WAYLAND
fi


# Initiate podman Volume with correct permissions
if [ "$CONTAINER_TOOL" == "podman" ]; then
    # Create a volume if not already exists, this is done now as
    # if left to the run command the directory can get the wrong permissions
    if [[ -z $(podman volume ls | grep zwift-$USER) ]]; then
        $CONTAINER_TOOL volume create zwift-$USER
    fi

    GENERAL_FLAGS+=(
        --userns keep-id:uid=$CONTAINER_UID,gid=$CONTAINER_GID
    )
fi

# Read the user specified extra flags if any
read -r -a CONTAINER_EXTRA_FLAGS <<< "$CONTAINER_EXTRA_ARGS"

# Normalize single-string flags into arrays for safe command construction
read -r -a ZWIFT_CONFIG_FLAG_ARR <<< "$ZWIFT_CONFIG_FLAG"
read -r -a ZWIFT_PASSWORD_SECRET_ARR <<< "$ZWIFT_PASSWORD_SECRET"
read -r -a ZWIFT_USER_CONFIG_FLAG_ARR <<< "$ZWIFT_USER_CONFIG_FLAG"
read -r -a ZWIFT_WORKOUT_VOL_ARR <<< "$ZWIFT_WORKOUT_VOL"
read -r -a ZWIFT_ACTIVITY_VOL_ARR <<< "$ZWIFT_ACTIVITY_VOL"
read -r -a ZWIFT_LOG_VOL_ARR <<< "$ZWIFT_LOG_VOL"
read -a ZWIFT_PROFILE_VOL_ARR <<< "$ZWIFT_PROFILE_VOL"
read -r -a VGA_DEVICE_FLAG_ARR <<< "$VGA_DEVICE_FLAG"
POSITIONAL_ARGS=("$@")

#########################
##### RUN CONTAINER #####
CMD=(
    "$CONTAINER_TOOL" run
    "${GENERAL_FLAGS[@]}"
    "${ZWIFT_FG_FLAG[@]}"
    "${ZWIFT_CONFIG_FLAG_ARR[@]}"
    "${ZWIFT_PASSWORD_SECRET_ARR[@]}"
    "${ZWIFT_USER_CONFIG_FLAG_ARR[@]}"
    "${ZWIFT_WORKOUT_VOL_ARR[@]}"
    "${ZWIFT_ACTIVITY_VOL_ARR[@]}"
    "${ZWIFT_LOG_VOL_ARR[@]}"
    "${ZWIFT_PROFILE_VOL_ARR[@]}"
    "${VGA_DEVICE_FLAG_ARR[@]}"
    "${DBUS_CONFIG_FLAGS[@]}"
    "${WM_FLAGS[@]}"
    "${CONTAINER_EXTRA_FLAGS[@]}"
    "${INTERACTIVE_FLAGS[@]}"
    "${POSITIONAL_ARGS[@]}"
    "$IMAGE:$VERSION"
)

# DRYRUN: print the exact command that would be executed, then exit
if [[ -n "$DRYRUN" ]]; then
    echo "DRYRUN: would execute:"
    printf '%q ' "${CMD[@]}"
    echo
    exit 0
fi

# Execute: interactive (-it) should not be captured
if [[ " ${ZWIFT_FG_FLAG[*]} " == *" -it "* ]]; then
    # In interactive mode we don't have a container ID to run xhost against later.
    # If using X11/XWayland, show instructions so users can enable X access manually.
    if [ -x "$(command -v xhost)" ] && [ -z $WINE_EXPERIMENTAL_WAYLAND ]; then
        echo "INTERACTIVE mode: xhost is not automatically enabled for this container."
        echo "If you need X11 apps inside the container to display, run this in another terminal:"
        echo "  xhost +local:$HOSTNAME"
        echo "After you're done, you can revoke access with:"
        echo "  xhost -local:$HOSTNAME"
    fi
    "${CMD[@]}"
    RC=$?
else
    CONTAINER=$("${CMD[@]}")
    RC=$?
fi

if [ $RC -ne 0 ]; then
    msgbox error "Error can't run zwift, check variables!" 10
    exit 0
fi

# Allow container to connect to X, has to be set for different UID
if [ -n "$CONTAINER" ] && [ -x "$(command -v xhost)" ] && [ -z $WINE_EXPERIMENTAL_WAYLAND ]; then
    xhost +local:$($CONTAINER_TOOL inspect --format='{{ .Config.Hostname  }}' $CONTAINER)
fi
