{ pkgs, ... }:

rec {
  server-wotlk = pkgs.callPackage ./server-wotlk.nix { };
  client-data-wotlk = pkgs.callPackage ./client-data-wotlk.nix { };
  default = server-wotlk;
}
