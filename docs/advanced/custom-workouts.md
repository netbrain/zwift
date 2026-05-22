---
title: Custom Workouts
nav_order: 1
parent: Advanced
---

# Custom Workout files

Zwift supports manually importing custom workout files with the `.zwo` file type.

## How can I add custom workout files?

1. Zwift workout files are stored in the workouts directory inside the container. To map the workouts directory to a directory
   on your PC, use the [`ZWIFT_WORKOUT_DIR`](../../configuration/options/#zwift_workout_dir) option. Make sure to create the
   target directory first if it does not exist yet.

   ```bash
   ZWIFT_WORKOUT_DIR="${xdg-user-dir DOCUMENTS}/Zwift/Workouts"
   ```

2. Launch Zwift so the workouts directory in the container gets mirrored to the directory on your PC. After the copying is done,
   close Zwift again.
3. The workouts folder will contain subdirectories e.g. `~/Documents/Zwift/Workouts/393938`. The number is your Zwift user ID.
   There will usually be only one ID, however if you have multiple Zwift accounts it may show one subdirectory for each user.
   To find the correct user ID you can use the following link: <https://www.virtualonlinecycling.com/p/zwiftid.html>.
4. Place your custom .zwo files in the directory with your Zwift user ID. It is also allowed to create subdirectories if you
   have a lot of .zwo files and you want to organize them.
5. Zwift will pick up the new workouts the first time it is launched after adding the files to the correct directory. They will
   be uploaded to the Zwift servers and are available on all devices you Zwift on, not only on the PC where you added the files.

## How can I delete custom workout files?

It is not enough to just delete the .zwo file. If you do so, it will be downloaded again the next time you launch Zwift. There
are two options to delete custom workout files:

### Option 1: Delete custom workouts in Zwift

Delete the custom workout in Zwift by following [the instructions in the Zwift documentation][delete-custom-workout].

### Option 2: Manually remove custom workouts

1. Open the `~/Documents/Zwift/Workouts/<zwift id>/workouts.files` file.
2. Find the workout you want to delete, for example:

   ```xml
   <custom_file>
         <name>my_fancy_workout.zwo</name>
         <time>1702588908</time>
         <guid>12345</guid>
         <checksum>123</checksum>
         <deleted>false</deleted>
   </custom_file>
   ```

3. Change the deleted line from `false` to `true`.
4. Delete the workout .zwo file.
5. The workout will be removed when you launch Zwift.

[delete-custom-workout]: https://support.zwift.com/en_us/custom-workouts-ryGOTVEPs#Deleting_a_Custom_Workout
