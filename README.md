# Zwift

[![Zwift updater][zwift-updater-src]][zwift-updater-href]
[![image-href][image-pulls-src]][image-href]
[![image-href][image-version-src]][image-href]
[![image-href][image-size-src]][image-href]


Hello fellow zwifters, here is a docker image for running zwift on linux. It uses the companion app by zwift for linking up smart trainers and other bluetooth devices (ant devices are not supported via the companion app). The reason why I made this solution was so i could run multiple zwift instances on one machine at the same time.

The container comes pre-installed with zwift, so no setup is required, simply pull and run. It should also now support all manner of graphics cards that has gl rendering.

If you find this image useful, then feel free add [me on zwift](https://www.zwift.com/eu/athlete/4e3c5880-1edd-4c5d-a1b8-0974ce3874f0) and give me a ride on from time to time.

![example.gif](https://raw.githubusercontent.com/netbrain/zwift/master/example.gif)

## Prerequisites
- [Docker](https://docs.docker.com/get-docker) or [Podman](https://podman.io/getting-started/installation)
- [nvidia-container-toolkit](https://github.com/NVIDIA/nvidia-container-toolkit) if you have nvidia proprietary driver
- ATI, Intel and Nouveau drivers should work out of the box

> :warning: **Podman Support 4.3 and Later.**: Podman before 4.3 does not support --userns=keep-id:uid=xxx,gid=xxx and will not start correctly, this impacts Ubuntu 22.04 and related builds such as PopOS 22.04. See Podman Section below.

## Install
```console
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/netbrain/zwift/master/bin/install.sh)"
```
This will put the `zwift.sh` script on your `$PATH`, add a desktop icon to /usr/local/share/applications.
NOTE: Icon may not show until logging off and back in.

## RUN
After installation, simply run:

```console
zwift
```
Note you might want to disable video screenshots ([#75](https://github.com/netbrain/zwift/issues/75))

If dbus is available through a unix socket, the screensaver will be inhibited every 30 seconds to prevent xscreensaver or other programs listening on the bus from inhibiting the screen.

## Configuration options
| Key                      | Default                 | Description                                               |
|--------------------------|-------------------------|-----------------------------------------------------------|
| USER                     | $USER                   | Used in creating the zwift volume `zwift-$USER`           |
| IMAGE                    | docker.io/netbrain/zwift| The image to use                                          |
| VERSION                  | latest                  | The image version/tag to use                              |
| DONT_CHECK               |                         | If set, don't check for updated zwift.sh                  |
| DONT_PULL                |                         | If set, don't pull for new image version                  |
| CONTAINER_TOOL           |                         | Defaults to podman if installed, else docker              |
| ZWIFT_USERNAME           |                         | If set, try to login to zwift automatically               |
| ZWIFT_PASSWORD           |                         | "                                                         |
| ZWIFT_WORKOUT_DIR        |                         | Set the workouts directory location                       |
| ZWIFT_ACTIVITY_DIR       |                         | Set the activities directory location                     |
| ZWIFT_FG                 |                         | If set, run the process in fg (-it) instead of bg (-d)    |
| ZWIFT_NO_GAMEMODE        |                         | If set, don't run gamemode                                |
| WINE_EXPERIMENTAL_WAYLAND|                         | If set, try to use experimental wayland support in wine 9 |
| NETWORKING               | bridge                  | Sets the type of container networking to use.             |
| ZWIFT_UID                | current users id        | Sets the UID that Zwift will run as (docker only)         |
| ZWIFT_GID                | current users group id  | Sets the GID that Zwift will run as (docker only)         |
| DEBUG                    |                         | If set enabled debug of zwift script "set -x"             |

These environment variables can be used to alter the execution of the zwift bash script.

Examples:

`DONT_PULL=1 zwift` will prevent docker/podman pull before launch

`CONTAINER_TOOL=docker zwift` will launch zwift with docker even if podman is installed

`USER=Fred zwift` perfect if your neighbor fred want's to try zwift, and you don't want to mess up your zwift config.

`NETWORKING=host zwift` will use host networking which may be needed to have Zwift talk to WiFi enabled trainers.

`ZWIFT_UID=123 ZWIFT_GID=123 zwift` will run Zwift as the given uid and gid.  By default Zwift runs with the uid and gid of the user that started the container. You should not need to change this except in rare cases.  NOTE: This does not work in wayland only X11.

`WINE_EXPERIMENTAL_WAYLAND=1 zwift` This will start zwift using Wayland and not XWayland. It will start full screen windowed.

You can also set these in `~/.config/zwift/config` to be sourced by the zwift.sh script on execution.

## How can I persist my login information so i don't need to login on every startup?

To authenticate through Zwift automatically simply add the following file `~/.config/zwift/config`:
```
ZWIFT_USERNAME=username
ZWIFT_PASSWORD=password
```

where `username` is your Zwift account email, and `password` your Zwift account password, respectively.

The credentials will be used to authenticate before launching the Zwift app, and the user should be logged in automatically in the game.

Note: This will be loaded by zwift.sh in cleartext as environment variables into the container.

Alternatively, instead of saving your password in the file, you can save your password in the SecretService keyring like so:

```
secret-tool store --label "Zwift password for ${ZWIFT_USERNAME}" application zwift username ${ZWIFT_USERNAME}
```

In this case the username should still be saved in the config file and the password will be read upon startup from the keyring and passed as a secret into the container (where it is an environment variable).

> :warning: **Do Not Quote the variables or add spaces**: The ID and Password are read as raw format so if you put ZWIFT_PASSWORD="password" it tries to use "password" and not just password, same for ''.  In addition do not add a space to the end of the line it will be sent as part of the pasword or username. This applies to ZWIFT_USERNAME and ZWIFT_PASSWORD. 

NOTE: You can also add other environment variable from the table to make starting easier:
```
ZWIFT_USERNAME=username
ZWIFT_PASSWORD=password

ZWIFT_WORKOUT_DIR=~/.config/zwift/workouts
WINE_EXPERIMENTAL_WAYLAND=1
```


## Podman Support

When running Zwift with podman, the user and group in the container is 1000 (user). To access the resources on the host we need to map the container id's 1000 to the host id's using uidmap and gidmap.  

For example if the host uid/gid is 1001/1001 then we need to map the host resources from /run/user/1001 to the container resource /run/user/1000 and map the user and group id's the same. This had to be done manually on the host posman start using --uidmap and --gidmap (not covered here)

From Podman 4.3 this became automatic by providing the Container UID/ GID and podman automatically sets up this maping.

NOTE: Using ZWIFT_UID/ GID will only work if the user starting podman has access to the /run/user/$ZWIFT_UID resources and does not work the same way as in Docker so is not supported.

## Where are the saves and why do I get a popup can't write to Document Folder?

This is a hang up from previous versions, mainly with podman. delete the volumes and after re-creation it should work fine.
```
podman volume rm zwift-xxxxx

or

docker volume rm zwift-xxxxx
```

NOTE: if you see a weird volume e.g. zwift-naeva it is a hang up from the past, delete it.

## I sometimes get a popup Not responding why?

For Gnome it is just timing out before zwift responds, just extend the timeout.

```
gsettings set org.gnome.mutter check-alive-timeout 60000
```

## The container is slow to start, why?

If your `$(id -u)` or `$(id -g)` is not equal to 1000 then this would cause the zwift container to re-map all files (chown, chgrp) within the container so there is no uid/gid conflicts. 
So if speed is a concern of yours, consider changing your user to match the containers uid and gid using `usermod` or contribute a better solution for handling uid/gid remapping in containers :)

## How do I connect my trainer, heart rate monitor, etc?

You can [use your phone as a bridge](https://support.zwift.com/using-the-zwift-companion-app-Hybn8qzPr).

For example, your Wahoo Kickr and Apple Watch conect to the Zwift Companion app on your
iPhone; then the Companion app connects over wifi to your PC running Zwift.

## How can I add custom .zwo files?
You can map the Zwift Workout folder using the environment variable ZWIFT_WORKOUT_DIR, for example if your workout directory is in $HOME/zwift_workouts then you would provide the environment variable

```ZWIFT_WORKOUT_DIR=$HOME/zwift_workouts```

You can add this variable into $HOME/.config/zwift/config or $HOME/.config/zwift/$USER-config.

The workouts folder will contain subvolders e.g. $HOME/.config/zwift/workouts/393938.  The number is your internal zwift id and you store you zwo files in the relevant folder.  There will usually be only one ID, however if you have multiple zwift login's it may show one subfolder for each, to find the ID you can use the following link: 

Webpage for finding internal ID: https://www.virtualonlinecycling.com/p/zwiftid.html

NOTES: 
- Any workouts created already will be copied into this folder on first start
- To add a new workout just copy the zwo file to this directory
- Deleting files from the directory will not delete them, they will be re-added when re-starting zwift, you must delete from the zwift menu

## How can I build the image myself?

```console
./bin/build-image.sh
```

## How can I fetch the image from docker hub?

https://hub.docker.com/r/netbrain/zwift

```console
docker pull netbrain/zwift:$VERSION # or simply latest
```

## How can I update Zwift?

The `zwift.sh` script will update zwift by checking for new image versions on every launch, however if you are not using this then you will have to pull netbrain/zwift:latest from time to time in order to be on the latest version.

There is a github action in place that will update zwift on a scheduled basis and publish new versions to docker hub.

## How can I install this on NixOS?

To use the NixOS module, configure your flake.nix:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zwift.url = "github:netbrain/zwift";
  };

  outputs = { nixpkgs, zwift, ... }: {
    nixosConfigurations."«hostname»" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ zwift.nixosModules.zwift ./configuration.nix ];
    };
  };
}
```

Then enable and configure the module in your NixOS configuration. The configuration options are written analog to the environment variables in camelCase:

```nix
{
  programs.zwift = {
   enable = true;

   #dontPull = true;
   #dontCheck = true;
   #version = "1.87.0";
  }
}
```

## Sponsors 💖

These are our really cool sponsors!

<!-- sponsors --><a href="https://github.com/altheus"><img src="https:&#x2F;&#x2F;github.com&#x2F;altheus.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/nowave7"><img src="https:&#x2F;&#x2F;github.com&#x2F;nowave7.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/cmuench"><img src="https:&#x2F;&#x2F;github.com&#x2F;cmuench.png" width="60px" alt="User avatar: Christian Münch" /></a><a href="https://github.com/nibbles-bytes"><img src="https:&#x2F;&#x2F;github.com&#x2F;nibbles-bytes.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/saltymedic"><img src="https:&#x2F;&#x2F;github.com&#x2F;saltymedic.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/ZachS"><img src="https:&#x2F;&#x2F;github.com&#x2F;ZachS.png" width="60px" alt="User avatar: Jethro Zach Solomon" /></a><a href="https://github.com/SvenHaedrich"><img src="https:&#x2F;&#x2F;github.com&#x2F;SvenHaedrich.png" width="60px" alt="User avatar: Sven Hädrich" /></a><a href="https://github.com/relief-melone"><img src="https:&#x2F;&#x2F;github.com&#x2F;relief-melone.png" width="60px" alt="User avatar: Relief.Melone" /></a><!-- sponsors -->

## Contributors ✨

Thanks go to these wonderful people:

<a href="https://github.com/quivrhq/quivr/graphs/contributors">
<img src="https://contrib.rocks/image?repo=netbrain/zwift" />
</a>

### Contribute 👋

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

## ⭐ Star History (for fun and giggles)

[![Star History Chart](https://api.star-history.com/svg?repos=netbrain/zwift&type=Date)](https://star-history.com/#netbrain/zwift&Date)


[zwift-updater-src]:https://github.com/netbrain/zwift/actions/workflows/zwift_updater.yaml/badge.svg
[zwift-updater-href]:https://github.com/netbrain/zwift/actions/workflows/zwift_updater.yaml
[image-version-src]:https://img.shields.io/docker/v/netbrain/zwift/latest?logo=docker&logoColor=white
[image-pulls-src]:https://badgen.net/docker/pulls/netbrain/zwift?icon=docker&label=pulls
[image-size-src]:https://badgen.net/docker/size/netbrain/zwift?icon=docker&label=size
[image-href]:https://hub.docker.com/r/netbrain/zwift/tags
