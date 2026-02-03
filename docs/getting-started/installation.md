---
title: Installation
parent: Getting Started
nav_order: 2
---

# Installation Methods

## Automatic Installation

### One-Line Installation

![example.gif](https://raw.githubusercontent.com/netbrain/zwift/master/example.gif)

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/netbrain/zwift/master/install/install.sh)"
```

This script will:

- Download the Zwift Docker image
- Create necessary configuration files
- Add zwift command to your system path
- Create desktop shortcut

## How can I update Zwift?

The `zwift.sh` script will update zwift by checking for new image versions on every launch, however if you are not using this
then you will have to pull `netbrain/zwift:latest` from time to time in order to be on the latest version.

There is a github action in place that will update zwift on a scheduled basis and publish new versions to docker hub.
