{ lib }:
let
  inherit (lib) mkOption types;
in
{
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
}
