---
title: Slow Start
parent: Troubleshooting
nav_order: 3
---

# The container is slow to start, why?

If you are using **Docker** and your `$(id -u)` or `$(id -g)` is not equal to 1000, the container needs to check and update
file ownership (`chown`) on every launch. Since the container is ephemeral, the uid/gid remapping does not persist between
runs. Only files with incorrect ownership are updated, but the check itself still needs to scan the file tree which can be
slow if you have a large Zwift installation.

If speed is a concern, you have two options:

1. **Use the volume variant** (`ZWIFT_VARIANT="volume"`): This mounts the entire `/home/user` as a persistent volume,
   so file ownership persists between runs and no `chown` is needed after the first launch. See
   [Volume Variant](../advanced/volume-variant.md) for details.
2. **Change your user IDs** to match the container's uid and gid (1000) using `usermod`.

**Podman** users are not affected by this since Podman handles uid/gid mapping via user namespaces (`--userns keep-id`).
