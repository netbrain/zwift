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

      zwift = import ./nix/zwift-fhs-package.nix {
        inherit
          pkgs
          system
          runfromprocess-rs
          ;
        zwift-icon = ./bin/Zwift.svg;
      };

      # Container-based package with all defaults (for nix run .#zwift-container)
      zwift-container = import ./nix/zwift-container-package.nix {
        inherit pkgs;
        zwift-sh = ./src/zwift.sh;
        zwift-icon = ./bin/Zwift.svg;
      };

      # NixOS modules
      nixosModuleFhs = import ./nix/module-fhs.nix { zwift-package = zwift; };
      nixosModuleContainer = import ./nix/module-container.nix {
        zwift-sh = ./src/zwift.sh;
        zwift-icon = ./bin/Zwift.svg;
      };
    in
    {
      nixosModules = {
        zwift-container = nixosModuleContainer;
        zwift-fhs = nixosModuleFhs;
        default = nixosModuleContainer;
      };

      # Development shell
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

      # Packages
      packages.${system} = {
        inherit
          zwift
          zwift-container
          ;
        default = zwift;

        # Legacy package for compatibility
        zwift-unwrapped = pkgs.stdenv.mkDerivation {
          pname = "zwift-unwrapped";
          version = "0-unstable";

          src = ./.;

          nativeBuildInputs = [ pkgs.copyDesktopItems ];

          installPhase = ''
            runHook preInstall
            install -Dm755 $src/src/zwift.sh -T $out/bin/zwift-unwrapped
            install -Dm644 $src/bin/Zwift.svg -T $out/share/icons/hicolor/scalable/apps/zwift.svg
            runHook postInstall
          '';

          desktopItems = [ "bin/Zwift.desktop" ];
        };
      };

      # Apps
      apps.${system} = {
        zwift = {
          type = "app";
          program = "${zwift}/bin/zwift";
        };
        zwift-container = {
          type = "app";
          program = "${zwift-container}/bin/zwift";
        };
        default = self.apps.${system}.zwift;
      };
    };
}
