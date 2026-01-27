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

## Configuration options

| Key                         | Default                    | Description                                                                                                                            |
|-----------------------------|----------------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| `USER`                      | `$USER`                    | Used in creating the zwift volume `zwift-$USER`                                                                                        |
| `IMAGE`                     | `docker.io/netbrain/zwift` | The image to use                                                                                                                       |
| `VERSION`                   | `latest`                   | The image version/tag to use                                                                                                           |
| `DONT_CHECK`                |                            | If set, don't check for updated `zwift.sh`                                                                                             |
| `DONT_PULL`                 |                            | If set, don't pull for new image version                                                                                               |
| `DRYRUN`                    |                            | If set, print the full container run command and exit                                                                                  |
| `INTERACTIVE`               |                            | If set, force `-it` and use `--entrypoint bash` for debugging                                                                          |
| `CONTAINER_TOOL`            |                            | Defaults to podman if installed, else docker                                                                                           |
| `CONTAINER_EXTRA_ARGS`      |                            | Extra args passed to docker/podman (`--cups=1.5`)                                                                                      |
| `ZWIFT_USERNAME`            |                            | If set, try to login to zwift automatically                                                                                            |
| `ZWIFT_PASSWORD`            |                            | If set, try to login to zwift automatically                                                                                            |
| `ZWIFT_WORKOUT_DIR`         |                            | Set the workouts directory location                                                                                                    |
| `ZWIFT_ACTIVITY_DIR`        |                            | Set the activities directory location                                                                                                  |
| `ZWIFT_LOG_DIR`             |                            | Set the logs directory location                                                                                                        |
| `ZWIFT_SCREENSHOTS_DIR`     |                            | Set the screenshots directory location, recommended to set `ZWIFT_SCREENSHOTS_DIR=$(xdg-user-dir PICTURES)/Zwift`                      |
| `ZWIFT_OVERRIDE_GRAPHICS`   |                            | If set, override the default zwift graphics profiles                                                                                   |
| `ZWIFT_OVERRIDE_RESOLUTION` |                            | If set, change game resolution (2560x1440, 3840x2160, ...)                                                                             |
| `ZWIFT_FG`                  |                            | If set, run the process in fg instead of bg (`-d`)                                                                                     |
| `ZWIFT_NO_GAMEMODE`         |                            | If set, don't run game mode                                                                                                            |
| `WINE_EXPERIMENTAL_WAYLAND` |                            | If set, try to use experimental wayland support in wine 9                                                                              |
| `NETWORKING`                | `bridge`                   | Sets the type of container networking to use.                                                                                          |
| `ZWIFT_UID`                 | current users id           | Sets the UID that Zwift will run as (docker only)                                                                                      |
| `ZWIFT_GID`                 | current users group id     | Sets the GID that Zwift will run as (docker only)                                                                                      |
| `DEBUG`                     |                            | If set enabled debug of zwift script `set -x`                                                                                          |
| `VGA_DEVICE_FLAG`           |                            | Override GPU/device flags for container (`--gpus=all`)                                                                                 |
| `PRIVILEGED_CONTAINER`      | `0`                        | If set, container will run in privileged mode, SELinux label separation will be disabled (`--privileged --security-opt label=disable`) |

These environment variables can be used to alter the execution of the zwift bash script.

Short note on NVIDIA Container Toolkit device flags:

- Podman: prefer setting `VGA_DEVICE_FLAG="--device=nvidia.com/gpu=all"` (CDI device request).
- Docker: prefer setting `VGA_DEVICE_FLAG="--gpus=all"`. If Docker ≥ 25 is configured with CDI
  (`nvidia-ctk runtime configure --enable-cdi`), `VGA_DEVICE_FLAG="--device=nvidia.com/gpu=all"` also works.

If you're running Docker with CDI and zwift fails to launch, try the long form `VGA_DEVICE_FLAG="--device=nvidia.com/gpu=all"`
(instead of `"--gpus=all"`).

See <https://github.com/netbrain/zwift/issues/208> for context.

Examples:

- `DONT_PULL=1 zwift` will prevent docker/podman pull before launch
- `DRYRUN=1 zwift` will print the underlying container run command and exit (no container is started)
- `INTERACTIVE=1 zwift` will force foreground `-it` and set `--entrypoint bash` for step-by-step debugging inside the container
- `CONTAINER_TOOL=docker zwift` will launch zwift with docker even if podman is installed
- `CONTAINER_EXTRA_ARGS=--cpus=1.5` will pass `--cpus=1.5` as extra argument to docker/podman (will use at most 1.5 CPU cores,
   this is useful on laptops to avoid overheating and subsequent throttling of the CPU by the system).
- `USER=Fred zwift` perfect if your neighbor fred want's to try zwift, and you don't want to mess up your zwift config.
- `NETWORKING=host zwift` will use host networking which may be needed to have zwift talk to wifi enabled trainers.
- `ZWIFT_UID=123 ZWIFT_GID=123 zwift` will run zwift as the given uid and gid. By default zwift runs with the uid and gid of
  the user that started the container. You should not need to change this except in rare cases. NOTE: This does not work in
  wayland only X11.
- `WINE_EXPERIMENTAL_WAYLAND=1 zwift` This will start zwift using Wayland and not XWayland. It will start full screen windowed.

You can also set these in `$HOME/.config/zwift/config` or `$HOME/.config/zwift/$USER-config` to be sourced by the `zwift.sh`
script on execution.

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

## Where are the saves and why do I get a popup can't write to Document Folder?

This is a hang up from previous versions, mainly with podman. delete the volumes and after re-creation it should work fine.

```text
podman volume rm zwift-xxxxx
```

or

```text
docker volume rm zwift-xxxxx
```

NOTE: if you see a weird volume e.g. `zwift-naeva` it is a hang up from the past, delete it.

## I sometimes get a popup Not responding why?

For Gnome it is just timing out before zwift responds, just extend the timeout.

```text
gsettings set org.gnome.mutter check-alive-timeout 60000
```

## The container is slow to start, why?

If your `$(id -u)` or `$(id -g)` is not equal to 1000 then this would cause the zwift container to re-map all files (`chown`,
`chgrp`) within the container so there is no uid/gid conflicts. So if speed is a concern of yours, consider changing your user
to match the containers uid and gid using `usermod` or contribute a better solution for handling uid/gid remapping in containers
:smiley:

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

## Troubleshooting

<details>
<summary><h3>My WiFi-capable trainer / Zwift Companion App is not detected</h3></summary>

If you have issues with device detection over WiFi/network, the issue may be related to your system's firewall.
Some Linux distributions use `firewalld` instead of `ufw`,
which is more restrictive and blocks multicast traffic by default,
which is essential for discovering devices over WiFi.

Distributions that use `firewalld` by default include:

- CentOS 7 and newer
- Fedora 18 and newer
- openSUSE 15 and newer (including Tumbleweed)

To check if the firewall is the issue, you can temporarily disable `firewalld`:

```console
systemctl stop firewalld
```

If your WiFi trainer / Zwift Companion App is now detected, the firewall is indeed the culprit.
Once you've identified this as the issue, you should configure your firewall
to allow multicast traffic on your network instead of disabling it entirely:

1. Identify your network/WiFi name.

2. Assign that network to a specific zone (e.g., "home"):

   (Assuming your distribution uses 'NetworkManager', which almost all do)

   **Via GUI**: On Plasma Settings (or similar), navigate to WiFi → [network name] → General → Firewall Zone, and select "home".

   **Via CLI**:

   ```console
   nmcli connection modify "<network name>" connection.zone home
   ```

3. Allow multicast traffic on the zone:

   The zone "home" might already be pre-configured with multicast support. If not, manually allow multicast with:

   ```console
   firewall-cmd --permanent --zone=home --add-rich-rule='rule family="ipv4" destination address="224.0.0.0/4" protocol value="udp" accept'
   ```

4. Restart `firewalld` or reload the configuration for the changes to take effect (shouldn't be needed but just in case):

   **Reload configuration** (recommended, no service interruption):

   ```console
   firewall-cmd --reload
   ```

   **Restart the service**:

   ```console
   systemctl restart firewalld
   ```

</details>
