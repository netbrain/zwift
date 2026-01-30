---
title: More stuff
nav_order: 5
parent: TODO
---

If `dbus` is available through a unix socket, the screensaver will be inhibited every 30 seconds to prevent `xscreensaver` or
other programs listening on the bus from inhibiting the screen.

## Podman Support

When running Zwift with podman, the user and group in the container is 1000 (user). To access the resources on the host we need
to map the container id 1000 to the host id using `uidmap` and `gidmap`.

For example if the host uid/gid is 1001/1001 then we need to map the host resources from `/run/user/1001` to the container
resource `/run/user/1000` and map the user and group id's the same. This had to be done manually on the host podman start using
`--uidmap` and `--gidmap` (not covered here).

From Podman 4.3 this became automatic by providing the Container UID/GID and podman automatically sets up this mapping.

NOTE: Using ZWIFT_UID/GID will only work if the user starting podman has access to the `/run/user/$ZWIFT_UID` resources and does
not work the same way as in Docker so is not supported.

## How do I connect my trainer, heart rate monitor, etc?

You can [use your phone as a bridge](https://support.zwift.com/using-the-zwift-companion-app-Hybn8qzPr).

For example, your Wahoo Kickr and Apple Watch connect to the Zwift Companion app on your iPhone; then the Companion app connects
over wifi to your PC running Zwift.

## How can I add custom .zwo files?

You can map the zwift Workout folder using the environment variable `ZWIFT_WORKOUT_DIR`, for example if your workout directory
is in `$HOME/zwift_workouts` then you would provide the environment variable `ZWIFT_WORKOUT_DIR="$HOME/zwift_workouts"`.

You can add this variable into `$HOME/.config/zwift/config` or `$HOME/.config/zwift/$USER-config`.

The workouts folder will contain subdirectories e.g. `$HOME/.config/zwift/workouts/393938`. The number is your internal zwift
id and you store you zwo files in the relevant folder. There will usually be only one ID, however if you have multiple zwift
logins it may show one subdirectory for each, to find the ID you can use the following link:

Webpage for finding internal ID: <https://www.virtualonlinecycling.com/p/zwiftid.html>

{: .note }
Any workouts created already will be copied into this folder on first start

{: .note }
To add a new workout just copy the zwo file to this directory

{: .note }
Deleting files from the directory will not delete them, they will be re-added when re-starting zwift, you must delete from the
zwift menu

## How can I build the image myself?

```console
./bin/build-image.sh
```

## How can I fetch the image from docker hub?

<https://hub.docker.com/r/netbrain/zwift>

```console
docker pull netbrain/zwift:$VERSION # or simply latest
```

## How can I update Zwift?

The `zwift.sh` script will update zwift by checking for new image versions on every launch, however if you are not using this
then you will have to pull `netbrain/zwift:latest` from time to time in order to be on the latest version.

There is a github action in place that will update zwift on a scheduled basis and publish new versions to docker hub.

{: .note }
> If you're running Docker with CDI and Zwift fails to launch, try the long form `VGA_DEVICE_FLAG="--device=nvidia.com/gpu=all"`
> (instead of `"--gpus=all"`).
>
> See <https://github.com/netbrain/zwift/issues/208> for context.
