---
title: Gnome Not Responding
parent: Troubleshooting
nav_order: 2
---

# I sometimes get a popup Not responding why?

For Gnome it is just timing out before zwift responds, extend the timeout.

```bash
gsettings set org.gnome.mutter check-alive-timeout 60000
```
