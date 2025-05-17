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
          containerTool,
          zwiftUsername,
          zwiftPassword,
          zwiftWorkoutDir,
          zwiftActivityDir,
          zwiftFg,
          zwiftNoGameMode,
          wineExperimentalWayland,
          networking,
          zwiftUid,
          zwiftGid,
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
          CONTAINER_TOOL=${containerTool}
          ZWIFT_USERNAME=${zwiftUsername}
          ZWIFT_PASSWORD=${zwiftPassword}
          ZWIFT_WOKROUT_DIR=${zwiftWorkoutDir}
          ZWIFT_ACTIVITY_DIR=${zwiftActivityDir}
          ZWIFT_FG=${zwiftFg}
          ZWIFT_NO_GAMEMODE=${zwiftNoGameMode}
          WINE_EXPERIMENTAL_WAYLAND=${wineExperimentalWayland}
          NETWORKING=${networking}
          ZWIFT_UID=${zwiftUid}
          ZWIFT_GID=${zwiftGid}
          DEBUG=${debug}

          ${./zwift.sh}
        '';

        installPhase = ''
          install -Dm755 ${nixosRun} -T $out/bin/${pname}
        '';

        desktopItems = [ "${src}/assets/Zwift.desktop" ];
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
              containerTool = lib.mkOption { type = lib.types.string; default = ""; };
              zwiftUsername = lib.mkOption { type = lib.types.string; default = ""; };
              zwiftPassword = lib.mkOption { type = lib.types.string; default = ""; };
              zwiftWorkoutDir = lib.mkOption { type = lib.types.string; default = ""; };
              zwiftActivityDir = lib.mkOption { type = lib.types.string; default = ""; };
              zwiftFg = lib.mkOption { type = lib.types.bool; default = false; };
              zwiftNoGameMode = lib.mkOption { type = lib.types.bool; default = false; };
              wineExperimentalWayland = lib.mkOption { type = lib.types.bool; default = false; };
              networking = lib.mkOption { type = lib.types.string; default = ""; };
              zwiftUid = lib.mkOption { type = lib.types.string; default = ""; };
              zwiftGid = lib.mkOption { type = lib.types.string; default = ""; };
              debug = lib.mkOption { type = lib.types.bool; default = ""; };
            };

            config = lib.mkIf config.programs.zwift.enable {
              virtualisation.podman.enable = true;
              environment = {
                systemPackages = with config.programs.zwift; [(wrapPackage {
                  inherit image containerTool zwiftUsername zwiftPassword zwiftWorkoutDir zwiftActivityDir networking zwiftUid zwiftGid;
                  tag = version;
                  dontCheck = if dontCheck then "1" else "" ;
                  dontPull = if dontPull then "1" else "";
                  zwiftFg = if zwiftFg then "1" else "";
                  zwiftNoGameMode = if zwiftNoGameMode then "1" else "";
                  wineExperimentalWayland = if wineNoExperimentalGameMode then "1" else "";
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
