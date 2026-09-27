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
  - If Zwift fails to launch, try setting `VGA_DEVICE_FLAG=(--runtime=nvidia --device="nvidia.com/gpu=all")`. See
    [this issue](https://github.com/netbrain/zwift/issues/208) for context.

[install-nvctk]: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
[install-nvcdi]: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/cdi-support.html

## Optional Software

### Recommended

#### GameMode

- If [GameMode](https://feralinteractive.github.io/gamemode/) is installed on the host system, it will automatically be used to
  launch Zwift inside the container. Some benefits are:
  - GameMode prevents the system from going idle (the screensaver won't activate)
  - GameMode enables extra optimizations
- Most Linux distributions come with GameMode pre-installed. If it is not
  installed on your system, it is most likely available through the package manager:
  - To check if GameMode is installed, run: `gamemoded --version`
  - To install GameMode, run: `sudo apt install gamemode`, `sudo dnf install gamemode`, ...
- To benefit from all possible optimizations GameMode has to offer, you can add your user to the GameMode group using
  `sudo usermod -aG gamemode $USER`, this is optional.

#### secret-tool

- If [secret-tool](https://linuxcommandlibrary.com/man/secret-tool) is installed, it can be used to
  [store your Zwift credentials securely](../../configuration/authentication)
  - secret-tool provides an easy to use interface to store passwords to and retrieve passwords from keyring daemons such as
    gnome-keyring and KWallet
- Most Linux distributions come with secret-tool pre-installed. If it is not
  installed on your system, it is most likely available through the package manager:
  - To check if secret-tool is installed, run: `secret-tool`
  - To install secret-tool, run: `sudo apt install libsecret-tools`, `sudo dnf install libsecret`, ...
