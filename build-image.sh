#!/usr/bin/env bash
set -x
set -e

# Check for proprietary nvidia driver and set correct device to use
if [[ -f "/proc/driver/nvidia/version" ]]
then
    VGA_DEVICE_FLAG="--gpus all"
else
    VGA_DEVICE_FLAG="--device /dev/dri:/dev/dri"
fi

docker build -t netbrain/zwift .
docker run \
    --name zwift \
    --privileged \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    $VGA_DEVICE_FLAG \
    netbrain/zwift:latest

BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
VERSION=$(curl -s http://cdn.zwift.com/gameassets/Zwift_Updates_Root/Zwift_ver_cur.xml | grep -oP 'sversion="\K.*?(?=")' | cut -f 1 -d ' ')
docker commit --change="LABEL org.opencontainers.image.created=$BUILD_DATE" \
    --change="LABEL org.opencontainers.image.version=$VERSION" \
    --change='CMD [""]' \
    -m "updated to version $VERSION" \
    zwift \
    netbrain/zwift:$VERSION
