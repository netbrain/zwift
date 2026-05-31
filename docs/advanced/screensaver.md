---
title: Inhibiting Screensaver
parent: Advanced
nav_order: 4
---

# Inhibiting the Screensaver

If `dbus` is available through a unix socket, the screensaver will be inhibited every 30 seconds to prevent `xscreensaver` or
other programs listening on the bus from inhibiting the screen.

if GameMode is installed on the host system. It will be used to launch Zwift inside the container. This will prevent the system
from going idle and will also enable extra optimizations. To benefit from all possible optimizations GameMode has to offer, you
can add your user to the GameMode group using `sudo usermod -aG gamemode $USER`, this is optional.
