{
  description = "Easily Zwift on Linux (Native)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      fenix,
      naersk,
      self,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Build the runfromprocess Windows executable
      runfromprocess = import ./nix/runfromprocess.nix {
        inherit pkgs;
        fenix = fenix.packages.${system};
        naersk = naersk.lib.${system};
      };

      # Build the wrapper scripts package
      zwift-scripts = import ./nix/zwift-package.nix {
        inherit pkgs;
        zwift-fhs = null; # Not needed for scripts package
      };

      # Build the FHS environment with all dependencies
      zwift-fhs = import ./nix/zwift-fhs.nix {
        inherit pkgs runfromprocess zwift-scripts;
      };

      # Final Zwift package that wraps everything
      zwift = import ./nix/zwift-native-package.nix {
        inherit pkgs zwift-fhs;
        zwift-icon = ./bin/Zwift.svg;
      };

      # Container-based package with all defaults (for nix run .#zwift-container)
      zwift-container = import ./nix/zwift-container-package.nix {
        inherit pkgs;
        zwift-sh = ./src/zwift.sh;
        zwift-icon = ./bin/Zwift.svg;
      };

      # NixOS modules
      nixosModule = import ./nix/module.nix { zwift-package = zwift; };
      nixosModuleContainer = import ./nix/module-container.nix {
        zwift-sh = ./src/zwift.sh;
        zwift-icon = ./bin/Zwift.svg;
      };
    in
    {
      # NixOS modules
      nixosModules = {
        zwift = nixosModule;
        zwift-container = nixosModuleContainer;
        default = nixosModule;
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

          # Docker (for legacy container approach)
          hadolint

          # Markdown
          nodePackages.markdownlint-cli2
          nodePackages.cspell

          # Documentation (Jekyll)
          ruby
          bundler

          # GitHub
          gh
          actionlint

          # YAML
          yamllint

          # Utilities
          curl
          jq

          # Rust (for runfromprocess development)
          rustc
          cargo
        ];
      };

      # Packages
      packages.${system} = {
        inherit runfromprocess zwift-fhs zwift zwift-scripts zwift-container;
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
