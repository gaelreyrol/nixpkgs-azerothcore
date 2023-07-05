{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.azerothcore;
in {
  options = {
    services.azerothcore = {
      enable = mkEnableOption "AzerothCore service";

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Whether to open the firewall for the auth & world server ports.";
      };

      serverPackage = mkOption {
        type = types.package;
        default = pkgs.azerothcore.server-wotlk;
        description = mdDoc "The AzerothCore package to use";
      };
      clientDataPackage = {
        type = types.package;
        default = pkgs.azerothcore.client-data-wotlk;
        description = mdDoc "The AzerothCore Client Data package to use";
      };
      
      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/azerothcore";
        description = mdDoc "The data directory";
      };
      logDir = mkOption {
        type = types.path;
        default = "/var/log/azerothcore";
        description = mdDoc "The log directory";
      };
      tmpDir = mkOption {
        type = types.path;
        default = "/tmp/azerothcore";
        description = mdDoc "The tmp directory to use";
      };

      hostname = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = lib.mdDoc "The hostname to reach the server.";
      };

      database = types.submodule {
        options = {
          username = mkOption {
            type = types.str;
            default = "azerothcore";
            description = mdDoc "The MySQL database user to use for auth & world servers.";
          };
        };
      };

      auth = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 3724;
            description = lib.mdDoc "Port to listen on for the auth server.";
          };
          address = mkOption {
            type = types.str;
            default = "0.0.0.0";
            description = mdDoc "Address to listen on for the auth server.";
          };
          database = mkOption {
            type = types.str;
            default = "azerothcore-auth";
            description = "Database name for the auth server.";
          };
        };
      };

      world = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 8085;
            description = lib.mdDoc "Port to listen on for the worl server.";
          };
          address = mkOption {
            type = types.str;
            default = "0.0.0.0";
            description = mdDoc "Address to listen on for the world server.";
          };
          dataDir = mkOption {
            type = types.path;
            default = "${cfg.dataDir}/data";
          };
          database = mkOption {
            type = types.str;
            default = "azerothcore-world";
            description = "Database name for the world server.";
          };
          charactersDatabase = mkOption {
            type = types.str;
            default = "azerothcore-characters";
            description = "Characters database name for the world server.";
          };
        };
      };
    };
  };

  config = {
    users.users.azerothcore = {
      home = cfg.dataDir;
      createHome = true;
      group = "azerothcore";
      uid = config.ids.uids.azerothcore;
    };
    users.groups.azerothcore.gid = config.ids.gids.azerothcore;

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 
      cfg.auth.port
      cfg.world.port
    ];

    environment.etc = let
      mysqlSocket = "/run/mysqld/mysqld.sock";
      databaseInfo = (user: database: ".;${mysqlSocket};${user};;${database}") cfg.database.user;
      authDatabaseInfo = databaseInfo cfg.auth.database;
    in {
      "azerothcore/authserver.conf".source = pkgs.runCommand "authserver.conf" {
        preferLocalBuild = true;
        buildInputs = [ pkgs.makeWrapper ];
      } ''
        cp ${cfg.serverPackage}/etc/authserver.conf.dist $out
        substituteInPlace $out \
          --replace 'LogsDir = ""' 'LogsDir = "${cfg.logDir}"' \
          --replace 'RealmServerPort = 3724' 'RealmServerPort = "${toString cfg.auth.port}"' \
          --replace 'BindIP = "0.0.0.0"' 'BindIP = "${cfg.auth.address}"' \
          --replace 'TempDir = ""' 'TempDir = "${cfg.tmpDir}"' \
          --replace \
            'LoginDatabaseInfo = "127.0.0.1;3306;acore;acore;acore_auth"' \
            'LoginDatabaseInfo = "${authDatabaseInfo}"'

      '';
      "azerothcore/worldserver.conf".source = pkgs.runCommand "worldserver.conf" {
        preferLocalBuild = true;
        buildInputs = [ pkgs.makeWrapper ];
      } ''
        cp ${cfg.serverPackage}/etc/worldserver.conf.dist $out
        substituteInPlace $out \
          --replace 'DataDir = "."' 'LogsDir = "${cfg.world.dataDir}"' \
          --replace 'LogsDir = ""' 'LogsDir = "${cfg.logDir}"' \
          --replace 'TempDir = ""' 'TempDir = "${cfg.tmpDir}"' \
          --replace \
            'LoginDatabaseInfo = "127.0.0.1;3306;acore;acore;acore_auth"' \
            'LoginDatabaseInfo = "${authDatabaseInfo}"' \
          --replace \
            'WorldDatabaseInfo = "127.0.0.1;3306;acore;acore;acore_world"' \
            'WorldDatabaseInfo = "${databaseInfo cfg.world.database}"' \
          --replace \
            'CharacterDatabaseInfo = "127.0.0.1;3306;acore;acore;acore_characters"' \
            'CharacterDatabaseInfo = "${databaseInfo cfg.world.charactersDatabase}"' \
          --replace 'WorldServerPort = 8085' 'WorldServerPort = "${toString cfg.world.port}"' \
          --replace 'BindIP = "0.0.0.0"' 'BindIP = "${cfg.world.address}"'
      '';
      "azerothcore/dbimport.conf".source = pkgs.runCommand "dbimport.conf" {
        preferLocalBuild = true;
        buildInputs = [ pkgs.makeWrapper ];
      } ''
        cp ${cfg.serverPackage}/etc/dbimport.conf.dist $out
      '';
    };

    systemd.services.azerothcore-auth = {
      description = "AzerothCore Auth Server";
      after = [ "network-online.target" "mysql.service" ];
      serviceConfig = {
        User = "azerothcore";
        Group = "azerothcore";
        RuntimeDirectory = "azerothcore";
        WorkingDirectory = cfg.dataDir;
        Restart = "on-failure";
        ExecStart = "${cfg.serverPackage}/bin/authserver -c ${authConfigFile}";
      };
    };
    systemd.services.azerothcore-world = {
      description = "AzerothCore World Server";
      after = [ "network-online.target" "mysql.service" "azerothcore-auth.service" ];
      preStart = ''
        rm ${cfg.world.dataDir}
        ln -s ${cfg.clientDataPackage} ${cfg.world.dataDir}
      '';
      serviceConfig = {
        User = "azerothcore";
        Group = "azerothcore";
        RuntimeDirectory = "azerothcore";
        WorkingDirectory = cfg.dataDir;
        Restart = "on-failure";
        ExecStart = "${cfg.serverPackage}/bin/worldserver -c ${worldConfigFile}";
      };
    };

    systemd.targets.azerothcore = rec {
      description = "AzerothCore";
      wantedBy = [ "multi-user.target" ];
      wants = [ "azerothcore-auth.service" "azerothcore-world.service" ];
      after = wants;
    };

    services.mysql = {
      enable = true;
      initialDatabases = {
        azerothcore-auth = {
          name = cfg.auth.database;
        };
        azerothcore-world = {
          name = cfg.world.database;
        };
        azerothcore-characters = {
          name = cfg.world.charactersDatabase;
        };
      };
      ensureUsers = [
        {
          name = "azerothcore";
          ensurePermissions = {
            "${cfg.auth.database}.*" = "ALL PRIVILEGES";
            "${cfg.world.database}.*" = "ALL PRIVILEGES";
            "${cfg.world.charactersDatabase}.*" = "ALL PRIVILEGES";
          };
        }
      ];
    };
  };
}