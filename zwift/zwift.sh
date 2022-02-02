#!/bin/bash

# The zwift version to launch
ZWIFT_VERSION=${ZWIFT_VERSION:-latest}

# The home directory to store zwift data
ZWIFT_HOME=${ZWIFT_HOME:-$HOME/.zwift/$USER}

# Create the zwift home directory if not already exists
mkdir -p $ZWIFT_HOME

# Check for updated container image
docker pull netbrain/zwift:$ZWIFT_VERSION

# Check for proprietary nvidia driver and set correct device to use
if [[ -f "/proc/driver/nvidia/version" ]]
then
	VGA_DEVICE_FLAG="--gpus all"
else
	VGA_DEVICE_FLAG="--device /dev/dri:/dev/dri"
fi

# Start the zwift container
CONTAINER=$(docker run \
	-d \
	--rm \
	--privileged \
	-e DISPLAY=$DISPLAY \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
	-v /run/user/$UID/pulse:/run/user/1000/pulse \
	-v $ZWIFT_HOME:/home/user/Zwift \
	$VGA_DEVICE_FLAG \
	netbrain/zwift:$ZWIFT_VERSION)
	
# Allow container to connect to X
xhost +local:$(docker inspect --format='{{ .Config.Hostname  }}' $CONTAINER)
