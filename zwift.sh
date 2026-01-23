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

    case $TYPE in
        error) echo -e "${RED}${BOLD}${UNDERLINE}Error - $MSG${NC}";;
        warning) echo -e "${BOLD}${UNDERLINE}Warning - $MSG${NC}";;
        question)
            echo -n -e "${RED}${BOLD}${UNDERLINE}Question - $MSG (y/n)${NC}"
            if [[ $TIMEOUT -ne 0 ]]; then
                read -r -t "$TIMEOUT" -n 1 -p " " yn
            else
                read -r -n 1 -p " " yn
            fi
            echo
            case $yn in
                y) return 0;;
                n) return 1;;
                *) return 5;;
            esac
        ;;
        *) echo -e "${BOLD}Info - $MSG${NC}";;
    esac
    if [[ $TIMEOUT -eq 0 ]]; then
        read -r -p "Press key to continue.. " -n1 -s
    else
        sleep "$TIMEOUT"
    fi
}

#########################################################
# Config early to allow setting of startup env files.
# More ease of use starting from desktop icon.

# Check for other zwift configuration, sourced here and passed on to container as well
if [[ -f "$HOME/.config/zwift/config" ]]; then
    ZWIFT_CONFIG_FLAG="--env-file $HOME/.config/zwift/config"
    # shellcheck source=/dev/null
    source "$HOME/.config/zwift/config"
fi

# Check for $USER specific zwift configuration, sourced here and passed on to container as well
if [[ -f "$HOME/.config/zwift/$USER-config" ]]; then
    ZWIFT_USER_CONFIG_FLAG="--env-file $HOME/.config/zwift/$USER-config"
    # shellcheck source=/dev/null
    source "$HOME/.config/zwift/$USER-config"
fi

# If a workout directory is specified then map to that directory.
if [[ -n $ZWIFT_WORKOUT_DIR ]]; then
    ZWIFT_WORKOUT_VOL="-v $ZWIFT_WORKOUT_DIR:/home/user/.wine/drive_c/users/user/Documents/Zwift/Workouts"
fi

# If an activity directory is specified then map to that directory.
if [[ -n $ZWIFT_ACTIVITY_DIR ]]; then
    ZWIFT_ACTIVITY_VOL="-v $ZWIFT_ACTIVITY_DIR:/home/user/.wine/drive_c/users/user/Documents/Zwift/Activities"
fi

# If a log directory is specified then map to that directory.
if [[ -n $ZWIFT_LOG_DIR ]]; then
    ZWIFT_LOG_VOL="-v $ZWIFT_LOG_DIR:/home/user/.wine/drive_c/users/user/Documents/Zwift/Logs"
fi

# If a screenshots directory is specified then map to that directory.
if [[ -n $ZWIFT_SCREENSHOTS_DIR ]]; then
    ZWIFT_SCREENSHOTS_VOL="-v $ZWIFT_SCREENSHOTS_DIR:/home/user/.wine/drive_c/users/user/Pictures/Zwift"
fi

# If overriding zwift graphics then map custom config to the graphics profiles.
if [[ $ZWIFT_OVERRIDE_GRAPHICS -eq "1" ]]; then
    ZWIFT_GRAPHICS_CONFIG="$HOME/.config/zwift/graphics.txt"

    # Check for $USER specific graphics config file.
    ZWIFT_USER_GRAPHICS_CONFIG="$HOME/.config/zwift/$USER-graphics.txt"
    if [ -f "$ZWIFT_USER_GRAPHICS_CONFIG" ]; then
        ZWIFT_GRAPHICS_CONFIG="$ZWIFT_USER_GRAPHICS_CONFIG"
    # Create graphics.txt file if it does not exist.
    elif [ ! -f "$ZWIFT_GRAPHICS_CONFIG" ]; then
        mkdir -p "$HOME/.config/zwift"
        echo -e "res 1920x1080(0x)\nsres 2048x2048\nset gSSAO=1\nset gFXAA=1\nset gSunRays=1\nset gHeadlight=1\nset gFoliagePercent=1.0\nset gSimpleReflections=0\nset gLODBias=0\nset gShowFPS=0" > "$ZWIFT_GRAPHICS_CONFIG"
        msgbox info "Created $ZWIFT_GRAPHICS_CONFIG with default values, edit this file to tweak the zwift graphics settings."
    fi

    # Override all zwift graphics profiles with the custom config file.
    ZWIFT_PROFILE_VOL_ARR=(
        -v "$ZWIFT_GRAPHICS_CONFIG":/home/user/.wine/drive_c/Program\ Files\ \(x86\)/Zwift/data/configs/basic.txt:ro
        -v "$ZWIFT_GRAPHICS_CONFIG":/home/user/.wine/drive_c/Program\ Files\ \(x86\)/Zwift/data/configs/medium.txt:ro
        -v "$ZWIFT_GRAPHICS_CONFIG":/home/user/.wine/drive_c/Program\ Files\ \(x86\)/Zwift/data/configs/high.txt:ro
        -v "$ZWIFT_GRAPHICS_CONFIG":/home/user/.wine/drive_c/Program\ Files\ \(x86\)/Zwift/data/configs/ultra.txt:ro
    )
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

# Lookup zwift password and create secret to pass to the container
if [ -n "$ZWIFT_USERNAME" ]; then
    echo "Looking up Zwift password for $ZWIFT_USERNAME..."
    PASSWORD_SECRET_NAME="zwift-password-$ZWIFT_USERNAME"

    # ZWIFT_PASSWORD not set, check if secret already exists or if password is stored in secret-tool
    if [ -z "$ZWIFT_PASSWORD" ]; then
        if $CONTAINER_TOOL secret inspect "$PASSWORD_SECRET_NAME" &> /dev/null; then
            echo "Password found in $CONTAINER_TOOL secret store"
            HAS_PASSWORD_SECRET="1"
        elif [ -x "$(command -v secret-tool)" ]; then
            echo "Looking for password in secret-tool (application zwift username $ZWIFT_USERNAME)"
            ZWIFT_PASSWORD=$(secret-tool lookup application zwift username "$ZWIFT_USERNAME")
        fi
    fi

    # ZWIFT_PASSWORD set or found in secret-tool, create/update secret
    if [ -n "$ZWIFT_PASSWORD" ]; then
        HAS_PLAINTEXT_PASSWORD="1"
        if echo "$ZWIFT_PASSWORD" | $CONTAINER_TOOL secret create "$([ "$CONTAINER_TOOL" == "podman" ] && echo "--replace=true")" "$PASSWORD_SECRET_NAME" - > /dev/null; then
            echo "Stored password in $CONTAINER_TOOL secret store"
            HAS_PASSWORD_SECRET="1"
        fi
    fi

    # prefer passing secret, otherwise pass ZWIFT_PASSWORD as plain text
    ZWIFT_USERNAME_FLAG="-e ZWIFT_USERNAME=$ZWIFT_USERNAME"
    if [[ $HAS_PASSWORD_SECRET -eq "1" ]]; then
        ZWIFT_PASSWORD_SECRET="--secret $PASSWORD_SECRET_NAME,type=env,target=ZWIFT_PASSWORD"
    elif [[ $HAS_PLAINTEXT_PASSWORD -eq "1" ]]; then
        ZWIFT_PASSWORD_SECRET="-e ZWIFT_PASSWORD=$ZWIFT_PASSWORD"
    else
        echo "No password found for $ZWIFT_USERNAME..."
        echo "To avoid manually entering your zwift password every time, either start zwift with \`ZWIFT_PASSWORD=\"hunter2\" zwift\` or store it in the secret-store"
        echo "\`secret-tool store --label \"Zwift password for $ZWIFT_USERNAME\" application zwift username $ZWIFT_USERNAME\`"
    fi
else
    echo "No Zwift credentials found..."
fi

if [ "$CONTAINER_TOOL" == "podman" ]; then
    # Podman has to use container id 1000
    # Local user is mapped to the container id
    LOCAL_UID=$ZWIFT_UID
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
        if [[ -n $WAYLAND_DISPLAY ]]; then
            WINDOW_MANAGER="Wayland"
        elif [[ -n $DISPLAY ]]; then
            WINDOW_MANAGER="XOrg"
        fi
    ;;
esac

# Verify which system we are using for wayland and some checks.
if [ "$WINDOW_MANAGER" = "Wayland" ]; then
    # System is using wayland or xwayland.
    if [ -z "$WINE_EXPERIMENTAL_WAYLAND" ]; then
        WINDOW_MANAGER="XWayland"
    else
        WINDOW_MANAGER="Wayland"
    fi

    # ZWIFT_UID does not work on XWayland, show warning
    if [ "$ZWIFT_UID" -ne "$(id -u)" ]; then
        msgbox warning "Wayland does not support ZWIFT_UID different to your id of $(id -u), may not start." 5
    fi
fi

#######################################
###### UPD SCRIPTS and CONTAINER ######

# Check for updated zwift.sh
if [[ ! $DONT_CHECK ]]; then
    REMOTE_SUM=$(curl -s https://raw.githubusercontent.com/netbrain/zwift/master/zwift.sh | sha256sum | awk '{print $1}')
    THIS_SUM=$(sha256sum "$0" | awk '{print $1}')

    # Compare the checksums
    if [ "$REMOTE_SUM" = "$THIS_SUM" ]; then
        echo "You are running latest zwift.sh 👏"
    else
        # Ask with Timeout, default is do not update.
        if msgbox question "You are not running the latest zwift.sh 😭, download? (Default no in 5 seconds)" 5; then
            pkexec env PATH="$PATH" bash -c "$(curl -fsSL https://raw.githubusercontent.com/netbrain/zwift/master/bin/install.sh)"
            exec "$0" "${@}"
        fi
    fi
fi

# Check for updated container image
if [[ ! $DONT_PULL ]]
then
    $CONTAINER_TOOL pull "$IMAGE":"$VERSION"
fi

#############################
##### PREPARE ALL FLAGS #####

# Define Base Container Parameters
GENERAL_FLAGS=(
    --rm
    --network "$NETWORKING"
    --name "zwift-$USER"
    --hostname "$HOSTNAME"

    -e DISPLAY="$DISPLAY"
    -e ZWIFT_UID="$CONTAINER_UID"
    -e ZWIFT_GID="$CONTAINER_GID"
    -e PULSE_SERVER="/run/user/$CONTAINER_UID/pulse/native"
    -e CONTAINER="$CONTAINER_TOOL"

    -v "zwift-$USER":/home/user/.wine/drive_c/users/user/Documents/Zwift
    -v "/run/user/$LOCAL_UID/pulse":"/run/user/$CONTAINER_UID/pulse"
)

###################################
##### SPECIFIC CONFIGURATIONS #####

# Setup container security flags
if [[ $PRIVILEGED_CONTAINER -eq "1" ]]
then
    CONT_SEC_FLAG=(--privileged --security-opt label=disable) # privileged container, less secure
else
    CONT_SEC_FLAG=(--security-opt label=type:container_runtime_t) # more secure
fi

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

if [[ -n "$DBUS_SESSION_BUS_ADDRESS" ]]; then
    [[ $DBUS_SESSION_BUS_ADDRESS =~ ^unix:path=([^,]+) ]]

    DBUS_UNIX_SOCKET=${BASH_REMATCH[1]}
    if [[ -n "$DBUS_UNIX_SOCKET" ]]; then
        DBUS_CONFIG_FLAGS=(
            -e DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS//$LOCAL_UID/$CONTAINER_UID}"
            -v "$DBUS_UNIX_SOCKET":"${DBUS_UNIX_SOCKET//$LOCAL_UID/$CONTAINER_UID}"
        )
    fi
fi

# Setup foreground/background flag
if [[ $ZWIFT_FG -eq "1" ]]; then
    ZWIFT_FG_FLAG=() # run in fg
else
    ZWIFT_FG_FLAG=(-d) # run in bg
fi

# INTERACTIVE mode: force foreground and provide a shell entrypoint for debugging
if [[ -n "$INTERACTIVE" ]]; then
    ZWIFT_FG_FLAG=(-it)
    INTERACTIVE_FLAGS=(--entrypoint bash)
fi

# Setup Flags for Window Managers
if [ $WINDOW_MANAGER == "Wayland" ]; then
    WM_FLAGS=(
        -e WINE_EXPERIMENTAL_WAYLAND=1
        -e XDG_RUNTIME_DIR="/run/user/$CONTAINER_UID"
        -e WAYLAND_DISPLAY="$WAYLAND_DISPLAY"

        -v "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY":"${XDG_RUNTIME_DIR//$LOCAL_UID/$CONTAINER_UID}/$WAYLAND_DISPLAY"
    )
fi

if [ $WINDOW_MANAGER == "XWayland" ] || [ $WINDOW_MANAGER == "XOrg" ]; then
    # If not XAuthority set then don't pass, hyprland is one that does not use it.
    if [ -z "$XAUTHORITY" ]; then
        WM_FLAGS=(
            -v /tmp/.X11-unix:/tmp/.X11-unix
        )
    else
        WM_FLAGS=(
            -e XAUTHORITY="${XAUTHORITY//$LOCAL_UID/$CONTAINER_UID}"

            -v /tmp/.X11-unix:/tmp/.X11-unix
            -v "$XAUTHORITY":"${XAUTHORITY//$LOCAL_UID/$CONTAINER_UID}"
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
    if ! podman volume ls | grep "zwift-$USER"; then
        $CONTAINER_TOOL volume create "zwift-$USER"
    fi

    GENERAL_FLAGS+=(
        --userns "keep-id:uid=$CONTAINER_UID,gid=$CONTAINER_GID"
    )
fi

# If custom resolution is requested, pass environment variable to container
if [[ -n $ZWIFT_OVERRIDE_RESOLUTION ]]; then
    GENERAL_FLAGS+=(
        -e ZWIFT_OVERRIDE_RESOLUTION="$ZWIFT_OVERRIDE_RESOLUTION"
    )
fi

# Read the user specified extra flags if any
read -r -a CONTAINER_EXTRA_FLAGS <<< "$CONTAINER_EXTRA_ARGS"

# Normalize single-string flags into arrays for safe command construction
read -r -a ZWIFT_CONFIG_FLAG_ARR <<< "$ZWIFT_CONFIG_FLAG"
read -r -a ZWIFT_USERNAME_FLAG_ARR <<< "$ZWIFT_USERNAME_FLAG"
read -r -a ZWIFT_PASSWORD_SECRET_ARR <<< "$ZWIFT_PASSWORD_SECRET"
read -r -a ZWIFT_USER_CONFIG_FLAG_ARR <<< "$ZWIFT_USER_CONFIG_FLAG"
read -r -a ZWIFT_WORKOUT_VOL_ARR <<< "$ZWIFT_WORKOUT_VOL"
read -r -a ZWIFT_ACTIVITY_VOL_ARR <<< "$ZWIFT_ACTIVITY_VOL"
read -r -a ZWIFT_LOG_VOL_ARR <<< "$ZWIFT_LOG_VOL"
read -r -a ZWIFT_SCREENSHOTS_VOL_ARR <<< "$ZWIFT_SCREENSHOTS_VOL"
read -r -a VGA_DEVICE_FLAG_ARR <<< "$VGA_DEVICE_FLAG"
POSITIONAL_ARGS=("$@")

#########################
##### RUN CONTAINER #####
CMD=(
    "$CONTAINER_TOOL" run
    "${GENERAL_FLAGS[@]}"
    "${CONT_SEC_FLAG[@]}"
    "${ZWIFT_FG_FLAG[@]}"
    "${ZWIFT_CONFIG_FLAG_ARR[@]}"
    "${ZWIFT_USERNAME_FLAG_ARR[@]}"
    "${ZWIFT_PASSWORD_SECRET_ARR[@]}"
    "${ZWIFT_USER_CONFIG_FLAG_ARR[@]}"
    "${ZWIFT_WORKOUT_VOL_ARR[@]}"
    "${ZWIFT_ACTIVITY_VOL_ARR[@]}"
    "${ZWIFT_LOG_VOL_ARR[@]}"
    "${ZWIFT_SCREENSHOTS_VOL_ARR[@]}"
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
    if [ -x "$(command -v xhost)" ] && [ -z "$WINE_EXPERIMENTAL_WAYLAND" ]; then
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
if [ -n "$CONTAINER" ] && [ -x "$(command -v xhost)" ] && [ -z "$WINE_EXPERIMENTAL_WAYLAND" ]; then
    xhost +local:"$($CONTAINER_TOOL inspect --format='{{ .Config.Hostname }}' "$CONTAINER")"
fi
