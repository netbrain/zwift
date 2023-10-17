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

## Install
```console
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/netbrain/zwift/master/bin/install.sh)"
```
This will put the `zwift.sh` script on your `$PATH`

## RUN
After installation, simply run:

```console
zwift
```

## Configuration options
| Key           | Default                 | Description                                     |
|---------------|-------------------------|-------------------------------------------------|
| USER          | $USER                   | Used in creating the zwift volume `zwift-$USER` |
| IMAGE         | docker.io/netbrain/zwift| The image to use                                |
| VERSION       | latest                  | The image version/tag to use                    |
| DONT_PULL     |                         | If set, don't pull for new image version        |
| CONTAINER_TOOL|                         | Defaults to podman if installed, else docker    |

These environment variables can be used to alter the execution of the zwift bash script.

Examples:

`DONT_PULL=1 zwift` will prevent docker/podman pull before launch

`CONTAINER_TOOL=docker zwift` will launch zwift with docker even if podman is installed

`USER=Fred zwift` perfect if your neighbor fred want's to try zwift, and you don't want to mess up your zwift config.

## How can I persist my login information so i don't need to login on every startup?

To authenticate through Zwift automatically, the credentials must be present in the zwift volume.
`docker volume ls` or `podman volume ls` should have a `zwift-$USER` volume.
A file named `.zwift-credentials` must contain the following lines:

```
ZWIFT_USERNAME=username
ZWIFT_PASSWORD=password
```

where `username` is your Zwift account email, and `password` your Zwift account password, respectively.
Note that if your password contains special characters such as `;` you will need to escape them using `\`. 

copy this file into your zwift volume `zwift-$USER`:

```console
# docker
docker run -v zwift-$USER:/data --name zwift-copy-op busybox true
docker cp .zwift-credentials zwift-copy-op:/data
docker rm zwift-copy-op

# podman
podman unshare
cp .zwift-credentials $(podman volume mount zwift-$USER)
exit
```

The credentials will be used to authenticate before launching the Zwift app, and the user should be logged in automatically in the game.

## How do I connect my trainer, heart rate monitor, etc?

You can [use your phone as a bridge](https://support.zwift.com/using-the-zwift-companion-app-Hybn8qzPr).

For example, your Wahoo Kickr and Apple Watch conect to the Zwift Companion app on your
iPhone; then the Companion app connects over wifi to your PC running Zwift.

## How can I add custom .zwo files?

The folder's name that receives .zwo files is dynamic based on your user's numeric ID. This example works considering you have a single user in the same docker volume.
After you've downloaded/created your .zwo files use the following script to copy it to the correct folder:

```console
# docker
docker run -v zwift-$USER:/data --name zwift-copy-op busybox ls /data/Workouts | xargs -I {} docker cp my-workouts-file.zwo zwift-copy-op:/data/Workouts/{}
docker rm zwift-copy-op

#podman
@TBD
```

If you have multiple users at the same volume you might want to find out which IDs exist in your setup and map the ID for each user to copy correctly to the corresponding user.
An example of this would be:

```console
# docker
docker run -v zwift-$USER:/data --name zwift-copy-op busybox true
docker cp my-workouts-file.zwo zwift-copy-op:/data/Workouts/1234
docker rm zwift-copy-op

#podman
@TBD
```

## How can I build the image myself?

```console
docker build -t netbrain/zwift .
docker run --gpus all \
 --privileged \
 --name zwift \
 -e DISPLAY=$DISPLAY \
 -v /tmp/.X11-unix:/tmp/.X11-unix \
netbrain/zwift
```

After install and update is complete stop the container `docker stop zwift` and proceed with comitting a new version.

```console
export VERSION=1.20.0                               # Or whatever the latest version is
docker commit zwift netbrain/zwift:$VERSION         # Create a new image with the latest update
docker rm zwift                                     # Remove the no longer needed container
```

## How can I fetch the image from docker hub?

https://hub.docker.com/r/netbrain/zwift

```console
docker pull netbrain/zwift:$VERSION # or simply latest
```

## How can I update Zwift?

The `zwift.sh` script will update zwift by checking for new image versions on every launch, however if you are not using this then you will have to pull netbrain/zwift:latest from time to time in order to be on the latest version.

There is a github action in place that will update zwift on a scheduled basis and publish new versions to docker hub.

## Contibute

If you would like to contribute, then please by all means I'll accept PR's. A good starting point would be to see if there's any open issues that you feel capable of doing. Let me know if I can help with anything.

### Show and tell 🙌

Check out our [Show and tell](https://github.com/netbrain/zwift/discussions/categories/show-and-tell) category in discussions and see how other people are using this solution, feel free to contribute your own tips and tricks :)

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
* Using a virual machine with pci passthrough
  * https://looking-glass.io/
  * https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF
  * https://github.com/VGPU-Community-Drivers/vGPU-Unlock-patcher (if you have a nvidia card you can eat your cake, and have it too by creating vgpus for vm's that leverage the host gpu, no dedicated gpu required)

[zwift-updater-src]:https://github.com/netbrain/zwift/actions/workflows/zwift_updater.yaml/badge.svg
[zwift-updater-href]:https://github.com/netbrain/zwift/actions/workflows/zwift_updater.yaml
[image-version-src]:https://img.shields.io/docker/v/netbrain/zwift/latest?logo=docker&logoColor=white
[image-pulls-src]:https://badgen.net/docker/pulls/netbrain/zwift?icon=docker&label=pulls
[image-size-src]:https://badgen.net/docker/size/netbrain/zwift?icon=docker&label=size
[image-href]:https://hub.docker.com/r/netbrain/zwift/tags
