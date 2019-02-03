{ config, pkgs, ... }:
{
    imports = [
        ../private/traits/sys.nix
        ../../../toolbox/wm/xmonad.nix
        ../../../toolbox/scripts/misc.nix
    ];
    services = {
        xserver = {
            enable = true;
            videoDrivers = [ "modesetting" "intel" ];
            desktopManager = {
                xterm.enable = false;
                gnome3.enable = true;
                default = "none";
            };
            displayManager = {
                lightdm.enable = true;
                gdm.enable = false;
                # TODO: think of migrating to home-manager "xsession" module (beware that it is more versatile)
                sessionCommands = ''
                    ${pkgs.xlibs.xmodmap}/bin/xmodmap /etc/Xmodmaprc
                    ${pkgs.xlibs.xmodmap}/bin/xmodmap -e "clear Lock"

                    export CURRENT_WM=${config.services.xserver.windowManager.default}
                    export TZ="${config.time.timeZone}"

                    ${pkgs.wmname}/bin/wmname LG3D

                    ${pkgs.xorg.xrdb}/bin/xrdb -merge $HOME/.Xresources

                    ${pkgs.xpointerbarrier}/bin/xpointerbarrier 20 0 0 0 &

                    ${pkgs.xidlehook}/bin/xidlehook --not-when-audio --not-when-fullscreen\
                          --timer normal 150 '${pkgs.dunst}/bin/dunstify -t 7000 -u critical "Locking in 30 seconds"' ''' \
                          --timer primary 30 '${pkgs.lockscreen}/bin/lockscreen' ''' &
                '';
            };
            xkbOptions = "caps:none";
            layout = "us,ru";
            libinput = {
                enable = true;
                naturalScrolling = true;
                disableWhileTyping = true;
                tapping = false;
                tappingDragLock = false;
                accelSpeed = "0.6";
            };
        };
        redshift = {
            enable = true;
            latitude = "${config.sys.redshift.latitude}";
            longitude = "${config.sys.redshift.longitude}";
            temperature.day = 5500;
            temperature.night = 3700;
        };
        # arbtt.enable = true; # FIXME: construct overlay
        autorandr = {
            enable = true;
            defaultTarget = "mobile";
        };
        compton = {
            enable = true;
            backend = "glx";
            vSync = "opengl-swc";
            opacityRules = [];
            package = pkgs.compton-git;
            extraOptions = ''
                inactive-dim 0.3
                focus-exclude '_NET_WM_NAME@:s = "rofi"'
            '';
        };
    };
    programs.light.enable = true;

    environment.systemPackages = with pkgs; [
        ckbcomp
        gmrun
        xlibs.xev
        xlibs.xprop
        xorg.xhost
        xorg.xmessage
    ];
    fonts = {
        fontconfig = {
            enable = true;
            useEmbeddedBitmaps = true;
        };
        enableFontDir = true;
        enableGhostscriptFonts = true;
        fonts = with pkgs; [
            anonymousPro
            corefonts
            dejavu_fonts
            dosemu_fonts
            emacs-all-the-icons-fonts
            fantasque-sans-mono
            fira-code
            fira-mono
            font-awesome-ttf
            go-font
            hack-font
            inconsolata
            iosevka
            mononoki
            noto-fonts
            noto-fonts-emoji
            powerline-fonts
            profont
            roboto-mono
            source-code-pro
            terminus_font
            terminus_font_ttf
            unifont
        ];
    };
}
