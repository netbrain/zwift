---
title: Prerequisites
parent: Getting Started
nav_order: 1
---

# System Prerequisites

## Minimum System Requirements

| Component             | Minimum Requirements   |
|-----------------------|------------------------|
| **Operating System**  | Linux (64-bit)         |
| **Container Runtime** | Docker or Podman 4.3+  |
| **RAM**               | 8 GB                   |
| **Graphics**          | OpenGL 3.1+ compatible |
| **Storage**           | 15 GB of free space    |

## Required Software

### Container Runtimes

- **Docker**
  - Install from [Docker documentation](https://docs.docker.com/get-docker/)
- **Podman** (Alternative)
  - Version 4.3+ recommended
  - Install from [Podman installation guide](https://podman.io/getting-started/installation)

### Additional Dependencies for NVIDIA users

- **NVIDIA Container Toolkit**
  - Install from [install guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)

{: .note }
**Note for Podman users**: Also follow the Container Device Interface
[guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/cdi-support.html).

[Next: Installation](/getting-started/installation){: .btn .btn-green }
