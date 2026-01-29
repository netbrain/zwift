---
title: Installation
parent: Getting Started
nav_order: 2
---

# Installation Methods

## Automatic Installation Script

### One-Line Installation

![example.gif](https://raw.githubusercontent.com/netbrain/zwift/master/example.gif)

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/netbrain/zwift/master/bin/install.sh)"
```

This script will:

- Download the Zwift Docker image
- Create necessary configuration files
- Add zwift command to your system path
- Create desktop shortcut

## Manual Installation Steps

### How can I build the image myself?

```bash
./bin/build-image.sh
```

### How can I fetch the image from docker hub?

<https://hub.docker.com/r/netbrain/zwift>

```bash
docker pull netbrain/zwift:$VERSION # or simply latest
```
