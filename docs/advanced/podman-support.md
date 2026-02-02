---
title: Podman Support
parent: Advanced
nav_order: 3
---

# Podman Support

When running Zwift with podman, the user and group in the container is 1000 (user). To access the resources on the host we need
to map the container id 1000 to the host id using `uidmap` and `gidmap`.

{: .note }
From Podman 4.3 this became automatic by providing the Container UID/GID and podman automatically sets up this mapping.

For example if the host uid/gid is 1001/1001 then we need to map the host resources from `/run/user/1001` to the container
resource `/run/user/1000` and map the user and group id's the same. This had to be done manually on the host podman start using
`--uidmap` and `--gidmap` (not covered here).

{: .warning }
Using ZWIFT_UID/GID will only work if the user starting podman has access to the `/run/user/$ZWIFT_UID` resources and does
not work the same way as in Docker so is not supported.
