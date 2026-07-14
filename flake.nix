{
  description = "Easily zwift on linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    runfromprocess-rs.url = "github:quietvoid/runfromprocess-rs?rev=a3d003c07d1bd11ff93c4cac96d2c3aa5deb8471";
  };

  outputs =
    {
      nixpkgs,
      runfromprocess-rs,
      self,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      zwift-fhs = import ./nix/zwift-fhs-package.nix {
        inherit
          pkgs
          system
          runfromprocess-rs
          ;
      };

      zwift-container = import ./nix/zwift-container-package.nix { inherit pkgs; };

      nixosModule = import ./nix/module.nix { zwift-fhs-package = zwift-fhs; };
    in
    {
      nixosModules = {
        zwift = nixosModule;
        default = nixosModule;
      };

      devShells.${system}.default = pkgs.mkShell {
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

      packages.${system} = {
        inherit
          zwift-fhs
          zwift-container
          ;
        default = zwift-container;

        zwift-unwrapped = pkgs.stdenv.mkDerivation rec {
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
      };
    };
}
