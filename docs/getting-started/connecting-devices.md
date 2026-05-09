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

1. Open the Companion App on your phone (don't forget to enable bluetooth!)
2. Start Zwift on your PC
3. The Companion App should show that it is connected to Zwift
4. On the Zwift pairing screen, select *PAIR THROUGH PHONE*
5. The Companion App should show *PAIRING DEVICES...*
6. You can now select your bluetooth devices on the Zwift pairing screen

For example, your Wahoo Kickr and Apple Watch connect to the Zwift Companion app on your iPhone, then the Companion app connects
over Wi-Fi to your PC running Zwift.

![Zwift Pairing Companion App](/assets/images/zwift-pairing-companion-scaled.png)
![Companion App Pairing](/assets/images/companion-pairing-scaled.png)

[companion-app-bridge]: https://support.zwift.com/en_us/using-the-zwift-companion-app-as-a-bridge-ByAnUzlLj

## Direct Connect

If you are using a direct connect (Wi-Fi or ethernet) enabled trainer, you do not need the Companion app. Setting the
[NETWORKING](../../configuration/options/#networking) configuration option to `NETWORKING="host"` will allow Zwift to discover
your device and connect to it directly.

If you also need to connect bluetooth devices such as a heart rate monitor or the Zwift Ride controllers and your trainer can
act as a bridge, you can [connect your bluetooth devices through your trainer][zwift-trainer-bridge]. If your trainer does not
have bridge functionality, you can connect your bluetooth devices through the Companion App. Examples of trainers that can act
as a bluetooth bridge are the [Wahoo Kickr Core 2 and Wahoo Kickr Bike Pro][wahoo-trainer-bridge].

For example, your heart rate monitor and Zwift Ride controllers connect to your Kickr Core 2 over bluetooth, then the Kickr Core
2 connects over Wi-Fi to your PC running Zwift.

[wahoo-trainer-bridge]: https://support.wahoofitness.com/hc/en-us/articles/28126062260370-How-to-use-the-KICKR-Bridge
[zwift-trainer-bridge]: https://support.zwift.com/en_us/using-your-trainer-as-a-bridge-rJ1JwU6Ee
