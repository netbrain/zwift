---
title: Remapping User UID/GID
parent: Advanced
nav_order: 3
---

# Remapping the host/container user

{: .warning }
> It is strongly discouraged to use a `ZWIFT_UID` and/or `ZWIFT_GID` that is different from your local user's uid/gid.

The [`ZWIFT_UID`](../../configuration/options/#zwift_uid) and [`ZWIFT_GID`](../../configuration/options/#zwift_gid)
configuration options are intended to remap the Zwift container user to the local user on your host system. This is needed if
your local user has a UID or GID that is not equal to 1000, this is the case if there are multiple user accounts on your host
system.

By default [`ZWIFT_UID`](../../configuration/options/#zwift_uid) and [`ZWIFT_GID`](../../configuration/options/#zwift_gid)
configuration options will be set to the UID and GID of your local user account respectively. It is possible (but strongly
discouraged) to intentionally set these configuration options to a different value (i.e. to the UID/GID of a different local
user on the host system). The effects of changing these values are different depending on whether you use Podman or Docker as
container tool.

## Podman

The user inside the Zwift container always has a UID/GID of 1000/1000. When using Podman as container tool, the container user
is mapped to the local user on the host system using `--userns=keep-id:uid=1000,gid=1000`. This cannot be changed by setting the
[`ZWIFT_UID`](../../configuration/options/#zwift_uid) and/or [`ZWIFT_GID`](../../configuration/options/#zwift_gid) options.

Instead [`ZWIFT_UID`](../../configuration/options/#zwift_uid) is used when mounting the user runtime directory
`/run/user/${ZWIFT_UID}` to the container. This is required to give the container access to the window manager, `dbus` session
and sound driver. Keep in mind that the local user on the host system needs access to the runtime directory of the user whose id
you are using for this to work!

[`ZWIFT_GID`](../../configuration/options/#zwift_gid) is ignored. Setting it does not impact functionality when using Podman.

## Docker

When using Docker as container tool, the UID and GID of the container user are modified to the values set in the
[`ZWIFT_UID`](../../configuration/options/#zwift_uid) and [`ZWIFT_GID`](../../configuration/options/#zwift_gid) options when
Zwift is launched. The ownership of all files and directories in the `zwift-$USER` volume is also updated accordingly.

The runtime directory of the local user on the host machine `/run/user/${UID}` is mounted to the container. This is required to
give the container access to the window manager, `dbus` session and sound driver. Keep in mind that the local user on the host
system to which the container user is mapped needs access to the runtime directory of the local user on the host system from
which the Zwift container is launched for this to work!
