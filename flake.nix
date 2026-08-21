{
  description = "Easily zwift on linux";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    {
      nixpkgs,
      self,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      zwift-fhs = import ./nix/zwift-fhs-package.nix { inherit pkgs; };

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
          markdownlint-cli2
          cspell

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
      };
    };
}
