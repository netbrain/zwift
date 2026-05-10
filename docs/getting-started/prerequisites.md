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
| **Container Runtime** | Podman 4.3+ or Docker                           |
| **RAM**               | 8 GB                                            |
| **Graphics**          | OpenGL 3.1+ compatible (integrated or discrete) |
| **Storage**           | 15 GB of free space                             |

## Required Software

### Supported Container Runtimes

#### Podman (Recommended)

- Install by following the [Podman install guide](https://podman.io/docs/installation#installing-on-linux)
- Podman 4.3 and earlier do not support `--userns=keep-id` and will not start correctly. This impacts Ubuntu 22.04 and related
  builds such as PopOS! 22.04.

#### Docker

- Rootless docker is not supported!
- Install by following the [Docker CE install guide](https://docs.docker.com/engine/install/)
- Add your user account to the docker group to be able to use docker without requiring sudo `sudo usermod -aG docker $USER`.

### Additional Dependencies for NVIDIA graphics cards

#### NVIDIA Container Toolkit

- Install by following the [NVIDIA Container Toolkit installation guide][install-nvctk]
- Podman
  - Also follow the [Container Device Interface guide][install-nvcdi]
  - Container Toolkit version v1.17.9 and earlier do not automatically update the cdi specification file. Regenerate it manually
    after NVIDIA driver updates by running the command: `sudo nvidia-ctk cdi generate --output=/var/run/cdi/nvidia.yaml`.
- Docker
  - If Zwift fails to launch, try setting `VGA_DEVICE_FLAG=(--device="nvidia.com/gpu=all")`. See
    [this issue](https://github.com/netbrain/zwift/issues/208) for context.

[install-nvctk]: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
[install-nvcdi]: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/cdi-support.html
