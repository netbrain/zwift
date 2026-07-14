# NixOS module for Zwift
{ zwift-fhs-package }:
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
        "fhs"
      ];
      default = "podman";
      description = ''
        How to run Zwift: "podman" or "docker" use a container; "fhs" uses native Wine via a FHS environment.
      '';
    };

    # FHS-only options
    winePrefix = mkOption {
      type = types.str;
      default = "";
      description = ''
        Custom Wine prefix directory. Defaults to ~/.wine-zwift if not specified.
        Only applies when containerTool = "fhs".
      '';
    };

    # Container-only options
    image = mkOption {
      type = types.str;
      default = "";
      description = "Container image to use. Only applies when containerTool = \"podman\" or \"docker\".";
    };

    version = mkOption {
      type = types.str;
      default = "";
      description = "Container image tag/version. Only applies when containerTool = \"podman\" or \"docker\".";
    };

    dontCheck = mkOption {
      type = types.bool;
      default = false;
      description = "Skip version check. Only applies when containerTool = \"podman\" or \"docker\".";
    };

    dontPull = mkOption {
      type = types.bool;
      default = false;
      description = "Skip pulling the container image. Only applies when containerTool = \"podman\" or \"docker\".";
    };

    dontClean = mkOption {
      type = types.bool;
      default = false;
      description = "Skip cleaning up the container after exit. Only applies when containerTool = \"podman\" or \"docker\".";
    };

    dryRun = mkOption {
      type = types.bool;
      default = false;
      description = "Perform a dry run without actually starting Zwift. Only applies when containerTool = \"podman\" or \"docker\".";
    };

    interactive = mkOption {
      type = types.bool;
      default = false;
      description = "Run the container interactively. Only applies when containerTool = \"podman\" or \"docker\".";
    };

    containerExtraArgs = mkOption {
      type = types.str;
      default = "";
      description = "Extra arguments passed to the container runtime. Only applies when containerTool = \"podman\" or \"docker\".";
    };

    networking = mkOption {
      type = types.str;
      default = "";
      description = "Container networking mode. Only applies when containerTool = \"podman\" or \"docker\".";
    };

    zwiftUid = mkOption {
      type = types.str;
      default = "";
      description = "UID to run Zwift as inside the container. Only applies when containerTool = \"podman\" or \"docker\".";
    };

    zwiftGid = mkOption {
      type = types.str;
      default = "";
      description = "GID to run Zwift as inside the container. Only applies when containerTool = \"podman\" or \"docker\".";
    };

    vgaDeviceFlag = mkOption {
      type = types.str;
      default = "";
      description = "VGA device flag for container GPU passthrough. Only applies when containerTool = \"podman\" or \"docker\".";
    };

    privilegedContainer = mkOption {
      type = types.bool;
      default = false;
      description = "Run the container in privileged mode. Only applies when containerTool = \"podman\" or \"docker\".";
    };

    # Common options
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

  config = mkIf cfg.enable (lib.mkMerge [
    (mkIf (cfg.containerTool == "fhs") {
      environment.systemPackages = [ zwift-fhs-package ];

      environment.etc."zwift/config".text = ''
        # Zwift configuration (auto-generated by NixOS module)
        ${lib.optionalString (cfg.zwiftUsername != "") "export ZWIFT_USERNAME=\"${cfg.zwiftUsername}\""}
        ${lib.optionalString (cfg.zwiftPassword != "") "export ZWIFT_PASSWORD=\"${cfg.zwiftPassword}\""}
        ${lib.optionalString (cfg.winePrefix != "") "export WINEPREFIX=\"${cfg.winePrefix}\""}
        ${lib.optionalString (cfg.zwiftWorkoutDir != "") "export ZWIFT_WORKOUT_DIR=\"${cfg.zwiftWorkoutDir}\""}
        ${lib.optionalString (cfg.zwiftActivityDir != "") "export ZWIFT_ACTIVITY_DIR=\"${cfg.zwiftActivityDir}\""}
        ${lib.optionalString (cfg.zwiftLogDir != "") "export ZWIFT_LOG_DIR=\"${cfg.zwiftLogDir}\""}
        ${lib.optionalString (cfg.zwiftScreenshotsDir != "") "export ZWIFT_SCREENSHOTS_DIR=\"${cfg.zwiftScreenshotsDir}\""}
        ${lib.optionalString cfg.zwiftOverrideGraphics "export ZWIFT_OVERRIDE_GRAPHICS=1"}
        ${lib.optionalString (cfg.zwiftOverrideResolution != "") "export ZWIFT_OVERRIDE_RESOLUTION=\"${cfg.zwiftOverrideResolution}\""}
        ${lib.optionalString cfg.zwiftFg "export ZWIFT_FG=1"}
        ${lib.optionalString cfg.zwiftNoGameMode "export ZWIFT_NO_GAMEMODE=1"}
        ${lib.optionalString cfg.wineExperimentalWayland "export WINE_EXPERIMENTAL_WAYLAND=1"}
        ${lib.optionalString cfg.debug "export DEBUG=1"}
      '';
    })

    (mkIf (cfg.containerTool != "fhs") {
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
    })
  ]);
}
