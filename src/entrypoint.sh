#!/usr/bin/env bash
set -e
set -x

readonly ZWIFT_UID=${ZWIFT_UID:-}
readonly ZWIFT_GID=${ZWIFT_GID:-}
readonly WINE_EXPERIMENTAL_WAYLAND=${WINE_EXPERIMENTAL_WAYLAND:-0}

# Check whether we are running in Docker/ Podman
# Docker has the file /.dockerenv
# Podman exposes itself in /run/.containerenv
CONTAINER_TOOL=${CONTAINER_TOOL:-}
if [[ ${CONTAINER_TOOL} != "docker" ]] && [[ ${CONTAINER_TOOL} != "podman" ]]; then
    if [[ -f "/.dockerenv" ]]; then
        CONTAINER_TOOL="docker"
    elif grep -q "podman" /run/.containerenv; then
        CONTAINER_TOOL="podman"
    else
        echo "Unknown Container."
        exit 1
    fi
fi
readonly CONTAINER_TOOL

# If Wayland Experimental need to blank DISPLAY here to enable Wayland.
# NOTE: DISPLAY must be unset here before run_zwift to work
#       Registry entries are set in the container install or won't work.
if [[ ${WINE_EXPERIMENTAL_WAYLAND} -eq 1 ]]; then
    unset DISPLAY
fi

# Check what container we are in:
if [[ ${CONTAINER_TOOL} == "docker" ]]; then
    # This script runs as the root user in Docker so need to do this to find the
    # home directory of the "user" user.
    zwift_home="/home/user/.wine/drive_c/Program Files (x86)/Zwift"
    mkdir -p "${zwift_home}"
    cd "${zwift_home}"

    user_uid="$(id -u user)"
    user_gid="$(id -g user)"

    # Test that it exists and is a number, and only if different to existing.
    switch_user_id=0
    if [[ -n ${ZWIFT_UID} ]] && [[ ${ZWIFT_UID} -eq ${ZWIFT_UID} ]] && [[ ${user_uid} -ne ${ZWIFT_UID} ]]; then
        user_uid="${ZWIFT_UID}"
        switch_user_id=1
    else
        echo "ZWIFT_UID is not set or not a number: '${ZWIFT_UID}'"
    fi
    if [[ -n ${ZWIFT_GID} ]] && [[ ${ZWIFT_GID} -eq ${ZWIFT_GID} ]] && [[ ${user_gid} -ne ${ZWIFT_GID} ]]; then
        user_gid="${ZWIFT_GID}"
        switch_user_id=1
    else
        echo "ZWIFT_GID is not set or not a number: '${ZWIFT_GID}'"
    fi

    # This section is only run if we are switching either UID or GID.
    if [[ ${switch_user_id} -eq 1 ]]; then
        usermod -o -u "${user_uid}" user
        groupmod -o -g "${user_gid}" user
        chown -R "${user_uid}:${user_gid}" /home/user

        # Only make the directory if not there.
        if [[ ! -d "/run/user/${user_uid}" ]]; then
            mkdir -p "/run/user/${user_uid}"
        fi

        chown -R user:user "/run/user/${user_uid}"
        sed -i "s/1000/${user_uid}/g" /etc/pulse/client.conf
    fi

    # Run update if that's the first argument or if zwift directory is empty
    if [[ $1 == "update" ]] || [[ -z "$(ls -A .)" ]]; then
        # Have to change owner for build as everything is root.
        chown -R user:user /home/user
        gosu user:user /bin/update_zwift.sh "${@}"
    else
        # Volume is mounted as root so always re-own.
        chown -R "${user_uid}:${user_gid}" /home/user/.wine/drive_c/users/user/Documents/Zwift
        gosu user:user /bin/run_zwift.sh "${@}"
    fi
else
    # We are running in podman.
    zwift_home="${HOME}/.wine/drive_c/Program Files (x86)/Zwift"
    mkdir -p "${zwift_home}"
    cd "${zwift_home}"

    if [[ $1 == "update" ]] || [[ -z "$(ls -A .)" ]]; then
        /bin/update_zwift.sh "${@}"
    else
        /bin/run_zwift.sh "${@}"
    fi
fi
