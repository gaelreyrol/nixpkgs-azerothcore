{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.azerothcore;
in {
  options = {
    services.azerothcore = {
      enable = mkEnableOption "AzerothCore service";
    };
  };

  imports = [];
  config = {};
}