#!/usr/bin/env bash
set -e
set -x

# Check whether we are running in Docker/ Podman
# Docker has the file /.dockerenv
# Podman exposes itself in /run/.containerenv
if [[ "$CONTAINER" != "docker" ]] && [[ "$CONTAINER" != "podman" ]]; then
    if [[ -f "/.dockerenv" ]]; then
        CONTAINER="docker"
    elif grep -q "podman" /run/.containerenv; then
        CONTAINER="podman"
    else
        echo "Unknown Container."
        exit 1
    fi
fi

# If Wayland Experimental need to blank DISPLAY here to enable Wayland.
# NOTE: DISPLAY must be unset here before run_swift to work
#       Registry entries are set in the container install or won't work.
if [[ -n $WINE_EXPERIMENTAL_WAYLAND ]]; then
    unset DISPLAY
fi

# Check what container we are in:
if [[ "$CONTAINER" == "docker" ]]; then
    # This script runs as the root user in Docker so need to do this to find the
    # home directory of the "user" user.
    ZWIFT_USER_HOME=$(getent passwd "user" | cut -d: -f6)
    ZWIFT_HOME="$ZWIFT_USER_HOME/.wine/drive_c/Program Files (x86)/Zwift"
    mkdir -p "$ZWIFT_HOME"
    cd "$ZWIFT_HOME"

    USER_UID=$(id -u user)
    USER_GID=$(id -g user)

    # Test that it exists and is a number, and only if different to existing.
    if [ "$ZWIFT_UID" -eq "$ZWIFT_UID" ] && [ "$USER_UID" -ne "$ZWIFT_UID" ]; then
        USER_UID=$ZWIFT_UID
        SWITCH_IDS=1
    else
        echo "ZWIFT_UID is not set or not a number: '$ZWIFT_UID'"
    fi
    if [ "$ZWIFT_GID" -eq "$ZWIFT_GID" ] && [ "$USER_GID" -ne "$ZWIFT_GID" ]; then
        USER_GID=$ZWIFT_GID
        SWITCH_IDS=1
    else
        echo "ZWIFT_GID is not set or not a number: ''$ZWIFT_GID'"
    fi

    # This section is only run if we are switching either UID or GID.
    if [[ -n $SWITCH_IDS ]]; then
        usermod -o -u "$USER_UID" user
        groupmod -o -g "$USER_GID" user
        chown -R "$USER_UID":"$USER_GID" /home/user

        # Only make the directory if not there.
        if [ ! -d "/run/user/$USER_UID" ]; then
            mkdir -p "/run/user/$USER_GID"
        fi

        chown -R user:user "/run/user/$USER_UID"
        sed -i "s/1000/$USER_UID/g" /etc/pulse/client.conf
    fi

    # Run update if that's the first argument or if zwift directory is empty
    if [ "$1" = "update" ] || [ ! "$(ls -A .)" ]; then
        # Have to change owner for build as everything is root.
        chown -R user:user /home/user
        gosu user:user /bin/update_zwift.sh "$@"
    else
        # Volume is mounted as root so always re-own.
        chown -R "$USER_UID":"$USER_GID" /home/user/.wine/drive_c/users/user/Documents/Zwift
        gosu user:user /bin/run_zwift.sh "$@"
    fi
else
    # We are running in podman.
    ZWIFT_HOME="/home/user/.wine/drive_c/Program Files (x86)/Zwift"
    mkdir -p "$ZWIFT_HOME"
    cd "$ZWIFT_HOME"

    if [ "$1" = "update" ] || [ ! "$(ls -A .)" ]; then
        /bin/update_zwift.sh "$@"
    else
        /bin/run_zwift.sh "$@"
    fi
fi
