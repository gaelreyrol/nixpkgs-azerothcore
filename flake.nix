{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }: 
  let
    forSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "x86_64-darwin"
      ]
        (system:
          function {
            inherit system;
            pkgs = import nixpkgs {
              inherit system;
            };
          }
        );
  in {
    packages = forSystems ({ pkgs, system }: {
      default = self.packages.${system}.azerothcore-wotlk;
      azerothcore-wotlk = pkgs.callPackage ./default.nix { };
    });

    overlays.default = final: prev: {
      azerothcore-wotlk = prev.callPackage ./default.nix { };
    };
  };
}
