---
title: Switch to user install
nav_order: 6
parent: Advanced
---

# How do I switch from a system wide install to a user local install?

If you have installed netbrain/zwift system wide and want to switch to a user local install instead so you don't need to enter
your root password when there is an update available, follow the steps below:

1. Download the install script and make it executable

   ```console
   foo@bar:~$ wget https://raw.githubusercontent.com/netbrain/zwift/master/bin/install.sh
   foo@bar:~$ chmod u+x install.sh
   ```

2. Uninstall netbrain/zwift (but keep your settings)

   ```console
   foo@bar:~$ sudo ./install.sh --uninstall --auto-confirm
   ```

3. Install netbrain/zwift for the current user

   ```console
   foo@bar:~$ ./install.sh --auto-confirm
   ```

4. Remove the install script since it is no longer needed

   ```console
   foo@bar:~$ rm install.sh
   ```
