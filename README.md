# Zwift

[![Zwift updater][zwift-updater-src]][zwift-updater-href]
[![image-href][image-pulls-src]][image-href]
[![image-href][image-version-src]][image-href]
[![image-href][image-size-src]][image-href]

Hello fellow zwifters, here is a docker image for running zwift on linux. It uses the companion app by zwift for linking up
smart trainers and other bluetooth devices (ant devices are not supported via the companion app). The reason why I made this
solution was so I could run multiple zwift instances on one machine at the same time.

The container comes pre-installed with zwift, so no setup is required, simply pull and run. It should also now support all
manner of graphics cards that have gl rendering.

If you find this image useful, then feel free to
[add me on zwift](https://www.zwift.com/eu/athlete/4e3c5880-1edd-4c5d-a1b8-0974ce3874f0) and give me a ride on from time to
time.

![example.gif](https://raw.githubusercontent.com/netbrain/zwift/master/example.gif)

## Prerequisites

- [Docker](https://docs.docker.com/get-docker) or [Podman](https://podman.io/getting-started/installation)
- [nvidia-container-toolkit](https://github.com/NVIDIA/nvidia-container-toolkit) if you have nvidia proprietary driver
- ATI, Intel and Nouveau drivers should work out of the box

> :warning: **Podman Support 4.3 and Later.**: Podman before 4.3 does not support `--userns=keep-id:uid=xxx,gid=xxx` and will
  not start correctly, this impacts Ubuntu 22.04 and related builds such as PopOS 22.04. See Podman Section below.

## Install

```console
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/netbrain/zwift/master/bin/install.sh)"
```

This will put the `zwift.sh` script on your `$PATH`, add a desktop icon to `/usr/local/share/applications`.

NOTE: Icon may not show until logging off and back in.

## RUN

After installation, simply run:

```console
zwift
```

NOTE: You might want to disable video screenshots ([#75](https://github.com/netbrain/zwift/issues/75))

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

## How can I access/modify the graphics settings?

By default, zwift assigns a graphics profile based on your graphics card. This profile can be either basic, medium, high, or
ultra. This profile determines the level of detail and the quality of the textures you get in game. It is not possible to change
which graphics profile the game uses. When the default options of the profile aren't optimal (for example when zwift doesn't
recognize your graphics card and you only get the `medium` profile or when your cpu is the bottleneck and your fps is on the low
side because zwift assigned the ultra profile), it is possible to manually tweak the graphics settings by setting
`ZWIFT_OVERRIDE_GRAPHICS=1`, and editing the settings in the `$HOME/.config/zwift/graphics.txt` or
`$HOME/.config/zwift/$USER-graphics.txt` file as you see fit. To find out which profile zwift assigned, you can upload your
zwift log to <https://zwiftalizer.com>.

The default settings for the different profiles are:

| key                  | description                                            | basic        | medium       | high         | ultra         |
|----------------------|--------------------------------------------------------|--------------|--------------|--------------|---------------|
| `res`                | texture resolution (independent from game resolution)  | 1024x576(0x) | 1280x720(0x) | 1280x720(0x) | 1920x1080(0x) |
| `sres`               | shadow resolution                                      | 512x512      | 1024x1024    | 1024x1024    | 2048x2048     |
| `gSSAO`              | enable high-quality lighting and shadows               | 0            | 0            | 1            | 1             |
| `gFXAA`              | enable anti-aliasing                                   | 1            | 1            | 1            | 1             |
| `gSunRays`           | enable sun rays (default 1)                            | 0            | 0            |              |               |
| `gHeadLight`         | enable bike headlights (default 1)                     | 0            | 0            |              |               |
| `gFoliagePercent`    | reduce/increase auto-generated foliage (default 1.0)   | 0.5          | 0.5          |              |               |
| `gSimpleReflections` | lower quality reflections (default 0)                  | 1            | 1            |              |               |
| `gLODBias`           | lower polygon count (higher value is lower, default 0) | 1            | 1            |              |               |
| `gShowFPS`           | display fps in the top left corner (default 0)         |              |              |              |               |

The number in parentheses after the texture resolution (for example `(0x)` after `1920x1080`) is the anti-aliasing setting. This
number can be modified to for example `1920x1080(4x)` or `1920x1080(8x)` to increase anti-aliasing.

Example `$HOME/.config/zwift/graphics.txt` (settings from the ultra profile, with in-game fps counter enabled):

```text
res 1920x1080(0x)
sres 2048x2048
set gSSAO=1
set gFXAA=1
set gShowFPS=1
```

Start zwift with the `ZWIFT_OVERRIDE_GRAPHICS=1 zwift` command to use the settings from the graphics.txt file.

You can find more information about these settings in this [Zwift Insider](https://zwiftinsider.com/config-file-tweaks/)
article. Note that this is an older article and as such some of the information in it is outdated. The default values of the
different profiles have changed to what is in the table listed above and for example the `aniso` setting does not exist anymore.

> :warning: **Before using ZWIFT_OVERRIDE_GRAPHICS**: This option requires that the `$HOME/.config/zwift/graphics.txt` file
exists. If a `graphics.txt` does not exist and the `ZWIFT_OVERRIDE_GRAPHICS` option is used, it will be created automatically
the first time zwift is launched.

Aside from the graphics profile which is assigned by zwift and cannot be changed, there is also the in-game setting to change
the display resolution. Changing this resolution does not change the graphics profile and as such does not affect the quality of
the textures, shadows, and other graphics options. It only affects the resolution of the game itself. Which resolutions are
available in the zwift in-game setting is dependent on the graphics profile assigned based on your graphics card. If zwift does
not recognize your graphics card or you have a WQHD or UHD display and zwift does not offer the higher resolutions, it is
possible to manually override the game resolution by setting the `ZWIFT_OVERRIDE_RESOLUTION` option. For example to force zwift
to use UHD you can launch it using `ZWIFT_OVERRIDE_RESOLUTION=3840x2160 zwift`.

The full list of available resolutions is:

| name   | resolution | pixels    |
|--------|------------|-----------|
| Low    | 576p       | 720x576   |
| Medium | 720p       | 1280x720  |
| High   | 1080p      | 1920x1080 |
| Ultra  | 1440p      | 2560x1440 |
| 4k UHD | 2160p      | 3840x2160 |

> :warning: **Before using ZWIFT_OVERRIDE_RESOLUTION**: This option requires that the `prefs.xml` file exists. Make sure to
  launch zwift at least once so it creates the `prefs.xml` file before using the `ZWIFT_OVERRIDE_RESOLUTION` option.

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

Then enable and configure the module in your NixOS configuration. The configuration options are written analog to the
environment variables in camelCase:

```nix
{
  programs.zwift = {
    # Enable the zwift module and install required dependencies
    enable = true;
    # The Docker image to use for zwift
    image = "docker.io/netbrain/zwift";
    # The zwift game version to run
    version = "1.67.0";
    # Container tool to run zwift (e.g., "podman" or "docker")
    containerTool = "podman";
    # If true, do not pull the image (use locally cached image)
    dontPull = false;
    # If true, skip new version check
    dontCheck = false;
    # If true, print the container run command and exit
    dryRun = false;
    # If set, launch container with "-it --entrypoint bash" for debugging
    interactive = false;
    # Extra args passed to docker/podman (e.g. "--cpus=1.5")
    containerExtraArgs = "";
    # Zwift account username (email address)
    zwiftUsername = "user@example.com";
    # Zwift account password
    zwiftPassword = "xxxx";
    # Directory to store zwift workout files
    zwiftWorkoutDir = "/var/lib/zwift/workouts";
    # Directory to store zwift activity files
    zwiftActivityDir = "/var/lib/zwift/activities";
    # Directory to store zwift log files
    zwiftLogDir = "/var/lib/zwift/logs";
    # Directory to store zwift screenshots
    zwiftScreenshotsDir = "/var/lib/zwift/screenshots";
    # Run zwift in the foreground (set true for foreground mode)
    zwiftFg = false;
    # Disable Linux GameMode if true
    zwiftNoGameMode = false;
    # Enable Wine's experimental Wayland support if using Wayland
    wineExperimentalWayland = false;
    # Networking mode for the container ("bridge" is default)
    networking = "bridge";
    # User ID for running the container (usually your own UID)
    zwiftUid = "1000";
    # Group ID for running the container (usually your own GID)
    zwiftGid = "1000";
    # GPU/device flags override (Docker: "--gpus=all", Podman/CDI: "--device=nvidia.com/gpu=all")
    vgaDeviceFlag = "--device=nvidia.com/gpu=all";
    # Enable debug output and verbose logging if true
    debug = false;
    # If set, run container in privileged mode ("--privileged --security-opt label=disable")
    privilegedContainer = false;
  };
}
```

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

## Sponsors 💖

These are our really cool sponsors!

<!-- markdownlint-disable line-length -->
<!-- cSpell:disable -->
<!-- sponsors --><a href="https://github.com/altheus"><img src="https:&#x2F;&#x2F;github.com&#x2F;altheus.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/nowave7"><img src="https:&#x2F;&#x2F;github.com&#x2F;nowave7.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/cmuench"><img src="https:&#x2F;&#x2F;github.com&#x2F;cmuench.png" width="60px" alt="User avatar: Christian Münch" /></a><a href="https://github.com/nibbles-bytes"><img src="https:&#x2F;&#x2F;github.com&#x2F;nibbles-bytes.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/saltymedic"><img src="https:&#x2F;&#x2F;github.com&#x2F;saltymedic.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/ZachS"><img src="https:&#x2F;&#x2F;github.com&#x2F;ZachS.png" width="60px" alt="User avatar: Jethro Zach Solomon" /></a><a href="https://github.com/SvenHaedrich"><img src="https:&#x2F;&#x2F;github.com&#x2F;SvenHaedrich.png" width="60px" alt="User avatar: Sven Hädrich" /></a><a href="https://github.com/relief-melone"><img src="https:&#x2F;&#x2F;github.com&#x2F;relief-melone.png" width="60px" alt="User avatar: Relief.Melone" /></a><a href="https://github.com/pdelagrave"><img src="https:&#x2F;&#x2F;github.com&#x2F;pdelagrave.png" width="60px" alt="User avatar: Pierre Delagrave" /></a><a href="https://github.com/sphexator"><img src="https:&#x2F;&#x2F;github.com&#x2F;sphexator.png" width="60px" alt="User avatar: Kristoffer T." /></a><a href="https://github.com/fliesentischsound"><img src="https:&#x2F;&#x2F;github.com&#x2F;fliesentischsound.png" width="60px" alt="User avatar: Robin" /></a><a href="https://github.com/Trawnick"><img src="https:&#x2F;&#x2F;github.com&#x2F;Trawnick.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/PlombiP"><img src="https:&#x2F;&#x2F;github.com&#x2F;PlombiP.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/iter59"><img src="https:&#x2F;&#x2F;github.com&#x2F;iter59.png" width="60px" alt="User avatar: " /></a><!-- sponsors -->
<!-- cSpell:enable -->
<!-- markdownlint-enable line-length -->

## Contributors ✨

Thanks go to these wonderful people:

[![Contributors](https://contrib.rocks/image?repo=netbrain/zwift)](https://github.com/netbrain/zwift/graphs/contributors)

### Contribute 👋

If you would like to contribute, then please by all means I'll accept PRs. A good starting point would be to see if there's
any open issues that you feel capable of doing. Let me know if I can help with anything.

### Show and tell 🙌

Check out our [Show and tell](https://github.com/netbrain/zwift/discussions/categories/show-and-tell) category in discussions
and see how other people are using this solution, feel free to contribute your own tips and tricks :smiley:

## Alternative's to this repository

- Install zwift using wine directly or a framework like `lutris`. You will however have to manage installation and updates
  yourself
- Use [`scrcpy`](https://github.com/Genymobile/scrcpy) to mirror android device to your linux screen
  - [Enable developer options on your android device](https://developer.android.com/studio/debug/dev-options#enable)
  - Pair your computer to the device using `adb pair`
    [documentation](https://developer.android.com/studio/command-line/adb#wireless-android11-command-line)
    - `./srccpy.sh adb pair ip:port`  [see my container solution](https://github.com/netbrain/dockerfiles/tree/master/scrcpy)
  - Mirror the android device screen onto your linux screen using `scrcpy`.
    - `./srccpy.sh scrcpy --tcpip=ip:port`
  - If you require sound as well, there's also a [`sndcpy`](https://github.com/rom1v/sndcpy) project (doesn't support wireless
    though, but the aforementioned can be modified to use usb)
- Using [`redroid`](https://hub.docker.com/r/redroid/redroid) to install zwift apk onto a android emulator (not tested)
- Using a virtual machine with pci passthrough
  - <https://looking-glass.io/>
  - <https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF>
  - <https://github.com/VGPU-Community-Drivers/vGPU-Unlock-patcher> (if you have a nvidia card you can eat your cake, and have
    it too by creating `vgpus` for vms that leverage the host gpu, no dedicated gpu required)

## ⭐ Star History (for fun and giggles)

[![Star History Chart](https://api.star-history.com/svg?repos=netbrain/zwift&type=Date)](https://star-history.com/#netbrain/zwift&Date)

[zwift-updater-src]:https://github.com/netbrain/zwift/actions/workflows/zwift_updater.yaml/badge.svg
[zwift-updater-href]:https://github.com/netbrain/zwift/actions/workflows/zwift_updater.yaml
[image-version-src]:https://img.shields.io/docker/v/netbrain/zwift/latest?logo=docker&logoColor=white
[image-pulls-src]:https://badgen.net/docker/pulls/netbrain/zwift?icon=docker&label=pulls
[image-size-src]:https://badgen.net/docker/size/netbrain/zwift?icon=docker&label=size
[image-href]:https://hub.docker.com/r/netbrain/zwift/tags
