---
title: Connecting Devices
parent: Getting Started
nav_order: 3
---

# How do I connect my trainer, heart rate monitor, etc?

## ANT+

ANT+ devices are not supported.

## Bluetooth

Wine does not fully support bluetooth yet. Instead, you can [use your phone as a bridge][companion-app-bridge] to connect your
bluetooth devices to Zwift.

For example, your Wahoo Kickr and Apple Watch connect to the Zwift Companion app on your iPhone, then the Companion app connects
over wifi to your PC running Zwift.

[companion-app-bridge]: https://support.zwift.com/en_us/using-the-zwift-companion-app-as-a-bridge-ByAnUzlLj

## Direct Connect

If you are using a direct connect (wifi or ethernet) enabled trainer, you do not need the Companion app. Setting the
[NETWORKING](../../configuration/options/#networking) configuration option to `NETWORKING="host"` will allow Zwift to discover
your device and connect to it directly.
