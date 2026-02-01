---
title: Inhibiting Screensaver
parent: Advanced
nav_order: 4
---

# Inhibiting the Screensaver

If `dbus` is available through a unix socket, the screensaver will be inhibited every 30 seconds to prevent `xscreensaver` or
other programs listening on the bus from inhibiting the screen.
