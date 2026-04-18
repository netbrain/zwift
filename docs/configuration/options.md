---
title: Configuration Options
parent: Configuration
nav_order: 1
---

# Configuration Options

## Usage

Environment variables are used as configuration options. They can either be passed on the commandline or in a config file that
is sourced by the zwift script.

### Commandline

The zwift script uses environment variables passed on the commandline.

```console
foo@bar:~$ # examples using the commandline
foo@bar:~$ DONT_PULL="1" zwift # prevent docker/podman pull before launch
foo@bar:~$ DRYRUN="1" zwift # print the underlying container run command and exit
foo@bar:~$ DONT_PULL="1" DRYRUN="1" zwift # combine the previous two options
foo@bar:~$ INTERACTIVE="1" zwift # run in the foreground and set entrypoint to bash for debugging
foo@bar:~$ CONTAINER_TOOL="docker" zwift # launch zwift with docker even if podman is installed
foo@bar:~$ CONTAINER_EXTRA_ARGS="--cpus=1.5" zwift # pass --cpus=1.5 to docker/podman
foo@bar:~$ USER="fred" zwift # perfect if your neighbor Fred wants to try zwift
foo@bar:~$ NETWORKING="host" zwift # use host networking which is needed for wifi enabled trainers
foo@bar:~$ WINE_EXPERIMENTAL_WAYLAND="1" zwift # start zwift using Wayland instead of XWayland
```

### Configuration file

The zwift script automatically loads environment variables from the following configuration files:

- `$HOME/.config/zwift/config`
- `$HOME/.config/zwift/$USER-config`

```bash
# example configuration file
ZWIFT_USERNAME='user@mail.com'
ZWIFT_WORKOUT_DIR="$(xdg-user-dir DOCUMENTS)/Zwift/Workouts"
ZWIFT_LOG_DIR="$(xdg-user-dir DOCUMENTS)/Zwift/Logs"
ZWIFT_SCREENSHOTS_DIR="$(xdg-user-dir PICTURES)/Zwift"
NETWORKING="host"
ZWIFT_OVERRIDE_GRAPHICS="1"
CONTAINER_EXTRA_ARGS=(-e XCURSOR_SIZE=48 --cpus=1.5)
```

## List of Environment Variables

These environment variables can be used to alter the execution of the zwift bash script.

### Overview

| Key                                                       | Default value              | Description                                         |
|:----------------------------------------------------------|:---------------------------|:----------------------------------------------------|
| [`DEBUG`](#debug)                                         | `0`                        | Enable `set -x` for all scripts                     |
| [`VERBOSITY`](#verbosity)                                 | `1`                        | Configure how much output should be shown           |
| [`USER`](#user)                                           | `$USER`                    | Use a different user to avoid conflicts             |
| [`IMAGE`](#image)                                         | `docker.io/netbrain/zwift` | The image to use                                    |
| [`VERSION`](#version)                                     | `latest`                   | The image version/tag to use                        |
| [`SCRIPT_VERSION`](#script_version)                       | `master`                   | The `zwift.sh` script version to use                |
| [`DONT_CHECK`](#dont_check)                               | `0`                        | If set to `1`, don't check for updated `zwift.sh`   |
| [`DONT_PULL`](#dont_pull)                                 | `0`                        | If set to `1`, don't pull for new image version     |
| [`DONT_CLEAN`](#dont_clean)                               | `0`                        | If set to `1`, don't clean up previous images       |
| [`DRYRUN`](#dryrun)                                       | `0`                        | If set to `1`, only print the container run command |
| [`INTERACTIVE`](#interactive)                             | `0`                        | If set to `1`, attach to the container terminal     |
| [`CONTAINER_TOOL`](#container_tool)                       |                            | Defaults to podman if installed, else docker        |
| [`CONTAINER_EXTRA_ARGS`](#container_extra_args)           |                            | Extra arguments to pass to podman/docker            |
| [`ZWIFT_USERNAME`](#zwift_username)                       |                            | Zwift username. If set, login automatically         |
| [`ZWIFT_PASSWORD`](#zwift_password)                       |                            | Zwift password.                                     |
| [`ZWIFT_WORKOUT_DIR`](#zwift_workout_dir)                 |                            | Set the workouts directory location                 |
| [`ZWIFT_ACTIVITY_DIR`](#zwift_activity_dir)               |                            | Set the activities directory location               |
| [`ZWIFT_LOG_DIR`](#zwift_log_dir)                         |                            | Set the logs directory location                     |
| [`ZWIFT_SCREENSHOTS_DIR`](#zwift_screenshots_dir)         |                            | Set the screenshots directory location              |
| [`ZWIFT_OVERRIDE_GRAPHICS`](#zwift_override_graphics)     | `0`                        | If set to `1`, override the zwift graphics profiles |
| [`ZWIFT_OVERRIDE_RESOLUTION`](#zwift_override_resolution) |                            | If set, change the game resolution                  |
| [`ZWIFT_FG`](#zwift_fg)                                   | `0`                        | If set to `1`, run the container in the foreground  |
| [`ZWIFT_NO_GAMEMODE`](#zwift_no_gamemode)                 | `0`                        | If set to `1`, don't run game mode                  |
| [`WINE_EXPERIMENTAL_WAYLAND`](#wine_experimental_wayland) | `0`                        | If set to `1`, use native Wayland                   |
| [`NETWORKING`](#networking)                               | `bridge`                   | Sets the type of container networking to use        |
| [`ZWIFT_UID`](#zwift_uid)                                 | `$(id -u)`                 | Sets the UID that Zwift will run as                 |
| [`ZWIFT_GID`](#zwift_gid)                                 | `$(id -g)`                 | Sets the GID that Zwift will run as                 |
| [`VGA_DEVICE_FLAG`](#vga_device_flag)                     |                            | Override container GPU/device flags                 |
| [`PRIVILEGED_CONTAINER`](#privileged_container)           | `0`                        | If set to `1`, run the container in privileged mode |
| [`ZWIFT_NO_PRIVILEGED`](#zwift_no_privileged)             | `0`                        | If set to `1`, disable privileged mode on non-SELinux systems |

---

### `DEBUG`

If enabled, echo all bash commands in the terminal (enables `set -x` for all scripts).

| Item              | Description               |
|:------------------|:--------------------------|
| Allowed values    | `0` - Disable debug mode. |
|                   | `1` - Enable debug mode.  |
| Default value     | `0`                       |
| Commandline usage | `DEBUG="1" zwift`         |
| Config file usage | :x:                       |

{: .warning }
If DEBUG is enabled, your username and password will be printed in the console in plain text. Before copy-pasting the zwift
script output into for example an issue, make sure to censor your zwift username and password! If ZWIFT_FG is enabled, you
should also remove the contents of the authentication token before sharing the output.

---

### `VERBOSITY`

Set the verbosity level. The output shown by the zwift scripts depends on this setting.

| Item              | Description                                                                   |
|:------------------|:------------------------------------------------------------------------------|
| Allowed values    | `0` - Show ok, warning and error messages.                                    |
|                   | `1` - Show ok, warning, error and info messages.                              |
|                   | `2` - Show ok, warning, error and info messages. Also show timestamps.        |
|                   | `3` - Show ok, warning, error, info and debug messages. Also show timestamps. |
| Default value     | `1`                                                                           |
| Commandline usage | `VERBOSITY="3" zwift`                                                         |
| Config file usage | `VERBOSITY="3"`                                                               |

{: .note }
Questions where user input is required are always shown, regardless of the verbosity level.

---

### `USER`

Use a different user to avoid configuration conflicts. Especially useful if you want to be able to use multiple zwift accounts
on a single linux user account.

- Used in sourcing the configuration file `$HOME/.config/zwift/$USER-config`.
- Used in creating the zwift volume `zwift-$USER`.

| Item              | Description         |
|:------------------|:--------------------|
| Allowed values    | string              |
| Default value     | `$USER`             |
| Commandline usage | `USER="fred" zwift` |
| Config file usage | :x:                 |

#### Example: Two Zwift users sharing a single Linux user account

- Fred and Bob both want to run Zwift on the same linux user account.

- The `$HOME/.config/zwift/config` file could look like:

  ```bash
  ZWIFT_USERNAME='bob@mail.com'
  ZWIFT_PASSWORD='the password for bob'
  NETWORKING="host"
  ZWIFT_OVERRIDE_GRAPHICS="1"
  ```

- The `$HOME/.config/zwift/fred-config` file could look like:

  ```bash
  ZWIFT_USERNAME='fred@mail.com'
  ZWIFT_PASSWORD='the password for fred'
  ```

  Running `USER="fred" zwift` will first load the `config` file and then the `fred-config` file. The values in the `fred-config`
  file will overwrite the values in the `config` file. So the zwift script will use Fred's username and password.

---

### `IMAGE`

See also [`VERSION`](#version), [`DONT_PULL`](#dont_pull).

Specify which container image to use.

| Item              | Description                     |
|:------------------|:--------------------------------|
| Allowed values    | string                          |
| Default value     | `docker.io/netbrain/zwift`      |
| Commandline usage | `IMAGE="localhost/zwift" zwift` |
| Config file usage | `IMAGE="localhost/zwift"`       |

{: .important }
When using a local image, you should also set `DONT_PULL="1"` to prevent the zwift script from trying to pull the image.

---

### `VERSION`

See also [`IMAGE`](#image), [`DONT_PULL`](#dont_pull).

Specify which container image version/tag to use. This can be useful to pin the image to a specific Zwift version.

| Item              | Description                |
|:------------------|:---------------------------|
| Allowed values    | string                     |
| Default value     | `latest`                   |
| Commandline usage | `VERSION="v1.110.2" zwift` |
| Config file usage | `VERSION="v1.110.2"`       |

{: .warning }
Pinning to a specific image version may result in Zwift failing to launch. Only use this option if you have a good reason.

---

### `SCRIPT_VERSION`

See also [`DONT_CHECK`](#dont_check).

Pin the `zwift.sh` script to a specific version.

| Item              | Description                                |
|:------------------|:-------------------------------------------|
| Allowed values    | `master` - Use the latest version.         |
|                   | `commit hash` - Pin to a specific version. |
| Default value     | `master`                                   |
| Commandline usage | `SCRIPT_VERSION="cd50c7" zwift`            |
| Config file usage | `SCRIPT_VERSION="cd50c7"`                  |

- To find the commit hashes, look at the zwift script git history on github at:
  <https://github.com/netbrain/zwift/commits/master/src/zwift.sh>.
- When using a commit hash, it is enough to specify the first 6 characters. For example to pin to commit
  `cd50c7454268a9bfa5de0e6615eb43b9e080b9b2` it is enough to set `SCRIPT_VERSION="cd50c7"`.

{: .warning }
Pinning to a specific image version may result in Zwift failing to launch. Only use this option if you have a good reason.

---

### `DONT_CHECK`

See also [`SCRIPT_VERSION`](#script_version).

If set to `1`, don't check for updated `zwift.sh` script.

| Item              | Description                                      |
|:------------------|:-------------------------------------------------|
| Allowed values    | `0` - Check for updated `zwift.sh` script.       |
|                   | `1` - Don't check for updated `zwift.sh` script. |
| Default value     | `0`                                              |
| Commandline usage | `DONT_CHECK="1" zwift`                           |
| Config file usage | `DONT_CHECK="1"`                                 |

{: .important }
Prefer pinning the zwift script to a specific version using `SCRIPT_VERSION="..."` instead of using `DONT_CHECK="1"`.

{: .warning }
Not updating the zwift script may result in Zwift failing to launch. Only use this option if you have a good reason.

---

### `DONT_PULL`

See also [`IMAGE`](#image), [`VERSION`](#version).

If set to `1`, don't pull for a new image version (implies `DONT_CLEAN=1`).

| Item              | Description                                    |
|:------------------|:-----------------------------------------------|
| Allowed values    | `0` - Check for updated container image.       |
|                   | `1` - Don't check for updated container image. |
| Default value     | `0`                                            |
| Commandline usage | `DONT_PULL="1" zwift`                          |
| Config file usage | `DONT_PULL="1"`                                |

{: .important }
Prefer pinning the container image to a specific version using `VERSION="..."` instead of using `DONT_PULL="1"`.

{: .warning }
Not updating the container image may result in Zwift failing to launch. Only use this option if you have a good reason.

---

### `DONT_CLEAN`

See also [`DONT_PULL`](#dont_pull).

If set to `1`, don't clean up previous image versions after pulling.

| Item              | Description                                                 |
|:------------------|:------------------------------------------------------------|
| Allowed values    | `0` - Clean up previous image versions after pulling.       |
|                   | `1` - Don't clean up previous image versions after pulling. |
| Default value     | `0`                                                         |
| Commandline usage | `DONT_CLEAN="1" zwift`                                      |
| Config file usage | `DONT_CLEAN="1"`                                            |

---

### `DRYRUN`

See also [`VERBOSITY`](#verbosity).

If set to `1`, print the full container run command and exit without launching Zwift.

| Item              | Description                                                    |
|:------------------|:---------------------------------------------------------------|
| Allowed values    | `0` - Launch Zwift.                                            |
|                   | `1` - Instead of launching Zwift, print the container command. |
| Default value     | `0`                                                            |
| Commandline usage | `DRYRUN="1" zwift`                                             |
| Config file usage | `DRYRUN="1"`                                                   |

{: .note }
The container command is also printed when the verbosity level is set to at least 3.

---

### `INTERACTIVE`

If set to `1`, launch the Zwift container in interactive mode. Instead of starting Zwift, the terminal will attach to the
container bash. This option will launch the container interactively with `-it` and use `--entrypoint bash` for debugging.

| Item              | Description                                                          |
|:------------------|:---------------------------------------------------------------------|
| Allowed values    | `0` - Launch Zwift.                                                  |
|                   | `1` - Instead of launching Zwift, connect to the container terminal. |
| Default value     | `0`                                                                  |
| Commandline usage | `INTERACTIVE="1" zwift`                                              |
| Config file usage | `INTERACTIVE="1"`                                                    |

---

### `CONTAINER_TOOL`

Configure which container tool to use.

| Item              | Description                                         |
|:------------------|:----------------------------------------------------|
| Allowed values    | `podman` - Use podman as container tool.            |
|                   | `docker` - Use docker as container tool.            |
| Default value     | `podman` if available, otherwise fall back `docker` |
| Commandline usage | `CONTAINER_TOOL="docker" zwift`                     |
| Config file usage | `CONTAINER_TOOL="docker"`                           |

---

### `CONTAINER_EXTRA_ARGS`

See also [Script Arguments](../arguments).

Provide a list of extra arguments to pass to the container tool (podman or docker).

| Item              | Description                                                                  |
|:------------------|:-----------------------------------------------------------------------------|
| Allowed values    | list                                                                         |
|                   | string                                                                       |
| Default value     |                                                                              |
| Commandline usage | `CONTAINER_EXTRA_ARGS="-e XCURSOR_SIZE=48 --cpus=1.5" zwift` - Use a string. |
| Config file usage | `CONTAINER_EXTRA_ARGS=(-e XCURSOR_SIZE=48 --cpus=1.5)` - Use a list.         |

The `CONTAINER_EXTRA_ARGS` option can also be used to pass extra environment variables to the container. To do so, use the `-e`
option. For example, to set the `XCURSOR_SIZE` environment variable to increase the Zwift cursor size, use:

```console
foo@bar:~$ # example using the commandline
foo@bar:~$ CONTAINER_EXTRA_ARGS="-e XCURSOR_SIZE=48" zwift
```

```bash
# example config file
CONTAINER_EXTRA_ARGS=(
    -e XCURSOR_SIZE=48             # set the Zwift cursor size
    -e HELLO_WORLD="Hello, world!" # pass another environment variable to the container
    --cpus=1.5                     # maybe also limit the cpu cores for the container
)
```

{: .important }
> It is not possible to pass values with spaces using the commandline. The following example will cause the zwift script to exit
> with an error!
>
> ```console
> foo@bar:~$ CONTAINER_EXTRA_ARGS="-e HELLO_WORLD='Hello, world!'" zwift
> ```
>
> It is however possible to do so in the config file using an array:
>
> ```bash
> # config file
> CONTAINER_EXTRA_ARGS=(-e HELLO_WORLD="Hello, world!")
> ```
>
> For this reason the zwift script will issue a warning if the `CONTAINER_EXTRA_ARGS` option is defined as a string instead of
> as a list.

---

### `ZWIFT_USERNAME`

See also [`ZWIFT_PASSWORD`](#zwift_password), [Authentication](../authentication).

Set your zwift username to automatically log into Zwift.

| Item              | Description                            |
|:------------------|:---------------------------------------|
| Allowed values    | string                                 |
| Default value     |                                        |
| Commandline usage | `ZWIFT_USERNAME='user@mail.com' zwift` |
| Config file usage | `ZWIFT_USERNAME='user@mail.com'`       |

---

### `ZWIFT_PASSWORD`

See also [`ZWIFT_USERNAME`](#zwift_username), [Authentication](../authentication).

Set your zwift password to automatically log into Zwift.

| Item              | Description                          |
|:------------------|:-------------------------------------|
| Allowed values    | string                               |
| Default value     |                                      |
| Commandline usage | `ZWIFT_PASSWORD='P4$w0rd\123' zwift` |
| Config file usage | `ZWIFT_PASSWORD='P4$w0rd\123'`       |

{: .important }
Use single quotes around your password instead of double quotes! When using double quotes `"` special sequences are substituted,
when using single quotes `'` all characters are treated literally.

{: .important }
> Special care needs to be taken if your password contains single quotes `'`!
>
> The solution is a bit different depending on whether the `'` appears at the start, somewhere in the middle or at the end of
> the password:
>
> - For a password with value `p'as`, set `ZWIFT_PASSWORD='p'"'"'as'` (replace `'` with `'"'"'`)
> - For a password with value `'pas`, set `ZWIFT_PASSWORD="'"'pas'` (prepend `'pas'` with `"'"`)
> - For a password with value `pas'`, set `ZWIFT_PASSWORD='pas'"'"` (append `"'"` to `'pas'`)
>
> If the password contains multiple single quotes, the above rules can be combined. For multiple consecutive quotes, use the
> same rule as for a single quote (for example to use password `p''as`, set `ZWIFT_PASSWORD='p'"''"'as'`).

{: .warning }
It is not recommended to store your password as plain text in the config file. Read the
[Authentication](../authentication) section to learn how to store your password using the Linux secret tool.

---

### `ZWIFT_WORKOUT_DIR`

See also [`ZWIFT_ACTIVITY_DIR`](#zwift_activity_dir), [`ZWIFT_LOG_DIR`](#zwift_log_dir),
[`ZWIFT_SCREENSHOTS_DIR`](#zwift_screenshots_dir).

Zwift workouts are stored inside the container, in the zwift user volume. If you need to access that directory to add or remove
custom workout files, use `ZWIFT_WORKOUT_DIR` to map it to a directory on the host.

| Item              | Description                                                          |
|:------------------|:---------------------------------------------------------------------|
| Allowed values    | string                                                               |
| Default value     |                                                                      |
| Recommended value | `$(xdg-user-dir DOCUMENTS)/Zwift/Workouts`                           |
| Commandline usage | `ZWIFT_WORKOUT_DIR="$(xdg-user-dir DOCUMENTS)/Zwift/Workouts" zwift` |
| Config file usage | `ZWIFT_WORKOUT_DIR="$(xdg-user-dir DOCUMENTS)/Zwift/Workouts"`       |

{: .note }
> The directory must exist on the host, you can create it using:
>
> ```bash
> mkdir -p "$(xdg-user-dir DOCUMENTS)/Zwift/Workouts"
> ```

---

### `ZWIFT_ACTIVITY_DIR`

See also [`ZWIFT_WORKOUT_DIR`](#zwift_workout_dir), [`ZWIFT_LOG_DIR`](#zwift_log_dir),
[`ZWIFT_SCREENSHOTS_DIR`](#zwift_screenshots_dir).

Zwift activities are stored inside the container, in the zwift user volume. If you need access to that directory to recover fit
files after Zwift crashed, use `ZWIFT_ACTIVITY_DIR` to map it to a directory on the host.

| Item              | Description                                                             |
|:------------------|:------------------------------------------------------------------------|
| Allowed values    | string                                                                  |
| Default value     |                                                                         |
| Recommended value | `$(xdg-user-dir DOCUMENTS)/Zwift/Activities`                            |
| Commandline usage | `ZWIFT_ACTIVITY_DIR="$(xdg-user-dir DOCUMENTS)/Zwift/Activities" zwift` |
| Config file usage | `ZWIFT_ACTIVITY_DIR="$(xdg-user-dir DOCUMENTS)/Zwift/Activities"`       |

{: .note }
> The directory must exist on the host, you can create it using:
>
> ```bash
> mkdir -p "$(xdg-user-dir DOCUMENTS)/Zwift/Activities"
> ```

---

### `ZWIFT_LOG_DIR`

See also [`ZWIFT_WORKOUT_DIR`](#zwift_workout_dir), [`ZWIFT_ACTIVITY_DIR`](#zwift_activity_dir),
[`ZWIFT_SCREENSHOTS_DIR`](#zwift_screenshots_dir).

Zwift game and launcher logs are stored inside the container, in the zwift user volume. If you need to access the log files,
use `ZWIFT_LOG_DIR` to map the logs directory to a directory on the host.

| Item              | Description                                                  |
|:------------------|:-------------------------------------------------------------|
| Allowed values    | string                                                       |
| Default value     |                                                              |
| Recommended value | `$(xdg-user-dir DOCUMENTS)/Zwift/Logs`                       |
| Commandline usage | `ZWIFT_LOG_DIR="$(xdg-user-dir DOCUMENTS)/Zwift/Logs" zwift` |
| Config file usage | `ZWIFT_LOG_DIR="$(xdg-user-dir DOCUMENTS)/Zwift/Logs"`       |

{: .note }
> The directory must exist on the host, you can create it using:
>
> ```bash
> mkdir -p "$(xdg-user-dir DOCUMENTS)/Zwift/Logs"
> ```

---

### `ZWIFT_SCREENSHOTS_DIR`

See also [`ZWIFT_WORKOUT_DIR`](#zwift_workout_dir), [`ZWIFT_ACTIVITY_DIR`](#zwift_activity_dir),
[`ZWIFT_LOG_DIR`](#zwift_log_dir).

Zwift (video) screenshots are stored inside the container, in the zwift user volume. To access screenshots taken in Zwift, use
`ZWIFT_SCREENSHOTS_DIR` to map the screenshots directory to a directory on the host. It is recommended to use this option to map
the screenshots directory to a Zwift subdirectory in your user pictures directory.

| Item              | Description                                                    |
|:------------------|:---------------------------------------------------------------|
| Allowed values    | string                                                         |
| Default value     |                                                                |
| Recommended value | `$(xdg-user-dir PICTURES)/Zwift`                               |
| Commandline usage | `ZWIFT_SCREENSHOTS_DIR="$(xdg-user-dir PICTURES)/Zwift" zwift` |
| Config file usage | `ZWIFT_SCREENSHOTS_DIR="$(xdg-user-dir PICTURES)/Zwift"`       |

{: .note }
> The directory must exist on the host, you can create it using:
>
> ```bash
> mkdir -p "$(xdg-user-dir PICTURES)/Zwift"
> ```

---

### `ZWIFT_OVERRIDE_GRAPHICS`

See also [`ZWIFT_OVERRIDE_RESOLUTION`](#zwift_override_resolution) and [Graphics Settings](../graphics).

If set to `1`, override the default Zwift graphics profiles. For details on how to customize the Zwift graphics settings, read
the [Graphics Settings](../graphics/#how-can-i-accessmodify-the-graphics-settings) section.

| Item              | Description                              |
|:------------------|:-----------------------------------------|
| Allowed values    | `0` - Don't overwrite graphics profiles. |
|                   | `1` - Overwrite graphics profiles.       |
| Default value     | `0`                                      |
| Commandline usage | `ZWIFT_OVERRIDE_GRAPHICS="1" zwift`      |
| Config file usage | `ZWIFT_OVERRIDE_GRAPHICS="1"`            |

---

### `ZWIFT_OVERRIDE_RESOLUTION`

See also [`ZWIFT_OVERRIDE_GRAPHICS`](#zwift_override_graphics) and [Graphics Settings](../graphics).

Set this option to a value to change the Zwift game resolution. For details on how to change the Zwift game resolution, read the
[Graphics Settings](../graphics/#how-can-i-change-the-game-resolution) section.

| Item              | Description                                   |
|:------------------|:----------------------------------------------|
| Allowed values    | string representing a display resolution      |
| Default value     |                                               |
| Commandline usage | `ZWIFT_OVERRIDE_RESOLUTION="3840x2160" zwift` |
| Config file usage | `ZWIFT_OVERRIDE_RESOLUTION="3840x2160"`       |

---

### `ZWIFT_FG`

If set to `1`, launch the container in the foreground instead of the background. Use this option if you want to see the output
of the scripts that run inside the container, if you need to wait for the container to finish to automatically perform a task,
or if you want to run Zwift with a 3rd party launcher (e.g. Steam).

| Item              | Description                                   |
|:------------------|:----------------------------------------------|
| Allowed values    | `0` - Launch the container in the background. |
|                   | `1` - Launch the container in the foreground. |
| Default value     | `0`                                           |
| Commandline usage | `ZWIFT_FG="1" zwift`                          |
| Config file usage | `ZWIFT_FG="1"`                                |

#### Example: Automatically perform a task after the container exits

```bash
#!/usr/bin/env bash
set -uo pipefail

exit_task() {
    echo "The script finished, so the container exited"
}
trap exit_task EXIT

export ZWIFT_FG=1

echo "Launching Zwift in the foregound"
zwift
echo "The Zwift container has exited"
```

---

### `ZWIFT_NO_GAMEMODE`

If set to `1`, don't use game mode.

| Item              | Description                          |
|:------------------|:-------------------------------------|
| Allowed values    | `0` - Start Zwift using game mode.   |
|                   | `1` - Start Zwift without game mode. |
| Default value     | `0`                                  |
| Commandline usage | `ZWIFT_NO_GAMEMODE="1" zwift`        |
| Config file usage | `ZWIFT_NO_GAMEMODE="1"`              |

{: .note }
Disabling game mode could result in reduced performance and screen saver issues.

---

### `WINE_EXPERIMENTAL_WAYLAND`

If set to `1`, use native Wayland instead of XWayland if the display manager is Wayland.

| Item              | Description                              |
|:------------------|:-----------------------------------------|
| Allowed values    | `0` - Use XWayland window manager.       |
|                   | `1` - Use native Wayland window manager. |
| Default value     | `0`                                      |
| Commandline usage | `WINE_EXPERIMENTAL_WAYLAND="1" zwift`    |
| Config file usage | `WINE_EXPERIMENTAL_WAYLAND="1"`          |

{: .note }
Only used if the window manager is Wayland. Ignored if the window manager is X11/XOrg.

{: .warning }
This feature is experimental. Reduced performance and other sporadic issues are expected.

---

### `NETWORKING`

See also [Connecting Devices](../../getting-started/setup).

Configure how the container connects to the Internet.

- The default value, bridge mode, is safer.
- The alternative value, host mode, is required when using direct connect for your trainer.

| Item              | Description                          |
|:------------------|:-------------------------------------|
| Allowed values    | `bridge` - Use a network bridge.     |
|                   | `host` - Use host networking.        |
| Default value     | `bridge`                             |
| Commandline usage | `NETWORKING="host" zwift`            |
| Config file usage | `NETWORKING="host"`                  |

---

### `ZWIFT_UID`

See also [`ZWIFT_GID`](#zwift_gid).

Use this option to launch Zwift from a different user id.

| Item              | Description              |
|:------------------|:-------------------------|
| Allowed values    | number                   |
| Default value     | `$(id -u)`               |
| Commandline usage | `ZWIFT_UID="1001" zwift` |
| Config file usage | `ZWIFT_UID="1001"`       |

{: .warning }
> It is strongly discouraged to use a `ZWIFT_UID` that is different from your user uid. If you decide to do so anyway, know
> that:
>
> - It does not work with podman
> - It does not work with Wayland
> - Cats and dogs may start living together

---

### `ZWIFT_GID`

See also [`ZWIFT_UID`](#zwift_uid).

Use this option to launch Zwift from a different group id.

| Item              | Description              |
|:------------------|:-------------------------|
| Allowed values    | number                   |
| Default value     | `$(id -g)`               |
| Commandline usage | `ZWIFT_GID="1001" zwift` |
| Config file usage | `ZWIFT_GID="1001"`       |

{: .warning }
> It is strongly discouraged to use a `ZWIFT_GID` that is different from your user gid. If you decide to do so anyway, know
> that:
>
> - It does not work with podman
> - It does not work with Wayland
> - Cats and dogs may start living together

---

### `VGA_DEVICE_FLAG`

See also [Prerequisites for NVIDIA graphics cards][nvidia-prerequisites-href].

Override the container GPU/device flags.

| Item              | Description                                          |
|:------------------|:-----------------------------------------------------|
| Allowed values    | list                                                 |
|                   | string                                               |
| Default value     | `--device="nvidia.com/gpu=all"` - nvidia + podman    |
|                   | `--gpus="all"` - nvidia + docker                     |
|                   | `--device="/dev/dri:/dev/dri"` - not nvidia          |
| Commandline usage | `VGA_DEVICE_FLAG="--gpus=all" zwift` - Use a string. |
| Config file usage | `VGA_DEVICE_FLAG=(--gpus=all)` - Use a list.         |

{: .important }
> It is not possible to pass values with spaces using the commandline. It is however possible to do so in the config file using
> an array.
>
> For this reason the zwift script will issue a warning if the `VGA_DEVICE_FLAG` option is defined as a string instead of as a
> list.

[nvidia-prerequisites-href]: ../../getting-started/prerequisites/#additional-dependencies-for-nvidia-graphics-cards

---

### `PRIVILEGED_CONTAINER`

If set to `1`, the container will run in privileged mode (`--privileged --security-opt label=disable`). If set to `0`, SELinux
label separation (`--security-opt label=type:container_runtime_t`) will be used if SELinux is available and active, otherwise it
will fallback to privileged mode.

| Item              | Description                             |
|:------------------|:----------------------------------------|
| Allowed values    | `0` - Use SELinux label separation.     |
|                   | `1` - Run container in privileged mode. |
| Default value     | `0`                                     |
| Commandline usage | `PRIVILEGED_CONTAINER="1" zwift`        |
| Config file usage | `PRIVILEGED_CONTAINER="1"`              |

{: .note }
Running the container in privileged mode is less secure. Only use this option if you have to.

---

### `ZWIFT_NO_PRIVILEGED`

If set to `1`, the container will not run in privileged mode on non-SELinux systems. By default, non-SELinux systems (e.g. Ubuntu with AppArmor) use `--privileged` for GPU compatibility. Set this if you have verified that Zwift runs correctly on your system without it.

| Item              | Description                                              |
|:------------------|:---------------------------------------------------------|
| Allowed values    | `0` - Use privileged mode on non-SELinux systems.        |
|                   | `1` - Disable privileged mode.                           |
| Default value     | `0`                                                      |
| Commandline usage | `ZWIFT_NO_PRIVILEGED="1" zwift`                          |
| Config file usage | `ZWIFT_NO_PRIVILEGED="1"`                                |

{: .note }
Some hardware/driver combinations (notably Intel integrated graphics on Ubuntu) may experience low framerates without privileged mode. See [#285](https://github.com/netbrain/zwift/issues/285).
