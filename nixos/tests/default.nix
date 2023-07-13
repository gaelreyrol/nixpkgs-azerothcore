{ pkgs, system, ... }:

pkgs.nixosTest ({
  name = "test";

  nodes = {
    server = { config, pkgs, ... }: {

      imports = [
        ../.
      ];

      config = {
        services.azerothcore.enable = true;
      };

    };
  };

  testScript = ''
    server.start()
    server.wait_for_unit("mysql.service")
    server.wait_for_unit("azerothcore-auth.service")
    server.wait_for_unit("azerothcore-world.service")
    server.wait_for_unit("azerothcore.target")
  '';
})
