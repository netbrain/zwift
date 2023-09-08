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

## Logging in automatically with zwift.sh

To authenticate through Zwift automatically, the credentials must be present in the mounted persisted Zwift config volume (`$HOME/.config/zwift/$USER/.zwift-credentials`).  
A file named `.zwift-credentials` must contain the following lines:

```console
ZWIFT_USERNAME=username
ZWIFT_PASSWORD=password
```

where `username` is your Zwift account email, and `password` your Zwift account password, respectively.  

The credentials will be used to authenticate before launching the Zwift app, and the user should be logged in automatically in the game.

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

If you would like to contribute, then please by all means I'll accept PR's. A good starting point would be to see if there's any open issues that you feel capable of doing. Let me know if I can help with anything.

## Alternative's to this repository

* Install zwift using wine directly or a framework like lutris. You will however have to manage installation and updates yourself
* Use [scrcpy](https://github.com/Genymobile/scrcpy) to mirror android device to your linux screen
  * [Enable developer options on your android device](https://developer.android.com/studio/debug/dev-options#enable)
  * Pair your computer to the device using `adb pair` [documentation](https://developer.android.com/studio/command-line/adb#wireless-android11-command-line) 
    * `./srccpy.sh adb pair ip:port`  [see my container solution](https://github.com/netbrain/dockerfiles/tree/master/scrcpy)
  * Mirror the android device screen onto your linux screen using scrcpy.
      * `./srccpy.sh scrcpy --tcpip=ip:port`
  * If you require sound aswell, there's also a [sndcpy](https://github.com/rom1v/sndcpy) project (doesn't support wireless though, but the abovementioned can be modified to use usb)
* Using [redroid](https://hub.docker.com/r/redroid/redroid) to install zwift apk onto a android emulator (not tested)

[zwift-updater-src]:https://github.com/netbrain/zwift/actions/workflows/zwift_updater.yaml/badge.svg
[zwift-updater-href]:https://github.com/netbrain/zwift/actions/workflows/zwift_updater.yaml
[image-version-src]:https://img.shields.io/docker/v/netbrain/zwift/latest?logo=docker&logoColor=white
[image-pulls-src]:https://badgen.net/docker/pulls/netbrain/zwift?icon=docker&label=pulls
[image-size-src]:https://badgen.net/docker/size/netbrain/zwift?icon=docker&label=size
[image-href]:https://hub.docker.com/r/netbrain/zwift/tags
