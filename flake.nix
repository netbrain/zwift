{
  description = "Easily zwift on linux";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, self }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      nixosModules = {
        zwift =
          { config, lib, ... }:
          {
            options.programs.zwift.enable = lib.mkEnableOption "zwift on linux";

            config = lib.mkIf config.programs.zwift.enable {
              virtualisation.podman.enable = true;
              environment.systemPackages = [ self.packages.x86_64-linux.zwift ];
            };
          };
        default = self.nixosModules.zwift;
      };

      packages.x86_64-linux = {
        zwift = pkgs.stdenv.mkDerivation rec {
          pname = "zwift";
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
