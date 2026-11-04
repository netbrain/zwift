---
title: First Launch
parent: Getting Started
nav_order: 3
---

# First Launch

## Persist your Login Information

To prevent Zwift from asking you to log in each time it is launched, you can persist your Zwift credentials. We recommend to
store your Zwift password securely using the Linux secret tool. To persist your Zwift credentials,
[follow these instructions][presist-credentials].

[presist-credentials]: ../../configuration/authentication/#how-can-i-persist-my-login-information-so-i-dont-need-to-login-on-every-startup

## Container Image Download

The first time Zwift is started, it will download the netbrain/zwift container image. This image is approximately 5.5 GiB in
size, so it will take some time to download. After the container image is downloaded, the Zwift game will be launched.

## Disable Video Screenshots

There is currently an issue with Zwift video screenshots that causes a huge amount of memory to be allocated. To the point where
most systems will run out of memory and grind to a halt a couple of minutes into a virtual or video route. It is advised to
disable video screenshots in the Zwift settings.

![Disable video screenshots](/assets/images/zwift-video-screenshots.png)

Related issue: [#438](https://github.com/netbrain/zwift/issues/438)
