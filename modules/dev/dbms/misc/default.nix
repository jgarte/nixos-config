{ config, inputs, lib, pkgs, ... }:
with import ../../../util.nix { inherit config inputs lib pkgs; };
with lib;

let
  cfg = config.dbms.misc;
  user = config.attributes.mainUser.name;
  nurpkgs = pkgs.unstable.nur.repos.wiedzmin;
in {
  options = {
    dbms.misc = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable misc helper DBMS tools.";
      };
      controlCenter.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable various DBMS instances access point.";
      };
      controlCenter.meta = mkOption {
        type = types.attrsOf types.attrs;
        default = { };
        description = "Various dbms access metadata.";
      };
      wm.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable WM keybindings.";
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home-manager.users.${user} = { home.packages = with pkgs; [ nodePackages.elasticdump ]; };
    })
    (mkIf (cfg.enable && cfg.controlCenter.enable) {
      nixpkgs.config.packageOverrides = _: rec {
        dbms = mkPythonScriptWithDeps "dbms" (with pkgs; [ pass nurpkgs.pystdlib python3Packages.redis tmux vpnctl ])
          (readSubstituted ../../../subst.nix ./scripts/dbms.py);
      };

      custom.housekeeping.metadataCacheInstructions = ''
        ${pkgs.redis}/bin/redis-cli set misc/dbms_meta ${lib.strings.escapeNixString
          (builtins.toJSON cfg.controlCenter.meta)}
      '';

      home-manager.users.${user} = { home.packages = with pkgs; [ dbms ]; };
    })
    (mkIf (cfg.enable && cfg.wm.enable) {
      wmCommon.keys = [{
        key = [ "d" ];
        cmd = "${pkgs.dbms}/bin/dbms";
        mode = "dev";
        desktop = "shell";
      }];
    })
    (mkIf (config.attributes.debug.scripts) { home-manager.users.${user} = { home.packages = with pkgs; [ dbms ]; }; })
  ];
}
