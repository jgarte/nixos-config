{ config, inputs, lib, pkgs, ... }:
with import ../util.nix { inherit config inputs lib pkgs; };
with lib;

let
  cfg = config.custom.housekeeping;
  user = config.attributes.mainUser.name;
  nurpkgs = pkgs.unstable.nur.repos.wiedzmin;
  prefix = config.wmCommon.prefix;
in {
  options = {
    custom.housekeeping = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable automated 'housekeeping'.";
      };
      cleanTrash.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable trash cleaning.";
      };
      cleanTrash.emptyInterval = mkOption {
        type = types.int;
        default = 7;
        description = "Days to keep trash.";
      };
      cleanTrash.calendarTimespec = mkOption {
        type = types.str;
        default = "";
        description = "Timestamp of service activation (in systemd format).";
      };
      healthChecking.enable = mkOption { # periodically checking systemd services journals for errors
        type = types.bool;
        default = false;
        description = "Whether to enable systemd service healthchecking.";
      };
      purgeExpired.enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable $HOME/.cache and $HOME/.config
          temporary files cleaning.
        '';
      };
      purgeExpired.cacheDepth = mkOption {
        type = types.str;
        default = "";
        example = "7d";
        description = "Time delta to consider cache files being older expired.";
      };
      purgeExpired.tempDepth = mkOption {
        type = types.str;
        default = "";
        example = "30d";
        description = "Time delta to consider temporary files being older expired.";
      };
      purgeExpired.calendarTimespec = mkOption {
        type = types.str;
        default = "";
        description = "Timestamp of service activation (in systemd format).";
      };
      fsDeduplication.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable FS deduplication tools.";
      };
      metadataCacheInstructions = mkOption {
        type = types.lines;
        default = "";
        description = "Set of commands needed to initialize system-wide data cache.";
      };
      dateFormats = mkOption {
        type = types.attrsOf types.str;
        default = {
          commonShell = "+%Y-%m-%d_%H:%M:%S";
          commonShellNoColons = "+%Y-%m-%d_%H-%M-%S";
          flameshot = "%Y-%m-%d_%H-%M-%S";
        };
        visible = false;
        readOnly = true;
        internal = true;
        description = "Date suffix formats fo various needs";
      };
      regex.url.py = mkOption { # TODO: make something like dateFormats above
        description = "Common URL regular expression, Python format";
        type = types.str;
        default = "(https?|ftp|file)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]*[-A-Za-z0-9+&@#/%=~_|]";
      };
      wm.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable WM keybindings.";
      };
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable) {
      services.redis.enable = true; # for various caching needs

      systemd.services.redis.postStart = cfg.metadataCacheInstructions;

      nixpkgs.config.packageOverrides = _: rec {
        # FIXME: use ideas from https://github.com/mitchweaver/bin/blob/5bad2e16006d82aeeb448f7185ce665934a9c242/util/pad
        srvctl = mkPythonScriptWithDeps "srvctl" (with pkgs; [
          nurpkgs.pyfzf
          nurpkgs.pystdlib
          python3Packages.libtmux
          python3Packages.redis
          python3Packages.xlib
        ]) (readSubstituted ../subst.nix ./scripts/srvctl.py);
        uptime_info = mkPythonScriptWithDeps "uptime_info" (with pkgs; [ dunst gnused procps ])
          (readSubstituted ../subst.nix ./scripts/uptime_info.sh);
      };
      home-manager.users.${user} = {
        home.packages = with pkgs; [ nurpkgs.redis-tui ];
        services.udiskie = {
          enable = true;
          automount = true;
          notify = true;
          tray = "auto";
        };
        programs.htop = {
          enable = true;
          fields = [ "USER" "PRIORITY" "NICE" "M_SIZE" "STATE" "PERCENT_CPU" "PERCENT_MEM" "TIME" "COMM" ];
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
              dmenu = "${nurpkgs.dmenu-ng}/bin/dmenu -p dunst:";
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
            urgency_low = { timeout = 3; };
            urgency_normal = { timeout = 5; };
            urgency_critical = { timeout = 7; };
          };
        };
        home.activation.srvctl = {
          after = [ "linkGeneration" ];
          before = [ ];
          data = "DISPLAY=:0 ${pkgs.srvctl}/bin/srvctl --invalidate-cache";
        };

      };
      environment.systemPackages = with pkgs; [ srvctl ];
    })
    (mkIf (cfg.enable && cfg.cleanTrash.enable) {
      assertions = [
        {
          assertion = (cfg.cleanTrash.enable && cfg.cleanTrash.calendarTimespec != "");
          message = "housekeeping: must schedule trash cleaning once it was enabled.";
        }
        {
          assertion = (!cfg.healthChecking.enable);
          message = "housekeeping: healthchecks are not implemented yet.";
        }
      ];

      systemd.user.services."clean-trash" = {
        description = "Clean trash";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.trash-cli}/bin/trash-empty ${builtins.toString cfg.cleanTrash.emptyInterval}";
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };
      systemd.user.timers."clean-trash" = renderTimer "Clean trash" "" "" cfg.cleanTrash.calendarTimespec;
    })
    (mkIf (cfg.enable && cfg.purgeExpired.enable) {
      assertions = [{
        assertion = (cfg.purgeExpired.enable && cfg.cleanTrash.calendarTimespec != "");
        message = "housekeeping: must schedule trash cleaning once it was enabled.";
      }];

      systemd.user.services."purge-home-cache" = {
        description = "Purge homedir cache";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''
            ${pkgs.fd}/bin/fd --no-ignore \
                              --changed-before ${purgeExpired.cacheDepth} \
                              . ${homePrefix ".cache"} \
                              --exec rm -f {}
          '';
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };
      systemd.user.timers."purge-home-cache" =
        renderTimer "Purge homedir cache" "" "" cfg.purgeExpired.calendarTimespec;
      systemd.user.services."purge-temp-files" = {
        description = "Purge temporary files";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''
            ${pkgs.fd}/bin/fd --no-ignore \
                              --changed-before ${purgeExpired.tempDepth} \
                              --type f --type e \
                              . ${homePrefix ".config"} \
                              --exec ${pkgs.trash-cli}/bin/trash-put {}
          '';
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };
      systemd.user.timers."purge-temp-files" =
        renderTimer "Purge temporary files" "" "" cfg.purgeExpired.calendarTimespec;
    })
    (mkIf cfg.fsDeduplication.enable {
      home-manager.users.${user} = { home.packages = with pkgs; [ dupd jdupes rmlint fpart ]; };
    })
    (mkIf (cfg.enable && cfg.wm.enable) {
      wmCommon.keys = [
        {
          key = [ "j" ];
          cmd = "${pkgs.srvctl}/bin/srvctl";
          mode = "services";
        }
        {
          key = [ prefix "Shift" "u" ];
          cmd = "${pkgs.uptime_info}/bin/uptime_info";
          mode = "root";
        }
      ];
    })
    (mkIf (cfg.enable && config.attributes.debug.scripts) {
      home-manager.users.${user} = { home.packages = with pkgs; [ srvctl uptime_info ]; };
    })
  ];
}
