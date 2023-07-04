{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }: 
  let
    forSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
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
    packages = forSystems ({ pkgs, system }: import ./packages { inherit pkgs; });

    overlays.default = final: prev: {
      azerothcore = prev.callPackage ./packages { };
    };

    nixosModules.default = import ./nixos;

    devShells = forSystems ({ pkgs, system }: {
      default = pkgs.mkShell {
        packages = [ pkgs.cachix pkgs.jq ];
      };
    });
  };
}
