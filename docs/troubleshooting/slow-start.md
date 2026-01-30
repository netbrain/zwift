---
title: Slow Start
parent: Troubleshooting
nav_order: 3
---

# The container is slow to start, why?

If your `$(id -u)` or `$(id -g)` is not equal to 1000 then this would cause the zwift container to re-map all files (`chown`,
`chgrp`) within the container so there is no uid/gid conflicts.

So if speed is a concern of yours, consider changing your user to match the containers uid and gid using `usermod` or contribute
a better solution for handling uid/gid remapping in containers. :smiley:
