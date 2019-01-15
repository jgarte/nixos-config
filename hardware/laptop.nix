{ config, pkgs, lib, ... }:

{
    imports = [
        ../toolbox/nas/scripts.nix
    ];

    powerManagement = {
        enable = true;
        powerDownCommands = ''
            ${pkgs.force_unmount_nas}/bin/force_unmount_nas
        '';
        resumeCommands = ''
            ${pkgs.systemd}/bin/systemctl restart imapfilter.service
            ${pkgs.systemd}/bin/systemctl restart sshuttle.service
        '';
        powertop.enable = true;
    };
    services.tlp.enable = true;
    services.acpid.enable = true;
}
