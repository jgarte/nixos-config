{ config, lib, pkgs, ...}:
with import ../const.nix {inherit config pkgs;};
with lib;

let
    cfg = config.services.git-push-updates;
    pathPkgs = with pkgs; [
        pass
        gitAndTools.pass-git-helper
    ];
in {
    options = {
        services.git-push-updates = {
            enable = mkOption {
                type = types.bool;
                default = false;
                example = true;
                description = ''
                    Whether to enable fetching updates from upstream(s).
                '';
            };
            bootTimespec = mkOption {
                type = types.str;
                default = false;
                description = ''
                    Interval to activate service after system boot (in systemd format).
                '';
            };
            activeTimespec = mkOption {
                type = types.str;
                default = "";
                description = ''
                    Interval to activate service while system runs (in systemd format).
                '';
            };
            calendarTimespec = mkOption {
                type = types.str;
                default = "";
                description = ''
                    Timestamp of service activation (in systemd format).
                '';
            };
        };
    };

    config = mkIf cfg.enable {
        assertions = [
            {
                assertion = (cfg.bootTimespec == "" && cfg.activeTimespec == "" && cfg.calendarTimespec != "") ||
                            (cfg.bootTimespec != "" && cfg.activeTimespec != "" && cfg.calendarTimespec == "");
                message = "Must provide either calendarTimespec or bootTimespec/activeTimespec pair.";
            }
        ];

        systemd.services."git-push-updates" = {
            description = "Push updates to registered git upstream(s)";
            path = pathPkgs;
            serviceConfig = {
                Type = "oneshot";
                ExecStart = "${pkgs.mr}/bin/mr push";
                StandardOutput = "journal+console";
                StandardError = "inherit";
            };
        };
        systemd.timers."git-push-updates" = {
            description = "Push updates to registered git upstream(s)";
            wantedBy = [ "timers.target" ];
            timerConfig = {
                OnBootSec = cfg.bootTimespec;
                OnUnitActiveSec = cfg.activeTimespec;
                OnCalendar = cfg.calendarTimespec;
            };
        };
    };
}
