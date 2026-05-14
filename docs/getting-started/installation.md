---
title: Installation
parent: Getting Started
nav_order: 2
---

# Installation Methods

## Automatic Installation

![example.gif](/assets/images/example.gif)

### System wide Installation

To install netbrain/zwift for all users on your system, run:

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/netbrain/zwift/master/bin/install.sh)"
```

### User local Installation

To install netbrain/zwift only for the current user, run:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/netbrain/zwift/master/bin/install.sh)"
```

This script will:

- Download the Zwift container image
- Add the zwift command to your system path
- Create a desktop shortcut

## How can I update Zwift?

The `zwift.sh` script will update Zwift by checking for new image versions on every launch, however if you are not using this
then you will have to pull `netbrain/zwift:latest` from time to time in order to be on the latest version.

There is a github action in place that will update Zwift on a scheduled basis and publish new versions to docker hub.
