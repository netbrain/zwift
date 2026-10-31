---
title: Video Routes
parent: Troubleshooting
nav_order: 5
---

# Video routes show a technical error

## Symptoms

- Zwift shows a technical error when you select **Video** in the route list
- `Log.txt` contains `Video decode context not supported on this hardware`

## Cause

Zwift checks for H.264 decoding through Direct3D 11 when you log in. In the container, wine provides this using
Vulkan Video, so your GPU driver needs to support `VK_KHR_video_decode_h264`.

## Solution

1. Make sure you are using the latest image
2. Use [`ZWIFT_LOG_DIR`](../../configuration/options/#zwift_log_dir) to access `Log.txt` and search for `VideoDecoderContext`:

   | Log message                               | Meaning                                                 |
   |-------------------------------------------|---------------------------------------------------------|
   | `hardware decode supported on '...'`      | The check passed                                        |
   | `device creation failed (0x887A0004)`     | Your driver doesn't expose Vulkan H.264 decoding        |
   | `CreateDXGIFactory1 failed`               | wine didn't find a usable Vulkan driver                 |

## Related

- [GitHub issue #425](https://github.com/netbrain/zwift/issues/425)
