{ pkgs, system, ... }:

pkgs.nixosTest ({
  name = "test";

  nodes = {
    server = { config, pkgs, ... }: {

      imports = [
        ../.
      ];

      services.azerothcore.enable = true;

    };
  };

  testScript = ''
  '';
})