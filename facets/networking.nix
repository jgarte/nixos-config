{ config, pkgs, ... }:

{
    nixpkgs.config.firefox = {
        enableAdobeFlashDRM = true;
        enableDjvu = true;
        enableGnomeExtensions = true;
        jre = false;
        icedtea = true;
    };
    nixpkgs.config.chromium = {
        enablePepperPDF = true;
    };

    services.psd = {
        enable = true;
        resyncTimer = "30min";
    };

    services.openssh = {
        enable = true;
        forwardX11 = true;
    };

    environment.systemPackages = with pkgs; [
        # TODO: maybe split even further
        afpfs-ng
        chromium
        firefox
        iperf
        lynx
        mosh
        netcat
        nethogs
        networkmanager
        networkmanager_dmenu
        networkmanagerapplet
        qbittorrent
        rclone
        skype
        slack
        socat
        tdesktop
        tdlib
        telega-server
        telegram-cli
        w3m
        wget
        youtube-dl
    ];
}
