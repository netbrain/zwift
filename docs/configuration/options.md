---
title: Configuration Options
parent: Configuration
nav_order: 1
---

# Configuration Options

## List of Environment Variables

These environment variables can be used to alter the execution of the zwift bash script.

| Key                         | Default                    | Description                                                                                                                            |
|-----------------------------|----------------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| `USER`                      | `$USER`                    | Used in creating the zwift volume `zwift-$USER`                                                                                        |
| `IMAGE`                     | `docker.io/netbrain/zwift` | The image to use                                                                                                                       |
| `VERSION`                   | `latest`                   | The image version/tag to use                                                                                                           |
| `SCRIPT_VERSION`            | `master`                   | The `zwift.sh` script version to use (git commit hash)                                                                                 |
| `DONT_CHECK`                | `0`                        | If set to `1`, don't check for updated `zwift.sh`                                                                                      |
| `DONT_PULL`                 | `0`                        | If set to `1`, don't pull for new image version (implies `DONT_CLEAN`)                                                                 |
| `DONT_CLEAN`                | `0`                        | If set to `1`, don't clean up previous image after pulling                                                                             |
| `DRYRUN`                    | `0`                        | If set to `1`, print the full container run command and exit                                                                           |
| `INTERACTIVE`               | `0`                        | If set to `1`, force `-it` and use `--entrypoint bash` for debugging                                                                   |
| `CONTAINER_TOOL`            |                            | Defaults to podman if installed, else docker                                                                                           |
| `CONTAINER_EXTRA_ARGS`      |                            | Extra args passed to docker/podman (`--cpus=1.5`)                                                                                      |
| `ZWIFT_USERNAME`            |                            | If set, try to login to zwift automatically                                                                                            |
| `ZWIFT_PASSWORD`            |                            | If set, try to login to zwift automatically                                                                                            |
| `ZWIFT_WORKOUT_DIR`         |                            | Set the workouts directory location                                                                                                    |
| `ZWIFT_ACTIVITY_DIR`        |                            | Set the activities directory location                                                                                                  |
| `ZWIFT_LOG_DIR`             |                            | Set the logs directory location                                                                                                        |
| `ZWIFT_SCREENSHOTS_DIR`     |                            | Set the screenshots directory location, recommended to set `ZWIFT_SCREENSHOTS_DIR="$(xdg-user-dir PICTURES)/Zwift"`                    |
| `ZWIFT_OVERRIDE_GRAPHICS`   | `0`                        | If set to `1`, override the default zwift graphics profiles                                                                            |
| `ZWIFT_OVERRIDE_RESOLUTION` |                            | If set, change game resolution (2560x1440, 3840x2160, ...)                                                                             |
| `ZWIFT_FG`                  | `0`                        | If set to `1`, run the process in fg instead of bg (`-d`)                                                                              |
| `ZWIFT_NO_GAMEMODE`         | `0`                        | If set to `1`, don't run game mode                                                                                                     |
| `WINE_EXPERIMENTAL_WAYLAND` | `0`                        | If set to `1`, try to use experimental wayland support in wine 9                                                                       |
| `NETWORKING`                | `bridge`                   | Sets the type of container networking to use.                                                                                          |
| `ZWIFT_UID`                 | current users id           | Sets the UID that Zwift will run as (docker only)                                                                                      |
| `ZWIFT_GID`                 | current users group id     | Sets the GID that Zwift will run as (docker only)                                                                                      |
| `DEBUG`                     | `0`                        | If set to `1`, enable debug of zwift script `set -x`                                                                                   |
| `VGA_DEVICE_FLAG`           |                            | Override GPU/device flags for container (`--gpus=all`)                                                                                 |
| `PRIVILEGED_CONTAINER`      | `0`                        | If set, container will run in privileged mode, SELinux label separation will be disabled (`--privileged --security-opt label=disable`) |

{: .important }
`ZWIFT_UID` and `ZWIFT_GID` can only be used with X11. They do not work in wayland!

### Examples

- `DONT_PULL="1" zwift` will prevent docker/podman pull before launch
- `DRYRUN="1" zwift` will print the underlying container run command and exit (no container is started)
- `INTERACTIVE="1" zwift` will force foreground `-it` and set `--entrypoint bash` for step-by-step debugging inside the
   container
- `CONTAINER_TOOL="docker" zwift` will launch zwift with docker even if podman is installed
- `CONTAINER_EXTRA_ARGS="--cpus=1.5" zwift` will pass `--cpus=1.5` as extra argument to docker/podman (will use at most 1.5 CPU
   cores, this is useful on laptops to avoid overheating and subsequent throttling of the CPU by the system).
- `USER="fred" zwift` perfect if your neighbor Fred want's to try zwift, and you don't want to mess up your zwift config.
- `NETWORKING="host" zwift` will use host networking which may be needed to have zwift talk to wifi enabled trainers.
- `ZWIFT_UID="123" ZWIFT_GID="123" zwift` will run zwift as the given uid and gid. By default zwift runs with the uid and gid of
  the user that started the container. You should not need to change this except in rare cases.
- `WINE_EXPERIMENTAL_WAYLAND="1" zwift` This will start zwift using Wayland and not XWayland. It will start full screen
  windowed.

{: .note }
> To pass extra environment variables to the container, they can be added to `CONTAINER_EXTRA_ARGS` with the `-e` flag.
>
> For example, to increase the cursor size in Zwift to 48, set the `XCURSOR_SIZE` environment variable using:
> `CONTAINER_EXTRA_ARGS=(-e XCURSOR_SIZE=48)`

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

## Configuration files

You can also save these in a configuration file that is automatically loaded by the zwift script.

- `$HOME/.config/zwift/config`
- `$HOME/.config/zwift/$USER-config`

{: .note }
The same syntax rules apply for the configuration files as for passing environment variables on the command line.

### Example config file

```bash
ZWIFT_USERNAME='user@mail.com'
ZWIFT_WORKOUT_DIR="$(xdg-user-dir DOCUMENTS)/Zwift/Workouts"
ZWIFT_LOG_DIR="$(xdg-user-dir DOCUMENTS)/Zwift/Logs"
ZWIFT_SCREENSHOTS_DIR="$(xdg-user-dir PICTURES)/Zwift"
NETWORKING="host"
ZWIFT_OVERRIDE_GRAPHICS="1"
CONTAINER_EXTRA_ARGS=(-e XCURSOR_SIZE=48)
```

### Example: Two Zwift users sharing a single Linux user account

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

- Running `USER="fred" zwift` will first load the `config` file and then the `fred-config` file. The values in the `fred-config`
  file will overwrite the values in the `config` file. So the zwift script will use Fred's username and password.
