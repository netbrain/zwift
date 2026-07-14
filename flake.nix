{
  description = "Easily zwift on linux";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, self }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      zwift-container = import ./nix/zwift-container-package.nix { inherit pkgs; };

      nixosModule = import ./nix/module.nix;
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
        inherit zwift-container;
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
