{
  description = "Easily zwift on linux";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, self }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      wrapPackage =
        {
          image,
          tag,
          dontCheck,
          dontPull,
          dontClean,
          dryRun,
          interactive,
          containerTool,
          containerExtraArgs,
          zwiftUsername,
          zwiftPassword,
          zwiftWorkoutDir,
          zwiftActivityDir,
          zwiftLogDir,
          zwiftScreenshotsDir,
          zwiftOverrideGraphics,
          zwiftOverrideResolution,
          zwiftFg,
          zwiftNoGameMode,
          wineExperimentalWayland,
          networking,
          zwiftUid,
          zwiftGid,
          vgaDeviceFlag,
          debug,
          privilegedContainer,
        }:
        pkgs.stdenv.mkDerivation rec {
          pname = "zwift";
          version = "0-unstable";

          src = self.packages.x86_64-linux.zwift;

          nixosRun = pkgs.writeShellScript "zwift-nixos.sh" ''
            ${pkgs.lib.optionalString (image != "") "export IMAGE=${image}"}
            ${pkgs.lib.optionalString (tag != "") "export VERSION=${tag}"}
            ${pkgs.lib.optionalString (dontCheck != "") "export DONT_CHECK=${dontCheck}"}
            ${pkgs.lib.optionalString (dontPull != "") "export DONT_PULL=${dontPull}"}
            ${pkgs.lib.optionalString (dontClean != "") "export DONT_PULL=${dontClean}"}
            ${pkgs.lib.optionalString (dryRun != "") "export DRYRUN=${dryRun}"}
            ${pkgs.lib.optionalString (interactive != "") "export INTERACTIVE=${interactive}"}
            ${pkgs.lib.optionalString (containerTool != "") "export CONTAINER_TOOL=${containerTool}"}
            ${pkgs.lib.optionalString (
              containerExtraArgs != ""
            ) "export CONTAINER_EXTRA_ARGS=${containerExtraArgs}"}
            ${pkgs.lib.optionalString (zwiftUsername != "") "export ZWIFT_USERNAME=${zwiftUsername}"}
            ${pkgs.lib.optionalString (zwiftPassword != "") "export ZWIFT_PASSWORD=${zwiftPassword}"}
            ${pkgs.lib.optionalString (zwiftWorkoutDir != "") "export ZWIFT_WORKOUT_DIR=${zwiftWorkoutDir}"}
            ${pkgs.lib.optionalString (zwiftActivityDir != "") "export ZWIFT_ACTIVITY_DIR=${zwiftActivityDir}"}
            ${pkgs.lib.optionalString (zwiftLogDir != "") "export ZWIFT_LOG_DIR=${zwiftLogDir}"}
            ${pkgs.lib.optionalString (
              zwiftScreenshotsDir != ""
            ) "export ZWIFT_SCREENSHOTS_DIR=${zwiftScreenshotsDir}"}
            ${pkgs.lib.optionalString (
              zwiftOverrideGraphics != ""
            ) "export ZWIFT_OVERRIDE_GRAPHICS=${zwiftOverrideGraphics}"}
            ${pkgs.lib.optionalString (
              zwiftOverrideResolution != ""
            ) "export ZWIFT_OVERRIDE_RESOLUTION=${zwiftOverrideResolution}"}
            ${pkgs.lib.optionalString (zwiftFg != "") "export ZWIFT_FG=${zwiftFg}"}
            ${pkgs.lib.optionalString (zwiftNoGameMode != "") "export ZWIFT_NO_GAMEMODE=${zwiftNoGameMode}"}
            ${pkgs.lib.optionalString (
              wineExperimentalWayland != ""
            ) "export WINE_EXPERIMENTAL_WAYLAND=${wineExperimentalWayland}"}
            ${pkgs.lib.optionalString (networking != "") "export NETWORKING=${networking}"}
            ${pkgs.lib.optionalString (zwiftUid != "") "export ZWIFT_UID=${zwiftUid}"}
            ${pkgs.lib.optionalString (zwiftGid != "") "export ZWIFT_GID=${zwiftGid}"}
            ${pkgs.lib.optionalString (debug != "") "export DEBUG=${debug}"}
            ${pkgs.lib.optionalString (vgaDeviceFlag != "") "export VGA_DEVICE_FLAG=${vgaDeviceFlag}"}
            ${pkgs.lib.optionalString (
              privilegedContainer != ""
            ) "export PRIVILEGED_CONTAINER=${privilegedContainer}"}

            ${./src/zwift.sh}
          '';

          nativeBuildInputs = [ pkgs.copyDesktopItems ];

          installPhase = ''
            runHook preInstall
            install -Dm755 ${nixosRun} -T $out/bin/${pname}
            install -Dm644 $src/share/icons/hicolor/scalable/apps/zwift.svg \
                    -T $out/share/icons/hicolor/scalable/apps/zwift.svg
            runHook postInstall
          '';

          desktopItems = [ "share/applications/Zwift.desktop" ];
        };
    in
    {
      nixosModules = {
        zwift =
          { config, lib, ... }:
          let
            inherit (lib.types) str bool enum;
            inherit (lib) mkEnableOption mkOption;
          in
          {
            options.programs.zwift = {
              enable = mkEnableOption "zwift on linux";

              image = lib.mkOption {
                type = str;
                default = "";
              };
              version = mkOption {
                type = str;
                default = "";
              };
              dontCheck = mkOption {
                type = lib.types.bool;
                default = false;
              };
              dontPull = mkOption {
                type = bool;
                default = false;
              };
              dontClean = mkOption {
                type = bool;
                default = false;
              };
              dryRun = mkOption {
                type = bool;
                default = false;
              };
              interactive = mkOption {
                type = bool;
                default = false;
              };
              containerTool = mkOption {
                type = enum [
                  "docker"
                  "podman"
                ];
                default = "podman";
              };
              containerExtraArgs = mkOption {
                type = str;
                default = "";
              };
              zwiftUsername = mkOption {
                type = str;
                default = "";
              };
              zwiftPassword = mkOption {
                type = str;
                default = "";
              };
              zwiftWorkoutDir = mkOption {
                type = str;
                default = "";
              };
              zwiftActivityDir = mkOption {
                type = str;
                default = "";
              };
              zwiftLogDir = mkOption {
                type = str;
                default = "";
              };
              zwiftScreenshotsDir = mkOption {
                type = str;
                default = "";
              };
              zwiftOverrideGraphics = mkOption {
                type = bool;
                default = false;
              };
              zwiftOverrideResolution = mkOption {
                type = str;
                default = "";
              };
              zwiftFg = mkOption {
                type = bool;
                default = false;
              };
              zwiftNoGameMode = mkOption {
                type = bool;
                default = false;
              };
              wineExperimentalWayland = mkOption {
                type = bool;
                default = false;
              };
              networking = mkOption {
                type = str;
                default = "";
              };
              zwiftUid = mkOption {
                type = str;
                default = "";
              };
              zwiftGid = mkOption {
                type = str;
                default = "";
              };
              vgaDeviceFlag = mkOption {
                type = str;
                default = "";
              };
              debug = mkOption {
                type = bool;
                default = false;
              };
              privilegedContainer = mkOption {
                type = bool;
                default = false;
              };
            };

            config = lib.mkIf config.programs.zwift.enable {
              virtualisation.podman.enable = lib.mkDefault (config.programs.zwift.containerTool == "podman");
              virtualisation.docker.enable = lib.mkDefault (config.programs.zwift.containerTool == "docker");
              environment = {
                systemPackages = with config.programs.zwift; [
                  (wrapPackage {
                    inherit
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
                    tag = version;
                    dontCheck = if dontCheck then "1" else "";
                    dontPull = if dontPull then "1" else "";
                    dontClean = if dontClean then "1" else "";
                    dryRun = if dryRun then "1" else "";
                    interactive = if interactive then "1" else "";
                    zwiftOverrideGraphics = if zwiftOverrideGraphics then "1" else "";
                    zwiftFg = if zwiftFg then "1" else "";
                    zwiftNoGameMode = if zwiftNoGameMode then "1" else "";
                    wineExperimentalWayland = if wineExperimentalWayland then "1" else "";
                    debug = if debug then "1" else "";
                    privilegedContainer = if privilegedContainer then "1" else "";
                  })
                ];
              };
            };
          };
        default = self.nixosModules.zwift;
      };

      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          # Bash
          shellcheck
          shfmt

          # Nix
          nil
          nixfmt

          # Docker
          hadolint

          # Markdown
          nodePackages.markdownlint-cli2
          nodePackages.cspell

          # Documentation (Jekyll)
          ruby
          bundler

          # Container runtime
          podman

          # GitHub
          gh
          actionlint

          # YAML
          yamllint

          # Utilities
          curl
          jq
        ];
      };

      packages.x86_64-linux = {
        zwift = pkgs.stdenv.mkDerivation rec {
          pname = "zwift-unwrapped";
          version = "0-unstable";

          src = ./.;

          nativeBuildInputs = [ pkgs.copyDesktopItems ];

          installPhase = ''
            runHook preInstall
            install -Dm755 $src/src/zwift.sh -T $out/bin/${pname}
            install -Dm644 $src/bin/Zwift.svg -T $out/share/icons/hicolor/scalable/apps/zwift.svg
            runHook postInstall
          '';

          desktopItems = [ "bin/Zwift.desktop" ];
        };
        default = self.packages.x86_64-linux.zwift;
      };
    };
}
