---
title: Customize Zwift graphics
nav_order: 2
---

# Customize Zwift graphics

## How can I access/modify the graphics settings?

By default, zwift assigns a graphics profile based on your graphics card. This profile can be either basic, medium, high, or
ultra. This profile determines the level of detail and the quality of the textures you get in game. It is not possible to change
which graphics profile the game uses. When the default options of the profile aren't optimal (for example when zwift doesn't
recognize your graphics card and you only get the `medium` profile or when your cpu is the bottleneck and your fps is on the low
side because zwift assigned the ultra profile), it is possible to manually tweak the graphics settings by setting
`ZWIFT_OVERRIDE_GRAPHICS=1`, and editing the settings in the `$HOME/.config/zwift/graphics.txt` or
`$HOME/.config/zwift/$USER-graphics.txt` file as you see fit. To find out which profile zwift assigned, you can upload your
zwift log to <https://zwiftalizer.com>.

The default settings for the different profiles are:

| key                  | description                                            | basic        | medium       | high         | ultra         |
|----------------------|--------------------------------------------------------|--------------|--------------|--------------|---------------|
| `res`                | texture resolution (independent from game resolution)  | 1024x576(0x) | 1280x720(0x) | 1280x720(0x) | 1920x1080(0x) |
| `sres`               | shadow resolution                                      | 512x512      | 1024x1024    | 1024x1024    | 2048x2048     |
| `gSSAO`              | enable high-quality lighting and shadows               | 0            | 0            | 1            | 1             |
| `gFXAA`              | enable anti-aliasing                                   | 1            | 1            | 1            | 1             |
| `gSunRays`           | enable sun rays (default 1)                            | 0            | 0            |              |               |
| `gHeadLight`         | enable bike headlights (default 1)                     | 0            | 0            |              |               |
| `gFoliagePercent`    | reduce/increase auto-generated foliage (default 1.0)   | 0.5          | 0.5          |              |               |
| `gSimpleReflections` | lower quality reflections (default 0)                  | 1            | 1            |              |               |
| `gLODBias`           | lower polygon count (higher value is lower, default 0) | 1            | 1            |              |               |
| `gShowFPS`           | display fps in the top left corner (default 0)         |              |              |              |               |

The number in parentheses after the texture resolution (for example `(0x)` after `1920x1080`) is the anti-aliasing setting. This
number can be modified to for example `1920x1080(4x)` or `1920x1080(8x)` to increase anti-aliasing.

Example `$HOME/.config/zwift/graphics.txt` (settings from the ultra profile, with in-game fps counter enabled):

```text
res 1920x1080(0x)
sres 2048x2048
set gSSAO=1
set gFXAA=1
set gShowFPS=1
```

Start zwift with the `ZWIFT_OVERRIDE_GRAPHICS=1 zwift` command to use the settings from the graphics.txt file.

You can find more information about these settings in this [Zwift Insider](https://zwiftinsider.com/config-file-tweaks/)
article. Note that this is an older article and as such some of the information in it is outdated. The default values of the
different profiles have changed to what is in the table listed above and for example the `aniso` setting does not exist anymore.

> :warning: **Before using ZWIFT_OVERRIDE_GRAPHICS**: This option requires that the `$HOME/.config/zwift/graphics.txt` file
exists. If a `graphics.txt` does not exist and the `ZWIFT_OVERRIDE_GRAPHICS` option is used, it will be created automatically
the first time zwift is launched.

Aside from the graphics profile which is assigned by zwift and cannot be changed, there is also the in-game setting to change
the display resolution. Changing this resolution does not change the graphics profile and as such does not affect the quality of
the textures, shadows, and other graphics options. It only affects the resolution of the game itself. Which resolutions are
available in the zwift in-game setting is dependent on the graphics profile assigned based on your graphics card. If zwift does
not recognize your graphics card or you have a WQHD or UHD display and zwift does not offer the higher resolutions, it is
possible to manually override the game resolution by setting the `ZWIFT_OVERRIDE_RESOLUTION` option. For example to force zwift
to use UHD you can launch it using `ZWIFT_OVERRIDE_RESOLUTION=3840x2160 zwift`.

The full list of available resolutions is:

| name   | resolution | pixels    |
|--------|------------|-----------|
| Low    | 576p       | 720x576   |
| Medium | 720p       | 1280x720  |
| High   | 1080p      | 1920x1080 |
| Ultra  | 1440p      | 2560x1440 |
| 4k UHD | 2160p      | 3840x2160 |

> :warning: **Before using ZWIFT_OVERRIDE_RESOLUTION**: This option requires that the `prefs.xml` file exists. Make sure to
  launch zwift at least once so it creates the `prefs.xml` file before using the `ZWIFT_OVERRIDE_RESOLUTION` option.
