# Zwift

[![Zwift updater][zwift-updater-src]][zwift-updater-href]
[![image-href][image-pulls-src]][image-href]
[![image-href][image-version-src]][image-href]
[![image-href][image-size-src]][image-href]

Hello fellow zwifters, here is a docker image for running zwift on linux. It uses the companion app by zwift for linking up
smart trainers and other bluetooth devices (ant devices are not supported via the companion app). The reason why I made this
solution was so I could run multiple zwift instances on one machine at the same time.

The container comes pre-installed with zwift, so no setup is required, simply pull and run. It should also now support all
manner of graphics cards that have gl rendering.

If you find this image useful, then feel free to
[add me on zwift](https://www.zwift.com/eu/athlete/4e3c5880-1edd-4c5d-a1b8-0974ce3874f0) and give me a ride on from time to
time.

![example.gif](https://raw.githubusercontent.com/netbrain/zwift/master/example.gif)

## Prerequisites

- [Docker](https://docs.docker.com/get-docker) or [Podman](https://podman.io/getting-started/installation)
- [nvidia-container-toolkit](https://github.com/NVIDIA/nvidia-container-toolkit) if you have nvidia proprietary driver
- ATI, Intel and Nouveau drivers should work out of the box

## Install

```console
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/netbrain/zwift/master/bin/install.sh)"
```

This will put the `zwift.sh` script on your `$PATH` and add a desktop icon to `/usr/local/share/applications`.

**NOTE**: Icon may not show until logging off and back in.

## Run

After installation, simply run:

```console
zwift
```

**NOTE**: You might want to disable video screenshots ([#75](https://github.com/netbrain/zwift/issues/75))

## Sponsors 💖

These are our really cool sponsors!

<!-- markdownlint-disable line-length -->
<!-- cSpell:disable -->
<!-- sponsors --><a href="https://github.com/altheus"><img src="https:&#x2F;&#x2F;github.com&#x2F;altheus.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/nowave7"><img src="https:&#x2F;&#x2F;github.com&#x2F;nowave7.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/cmuench"><img src="https:&#x2F;&#x2F;github.com&#x2F;cmuench.png" width="60px" alt="User avatar: Christian Münch" /></a><a href="https://github.com/nibbles-bytes"><img src="https:&#x2F;&#x2F;github.com&#x2F;nibbles-bytes.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/saltymedic"><img src="https:&#x2F;&#x2F;github.com&#x2F;saltymedic.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/ZachS"><img src="https:&#x2F;&#x2F;github.com&#x2F;ZachS.png" width="60px" alt="User avatar: Jethro Zach Solomon" /></a><a href="https://github.com/SvenHaedrich"><img src="https:&#x2F;&#x2F;github.com&#x2F;SvenHaedrich.png" width="60px" alt="User avatar: Sven Hädrich" /></a><a href="https://github.com/relief-melone"><img src="https:&#x2F;&#x2F;github.com&#x2F;relief-melone.png" width="60px" alt="User avatar: Relief.Melone" /></a><a href="https://github.com/pdelagrave"><img src="https:&#x2F;&#x2F;github.com&#x2F;pdelagrave.png" width="60px" alt="User avatar: Pierre Delagrave" /></a><a href="https://github.com/sphexator"><img src="https:&#x2F;&#x2F;github.com&#x2F;sphexator.png" width="60px" alt="User avatar: Kristoffer T." /></a><a href="https://github.com/fliesentischsound"><img src="https:&#x2F;&#x2F;github.com&#x2F;fliesentischsound.png" width="60px" alt="User avatar: Robin" /></a><a href="https://github.com/Trawnick"><img src="https:&#x2F;&#x2F;github.com&#x2F;Trawnick.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/PlombiP"><img src="https:&#x2F;&#x2F;github.com&#x2F;PlombiP.png" width="60px" alt="User avatar: " /></a><a href="https://github.com/iter59"><img src="https:&#x2F;&#x2F;github.com&#x2F;iter59.png" width="60px" alt="User avatar: " /></a><!-- sponsors -->
<!-- cSpell:enable -->
<!-- markdownlint-enable line-length -->

## Contributors ✨

Thanks go to these wonderful people:

[![Contributors](https://contrib.rocks/image?repo=netbrain/zwift)](https://github.com/netbrain/zwift/graphs/contributors)

### Contribute 👋

If you would like to contribute, then please by all means I'll accept PRs. A good starting point would be to see if there's
any open issues that you feel capable of doing. Let me know if I can help with anything.

### Show and tell 🙌

Check out our [Show and tell](https://github.com/netbrain/zwift/discussions/categories/show-and-tell) category in discussions
and see how other people are using this solution, feel free to contribute your own tips and tricks :smiley:

## Alternative's to this repository

- Install zwift using wine directly or a framework like `lutris`. You will however have to manage installation and updates
  yourself
- Use [`scrcpy`](https://github.com/Genymobile/scrcpy) to mirror android device to your linux screen
  - [Enable developer options on your android device](https://developer.android.com/studio/debug/dev-options#enable)
  - Pair your computer to the device using `adb pair`
    [documentation](https://developer.android.com/studio/command-line/adb#wireless-android11-command-line)
    - `./srccpy.sh adb pair ip:port`  [see my container solution](https://github.com/netbrain/dockerfiles/tree/master/scrcpy)
  - Mirror the android device screen onto your linux screen using `scrcpy`.
    - `./srccpy.sh scrcpy --tcpip=ip:port`
  - If you require sound as well, there's also a [`sndcpy`](https://github.com/rom1v/sndcpy) project (doesn't support wireless
    though, but the aforementioned can be modified to use usb)
- Using [`redroid`](https://hub.docker.com/r/redroid/redroid) to install zwift apk onto a android emulator (not tested)
- Using a virtual machine with pci passthrough
  - <https://looking-glass.io/>
  - <https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF>
  - <https://github.com/VGPU-Community-Drivers/vGPU-Unlock-patcher> (if you have a nvidia card you can eat your cake, and have
    it too by creating `vgpus` for vms that leverage the host gpu, no dedicated gpu required)

## ⭐ Star History (for fun and giggles)

[![Star History Chart](https://api.star-history.com/svg?repos=netbrain/zwift&type=Date)](https://star-history.com/#netbrain/zwift&Date)

[zwift-updater-src]:https://github.com/netbrain/zwift/actions/workflows/zwift_updater.yaml/badge.svg
[zwift-updater-href]:https://github.com/netbrain/zwift/actions/workflows/zwift_updater.yaml
[image-version-src]:https://img.shields.io/docker/v/netbrain/zwift/latest?logo=docker&logoColor=white
[image-pulls-src]:https://badgen.net/docker/pulls/netbrain/zwift?icon=docker&label=pulls
[image-size-src]:https://badgen.net/docker/size/netbrain/zwift?icon=docker&label=size
[image-href]:https://hub.docker.com/r/netbrain/zwift/tags
