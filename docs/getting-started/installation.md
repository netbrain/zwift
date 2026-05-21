---
title: Installation
parent: Getting Started
nav_order: 2
---

# Installing, Updating and Uninstalling

## Automatic Installation

### User local Installation (Recommended)

To install netbrain/zwift only for the current user, run:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/netbrain/zwift/master/bin/install.sh)"
```

### System wide Installation

To install netbrain/zwift for all users on your system, run:

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/netbrain/zwift/master/bin/install.sh)"
```

This script will:

- Add the zwift command to your system path
- Create a desktop shortcut

## First Launch

The first time zwift is started, it will download the netbrain/zwift container image. This image is approximately 5.5 GiB in
size, so it will take some time to download. After the container image is downloaded, the Zwift game will be launched.

## How can I update Zwift?

There is a github action in place that will update Zwift on a scheduled basis and publish new versions to docker hub.

The `zwift.sh` script will update Zwift by checking for new image and script versions on every launch, however if you are not
using this then you will have to pull `netbrain/zwift:latest` from time to time in order to be on the latest version.

## How can I uninstall netbrain/zwift?

Download the `install.sh` script and invoke it with the `--uninstall` argument.

- If invoked with sudo, both the user local and system wide installation can be removed.
- If invoked without sudo, only the user local installation can be removed.

```console
foo@bar:~$ wget https://raw.githubusercontent.com/netbrain/zwift/master/bin/install.sh
foo@bar:~$ chmod u+x install.sh
foo@bar:~$ ./install.sh --uninstall
foo@bar:~$ rm install.sh
```

Uninstalling netbrain/zwift will:

- Remove the scripts and desktop shortcut
- Keep the Zwift container image
- Keep your Zwift settings (volume and configuration files)

To remove the netbrain/zwift container image, run:

```console
foo@bar:~$ podman rmi docker.io/netbrain/zwift    # or docker rmi docker.io/netbrain/zwift
```

To remove your Zwift settings, run:

```console
foo@bar:~$ podman volume rm zwift-$USER           # or docker volume rm zwift-$USER
foo@bar:~$ rm -rf ~/.config/zwift
```
