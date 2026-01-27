---
title: Home
layout: home
nav_order: 1
description: "Easily Zwift on Linux!"
permalink: /
---

# netbrain/zwift

Easily Zwift on Linux! :100:

> :warning: **Podman Support 4.3 and Later.**: Podman before 4.3 does not support `--userns=keep-id:uid=xxx,gid=xxx` and will
  not start correctly, this impacts Ubuntu 22.04 and related builds such as PopOS 22.04. See Podman Section below.

If `dbus` is available through a unix socket, the screensaver will be inhibited every 30 seconds to prevent `xscreensaver` or
other programs listening on the bus from inhibiting the screen.

## How can I persist my login information so i don't need to login on every startup?

To authenticate through Zwift automatically simply add the following file `$HOME/.config/zwift/config`:

```text
ZWIFT_USERNAME=username
ZWIFT_PASSWORD=password
```

Where `username` is your zwift account email, and `password` your zwift account password, respectively.

The credentials will be used to authenticate before launching the zwift app, and the user should be logged in automatically in
the game.

NOTE: This will be loaded by `zwift.sh` in cleartext as environment variables into the container.

Alternatively, instead of saving your password in the file, you can save your password in the secret service keyring like so:

```text
secret-tool store --label "Zwift password for ${ZWIFT_USERNAME}" application zwift username ${ZWIFT_USERNAME}
```

In this case the username should still be saved in the config file and the password will be read upon startup from the keyring
and passed as a secret into the container (where it is an environment variable).

> :warning: **Do Not Quote the variables or add spaces**: The ID and Password are read as raw format so if you put
  `ZWIFT_PASSWORD="password"` it tries to use `"password"` and not just `password`, same for `''`.  In addition do not add a
  space to the end of the line it will be sent as part of the password or username. This applies to `ZWIFT_USERNAME` and
  `ZWIFT_PASSWORD`.

NOTE: You can also add other environment variable from the table to make starting easier:

```text
ZWIFT_USERNAME=username
ZWIFT_PASSWORD=password

ZWIFT_WORKOUT_DIR=~/.config/zwift/workouts
WINE_EXPERIMENTAL_WAYLAND=1
```

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
is in `$HOME/zwift_workouts` then you would provide the environment variable `ZWIFT_WORKOUT_DIR=$HOME/zwift_workouts`.

You can add this variable into `$HOME/.config/zwift/config` or `$HOME/.config/zwift/$USER-config`.

The workouts folder will contain subdirectories e.g. `$HOME/.config/zwift/workouts/393938`. The number is your internal zwift
id and you store you zwo files in the relevant folder. There will usually be only one ID, however if you have multiple zwift
logins it may show one subdirectory for each, to find the ID you can use the following link:

Webpage for finding internal ID: <https://www.virtualonlinecycling.com/p/zwiftid.html>

NOTES:

- Any workouts created already will be copied into this folder on first start
- To add a new workout just copy the zwo file to this directory
- Deleting files from the directory will not delete them, they will be re-added when re-starting zwift, you must delete from the
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
