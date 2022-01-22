#!/bin/bash
ZWIFT_VERSION=${ZWIFT_VERSION:-latest}
ZWIFT_HOME=${ZWIFT_HOME:-$HOME/.zwift/$USER}
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
	
xhost +local:$(docker inspect --format='{{ .Config.Hostname  }}' $CONTAINER)
