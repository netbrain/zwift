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
# Example configuration file
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

| Key                                                       | Default                    | Description                                                                                                                            |
|:----------------------------------------------------------|:---------------------------|:---------------------------------------------------------------------------------------------------------------------------------------|
| [`DEBUG`](#debug)                                         | `0`                        | Enable `set -x` for all scripts                                                                                                        |
| [`VERBOSITY`](#verbosity)                                 | `1`                        | Configure how much output should be shown by the scripts                                                                               |
| [`USER`](#user)                                           | `$USER`                    | Use a different user to avoid configuration conflicts                                                                                  |
| [`IMAGE`](#image)                                         | `docker.io/netbrain/zwift` | The image to use                                                                                                                       |
| [`VERSION`](#version)                                     | `latest`                   | The image version/tag to use                                                                                                           |
| [`SCRIPT_VERSION`](#script_version)                       | `master`                   | The `zwift.sh` script version to use (git commit hash)                                                                                 |
| [`DONT_CHECK`](#dont_check)                               | `0`                        | If set to `1`, don't check for updated `zwift.sh`                                                                                      |
| [`DONT_PULL`](#dont_pull)                                 | `0`                        | If set to `1`, don't pull for new image version (implies `DONT_CLEAN`)                                                                 |
| [`DONT_CLEAN`](#dont_clean)                               | `0`                        | If set to `1`, don't clean up previous image after pulling                                                                             |
| [`DRYRUN`](#dryrun)                                       | `0`                        | If set to `1`, print the full container run command and exit                                                                           |
| [`INTERACTIVE`](#interactive)                             | `0`                        | If set to `1`, force `-it` and use `--entrypoint bash` for debugging                                                                   |
| [`CONTAINER_TOOL`](#container_tool)                       |                            | Defaults to podman if installed, else docker                                                                                           |
| [`CONTAINER_EXTRA_ARGS`](#container_extra_args)           |                            | Extra args passed to docker/podman (`--cpus=1.5`)                                                                                      |
| [`ZWIFT_USERNAME`](#zwift_username)                       |                            | If set, try to login to zwift automatically                                                                                            |
| [`ZWIFT_PASSWORD`](#zwift_password)                       |                            | If set, try to login to zwift automatically                                                                                            |
| [`ZWIFT_WORKOUT_DIR`](#zwift_workout_dir)                 |                            | Set the workouts directory location                                                                                                    |
| [`ZWIFT_ACTIVITY_DIR`](#zwift_activity_dir)               |                            | Set the activities directory location                                                                                                  |
| [`ZWIFT_LOG_DIR`](#zwift_log_dir)                         |                            | Set the logs directory location                                                                                                        |
| [`ZWIFT_SCREENSHOTS_DIR`](#zwift_screenshots_dir)         |                            | Set the screenshots directory location, recommended to set `ZWIFT_SCREENSHOTS_DIR="$(xdg-user-dir PICTURES)/Zwift"`                    |
| [`ZWIFT_OVERRIDE_GRAPHICS`](#zwift_override_graphics)     | `0`                        | If set to `1`, override the default zwift graphics profiles                                                                            |
| [`ZWIFT_OVERRIDE_RESOLUTION`](#zwift_override_resolution) |                            | If set, change game resolution (2560x1440, 3840x2160, ...)                                                                             |
| [`ZWIFT_FG`](#zwift_fg)                                   | `0`                        | If set to `1`, run the process in fg instead of bg (`-d`)                                                                              |
| [`ZWIFT_NO_GAMEMODE`](#zwift_no_gamemode)                 | `0`                        | If set to `1`, don't run game mode                                                                                                     |
| [`WINE_EXPERIMENTAL_WAYLAND`](#wine_experimental_wayland) | `0`                        | If set to `1`, try to use experimental wayland support in wine 9                                                                       |
| [`NETWORKING`](#networking)                               | `bridge`                   | Sets the type of container networking to use.                                                                                          |
| [`ZWIFT_UID`](#zwift_uid)                                 | `$(id -u)`                 | Sets the UID that Zwift will run as                                                                                                    |
| [`ZWIFT_GID`](#zwift_gid)                                 | `$(id -g)`                 | Sets the GID that Zwift will run as                                                                                                    |
| [`VGA_DEVICE_FLAG`](#vga_device_flag)                     |                            | Override GPU/device flags for container (`--gpus=all`)                                                                                 |
| [`PRIVILEGED_CONTAINER`](#privileged_container)           | `0`                        | If set, container will run in privileged mode, SELinux label separation will be disabled (`--privileged --security-opt label=disable`) |

### DEBUG

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

### VERBOSITY

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

### USER

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
  NETWORKING="host"
  ZWIFT_OVERRIDE_GRAPHICS="1"
  ```

- The `$HOME/.config/zwift/bob-config` file could look like:

  ```bash
  ZWIFT_USERNAME='bob@mail.com'
  ZWIFT_PASSWORD='the password for bob'
  ```

  Running `USER="bob" zwift` will first load the `config` file and then the `bob-config` file. The values in the `bob-config`
  file will overwrite the values in the `config` file. So the zwift script will use Bob's username and password.

- The `$HOME/.config/zwift/fred-config` file could look like:

  ```bash
  ZWIFT_USERNAME='fred@mail.com'
  ZWIFT_PASSWORD='the password for fred'
  ```

  Running `USER="fred" zwift` will first load the `config` file and then the `fred-config` file. The values in the `fred-config`
  file will overwrite the values in the `config` file. So the zwift script will use Fred's username and password.

### IMAGE

See also [`VERSION`](#version), [`DONT_PULL`](#dont_pull).

| Item              | Description                     |
|:------------------|:--------------------------------|
| Allowed values    | string                          |
| Default value     | `docker.io/netbrain/zwift`      |
| Commandline usage | `IMAGE="localhost/zwift" zwift` |
| Config file usage | `IMAGE="localhost/zwift"`       |

{: .important }
When using a local image, you should also set `DONT_PULL="1"`.

### VERSION

See also [`IMAGE`](#image), [`DONT_PULL`](#dont_pull).

### SCRIPT_VERSION

See also [`DONT_CHECK`](#dont_check).

### DONT_CHECK

See also [`SCRIPT_VERSION`](#script_version).

### DONT_PULL

See also [`IMAGE`](#image), [`VERSION`](#version).

### DONT_CLEAN

See also [`DONT_PULL`](#dont_pull).

### DRYRUN

### INTERACTIVE

### CONTAINER_TOOL

### CONTAINER_EXTRA_ARGS

{: .note }
> To pass extra environment variables to the container, they can be added to `CONTAINER_EXTRA_ARGS` with the `-e` flag.
>
> For example, to increase the cursor size in Zwift to 48, set the `XCURSOR_SIZE` environment variable using:
> `CONTAINER_EXTRA_ARGS=(-e XCURSOR_SIZE=48)`

### ZWIFT_USERNAME

See also [`ZWIFT_PASSWORD`](#zwift_password).

### ZWIFT_PASSWORD

See also [`ZWIFT_USERNAME`](#zwift_username).

### ZWIFT_WORKOUT_DIR

See also [`ZWIFT_ACTIVITY_DIR`](#zwift_activity_dir), [`ZWIFT_LOG_DIR`](#zwift_log_dir),
[`ZWIFT_SCREENSHOTS_DIR`](#zwift_screenshots_dir).

### ZWIFT_ACTIVITY_DIR

See also [`ZWIFT_WORKOUT_DIR`](#zwift_workout_dir), [`ZWIFT_LOG_DIR`](#zwift_log_dir),
[`ZWIFT_SCREENSHOTS_DIR`](#zwift_screenshots_dir).

### ZWIFT_LOG_DIR

See also [`ZWIFT_WORKOUT_DIR`](#zwift_workout_dir), [`ZWIFT_ACTIVITY_DIR`](#zwift_activity_dir),
[`ZWIFT_SCREENSHOTS_DIR`](#zwift_screenshots_dir).

### ZWIFT_SCREENSHOTS_DIR

See also [`ZWIFT_WORKOUT_DIR`](#zwift_workout_dir), [`ZWIFT_ACTIVITY_DIR`](#zwift_activity_dir),
[`ZWIFT_LOG_DIR`](#zwift_log_dir).

### ZWIFT_OVERRIDE_GRAPHICS

See also [`ZWIFT_OVERRIDE_RESOLUTION`](#zwift_override_resolution).

### ZWIFT_OVERRIDE_RESOLUTION

See also [`ZWIFT_OVERRIDE_GRAPHICS`](#zwift_override_graphics).

### ZWIFT_FG

### ZWIFT_NO_GAMEMODE

### WINE_EXPERIMENTAL_WAYLAND

### NETWORKING

### ZWIFT_UID

See also [`ZWIFT_GID`](#zwift_gid).

{: .important }
`ZWIFT_UID` and `ZWIFT_GID` can only be used with X11. They do not work in wayland!

### ZWIFT_GID

See also [`ZWIFT_UID`](#zwift_uid).

{: .important }
`ZWIFT_UID` and `ZWIFT_GID` can only be used with X11. They do not work in wayland!

### VGA_DEVICE_FLAG

### PRIVILEGED_CONTAINER

## Syntax

Special characters in the value of environment variables need to be escaped to make sure they are interpreted literally. For
example `ZWIFT_PASSWORD=my password` would cause the `ZWIFT_PASSWORD` variable to have two values `my` and `password` instead
of the single value `my password`.

{: .important }
> Use single quotes to escape the value of the username and password!
>
> - `ZWIFT_USERNAME='user@mail.com'`
> - `ZWIFT_PASSWORD='my password'`

{: .important }
> Use an array for `CONTAINER_EXTRA_ARGS` and `VGA_DEVICE_FLAG`!
>
> - `CONTAINER_EXTRA_ARGS=(--cpus="1.5" -e XCURSOR_SIZE=48)`
> - `VGA_DEVICE_FLAG=(--gpus="all")`
>
> **Note**: When passing these arguments directly on the commandline, arrays cannot be used. Use `VARIABLE="value"` or
> `VARIABLE='value'` instead.

{: .important }
> Use double quotes to escape the value of all other environment variables!
>
> - `ZWIFT_SCREENSHOTS_DIR="$(xdg-user-dir PICTURES)/Zwift"`
> - `DONT_PULL="1"`

Most environment variables don't have special characters aside from spaces. For those variables is it enough to wrap them in
double quotes.

Passwords (and to some extend email addresses) can however contain nearly every possible character sequence. Double quotes are
not enough to stop escape sequences and bash code from being substituted. For example writing `ZWIFT_PASSWORD="Pa$word\n123"`
would try to substitute `$word` for the value of the variable `word`, which would most likely be empty. It would also replace
`\n` with a new line. This is not desirable. Instead of double quotes, single quotes can be used to prevent this expansion from
happening. Using `ZWIFT_PASSWORD='Pa$word\n123'` would treat all characters literally and behave as expected.

{: .important }
> Since we use single quotes around the password, passwords that contain single quotes still pose an issue. For example
> `bob's excellent pa$$w0rd` would cause all sorts of nasty errors being spit out by the zwift script. Single quotes in the
> password need to be replaced by a different character sequence to make them work. If multiple single quotes are present in the
> password, each of them needs to be replaced according to the rules below.
>
> `ZWIFT_PASSWORD='bob'"'"'s excellent pa$$w0rd'`
>
> The sequence is a bit different depending on whether the `'` appears at the start, somewhere in the middle or at the end of
> the password.
>
> - For a password with value `p'as`, set `ZWIFT_PASSWORD='p'"'"'as'` (replace `'` with `'"'"'`)
> - For a password with value `'pas`, set `ZWIFT_PASSWORD="'"'pas'` (prepend `'pas'` with `"'"`)
> - For a password with value `pas'`, set `ZWIFT_PASSWORD='pas'"'"` (append `'"'` to `'pas'`)
