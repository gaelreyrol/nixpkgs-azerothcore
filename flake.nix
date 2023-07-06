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
    in
    {
      packages = forSystems ({ pkgs, system }: import ./pkgs { inherit pkgs; } // {
        nixos = import ./nixos/tests {
          inherit system;
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ self.overlays.default ];
          };
        };
      });

      overlays.default = final: prev: {
        azerothcore = prev.callPackage ./pkgs { };
      };

      nixosModules = {
        azerothcore = import ./nixos;
        default = self.nixosModules.azerothcore;
      };

      devShells = forSystems ({ pkgs, system }: {
        default = pkgs.mkShell {
          packages = [ pkgs.cachix pkgs.jq ];
        };
      });

      # checks = forSystems ({ pkgs, system }: {
      #   nixos = import ./nixos/tests {
      #     inherit system;
      #     pkgs = import nixpkgs {
      #       inherit system;
      #       config.allowUnfree = true;
      #       overlays = [ self.overlays.default ];
      #     };
      #   }; 
      # });
    };
}
