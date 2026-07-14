# NixOS module for Zwift
{ config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.zwift;
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    ;
  wrapContainerPackage =
    args: import ./zwift-container-package.nix ({ inherit pkgs; } // args);
in
{
  options.programs.zwift = {
    enable = mkEnableOption "Zwift on Linux";

    containerTool = mkOption {
      type = types.enum [
        "podman"
        "docker"
      ];
      default = "podman";
      description = ''How to run Zwift: "podman" or "docker".'';
    };

    image = mkOption {
      type = types.str;
      default = "";
      description = "Container image to use.";
    };

    version = mkOption {
      type = types.str;
      default = "";
      description = "Container image tag/version.";
    };

    dontCheck = mkOption {
      type = types.bool;
      default = false;
      description = "Skip version check.";
    };

    dontPull = mkOption {
      type = types.bool;
      default = false;
      description = "Skip pulling the container image.";
    };

    dontClean = mkOption {
      type = types.bool;
      default = false;
      description = "Skip cleaning up the container after exit.";
    };

    dryRun = mkOption {
      type = types.bool;
      default = false;
      description = "Perform a dry run without actually starting Zwift.";
    };

    interactive = mkOption {
      type = types.bool;
      default = false;
      description = "Run the container interactively.";
    };

    containerExtraArgs = mkOption {
      type = types.str;
      default = "";
      description = "Extra arguments passed to the container runtime.";
    };

    networking = mkOption {
      type = types.str;
      default = "";
      description = "Container networking mode.";
    };

    zwiftUid = mkOption {
      type = types.str;
      default = "";
      description = "UID to run Zwift as inside the container.";
    };

    zwiftGid = mkOption {
      type = types.str;
      default = "";
      description = "GID to run Zwift as inside the container.";
    };

    vgaDeviceFlag = mkOption {
      type = types.str;
      default = "";
      description = "VGA device flag for container GPU passthrough.";
    };

    privilegedContainer = mkOption {
      type = types.bool;
      default = false;
      description = "Run the container in privileged mode.";
    };

    zwiftUsername = mkOption {
      type = types.str;
      default = "";
      description = "Zwift account email for automatic login.";
    };

    zwiftPassword = mkOption {
      type = types.str;
      default = "";
      description = ''
        Zwift account password for automatic login.
        Consider using a secrets management solution instead of storing passwords in your config.
      '';
    };

    zwiftWorkoutDir = mkOption {
      type = types.str;
      default = "";
      description = "Custom directory for Zwift workouts.";
    };

    zwiftActivityDir = mkOption {
      type = types.str;
      default = "";
      description = "Custom directory for Zwift activities.";
    };

    zwiftLogDir = mkOption {
      type = types.str;
      default = "";
      description = "Custom directory for Zwift logs.";
    };

    zwiftScreenshotsDir = mkOption {
      type = types.str;
      default = "";
      description = "Custom directory for Zwift screenshots.";
    };

    zwiftOverrideGraphics = mkOption {
      type = types.bool;
      default = false;
      description = "Use custom graphics configuration.";
    };

    zwiftOverrideResolution = mkOption {
      type = types.str;
      default = "";
      example = "1920x1080";
      description = "Override the Zwift display resolution.";
    };

    zwiftFg = mkOption {
      type = types.bool;
      default = false;
      description = "Run Zwift in foreground mode.";
    };

    zwiftNoGameMode = mkOption {
      type = types.bool;
      default = false;
      description = "Disable GameMode integration.";
    };

    wineExperimentalWayland = mkOption {
      type = types.bool;
      default = false;
      description = "Enable experimental Wayland support in Wine.";
    };

    debug = mkOption {
      type = types.bool;
      default = false;
      description = "Enable debug output.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.podman.enable = lib.mkDefault (cfg.containerTool == "podman");
    virtualisation.docker.enable = lib.mkDefault (cfg.containerTool == "docker");

    environment.systemPackages = [
      (wrapContainerPackage {
        inherit (cfg)
          image
          containerTool
          containerExtraArgs
          zwiftUsername
          zwiftPassword
          zwiftWorkoutDir
          zwiftActivityDir
          zwiftLogDir
          zwiftScreenshotsDir
          zwiftOverrideResolution
          networking
          zwiftUid
          zwiftGid
          vgaDeviceFlag
          ;
        tag = cfg.version;
        dontCheck = if cfg.dontCheck then "1" else "";
        dontPull = if cfg.dontPull then "1" else "";
        dontClean = if cfg.dontClean then "1" else "";
        dryRun = if cfg.dryRun then "1" else "";
        interactive = if cfg.interactive then "1" else "";
        zwiftOverrideGraphics = if cfg.zwiftOverrideGraphics then "1" else "";
        zwiftFg = if cfg.zwiftFg then "1" else "";
        zwiftNoGameMode = if cfg.zwiftNoGameMode then "1" else "";
        wineExperimentalWayland = if cfg.wineExperimentalWayland then "1" else "";
        debug = if cfg.debug then "1" else "";
        privilegedContainer = if cfg.privilegedContainer then "1" else "";
      })
    ];
  };
}
