# nixpkgs-azerothcore

[![.github/workflows/ci.yml](https://github.com/gaelreyrol/nixpkgs-azerothcore/actions/workflows/ci.yml/badge.svg)](https://github.com/gaelreyrol/nixpkgs-azerothcore/actions/workflows/ci.yml)

>  Automated, pre-built packages for AzerothCore for NixOS. 

This repository is mostly for fun, to learn Nix packaging and distribution.

> Flake feature is the only supported usage method.

## Flake Usage

In your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs-azerothcore.url = "github:gaelreyrol/nixpkgs-azerothcore";

    # only needed if you use as a package set:
    nixpkgs-azerothcore.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: {
    nixosConfigurations."myserver" =
    let
      system = "x86_64-linux";
    in nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [({pkgs, config, ... }: {
        config = {
          nix.settings = {
            # add binary caches
            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "nixpkgs-azerothcore.cachix.org-1:GYsuj+qDDx53K+4IO5DuGQdocNzKgxOf1aAk5GPWLes="
            ];
            substituters = [
              "https://cache.nixos.org"
              "https://nixpkgs-azerothcore.cachix.org"
            ];
          };

          # add the overlay
          nixpkgs.overlays = [ inputs.nixpkgs-azerothcore.overlay ];

          # install the main package
          environment.systemPackages = [
            pkgs.azerothcore-wotlk
          ];
        };
      })];
    };
  };
}
```

