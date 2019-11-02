{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.custom.system;
  systemctl-status = pkgs.writeScriptBin "systemctl-status" ''
    if [ $# -le 1 ]; then
        echo -e ""
    else
        if [[ $# == 2 ]]; then
            if [[ $2 =~ ^\[ ]]; then
                STATUS=`${pkgs.systemd}/bin/systemctl status $1 | ${pkgs.gawk}/bin/awk 'NR==3 {print $2}'`
            else
                echo -e ""
            fi
        elif [[ $# == 3 ]]; then
            STATUS=`${pkgs.systemd}/bin/systemctl --user status $1 | ${pkgs.gawk}/bin/awk 'NR==3 {print $2}'`
        fi
        if [ $STATUS == "inactive" ]
        then
            echo -e ""
        else
            if [ -z "$2" ]
            then
                echo -e "[*]"
            else
                echo -e $2
            fi
        fi
    fi
  '';
  wifi-status = pkgs.writeScriptBin "wifi-status" ''
    ESSID=`${pkgs.wirelesstools}/bin/iwgetid -r`
    STRENGTH=$((`awk 'NR==3 {print substr($3, 1, length($3)-1)}' /proc/net/wireless`*100/70))
    QUALITY_COLOR=
    case 1 in
        $((STRENGTH < 30)))
            QUALITY_COLOR=red
            ;;
        $((STRENGTH >= 30 && STRENGTH < 70)))
            QUALITY_COLOR=yellow
            ;;
        $((STRENGTH >= 70 && STRENGTH <= 100)))
            QUALITY_COLOR=green
            ;;
    esac
    echo $ESSID: "<fc=$QUALITY_COLOR>$STRENGTH</fc>%"
  '';
  uptime_info = pkgs.writeScriptBin "uptime_info" ''
    ${pkgs.dunst}/bin/dunstify -t 7000 "Uptime: $(${pkgs.procps}/bin/w | \
    ${pkgs.gnused}/bin/sed -r '1 s/.*up *(.*),.*user.*/\1/g;q')"
  '';
  services_journals = pkgs.writeScriptBin "services_journals" ''
    #! /usr/bin/env nix-shell
    #! nix-shell -i python3 -p python3 python3Packages.dmenu-python

    import os
    import subprocess
    import sys

    import dmenu

    services = []

    system_units_task = subprocess.Popen("systemctl list-unit-files", shell=True, stdout=subprocess.PIPE)
    services.extend(["{0} [system]".format(unit.split()[0].split(".")[0])
                     for unit in system_units_task.stdout.read().decode().split("\n")[1:-3]
                     if unit.split()[0].endswith("service")])
    assert system_units_task.wait() == 0

    user_units_task = subprocess.Popen("systemctl --user list-unit-files", shell=True, stdout=subprocess.PIPE)
    services.extend(["{0} [user]".format(unit.split()[0].split(".")[0])
                     for unit in user_units_task.stdout.read().decode().split("\n")[1:-3]
                     if unit.split()[0].endswith("service")])
    assert system_units_task.wait() == 0

    journal = dmenu.show(sorted(list(dict.fromkeys(services))), prompt='journal for', lines=30)
    if not journal:
        sys.exit(1)
    os.system('tmux new-window "journalctl {0}-u {1}"'.format("--user " if "user" in journal else "", journal.split()[0]))
  '';
in {
  options = {
    custom.system = {
      graphics.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable graphics-related tools.";
      };
      hardware.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable structured JSON manipulation tools.";
      };
      forensics.enable = mkOption {
        type = types.bool;
        default = false;
        description = ''Whether to enable various "system forensics" tools.'';
      };
      monitoring.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable monitoring/notification tools.";
      };
      powersave.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable powersaving.";
      };
      powersave.notifications.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable notifications on low battery level.";
      };
      powersave.notifications.battery = mkOption {
        type = types.str;
        default = "BAT0";
        description = ''
          Battery to monitor.
        '';
      };
      powersave.notifications.notifyAfter = mkOption {
        type = types.int;
        default = 10;
        description = ''
          Battery level after which notifications should be sent.
        '';
      };
      powersave.notifications.suspendAfter = mkOption {
        type = types.int;
        default = 5;
        description = ''
          Battery level after which a suspend should be performed.
        '';
      };
      powersave.notifications.suspendTimeout = mkOption {
        type = types.str;
        default = "60s";
        description = ''
          How much to wait before suspending.
        '';
      };
      powersave.notifications.suspendCommand = mkOption {
        type = types.str;
        default = "systemctl suspend";
        description = ''
          Command to issue on suspend.
        '';
      };
      powersave.rules = mkOption {
        type = types.attrs;
        default = {
          Chromium = {
            suspendDelay = 10;
            matchWmClassContains = "Chromium-browser";
            suspendSubtreePattern = "chromium";
          };
          Firefox = {
            suspendDelay = 10;
            matchWmClassContains = "Firefox";
            suspendSubtreePattern = "firefox";
          };
        };
        description = "Apps suspending rules.";
      };
      scripts.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable custom scripts.";
      };
      xmonad.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable XMonad keybindings.";
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.graphics.enable {
      home-manager.users."${config.attributes.mainUser.name}" = {
        home.packages = with pkgs; [
          drm_info
          xtruss
        ];
      };
    })
    (mkIf cfg.hardware.enable {
      home-manager.users."${config.attributes.mainUser.name}" = {
        home.packages = with pkgs; [
          acpitool
          dmidecode
          iw
          lshw
          pciutils
          usbutils
          # wirelesstools
        ];
        services.udiskie = {
          enable = true;
          automount = true;
          notify = true;
          tray = "never";
        };
      };
    })
    (mkIf cfg.forensics.enable {
      home-manager.users."${config.attributes.mainUser.name}" = {
        home.packages = with pkgs; [
          extrace
          libwhich
          lsof
          ltrace
          strace
        ];
      };
    })
    (mkIf cfg.monitoring.enable {
      home-manager.users."${config.attributes.mainUser.name}" = {
        home.packages = with pkgs; [
          gotop
          iotop
          nmon
          pagemon
          procs
        ];
        programs.htop = {
          enable = true;
          fields = [
            "USER"
            "PRIORITY"
            "NICE"
            "M_SIZE"
            "STATE"
            "PERCENT_CPU"
            "PERCENT_MEM"
            "TIME"
            "COMM"
          ];
          meters.left = [ "AllCPUs" "Memory" ];
          colorScheme = 0;
          detailedCpuTime = true;
        };
        services.dunst = { # TODO: consider extracting options
          enable = true;
          settings = {
            global = {
              alignment = "left";
              always_run_script = "true";
              bounce_freq = 0;
              browser = "${pkgs.firefox-unwrapped}/bin/firefox -new-tab";
              dmenu = "${pkgs.dmenu}/bin/dmenu -p dunst:";
              ellipsize = "middle";
              follow = "keyboard";
              force_xinerama = "false";
              format = "<span foreground='#F3F4F5'><b>%s %p</b></span>\\n%b";
              frame_color = "#232323";
              frame_width = 3;
              geometry = "0x5-15+15";
              hide_duplicates_count = "false";
              history_length = 20;
              horizontal_padding = 10;
              icon_position = "left";
              idle_threshold = 120;
              ignore_newline = "no";
              indicate_hidden = "yes";
              line_height = 0;
              markup = "full";
              max_icon_size = 32;
              monitor = 0;
              notification_height = 0;
              padding = 10;
              separator_color = "frame";
              separator_height = 2;
              show_age_threshold = 60;
              show_indicators = "yes";
              shrink = "no";
              sort = "yes";
              stack_duplicates = "true";
              startup_notification = "false";
              sticky_history = "yes";
              transparency = 0;
              verbosity = "mesg";
              word_wrap = "yes";
            };
            shortcuts = {
              close = "ctrl+space";
              close_all = "ctrl+shift+space";
              history = "ctrl+grave";
              context = "ctrl+shift+period";
            };
            urgency_low = {
              background = "#232323";
              foreground = "#A8A8A8";
              timeout = 3;
            };
            urgency_normal = {
              background = "#285577";
              foreground = "#ffffff";
              timeout = 5;
            };
            urgency_critical = {
              background = "#D64E4E";
              foreground = "#F0E0E0";
              frame_color = "#D64E4E";
              timeout = 7;
            };
          };
        };
      };
    })
    (mkIf cfg.scripts.enable {
      environment.systemPackages = with pkgs; [
        services_journals
        wifi-status
      ];
    })
    (mkIf cfg.xmonad.enable {
      wm.xmonad.keybindings = {
        "M-C-j" = ''spawn "${services_journals}/bin/services_journals" >> showWSOnProperScreen "shell"'';
        "M-S-u" = ''spawn "${uptime_info}/bin/uptime_info"'';
      };
    })
    (mkIf cfg.powersave.enable {
      home-manager.users."${config.attributes.mainUser.name}" = {
        services.xsuspender = {
          enable = true;
          defaults = {
            suspendDelay = 10;
            onlyOnBattery = false;
          };
          rules = cfg.powersave.rules;
        };
      };
    })
    (mkIf (cfg.xmonad.enable && cfg.powersave.enable) {
      wm.xmonad.keybindings = {
        "M-s x <Up>" = ''spawn "${pkgs.systemd}/bin/systemctl --user restart xsuspender.service"'';
        "M-s x <Down>" = ''spawn "${pkgs.systemd}/bin/systemctl --user stop xsuspender.service"'';
      };
    })
    (mkIf (cfg.powersave.enable && cfg.powersave.notifications.enable) {
      systemd.user.timers."lowbatt" = {
        description = "check battery level";
        timerConfig.OnBootSec = "1m";
        timerConfig.OnUnitInactiveSec = "1m";
        timerConfig.Unit = "lowbatt.service";
        wantedBy = [ "timers.target" ];
      };
      systemd.user.services."lowbatt" = {
        description = "battery level notifier";
        serviceConfig.PassEnvironment = "DISPLAY";
        script = ''
          export battery_capacity=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${cfg.powersave.notifications.battery}/capacity)
          export battery_status=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${cfg.powersave.notifications.battery}/status)
          if [[ $battery_capacity -le ${builtins.toString cfg.powersave.notifications.notifyAfter} && $battery_status = "Discharging" ]]; then
              ${pkgs.dunst}/bin/dunstify -u critical "Battery low, consider plugging in."
          fi

          if [[ $battery_capacity -le ${builtins.toString cfg.powersave.notifications.suspendAfter} && $battery_status = "Discharging" ]]; then
              ${pkgs.dunst}/bin/dunstify -u critical -t 5000 Battery CRITICALLY low, will suspend in ${cfg.powersave.notifications.suspendTimeout}."
              sleep ${cfg.powersave.notifications.suspendTimeout}

              battery_status=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${cfg.powersave.notifications.battery}/status)
              if [[ $battery_status = "Discharging" ]]; then
                  ${cfg.powersave.notifications.suspendCommand}
              fi
          fi
        '';
      };
    })
  ];
}