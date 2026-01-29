---
title: Prerequisites
parent: Getting Started
nav_order: 1
---

# System Prerequisites

## Minimum System Requirements

| Component             | Minimum Requirements                            |
|-----------------------|-------------------------------------------------|
| **Operating System**  | Linux (64-bit)                                  |
| **Container Runtime** | Docker or Podman 4.3+                           |
| **RAM**               | 8 GB                                            |
| **Graphics**          | OpenGL 3.1+ compatible (integrated or discrete) |
| **Storage**           | 15 GB of free space                             |

## Required Software

### Container Runtimes

- **Docker**
  - Install from [Docker documentation](https://docs.docker.com/get-docker/)
- **Podman** (Alternative)
  - Version 4.3+ recommended
  - Install from [Podman installation guide](https://podman.io/getting-started/installation)

{: .warning }
**Podman 4.3 and earlier**: Does not support `--userns=keep-id:uid=xxx,gid=xxx` and will not start correctly, this impacts
Ubuntu 22.04 and related builds such as PopOS! 22.04.

### Additional Dependencies for NVIDIA graphics cards

- **NVIDIA Container Toolkit**
  - Install from [NVIDIA Container Toolkit installation guide](
    https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)

{: .important }
**Podman users**: Also follow the [Container Device Interface guide](
  https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/cdi-support.html)

{: .note }
**NVIDIA Container Toolkit before v1.18.0**: The cdi specification file needs to be generated manually each time
the NVIDIA driver is updated using the following command: `sudo nvidia-ctk cdi generate --output=/var/run/cdi/nvidia.yaml`
