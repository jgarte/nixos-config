{ config, pkgs, lib, ... }:

{
    imports = [
        ../pkgs/setup.nix
        ../partitions/x230-laptoptop.nix
        ../hardware/bluetooth.nix
        ../hardware/intel.nix
        ../hardware/laptop.nix
        ../hardware/misc.nix
        ../hardware/sound.nix
        ../services/xserver.nix
        ../users/alex3rd/default.nix
        ../users/root.nix
        <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

    boot.loader.grub = {
        enable = true;
        version = 2;
        device = "/dev/sda";
        configurationLimit = 10;
    };
    boot.plymouth.enable = true;

    services = {
        irqbalance.enable = true;
        mpd.enable = true;
        chrony.enable = true;
        psd = {
            enable = true;
            resyncTimer = "30min";
        };
        openssh = {
            enable = true;
            forwardX11 = true;
        };
    };

    security.sudo.wheelNeedsPassword = false;

    security.polkit.extraConfig = ''
        /* Allow users in wheel group to manage systemd units without authentication */
        polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
                subject.isInGroup("wheel")) {
                return polkit.Result.YES;
            }
        });
    '';

    i18n = {
        consoleFont = "Lat2-Terminus16";
        defaultLocale = "ru_RU.UTF-8";
        consoleUseXkbConfig = true;
        inputMethod = {
            enabled = "ibus";
            ibus.engines = with pkgs.ibus-engines; [
                table
                table-others # for LaTeX input
                m17n
            ];
        };
    };

    time.timeZone = "Europe/Moscow";

    services.printing = {
        enable = true;
        drivers = [ pkgs.hplip ];
    };

    # scanner
    nixpkgs.config = {
        sane.snapscanFirmware = "/etc/nixos/contrib/blobs/Esfw52.bin";
    };

    hardware.sane = {
        enable = true;
        # extraBackends = [ pkgs.epkowa ];
    };

    nixpkgs.config.allowUnfree = true;

    networking = {
        hostName = "x230";
        hostId = "2ab69157";
        firewall.enable = false;
        usePredictableInterfaceNames = true;
        wlanInterfaces = {
            "wlan0" = { device = "wlp3s0"; };
        };
        networkmanager = {
            enable = true;
            unmanaged = [ "interface-name:ve-*" ];
        };
    };

    system.stateVersion = "18.03";
}
