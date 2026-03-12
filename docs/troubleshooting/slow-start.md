---
title: Slow Start
parent: Troubleshooting
nav_order: 3
---

# The container is slow to start, why?

If you are using **Docker** and your `$(id -u)` or `$(id -g)` is not equal to 1000, the container needs to update file ownership
(`chown`) on the first run after a uid/gid change. Subsequent launches should be fast since only files with incorrect ownership
are updated.

If speed is still a concern, consider changing your user to match the container's uid and gid (1000) using `usermod`.

**Podman** users are not affected by this since Podman handles uid/gid mapping via user namespaces (`--userns keep-id`).
