let
  deps = import ../../nix/sources.nix;
  nixpkgs-pinned-02_08_19  = import deps.nixpkgs-pinned-02_08_19 { config.allowUnfree = true; };
  nixpkgs-pinned-05_12_19  = import deps.nixpkgs-pinned-05_12_19 { config.allowUnfree = true; };
in
{ config, lib, pkgs, ... }:
with import ../util.nix { inherit config lib pkgs; };
with lib;

let
  cfg = config.tools.dbms;
  dbms = writePythonScriptWithPythonPackages "dbms" [
    pkgs.python3Packages.dmenu-python
    pkgs.python3Packages.redis
  ] ''
    import json
    import os
    import subprocess

    import dmenu
    import redis


    r = redis.Redis(host='localhost', port=6379, db=0)
    dbms_meta = json.loads(r.get("job/dbms_meta"))

    dbms_entry = dmenu.show(dbms_meta.keys(), lines=5)
    if dbms_entry:
        dbms_pass_task = subprocess.Popen("${pkgs.pass}/bin/pass {0}".format(dbms_meta[dbms_entry]["passwordPassPath"]),
                                          shell=True, stdout=subprocess.PIPE)
        dbms_pass = dbms_pass_task.stdout.read().decode().split("\n")[0]
        assert dbms_pass_task.wait() == 0

        if dbms_meta[dbms_entry]["command"] == "mycli":
            os.system('${pkgs.tmux}/bin/tmux new-window "${nixpkgs-pinned-05_12_19.mycli}/bin/mycli --host {0} --user {1} --password {2}"'.format(
                dbms_meta[dbms_entry]["ip"],
                dbms_meta[dbms_entry]["user"],
                dbms_pass
            ))
        elif dbms_meta[dbms_entry]["command"] == "mycli":
            os.system('${pkgs.tmux}/bin/tmux new-window "PGPASSWORD={2} ${nixpkgs-pinned-05_12_19.pgcli}/bin/pgcli --host {0} --user {1}"'.format(
                dbms_meta[dbms_entry]["ip"],
                dbms_meta[dbms_entry]["user"],
                dbms_pass
            ))
  '';
in {
  options = {
    tools.dbms = {
      postgresql.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable PostgreSQL helper tools.";
      };
      mysql.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable MySQL helper tools.";
      };
      sqlite.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable Sqlite helper tools.";
      };
      misc.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable misc helper tools.";
      };
      jobDbms.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable job dbms connectivity.";
      };
      xmonad.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable XMonad keybindings.";
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.postgresql.enable {
      home-manager.users."${config.attributes.mainUser.name}" = {
        home.packages = with pkgs; [
          pgcenter
          nixpkgs-pinned-05_12_19.pgcli
        ];
      };
    })
    (mkIf cfg.mysql.enable {
      home-manager.users."${config.attributes.mainUser.name}" = {
        home.packages = with pkgs; [
            nixpkgs-pinned-05_12_19.mycli
        ];
      };
    })
    (mkIf cfg.sqlite.enable {
      home-manager.users."${config.attributes.mainUser.name}" = {
        home.packages = with pkgs; [
          sqlitebrowser
          nixpkgs-pinned-02_08_19.litecli # TODO: shell automation: skim for selecting db file, you get the idea
        ];
      };
    })
    (mkIf cfg.misc.enable {
      home-manager.users."${config.attributes.mainUser.name}" = {
        home.packages = with pkgs; [
          nixpkgs-pinned-05_12_19.nodePackages.elasticdump
        ];
      };
    })
    (mkIf (cfg.jobDbms.enable && cfg.xmonad.enable) {
      custom.dev.metadataCacheInstructions = ''
        ${pkgs.redis}/bin/redis-cli set job/dbms_meta ${lib.strings.escapeNixString (builtins.toJSON config.secrets.job.infra.dbmsMeta)}
      '';
      wm.xmonad.keybindings = {
        "M-C-y" = ''spawn "${dbms}/bin/dbms" >> showWSOnProperScreen "shell"'';
      };
    })
  ];
}
