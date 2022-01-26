#!/bin/bash

# The zwift version to launch
ZWIFT_VERSION=${ZWIFT_VERSION:-latest}

# The home directory to store zwift data
ZWIFT_HOME=${ZWIFT_HOME:-$HOME/.zwift/$USER}

# Create the zwift home directory if not already exists
mkdir -p $ZWIFT_HOME

# Start the zwift container
CONTAINER=$(docker run \
	-d \
	--privileged \
	--gpus all \
	--cpus=2 \
	--rm \
	-e DISPLAY=$DISPLAY \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
	-v /run/user/$UID/pulse:/run/user/1000/pulse \
	-v $ZWIFT_HOME:/home/user/Zwift \
	netbrain/zwift:$ZWIFT_VERSION)
	
# Allow container to connect to X
xhost +local:$(docker inspect --format='{{ .Config.Hostname  }}' $CONTAINER)
