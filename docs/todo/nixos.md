---
title: NixOS
parent: TODO
nav_order: 3
---

# NixOS

## Installation

To use the NixOS module, configure your flake.nix:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zwift.url = "github:netbrain/zwift";
  };

  outputs = { nixpkgs, zwift, ... }: {
    nixosConfigurations."«hostname»" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ zwift.nixosModules.zwift ./configuration.nix ];
    };
  };
}
```

## Configuration

Then enable and configure the module in your NixOS configuration. The configuration options are written analog to the
environment variables in camelCase:

```nix
{
  programs.zwift = {
    # Enable the zwift module and install required dependencies
    enable = true;
    # The Docker image to use for zwift
    image = "docker.io/netbrain/zwift";
    # The zwift game version to run
    version = "1.67.0";
    # Container tool to run zwift (e.g., "podman" or "docker")
    containerTool = "podman";
    # If true, do not pull the image (use locally cached image)
    dontPull = false;
    # If true, skip new version check
    dontCheck = false;
    # If true, print the container run command and exit
    dryRun = false;
    # If set, launch container with "-it --entrypoint bash" for debugging
    interactive = false;
    # Extra args passed to docker/podman (e.g. "--cpus=1.5")
    containerExtraArgs = "";
    # Zwift account username (email address)
    zwiftUsername = "user@example.com";
    # Zwift account password
    zwiftPassword = "xxxx";
    # Directory to store zwift workout files
    zwiftWorkoutDir = "/var/lib/zwift/workouts";
    # Directory to store zwift activity files
    zwiftActivityDir = "/var/lib/zwift/activities";
    # Directory to store zwift log files
    zwiftLogDir = "/var/lib/zwift/logs";
    # Directory to store zwift screenshots
    zwiftScreenshotsDir = "/var/lib/zwift/screenshots";
    # Run zwift in the foreground (set true for foreground mode)
    zwiftFg = false;
    # Disable Linux GameMode if true
    zwiftNoGameMode = false;
    # Enable Wine's experimental Wayland support if using Wayland
    wineExperimentalWayland = false;
    # Networking mode for the container ("bridge" is default)
    networking = "bridge";
    # User ID for running the container (usually your own UID)
    zwiftUid = "1000";
    # Group ID for running the container (usually your own GID)
    zwiftGid = "1000";
    # GPU/device flags override (Docker: "--gpus=all", Podman/CDI: "--device=nvidia.com/gpu=all")
    vgaDeviceFlag = "--device=nvidia.com/gpu=all";
    # Enable debug output and verbose logging if true
    debug = false;
    # If set, run container in privileged mode ("--privileged --security-opt label=disable")
    privilegedContainer = false;
  };
}
```

## Firewall

You may need to adjust your firewall settings to allow multicast traffic for device (needed to communicate to the
companion app as well as to access the Wahoo trainer and Zwift click devices).

```nix
networking = {
  firewall = {
    allowedUDPPorts = [3022 3024];
    allowedTCPPorts = [21587 21588];
  };
};
```
