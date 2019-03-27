{ config, lib, pkgs, ... }:

{
    fileSystems."/" = {
        device = "/dev/disk/by-label/nixos-root";
        fsType = "ext4";
    };

    fileSystems."/boot" = {
        device = "/dev/disk/by-label/nixos-boot";
        fsType = "ext2";
    };

    fileSystems."${config.services.syncthing.dataDir}/bookshelf" = {
        device = "${config.users.extraUsers.alex3rd.home}/bookshelf"; # TODO: check if we could use env var or substitution here
        options = [ "bind" ];
    };

    swapDevices = [ ];
}
