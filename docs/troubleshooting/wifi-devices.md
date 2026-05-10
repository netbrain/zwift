---
title: Wi-Fi Device Not Detected
parent: Troubleshooting
nav_order: 1
---

# My direct connect capable trainer / the Zwift Companion app is not detected

## Run the Zwift container with host networking

By default the Zwift container uses a bridge network that isolates it from the network the host system is connected to. This
could make it impossible for the Zwift container to detect devices on the network such as a direct connect enabled trainer or
the Zwift Companion app.

Allow the Zwift container to access the host network by setting the [NETWORKING](../../configuration/options/#networking)
configuration option:

```bash
NETWORKING="host"
```

## Check your firewall configuration

If you have issues with device detection over Wi-Fi or ethernet, they may be related to your system's firewall. Some Linux
distributions use `firewalld` instead of `ufw`, which is more restrictive and blocks multicast traffic by default, which is
essential for discovering devices over Wi-Fi.

Distributions that use `firewalld` by default include:

- CentOS 7 and newer
- Fedora 18 and newer
- openSUSE 15 and newer (including Tumbleweed)

To check if the firewall is the issue, you can temporarily disable `firewalld`:

```bash
systemctl stop firewalld
```

If your Wi-Fi trainer / Zwift Companion app is now detected, the firewall is indeed the culprit. Once you've identified this as
the issue, you should configure your firewall to allow multicast traffic on your network instead of disabling it entirely:

1. Identify your Wi-Fi / network name.

2. Assign that network to a specific zone (e.g. *home*):

   (Assuming your distribution uses *NetworkManager*, which almost all do)

   **Via GUI**: On Plasma Settings (or similar), navigate to *Wi-Fi* → *[network name]* → *General* → *Firewall Zone*, and
   select *home*

   **Via CLI**:

   ```bash
   nmcli connection modify "<network name>" connection.zone home
   ```

3. Allow multicast traffic on the zone:

   The zone *home* might already be pre-configured with multicast support. If not, manually allow multicast with:

   ```bash
   firewall-cmd --permanent --zone=home --add-rich-rule='rule family="ipv4" destination address="224.0.0.0/4" protocol value="udp" accept'
   ```

4. Restart `firewalld` or reload the configuration for the changes to take effect (shouldn't be needed but just in case):

   **Reload configuration** (recommended, no service interruption):

   ```bash
   firewall-cmd --reload
   ```

   **Restart the service**:

   ```bash
   systemctl restart firewalld
   ```
