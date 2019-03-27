{config, pkgs, lib, ...}:
with import ../const.nix {inherit config pkgs;};
{
    imports = [
        ../private/job.nix
        ../private/dev.nix
        ../../../toolbox/scripts/git.nix
    ];
    systemd.services."git-fetch-updates-work" = {
        description = "Fetch updates from work git repos";
        path = [ pkgs.pass pkgs.gitAndTools.pass-git-helper ];
        serviceConfig = {
            Type = "oneshot";
            User = "${userName}";
            ExecStart = "${pkgs.git-fetch-batch}/bin/git-fetch-batch ${config.job.workspacePath}";
            StandardOutput = "journal+console";
            StandardError = "inherit";
        };
    };
    systemd.timers."git-fetch-updates-work" = {
        description = "Fetch updates from work git repos";
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnBootSec = "1min";
            OnUnitActiveSec = "1hour";
        };
    };
    systemd.services."git-save-wip-work" = {
        description = "Commit WIP changes to work repos";
        path = [ pkgs.pass pkgs.gitAndTools.pass-git-helper pkgs.stgit ];
        serviceConfig = {
            Type = "oneshot";
            User = "${userName}";
            ExecStart = "${pkgs.git-save-wip-batch}/bin/git-save-wip-batch ${config.job.workspacePath}";
            StandardOutput = "journal+console";
            StandardError = "inherit";
        };
    };
    systemd.timers."git-save-wip-work" = {
        description = "Commit WIP changes to work repos";
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnBootSec = "1min";
            OnUnitActiveSec = "30min";
        };
    };
    systemd.services."git-save-wip-pets" = {
        description = "Commit WIP changes to pet projects' repos";
        path = [ pkgs.pass pkgs.gitAndTools.pass-git-helper pkgs.stgit ];
        serviceConfig = {
            Type = "oneshot";
            User = "${userName}";
            ExecStart = "${pkgs.git-save-wip-batch}/bin/git-save-wip-batch" + (lib.concatMapStrings (loc: " ${loc}") config.dev.petProjectLocations);
            StandardOutput = "journal+console";
            StandardError = "inherit";
        };
    };
    systemd.timers."git-save-wip-pets" = {
        description = "Commit WIP changes to pet projects' repos";
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnBootSec = "1min";
            OnUnitActiveSec = "30min";
        };
    };
}
