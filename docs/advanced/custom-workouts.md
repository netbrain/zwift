---
title: Custom Workouts
nav_order: 1
parent: Advanced
---

# How can I add custom .zwo files?

You can map the zwift Workout folder using the environment variable `ZWIFT_WORKOUT_DIR`, for example if your workout directory
is in `$HOME/zwift_workouts` then you would provide the environment variable `ZWIFT_WORKOUT_DIR="$HOME/zwift_workouts"`.

You can add this variable into `$HOME/.config/zwift/config` or `$HOME/.config/zwift/$USER-config`.

The workouts folder will contain subdirectories e.g. `$HOME/.config/zwift/workouts/393938`. The number is your internal zwift
id and you store you zwo files in the relevant folder. There will usually be only one ID, however if you have multiple zwift
logins it may show one subdirectory for each, to find the ID you can use the following link:

Webpage for finding internal ID: <https://www.virtualonlinecycling.com/p/zwiftid.html>

{: .note }
Any workouts created already will be copied into this folder on first start

{: .note }
To add a new workout just copy the zwo file to this directory

{: .note }
Deleting files from the directory will not delete them, they will be re-added when re-starting zwift, you must delete from the
zwift menu
