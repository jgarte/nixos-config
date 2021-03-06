{ config, inputs, lib, pkgs, ... }:
with import ../../../util.nix { inherit config inputs lib pkgs; };
with lib;

let
  cfg = config.dev.git.autopush;
  user = config.attributes.mainUser.name;
  nurpkgs = pkgs.unstable.nur.repos.wiedzmin;
in {
  options = {
    dev.git.autopush = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable Git VCS infrastructure.";
      };
      when = mkOption {
        type = types.str;
        default = "";
        description = "When to push updates (on calendar).";
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      assertions = [
        {
          assertion = config.dev.git.batch.enable;
          message = "git: automatic updates pushing requires batch setup to be enabled.";
        }
        {
          assertion = cfg.enable && cfg.when != "";
          message = "git: automatic updates pushing is enabled while not scheduled.";
        }
      ];

      nixpkgs.config.packageOverrides = _: rec {
        gitpush = mkPythonScriptWithDeps "gitpush"
          (with pkgs; [ nurpkgs.pyfzf nurpkgs.pystdlib python3Packages.pygit2 python3Packages.redis ])
          (readSubstituted ../../../subst.nix ./scripts/gitpush.py);
      };

      dev.git.batch.commands = {
        push = [ "${pkgs.gitpush}/bin/gitpush" ];
      };

      systemd.services."git-push-updates" = {
        description = "Push updates to registered git upstream(s)";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.mr}/bin/mr push";
          WorkingDirectory = homePrefix "";
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };
      systemd.timers."git-push-updates" =
        renderTimer "Push updates to registered git upstream(s)" "10m" "15m" cfg.pushUpdates.when;
    })
  ];
}
