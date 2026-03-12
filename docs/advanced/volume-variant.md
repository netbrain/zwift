---
title: Volume Variant
parent: Advanced
nav_order: 4
---

# Volume Variant

The default mode mounts only the Zwift documents directory as a volume. The **volume variant** mounts the entire
`/home/user` directory as a persistent volume instead. On first run, the container runtime automatically populates the
volume from the image contents — no separate installation step needed.

## Benefits

- **No per-launch chown**: File ownership persists in the volume, eliminating the slow `chown` that Docker users with
  non-1000 uid/gid experience on every launch.
- **Persistent wine prefix**: The entire Wine configuration, registry, and installed prerequisites are preserved between
  runs.

## How it works

| | Default (`container`) | Volume (`volume`) |
| --- | --- | --- |
| **Image** | `netbrain/zwift:latest` | `netbrain/zwift:latest` (same image) |
| **Volume** | `zwift-$USER` mounted at Zwift docs directory | `zwift-home-$USER` mounted at `/home/user` |
| **First run** | Seconds | Seconds (volume auto-populated from image) |
| **Subsequent runs** | Seconds | Seconds |
| **chown on launch** | Every launch if uid/gid != 1000 | Skipped (ownership persists in volume) |

When a new named volume is mounted to a container path that already has data, Docker (and Podman) automatically copy
the image contents into the volume. This means the first launch is just as fast as any other — no download or
installation wait.

## Usage

### Environment variable

```bash
ZWIFT_VARIANT="volume" zwift
```

Or add to your config file (`~/.config/zwift/config`):

```bash
ZWIFT_VARIANT="volume"
```

### NixOS module

```nix
{
  programs.zwift = {
    enable = true;
    variant = "volume";
  };
}
```

### Standalone Nix package

```bash
nix run github:netbrain/zwift#zwift-volume
```

## Updating Zwift

Zwift updates itself through its built-in launcher. You can also force an update by passing `--update` as an entrypoint
argument:

```bash
ZWIFT_VARIANT="volume" zwift -- --update
```

## Resetting the installation

To start fresh, remove the persistent volume:

```bash
docker volume rm "zwift-home-$USER"
```

The next launch will re-populate the volume from the current image.
