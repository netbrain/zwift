---
title: Troubleshooting
nav_order: 3
---

# Troubleshooting

<details>
<summary><h3>My WiFi-capable trainer / Zwift Companion App is not detected</h3></summary>

If you have issues with device detection over WiFi/network, the issue may be related to your system's firewall.
Some Linux distributions use `firewalld` instead of `ufw`,
which is more restrictive and blocks multicast traffic by default,
which is essential for discovering devices over WiFi.

Distributions that use `firewalld` by default include:

- CentOS 7 and newer
- Fedora 18 and newer
- openSUSE 15 and newer (including Tumbleweed)

To check if the firewall is the issue, you can temporarily disable `firewalld`:

```console
systemctl stop firewalld
```

If your WiFi trainer / Zwift Companion App is now detected, the firewall is indeed the culprit.
Once you've identified this as the issue, you should configure your firewall
to allow multicast traffic on your network instead of disabling it entirely:

1. Identify your network/WiFi name.

2. Assign that network to a specific zone (e.g., "home"):

   (Assuming your distribution uses 'NetworkManager', which almost all do)

   **Via GUI**: On Plasma Settings (or similar), navigate to WiFi → [network name] → General → Firewall Zone, and select "home".

   **Via CLI**:

   ```console
   nmcli connection modify "<network name>" connection.zone home
   ```

3. Allow multicast traffic on the zone:

   The zone "home" might already be pre-configured with multicast support. If not, manually allow multicast with:

   ```console
   firewall-cmd --permanent --zone=home --add-rich-rule='rule family="ipv4" destination address="224.0.0.0/4" protocol value="udp" accept'
   ```

4. Restart `firewalld` or reload the configuration for the changes to take effect (shouldn't be needed but just in case):

   **Reload configuration** (recommended, no service interruption):

   ```console
   firewall-cmd --reload
   ```

   **Restart the service**:

   ```console
   systemctl restart firewalld
   ```

</details>
