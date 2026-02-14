#!/usr/bin/env bash
set -e

readonly DEBUG="${DEBUG:-0}"
if [[ ${DEBUG} -eq 1 ]]; then set -x; fi

readonly ZWIFT_UID="${ZWIFT_UID:-$(id -u user)}"
readonly ZWIFT_GID="${ZWIFT_GID:-$(id -g user)}"
readonly WINE_EXPERIMENTAL_WAYLAND="${WINE_EXPERIMENTAL_WAYLAND:-0}"
readonly CONTAINER_TOOL="${CONTAINER_TOOL:?}"

readonly ZWIFT_HOME="/home/user/.wine/drive_c/Program Files (x86)/Zwift"
readonly ZWIFT_DOCS="/home/user/.wine/drive_c/users/user/Documents/Zwift"

# If Wayland Experimental need to blank DISPLAY here to enable Wayland.
# NOTE: DISPLAY must be unset here before run_zwift to work
#       Registry entries are set in the container install or won't work.
if [[ ${WINE_EXPERIMENTAL_WAYLAND} -eq 1 ]]; then
    unset DISPLAY
fi

mkdir -p "${ZWIFT_HOME}"
cd "${ZWIFT_HOME}"

# Run update if that's the first argument or if zwift directory is empty
if [[ ${1} == "update" ]] || [[ -z "$(ls -A .)" ]]; then
    readonly UPDATE_REQUIRED=1
else
    readonly UPDATE_REQUIRED=0
fi

if [[ ${CONTAINER_TOOL} == "docker" ]]; then
    user_uid="$(id -u user)"
    user_gid="$(id -g user)"

    # Test that it exists and is a number, and only if different to existing.
    switch_user_id=0
    if [[ ! ${ZWIFT_UID} =~ ^[0-9]+$ ]]; then
        echo "ZWIFT_UID is not a number: '${ZWIFT_UID}'" >&2
    elif [[ ${user_uid} -ne ${ZWIFT_UID} ]]; then
        user_uid="${ZWIFT_UID}"
        switch_user_id=1
    fi
    if [[ ! ${ZWIFT_GID} =~ ^[0-9]+$ ]]; then
        echo "ZWIFT_GID is not a number: '${ZWIFT_GID}'" >&2
    elif [[ ${user_gid} -ne ${ZWIFT_GID} ]]; then
        user_gid="${ZWIFT_GID}"
        switch_user_id=1
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
    if [[ ${UPDATE_REQUIRED} -eq 1 ]]; then
        # Have to change owner for build as everything is root.
        chown -R user:user /home/user
        gosu user:user /bin/update_zwift.sh "${@}"
    else
        # Volume is mounted as root so always re-own.
        chown -R "${user_uid}:${user_gid}" "${ZWIFT_DOCS}"
        gosu user:user /bin/run_zwift.sh "${@}"
    fi
else
    # We are running in podman.
    if [[ ${UPDATE_REQUIRED} -eq 1 ]]; then
        /bin/update_zwift.sh "${@}"
    else
        /bin/run_zwift.sh "${@}"
    fi
fi
