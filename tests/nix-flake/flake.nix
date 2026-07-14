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

      makeSystem =
        containerTool:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            zwift.nixosModules.zwift
            {
              boot.isContainer = true;
              programs.zwift = {
                enable = true;
                inherit containerTool;
              };
            }
          ];
        };
    in
    {
      packages.${system} = {
        podman = (makeSystem "podman").config.system.build.toplevel;
        docker = (makeSystem "docker").config.system.build.toplevel;
        fhs = (makeSystem "fhs").config.system.build.toplevel;
        default = (makeSystem "podman").config.system.build.toplevel;
      };
    };
}
