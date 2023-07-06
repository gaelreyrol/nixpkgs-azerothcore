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
              config.allowUnfree = true;
            };
          }
        );
  in {
    packages = forSystems ({ pkgs, system }: import ./pkgs { inherit pkgs; });

    overlays.default = final: prev: {
      azerothcore = prev.callPackage ./pkgs { };
    };

    nixosModules.default = import ./nixos;

    devShells = forSystems ({ pkgs, system }: {
      default = pkgs.mkShell {
        packages = [ pkgs.cachix pkgs.jq ];
      };
    });
  };
}
