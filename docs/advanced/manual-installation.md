---
title: Manual Installation
parent: Advanced
nav_order: 5
---

# Manual Installation Steps

## How can I build the image myself?

To build the image from scratch, run:

```console
foo@bar:~$ ./src/build-image.sh
```

To only update the scripts in the image, run:

```console
foo@bar:~$ ./src/update-image.sh
```

## How can I fetch the image from docker hub?

[![image-href][image-pulls-src]][image-href]
[![image-href][image-version-src]][image-href]
[![image-href][image-size-src]][image-href]

The netbrain/zwift image is hosted on docker hub at <https://hub.docker.com/r/netbrain/zwift>.

Download the latest image version:

```console
foo@bar:~$ podman pull netbrain/zwift:latest      # or docker pull
```

Or a specific Zwift version, for example:

```console
foo@bar:~$ podman pull netbrain/zwift:v1.113.0    # or docker pull
```

[image-version-src]: https://img.shields.io/docker/v/netbrain/zwift/latest?logo=docker&logoColor=white
[image-pulls-src]: https://badgen.net/docker/pulls/netbrain/zwift?icon=docker&label=pulls
[image-size-src]: https://badgen.net/docker/size/netbrain/zwift?icon=docker&label=size
[image-href]: https://hub.docker.com/r/netbrain/zwift/tags
