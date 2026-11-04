# ANT+ heart rate bridge

Wine has no ANT+ support, so Zwift in the container cannot use an ANT+ dongle.
This bridge keeps ANT+ out of the container. A small Python script runs on the
host, reads an ANT+ heart rate strap through the USB dongle with
[openant](https://github.com/Tigge/openant), and offers the heart rate on the
network as a Direct Connect device, the same way a Wahoo KICKR does. Zwift
finds it by itself and lists it under Heart Rate. No Companion app is needed.

How it works:

- It advertises `_wahoo-fitness-tnp._tcp` over mDNS with `avahi-publish`, on
  TCP port 36867.
- It answers Direct Connect requests with the standard heart rate service
  (`0x180D`) and measurement characteristic (`0x2A37`).
- It sends the latest heart rate once per second, and nothing when the strap
  has been silent for 5 seconds.

Only heart rate is supported. Power meters, cadence and speed sensors are not.

## Requirements

- An ANT USB stick (ANTUSB2 `0fcf:1008` or ANTUSB-m `0fcf:1009`) in the PC
  that runs Zwift.
- `NETWORKING="host"` in `~/.config/zwift/config`, so Zwift can see mDNS
  devices on the host.
- Python 3 with `venv`, and `avahi-publish`. The Avahi daemon must be
  running. On Debian/Ubuntu: `sudo apt install python3-venv avahi-utils`.
  On Fedora: `sudo dnf install avahi-tools`.

## Install

1. Give your user access to the dongle, then unplug it and plug it in again:

   ```bash
   sudo cp 42-ant-usb-sticks.rules /etc/udev/rules.d/
   sudo udevadm control --reload-rules
   ```

2. Copy the script and install the Python packages:

   ```bash
   mkdir -p ~/.local/share/ant-hrm-bridge
   cp ant-hrm-bridge.py ~/.local/share/ant-hrm-bridge/
   python3 -m venv ~/.local/share/ant-hrm-bridge/venv
   ~/.local/share/ant-hrm-bridge/venv/bin/pip install -r requirements.txt
   ```

3. Check that the strap is found. Wet the strap, put it on, and run:

   ```bash
   ~/.local/share/ant-hrm-bridge/venv/bin/python \
     ~/.local/share/ant-hrm-bridge/ant-hrm-bridge.py --ant-only
   ```

   It prints `Found heart rate strap with ANT ID <ID>` and then the heart rate
   every 5 seconds. Stop it with Ctrl+C.

4. Run it as a user service, so it starts at login:

   ```bash
   mkdir -p ~/.config/systemd/user
   cp ant-hrm-bridge.service ~/.config/systemd/user/
   systemctl --user daemon-reload
   systemctl --user enable --now ant-hrm-bridge
   ```

5. Start Zwift, open the pairing screen and pick **ANT HRM Bridge** under
   Heart Rate. Zwift remembers it next time.

Check the log with `journalctl --user -u ant-hrm-bridge -f`.

## Options

| Option         | Meaning                                                      |
|----------------|--------------------------------------------------------------|
| `--belt-id ID` | Only use the strap with this ANT ID. Default: the first one. |
| `--name NAME`  | Name shown in Zwift. Default: `ANT HRM Bridge`.              |
| `--port PORT`  | Direct Connect TCP port. Default: 36867.                     |
| `--ant-only`   | Only read and print the heart rate.                          |
| `--sim`        | Send a simulated heart rate, for testing without a strap.    |
| `--ble`        | Offer a Bluetooth LE sensor instead, for the Companion app.  |
| `--verbose`    | Log every Direct Connect message.                            |

If there is more than one strap nearby (in a gym, or at home with a partner),
use `--belt-id` with the ID from step 3 in the `ExecStart` line of the service.

`--ble` is an older route through the PC's Bluetooth adapter and the Companion
app. It needs `dbus-python` and `PyGObject` (`python3-dbus` and `python3-gi`
on Debian/Ubuntu); create the venv with `--system-site-packages` to use the
system packages. Direct Connect is simpler and is the recommended route.

## Notes

- Only one program can use the dongle at a time. Stop the service before you
  run the script by hand.
- If the dongle is unplugged, the bridge exits and systemd restarts it.
- When the strap sends nothing (not worn, or dry), Zwift reconnects about
  every 10 seconds. This stops as soon as the strap sends a heart rate.
- The strap is picked up again when it comes back after a break, since the
  ANT channel keeps searching. Tested with a 27 minute break: the heart rate
  was back within seconds of putting the strap on, with no restart.
- After you take the strap off, it may keep sending the last value for a
  couple of minutes (the HRM-Tri repeated 102 bpm for about 2 minutes), so
  the heart rate in Zwift looks frozen until the strap goes quiet.

## Tested

- Garmin HRM-Tri with an ANTUSB-m dongle, Ubuntu 26.04, podman, Zwift
  1.124.0: full rides of 33 and 56 minutes with a heart rate every second,
  and automatic pairing after a reboot.

Other straps and dongles should work if they follow the ANT+ heart rate
profile, but have not been tested. Reports are welcome.

Twice, the HRM-Tri reported 219-245 bpm for about a minute shortly after a
ride. The cause is unknown. The bridge passes on what the strap sends.
