{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zwift.url = "path:../..";
  };

  outputs =
    {
      self,
      nixpkgs,
      zwift,
      ...
    }:
    let
      system = "x86_64-linux";

      nixosSystem = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          zwift.nixosModules.zwift
          ./configuration.nix
        ];
      };
    in
    {
      packages.${system}.default = nixosSystem.config.system.build.toplevel;
    };
}
