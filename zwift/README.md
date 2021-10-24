# Zwift

## Prerequisites

- [nvidia-container-toolkit](https://github.com/NVIDIA/nvidia-docker)
- Allow container to access the x-host by issuing the command `xhost +` (this will however allow everyone to your X server which is considere unsafe, if this is a concern of yours, then `man xhost`)
- Build netbrain/nvidia-wine (`cd ../nvidia-wine && docker build -t netbrain/nvidia-wine .`)

## Build, Update and Commit

```
docker build -t netbrain/zwift .
docker run --gpus all \
 --privileged \
 --name zwift \
 -e DISPLAY=$DISPLAY \
 -v /tmp/.X11-unix:/tmp/.X11-unix \
netbrain/zwift
```

After install and update is complete stop the container `docker stop zwift` and proceed with comitting a new version.

```
export ZWIFT_VERSION=1.0.85684 			  	# Or whatever the latest version is
docker commit zwift netbrain/zwift:$ZWIFT_VERSION 	# Create a new image with the latest update
docker rm zwift 					# Remove the no longer needed container
```

## Or Pull from docker hub

https://hub.docker.com/repository/docker/netbrain/zwift

```
docker pull netbrain/zwift:$ZWIFT_VERSION # or simply latest
```

## Run Zwift

```
docker run --gpus all \
 --privileged \
 --rm \
 -e DISPLAY=$DISPLAY \
 -v /tmp/.X11-unix:/tmp/.X11-unix \
 -v /run/user/$UID/pulse:/run/user/1000/pulse \ 
 -v $HOME/.zwift:/home/user/Zwift \
netbrain/zwift:$ZWIFT_VERSION
```
