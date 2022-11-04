# Zwift
 
[![Zwift updater][zwift-updater-src]][zwift-updater-href]
[![image-href][image-pulls-src]][image-href]
[![image-href][image-version-src]][image-href]
[![image-href][image-size-src]][image-href]


Hello fellow zwifters, here is a docker image for running zwift on linux. It uses the companion app by zwift for linking up smart trainers and other bluetooth/ant devices. The reason why I made this solution was so i could run multiple zwift instances on one machine at the same time. 

The container comes pre-installed with zwift, so no setup is required, simply pull and run. It should also now support all manner of graphics cards that has gl rendering.

If you find this image useful, then feel free add [me on zwift](https://www.zwift.com/eu/athlete/4e3c5880-1edd-4c5d-a1b8-0974ce3874f0) and give me a ride on from time to time.

![example.gif](https://raw.githubusercontent.com/netbrain/zwift/master/example.gif)

## Prerequisites
- [Docker](https://docs.docker.com/get-docker) or [Podman](https://podman.io/getting-started/installation)
- [nvidia-container-toolkit](https://github.com/NVIDIA/nvidia-docker) if you have nvidia proprietary driver
- ATI, Intel and Nouveau drivers should work out of the box (not tested)
- Allow container to access the x-host by issuing the command `xhost +` (this will however allow everyone to your X server which is considere unsafe, if this is a concern of yours, then `man xhost`)

## Quickstart guide
```
wget https://raw.githubusercontent.com/netbrain/zwift/master/zwift.sh -P ~/bin
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

Instead of `--gpus all`, it might suffice to do a `-v /dev/dri:/dev/dri` instead depending on your graphics card and drivers.

Please note that the above command does not mount a volume to persist configuration files. 
If you want a proper setup then please use `zwift.sh`.

## How do I connect my trainer, heart rate monitor, etc?

You can [use your phone as a bridge](https://support.zwift.com/using-the-zwift-companion-app-Hybn8qzPr).

For example, your Wahoo Kickr and Apple Watch conect to the Zwift Companion app on your
iPhone; then the Companion app connects over wifi to your PC running Zwift.

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
export VERSION=1.20.0			  		# Or whatever the latest version is
docker commit zwift netbrain/zwift:$VERSION 		# Create a new image with the latest update
docker rm zwift 					# Remove the no longer needed container
```

## How can I fetch the image from docker hub?

https://hub.docker.com/r/netbrain/zwift

```
docker pull netbrain/zwift:$VERSION # or simply latest
```

## How can I update Zwift?

Zwift does not update on it's own. So in order to keep zwift up to date you can simply pull netbrain/zwift:latest from time to time. There is a github action in place that will update zwift on a scheduled basis and publish new versions to docker hub.

## Contibute

If you would like to contribute, then please by all means I'll accept PR's. 

[zwift-updater-src]:https://github.com/netbrain/zwift/actions/workflows/zwift_updater.yaml/badge.svg
[zwift-updater-href]:https://github.com/netbrain/zwift/actions/workflows/zwift_updater.yaml
[image-version-src]:https://badgen.net/docker/metadata/version/netbrain/zwift/latest?icon=docker
[image-pulls-src]:https://badgen.net/docker/pulls/netbrain/zwift?icon=docker&label=pulls
[image-size-src]:https://badgen.net/docker/size/netbrain/zwift?icon=docker&label=size
[image-href]:https://hub.docker.com/r/netbrain/zwift
