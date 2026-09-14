{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.zwift;

  inherit (lib)
    mkIf
    mkOption
    types
    ;

  wrapContainerPackage = args: import ./zwift-container-package.nix ({ inherit pkgs; } // args);

  wrapFhsPackage = args: import ./zwift-fhs-package.nix ({ inherit pkgs; } // args);

  nullableToEmpty = value: if value == null then "" else value;

  nullableBoolToString =
    value: default:
    let
      boolValue = if value == null then default else value;
    in
    if boolValue then "1" else "";

  isFhs = cfg.containerTool == "fhs";

  optionDefinitions = {
    enable = {
      type = types.bool;
      default = false;
      description = "Enable Zwift on Linux.";
    };

    containerTool = {
      type = types.enum [
        "podman"
        "docker"
        "fhs"
      ];
      default = "podman";
      description = ''
        How to run Zwift: "podman" or "docker" use a container; "fhs" uses
        native Wine via a FHS environment.
      '';
    };

    # FHS-only options
    winePrefix = {
      type = types.nullOr types.str;
      default = null;
      supportedContainerTools = [ "fhs" ];
      description = ''
        Custom Wine prefix directory. Defaults to ~/.wine-zwift if not specified.
      '';
    };

    # Container-only options
    image = {
      type = types.nullOr types.str;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Container image to use.
      '';
    };

    version = {
      type = types.nullOr types.str;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Container image tag/version.
      '';
    };

    dontUpdate = {
      type = types.nullOr types.bool;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Skip version check.
      '';
    };

    dontClean = {
      type = types.nullOr types.bool;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Skip cleaning up the container after exit.
      '';
    };

    dryRun = {
      type = types.nullOr types.bool;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Perform a dry run without actually starting Zwift.
      '';
    };

    interactive = {
      type = types.nullOr types.bool;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Run the container interactively.
      '';
    };

    containerExtraArgs = {
      type = types.nullOr types.str;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Extra arguments passed to the container runtime.
      '';
    };

    networking = {
      type = types.nullOr types.str;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Container networking mode.
      '';
    };

    vgaDeviceFlag = {
      type = types.nullOr types.str;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        VGA device flag for container GPU passthrough.
      '';
    };

    privilegedContainer = {
      type = types.nullOr types.bool;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Run the container in privileged mode.
      '';
    };

    zwiftUsername = {
      type = types.nullOr types.str;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Zwift account email for automatic login.
      '';
    };

    zwiftPassword = {
      type = types.nullOr types.str;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Zwift account password for automatic login.

        Consider using a secrets management solution instead of storing
        passwords in your config.
      '';
    };

    zwiftWorkoutDir = {
      type = types.nullOr types.str;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Custom directory for Zwift workouts.
      '';
    };

    zwiftActivityDir = {
      type = types.nullOr types.str;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Custom directory for Zwift activities.
      '';
    };

    zwiftLogDir = {
      type = types.nullOr types.str;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Custom directory for Zwift logs.
      '';
    };

    zwiftScreenshotsDir = {
      type = types.nullOr types.str;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Custom directory for Zwift screenshots.
      '';
    };

    zwiftOverrideGraphics = {
      type = types.nullOr types.bool;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Use custom graphics configuration.
      '';
    };

    zwiftOverrideResolution = {
      type = types.nullOr types.str;
      default = null;
      example = "1920x1080";
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Override the Zwift display resolution.
      '';
    };

    zwiftFg = {
      type = types.nullOr types.bool;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Run Zwift in foreground mode.
      '';
    };

    zwiftNoGameMode = {
      type = types.nullOr types.bool;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Disable GameMode integration.
        Note that GameMode is currently not supported with containerTool = fhs.
      '';
    };

    wineExperimentalWayland = {
      type = types.nullOr types.bool;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = ''
        Enable experimental Wayland support in Wine.
      '';
    };

    disableBluetooth = {
      type = types.nullOr types.bool;
      default = null;
      supportedContainerTools = [
        "podman"
        "docker"
      ];
      description = "Do not allow the container to access host bluetooth.";
    };

    # Common options
    debug = {
      type = types.bool;
      default = false;
      description = "Enable debug output.";
    };

    verbosity = {
      type = types.enum [
        "0"
        "1"
        "2"
        "3"
      ];
      default = "1";
      description = "Verbosity level.";
    };
  };

  mkOptionDefinition =
    _name: definition: mkOption (lib.removeAttrs definition [ "supportedContainerTools" ]);

  assertions = lib.mapAttrsToList (name: definition: {
    assertion = cfg.${name} == null || lib.elem cfg.containerTool definition.supportedContainerTools;

    message = "programs.zwift.${name} is only valid with containerTool = ${lib.concatStringsSep ", " definition.supportedContainerTools}.";
  }) (lib.filterAttrs (_name: definition: definition ? supportedContainerTools) optionDefinitions);
in
{
  options.programs.zwift = lib.mapAttrs mkOptionDefinition optionDefinitions;

  config = mkIf cfg.enable {
    inherit assertions;

    environment.systemPackages =
      if isFhs then
        [
          (wrapFhsPackage {
            winePrefix = nullableToEmpty cfg.winePrefix;
            debug = if cfg.debug then "1" else "";
            verbosity = cfg.verbosity;
          })
        ]
      else
        [
          (wrapContainerPackage {
            containerTool = cfg.containerTool;
            image = nullableToEmpty cfg.image;
            tag = nullableToEmpty cfg.version;
            containerExtraArgs = nullableToEmpty cfg.containerExtraArgs;
            zwiftUsername = nullableToEmpty cfg.zwiftUsername;
            zwiftPassword = nullableToEmpty cfg.zwiftPassword;
            zwiftWorkoutDir = nullableToEmpty cfg.zwiftWorkoutDir;
            zwiftActivityDir = nullableToEmpty cfg.zwiftActivityDir;
            zwiftLogDir = nullableToEmpty cfg.zwiftLogDir;
            zwiftScreenshotsDir = nullableToEmpty cfg.zwiftScreenshotsDir;
            zwiftOverrideResolution = nullableToEmpty cfg.zwiftOverrideResolution;
            networking = nullableToEmpty cfg.networking;
            vgaDeviceFlag = nullableToEmpty cfg.vgaDeviceFlag;
            dontUpdate = nullableBoolToString cfg.dontUpdate false;
            dontClean = nullableBoolToString cfg.dontClean false;
            dryRun = nullableBoolToString cfg.dryRun false;
            interactive = nullableBoolToString cfg.interactive false;
            zwiftOverrideGraphics = nullableBoolToString cfg.zwiftOverrideGraphics false;
            zwiftFg = nullableBoolToString cfg.zwiftFg false;
            zwiftNoGameMode = nullableBoolToString cfg.zwiftNoGameMode false;
            wineExperimentalWayland = nullableBoolToString cfg.wineExperimentalWayland false;
            privilegedContainer = nullableBoolToString cfg.privilegedContainer false;
            disableBluetooth = nullableBoolToString cfg.disableBluetooth true;
            debug = if cfg.debug then "1" else "";
            verbosity = cfg.verbosity;
          })
        ];

    virtualisation.podman.enable = lib.mkDefault (cfg.containerTool == "podman");

    virtualisation.docker.enable = lib.mkDefault (cfg.containerTool == "docker");
  };
}
