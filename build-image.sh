#!/bin/bash +x

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
