# Zwift

Hello fellow zwifters, here is a docker image for running zwift on linux. It uses the companion app by zwift for linking up smart trainers and other bluetooth/ant devices. The reason why I made this solution was so i could run multiple zwift instances on one machine at the same time. 

The container comes pre-installed with zwift, so no setup is required, simply pull and run. It should also now support all manner of graphics cards that has gl rendering.

If you find this image useful, then feel free add [me](https://www.zwift.com/eu/athlete/4e3c5880-1edd-4c5d-a1b8-0974ce3874f0) and give me a ride on from time to time.

## Prerequisites
- [Docker](https://docs.docker.com/get-docker) or [Podman](https://podman.io/getting-started/installation)
- [nvidia-container-toolkit](https://github.com/NVIDIA/nvidia-docker) if you have nvidia proprietary driver
- ATI, Intel and Nouveau drivers should work out of the box (not tested)
- Allow container to access the x-host by issuing the command `xhost +` (this will however allow everyone to your X server which is considere unsafe, if this is a concern of yours, then `man xhost`)

## Quickstart guide
```
wget https://raw.githubusercontent.com/netbrain/dockerfiles/master/zwift/zwift.sh -P ~/bin
chmod +x ~/bin/zwift.sh
~/bin/zwift.sh
```

Or you can run the following instead:

```
xhost +
docker pull netbrain/zwift:latest
docker run --gpus all \ 
 --privileged \
 --rm \
 -e DISPLAY=$DISPLAY \
 -v /tmp/.X11-unix:/tmp/.X11-unix \
 -v /run/user/$UID/pulse:/run/user/1000/pulse \
netbrain/zwift:latest
```

Instead of --gpus all, it might suffice to do a `-v /dev/dri:/dev/dri` instead dependning on your graphics card and drivers.

Please note that the above command does not mount a volume to persist configuration files. 
If you wan't a proper setup then take a look at zwift.sh

## How can I build the image myself?

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
export ZWIFT_VERSION=1.20.0			  	# Or whatever the latest version is
docker commit zwift netbrain/zwift:$ZWIFT_VERSION 	# Create a new image with the latest update
docker rm zwift 					# Remove the no longer needed container
```

## How can I fetch the image from docker hub?

https://hub.docker.com/repository/docker/netbrain/zwift

```
docker pull netbrain/zwift:$ZWIFT_VERSION # or simply latest
```

## How can I update Zwift?

Zwift does not update on it's own. So in order to keep zwift up to date you can simply pull netbrain/zwift:latest from time to time, I will try to keep up with the updates. However if I fail at this task then see the following instructions.

```
docker run --gpus all \
 --privileged \
 --name zwift \
 -e DISPLAY=$DISPLAY \
 -v /tmp/.X11-unix:/tmp/.X11-unix \
netbrain/zwift:latest update

export ZWIFT_VERSION=1.20.0 #increment this 
docker commit zwift netbrain/zwift:$ZWIFT_VERSION
docker tag netbrain/zwift:$ZWIFT_VERSION netbrain/zwift:latest
docker push netbrain/zwift:$ZWIFT_VERSION
docker push netbrain/zwift:latest
```

## Contibute

If you would like to contribute, then please by all means ill accept PR's. 
