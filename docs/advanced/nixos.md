---
title: NixOS
parent: Advanced
nav_order: 2
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
environment variables in camelCase.

The `containerTool` option selects the backend: `podman` (default), `docker` or `fhs`. The first two run Zwift in a
container, `fhs` runs Zwift natively with Wine in an FHS environment.

### Container backend

```nix
{
  programs.zwift = {
    # Enable the zwift module and install required dependencies
    enable = true;
    # Container tool to run zwift: "podman", "docker" or "fhs"
    containerTool = "podman";
    # The Docker image to use for zwift
    image = "docker.io/netbrain/zwift";
    # The zwift game version to run
    version = "1.67.0";
    # If true, skip new version check
    dontUpdate = false;
    # If true, don't clean up previous images after pulling
    dontClean = false;
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
    # Use custom graphics profiles if true
    zwiftOverrideGraphics = false;
    # Override the game resolution (e.g. "1920x1080")
    zwiftOverrideResolution = "";
    # Run zwift in the foreground (set true for foreground mode)
    zwiftFg = false;
    # Disable Linux GameMode if true
    zwiftNoGameMode = false;
    # Enable Wine's experimental Wayland support if using Wayland
    wineExperimentalWayland = false;
    # Networking mode for the container ("bridge" is default)
    networking = "bridge";
    # GPU/device flags override (Docker: "--gpus=all", Podman/CDI: "--device=nvidia.com/gpu=all")
    vgaDeviceFlag = "--device=nvidia.com/gpu=all";
    # Enable debug output and verbose logging if true
    debug = false;
    # Verbosity level
    verbosity = "1";
    # If set, run container in privileged mode ("--privileged --security-opt label=disable")
    privilegedContainer = false;
    # If set to false, allow the container access to host bluetooth
    disableBluetooth = false;
  };
}
```

### FHS backend

```nix
{
  programs.zwift = {
    # Enable the zwift module and install required dependencies
    enable = true;
    # Run zwift natively with Wine in an FHS environment
    containerTool = "fhs";
    # Custom Wine prefix, defaults to ~/.wine-zwift
    winePrefix = "/home/example/.wine-zwift";
    # Enable debug output if true
    debug = false;
    # Verbosity level
    verbosity = "1";
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
