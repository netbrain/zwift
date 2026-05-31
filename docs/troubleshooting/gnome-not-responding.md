---
title: Gnome Not Responding
parent: Troubleshooting
nav_order: 2
---

# I sometimes get a popup "Zwift Is Not Responding", why?

Gnome (Mutter) has a standard timeout of 5 seconds in which it expects applications to respond. This is often not
enough when launching heavier applications such as a game.

!["Zwift" Is Not Responding](/assets/images/gnome-not-responding.png)
{: .text-center }

The solution is to simply extend the timeout or disable it entirely.

To extend the timeout to 1 minute (recommended):

```console
foo@bar:~$ gsettings set org.gnome.mutter check-alive-timeout 60000
```

To disable the timeout entirely:

```console
foo@bar:~$ gsettings set org.gnome.mutter check-alive-timeout 0
```
