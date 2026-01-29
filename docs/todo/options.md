---
title: Configuration options
parent: TODO
nav_order: 2
---

# Configuration options

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
