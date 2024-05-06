#!/bin/bash
set -e
set -x

source /bin/zwift_common.sh

USER_UID=`id -u user`
USER_GID=`id -g user`

# Test that it exists and is a number
if [ -n "$ZWIFT_UID" ] && [ "$ZWIFT_UID" -eq "$ZWIFT_UID" ]; then
  USER_UID=$ZWIFT_UID
else 
  echo "ZWIFT_UID is not set or not a number: '$ZWIFT_UID'"
fi
if [ -n "$ZWIFT_GID" ] && [ "$ZWIFT_GID" -eq "$ZWIFT_GID" ]; then
  USER_GID=$ZWIFT_GID
else 
  echo "ZWIFT_GID is not set or not a number: ''$ZWIFT_GID'"
fi

# The next two should be no-ops if ZWIFT_UID/GID are not set but no harm
# running them anyway.
usermod -o -u ${USER_UID} user
groupmod -o -g ${USER_GID} user
chown -R ${USER_UID}:${USER_GID} /home/user

mkdir -p /run/user/${USER_UID} && chown -R user:user /run/user/${USER_UID}
sed -i "s/1000/${USER_UID}/g" /etc/pulse/client.conf

# Run update if that's the first argument or if zwift directory is empty
if [ "$1" = "update" ] || [ ! "$(ls -A ${ZWIFT_HOME})" ] ; then
  gosu user:user /bin/update_zwift.sh "$@"
else
  gosu user:user /bin/run_zwift.sh "$@"
fi
