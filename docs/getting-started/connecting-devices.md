---
title: Connecting Devices
parent: Getting Started
nav_order: 3
---

# How do I connect my trainer, heart rate monitor, etc?

[Zwift Support: Connecting Your Devices for Cycling][connecting-devices]

## ANT+

ANT+ devices are not supported.

## Bluetooth

Wine does not fully support Bluetooth Low Energy yet. Instead, you can [use your phone as a bridge][companion-app-bridge] to
connect your bluetooth devices to Zwift.

1. Open the Companion App on your phone (don't forget to enable bluetooth!)
2. Start Zwift on your PC
3. The Companion App should show that it is connected to Zwift
4. On the Zwift pairing screen, select *PAIR THROUGH PHONE*
5. The Companion App should show *PAIRING DEVICES...*
6. You can now select your bluetooth devices on the Zwift pairing screen

For example, your Wahoo Kickr and Apple Watch connect to the Zwift Companion App on your iPhone, then the Companion App connects
over Wi-Fi to your PC running Zwift.

If you are having troubles trying to get Zwift to connect to the Zwift Companion App, read
[Wi-Fi Device Not Detected](../../troubleshooting/wifi-devices).

![Zwift Pairing Companion App](/assets/images/zwift-pairing-companion-scaled.png)
![Companion App Pairing](/assets/images/companion-pairing-scaled.png)

## Direct Connect

If you are using a direct connect (Wi-Fi or ethernet) enabled trainer, you do not need the Companion App. Setting the
[NETWORKING](../../configuration/options/#networking) configuration option to `NETWORKING="host"` will allow Zwift to discover
your device and connect to it directly.

If you also need to connect bluetooth devices such as a heart rate monitor or the Zwift Ride controllers and your trainer can
act as a bridge, you can [connect your bluetooth devices through your trainer][zwift-trainer-bridge]. If your trainer does not
have bridge functionality, you can connect your bluetooth devices through the Companion App. Examples of trainers that can act
as a bluetooth bridge are the [Wahoo Kickr Core 2][wahoo-trainer-bridge], [Wahoo Kickr Bike Pro][wahoo-trainer-bridge] and the
[JetBlack Victory][jetblack-trainer-bridge].

For example, your heart rate monitor and Zwift Ride controllers connect to your Kickr Core 2 over bluetooth, then the Kickr Core
2 connects over Wi-Fi to your PC running Zwift.

If you are having troubles trying to get Zwift to connect to the Zwift Companion App or discover your direct connect enabled
trainer, read [Wi-Fi Device Not Detected](../../troubleshooting/wifi-devices).

## USB

If you are using a trainer that can be plugged in directly to your PC with a USB cable, you do not need the Companion App.
Follow the instructions below to allow Zwift to discover your device and connect to it directly. An example of a trainer that
has this capability is the JetBlack Victory.

1. Allow rootless access to the USB device by creating a udev rule:

   ```console
   foo@bar:~$ sudo echo 'ACTION=="add|change", SUBSYSTEM=="usb|tty", ATTRS{idVendor}=="393c", ATTRS{idProduct}=="0006", MODE="0660", GROUP="plugdev", TAG+="uaccess"' > /etc/udev/rules.d/99-jetblack-victory.rules
   foo@bar:~$ sudo udevadm control --reload-rules
   foo@bar:~$ sudo udevadm trigger
   ```

   If you are not using a JetBlack Victory, change the vendor id and product id attributes to the USB VID/PID of your device.

2. Pass the USB device to the netbrain/zwift container using the
   [CONTAINER_EXTRA_ARGS](../../configuration/options/#container_extra_args) configuration option:

   ```bash
   CONTAINER_EXTRA_ARGS=(--device=/dev/ttyACM0)
   ```

   It is possible that your device gets a different number, for example `ttyACM1`. If you are not using a JetBlack Victory,
   it is also possible that your device is recognized as `ttyUSB0`.

3. On the Zwift pairing screen, use the USB option when connecting your trainer. Read the
   [JetBlack Victory Adds USB Connection Support][jetblack-victory-usb] Zwift Insider article for detailed instructions.

If you also need to connect bluetooth devices such as a heart rate monitor or the Zwift Ride controllers and your trainer can
act as a bridge, you can [connect your bluetooth devices through your trainer][zwift-trainer-bridge]. If your trainer does not
have bridge functionality, you can connect your bluetooth devices through the Companion App. Examples of trainers that can act
as a bluetooth bridge are the [Wahoo Kickr Core 2][wahoo-trainer-bridge], [Wahoo Kickr Bike Pro][wahoo-trainer-bridge] and the
[JetBlack Victory][jetblack-trainer-bridge].

For example, your heart rate monitor and Zwift Ride controllers connect to your JetBlack Victory over bluetooth, then the
JetBlack Victory connects over USB to your PC running Zwift.

[connecting-devices]: https://support.zwift.com/en_us/connecting-your-devices-for-cycling-HJIFDrw5S
[companion-app-bridge]: https://support.zwift.com/en_us/using-the-zwift-companion-app-as-a-bridge-ByAnUzlLj
[wahoo-trainer-bridge]: https://support.wahoofitness.com/hc/en-us/articles/28126062260370-How-to-use-the-KICKR-Bridge
[zwift-trainer-bridge]: https://support.zwift.com/en_us/using-your-trainer-as-a-bridge-rJ1JwU6Ee
[jetblack-trainer-bridge]: https://youtu.be/SeuzHzamYT0
[jetblack-victory-usb]: https://zwiftinsider.com/jetblack-victory-usb/
