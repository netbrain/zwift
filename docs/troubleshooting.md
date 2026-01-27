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

<details>
<summary><h3>Where are the saves and why do I get a popup can't write to Document Folder?</h3></summary>

This is a hang up from previous versions, mainly with podman. delete the volumes and after re-creation it should work fine.

```text
podman volume rm zwift-xxxxx
```

or

```text
docker volume rm zwift-xxxxx
```

**NOTE**: if you see a weird volume e.g. `zwift-naeva` it is a hang up from the past, delete it.

</details>

<details>
<summary><h3>I sometimes get a popup Not responding why?</h3></summary>

For Gnome it is just timing out before zwift responds, just extend the timeout.

```text
gsettings set org.gnome.mutter check-alive-timeout 60000
```

</details>

<details>
<summary><h3>The container is slow to start, why?</h3></summary>

If your `$(id -u)` or `$(id -g)` is not equal to 1000 then this would cause the zwift container to re-map all files (`chown`,
`chgrp`) within the container so there is no uid/gid conflicts. So if speed is a concern of yours, consider changing your user
to match the containers uid and gid using `usermod` or contribute a better solution for handling uid/gid remapping in containers
:smiley:

</details>
