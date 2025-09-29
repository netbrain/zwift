{
  description = "Easily zwift on linux";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, self }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      wrapPackage = {
          image,
          tag,
          dontCheck,
          dontPull,
          dryRun,
          interactive,
          containerTool,
          containerExtraArgs,
          zwiftUsername,
          zwiftPassword,
          zwiftWorkoutDir,
          zwiftActivityDir,
          zwiftLogDir,
          zwiftOverrideGraphics,
          zwiftOverrideResolution,
          zwiftFg,
          zwiftNoGameMode,
          wineExperimentalWayland,
          networking,
          zwiftUid,
          zwiftGid,
          vgaDeviceFlag,
          debug
        }: pkgs.stdenv.mkDerivation rec {
        pname = "zwift";
        version = "0-unstable";

        src = self.packages.x86_64-linux.zwift;

        nixosRun = pkgs.writeShellScript "zwift-nixos.sh" ''
          IMAGE=${image}
          VERSION=${tag}
          DONT_CHECK=${dontCheck}
          DONT_PULL=${dontPull}
          DRYRUN=${dryRun}
          INTERACTIVE=${interactive}
          CONTAINER_TOOL=${containerTool}
          CONTAINER_EXTRA_ARGS=${containerExtraArgs}
          ZWIFT_USERNAME=${zwiftUsername}
          ZWIFT_PASSWORD=${zwiftPassword}
          ZWIFT_WORKOUT_DIR=${zwiftWorkoutDir}
          ZWIFT_ACTIVITY_DIR=${zwiftActivityDir}
          ZWIFT_LOG_DIR=${zwiftLogDir}
          ZWIFT_OVERRIDE_GRAPHICS=${zwiftOverrideGraphics}
          ZWIFT_OVERRIDE_RESOLUTION=${zwiftOverrideResolution}
          ZWIFT_FG=${zwiftFg}
          ZWIFT_NO_GAMEMODE=${zwiftNoGameMode}
          WINE_EXPERIMENTAL_WAYLAND=${wineExperimentalWayland}
          NETWORKING=${networking}
          ZWIFT_UID=${zwiftUid}
          ZWIFT_GID=${zwiftGid}
          DEBUG=${debug}
          VGA_DEVICE_FLAG=${vgaDeviceFlag}

          ${./zwift.sh}
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
          {
            options.programs.zwift = {
              enable = lib.mkEnableOption "zwift on linux";

              image = lib.mkOption { type = lib.types.string; default = ""; };
              version = lib.mkOption { type = lib.types.string; default = ""; };
              dontCheck = lib.mkOption { type = lib.types.bool; default = false; };
              dontPull = lib.mkOption { type = lib.types.bool; default = false; };
              dryRun = lib.mkOption { type = lib.types.bool; default = false; };
              interactive = lib.mkOption { type = lib.types.bool; default = false; };
              containerTool = lib.mkOption { type = lib.types.string; default = ""; };
              containerExtraArgs = lib.mkOption { type = lib.types.string; default = ""; };
              zwiftUsername = lib.mkOption { type = lib.types.string; default = ""; };
              zwiftPassword = lib.mkOption { type = lib.types.string; default = ""; };
              zwiftWorkoutDir = lib.mkOption { type = lib.types.string; default = ""; };
              zwiftActivityDir = lib.mkOption { type = lib.types.string; default = ""; };
              zwiftLogDir = lib.mkOption { type = lib.types.string; default = ""; };
              zwiftOverrideGraphics = lib.mkOption { type = lib.types.bool; default = false };
              zwiftOverrideResolution = lib.mkOption { type = lib.types.string; default = ""; };
              zwiftFg = lib.mkOption { type = lib.types.bool; default = false; };
              zwiftNoGameMode = lib.mkOption { type = lib.types.bool; default = false; };
              wineExperimentalWayland = lib.mkOption { type = lib.types.bool; default = false; };
              networking = lib.mkOption { type = lib.types.string; default = ""; };
              zwiftUid = lib.mkOption { type = lib.types.string; default = ""; };
              zwiftGid = lib.mkOption { type = lib.types.string; default = ""; };
              vgaDeviceFlag = lib.mkOption { type = lib.types.string; default = ""; };
              debug = lib.mkOption { type = lib.types.bool; default = false; };
            };

            config = lib.mkIf config.programs.zwift.enable {
              virtualisation.podman.enable = true;
              environment = {
                systemPackages = with config.programs.zwift; [(wrapPackage {
                  inherit image containerTool containerExtraArgs zwiftUsername zwiftPassword zwiftWorkoutDir zwiftActivityDir zwiftLogDir zwiftOverrideResolution networking zwiftUid zwiftGid vgaDeviceFlag;
                  tag = version;
                  dontCheck = if dontCheck then "1" else "" ;
                  dontPull = if dontPull then "1" else "";
                  dryRun = if dryRun then "1" else "";
                  interactive = if interactive then "1" else "";
                  zwiftOverrideGraphics = if zwiftOverrideGraphics then "1" else "";
                  zwiftFg = if zwiftFg then "1" else "";
                  zwiftNoGameMode = if zwiftNoGameMode then "1" else "";
                  wineExperimentalWayland = if wineExperimentalWayland then "1" else "";
                  debug = if debug then "1" else "";
                })];
              };
            };
          };
        default = self.nixosModules.zwift;
      };

      packages.x86_64-linux = {
        zwift = pkgs.stdenv.mkDerivation rec {
          pname = "zwift-unwrapped";
          version = "0-unstable";

          src = ./.;

          nativeBuildInputs = [ pkgs.copyDesktopItems ];

          installPhase = ''
            runHook preInstall
            install -Dm755 zwift.sh -T $out/bin/${pname}
            install -Dm644 $src/assets/hicolor/scalable/apps/Zwift\ Logogram.svg \
              -T $out/share/icons/hicolor/scalable/apps/zwift.svg
            runHook postInstall
          '';

          desktopItems = [ "assets/Zwift.desktop" ];
        };
        default = self.packages.x86_64-linux.zwift;
      };
    };
}
