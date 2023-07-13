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
                overlays = [
                  (self: super: {
                    ccacheWrapper = super.ccacheWrapper.override {
                      extraConfig = ''
                        export CCACHE_COMPRESS=1
                        export CCACHE_DIR="/var/cache/ccache"
                        export CCACHE_UMASK=007
                        if [ ! -d "$CCACHE_DIR" ]; then
                          echo "====="
                          echo "Directory '$CCACHE_DIR' does not exist"
                          echo "Please create it with:"
                          echo "  sudo mkdir -m0770 '$CCACHE_DIR'"
                          echo "  sudo chown root:nixbld '$CCACHE_DIR'"
                          echo "====="
                          exit 1
                        fi
                        if [ ! -w "$CCACHE_DIR" ]; then
                          echo "====="
                          echo "Directory '$CCACHE_DIR' is not accessible for user $(whoami)"
                          echo "Please verify its access permissions"
                          echo "====="
                          exit 1
                        fi
                      '';
                    };
                  })
                ];
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
            overlays = [
              self.overlays.default
            ];
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
