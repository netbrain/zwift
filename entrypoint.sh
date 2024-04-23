#!/bin/bash
set -e
set -x

usermod -o -u ${ZWIFT_UID} user && groupmod -o -g ${ZWIFT_GID} user
chown -R ${ZWIFT_UID}:${ZWIFT_GID} /home/user
sed -i "s/1000/${ZWIFT_UID}/g" /etc/pulse/client.conf
mkdir -p /run/user/${ZWIFT_UID} && chown -R user:user /run/user/${ZWIFT_UID}

gosu user:user /bin/setup_and_run_zwift
