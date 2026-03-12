---
title: Slow Start
parent: Troubleshooting
nav_order: 3
---

# The container is slow to start, why?

If your `$(id -u)` or `$(id -g)` is not equal to 1000 then this would cause the zwift container to re-map all files (`chown`,
`chgrp`) within the container so there is no uid/gid conflicts.

If speed is a concern, you have two options:

1. **Use the volume variant** (`ZWIFT_VARIANT="volume"`): This mounts the entire `/home/user` as a persistent volume,
   so file ownership persists between runs and no `chown` is needed after the first launch. See
   [Volume Variant]({% link advanced/volume-variant.md %}) for details.
2. **Change your user IDs** to match the container's uid and gid (1000) using `usermod`.
