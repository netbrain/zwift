---
title: Documents Folder Not Writable
parent: Troubleshooting
nav_order: 4
---

# Where are the saves and why do I get a popup can't write to Document Folder?

This is a hang up from previous versions, mainly with podman. Delete the volumes and after re-creation it should work fine.

```bash
podman volume rm zwift-xxxxx
```

or

```bash
docker volume rm zwift-xxxxx
```

{: .note }
If you see a weird volume e.g. `zwift-naeva` it is a hang up from the past, delete it.
