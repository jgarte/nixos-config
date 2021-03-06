{ config, inputs, lib, pkgs, ... }:
with import ../../util.nix { inherit config inputs lib pkgs; };
with lib;

let
  cfg = config.content.screenshots;
  user = config.attributes.mainUser.name;
  prefix = config.wmCommon.prefix;
in {
  options = {
    content.screenshots = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable screenshots management.";
      };
      baseDir = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Screenshots base directory";
      };
      ordering.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable screenshots ordering.";
      };
      ordering.timespec = mkOption {
        type = types.str;
        default = "";
        description = "Timestamp of service activation (in systemd format).";
      };
      wm.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable WM keybindings.";
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      assertions = [{
        assertion = cfg.baseDir != null;
        message = "Must provide path to screenshots dir.";
      }];

      home-manager.users.${user} = let
        flameshot_config_text = lib.generators.toINI { } {
          General = {
            disabledTrayIcon = true;
            drawColor = "#ff0000";
            drawThickness = 0;
            filenamePattern = "screenshot-${config.custom.housekeeping.dateFormats.flameshot}";
            saveAfterCopyPath = cfg.baseDir;
            savePath = cfg.baseDir;
          };
        };
      in {
        home.packages = with pkgs; [ flameshot ];
        xdg.configFile."flameshot.ini".text = flameshot_config_text;
        xdg.configFile."flameshot/flameshot.ini".text = flameshot_config_text;
      };
      wmCommon.autostart.entries = [ "flameshot" ];
    })
    (mkIf (cfg.enable && cfg.ordering.enable) {
      nixpkgs.config.packageOverrides = _: rec {
        order_screenshots = mkShellScriptWithDeps "order_screenshots" (with pkgs; [ coreutils ])
          (readSubstituted ../../subst.nix ./scripts/order_screenshots.sh);
      };

      systemd.user.services."order-screenshots" = {
        description = "Screenshots ordering";
        wantedBy = [ "graphical.target" ];
        partOf = [ "graphical.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.order_screenshots}/bin/order_screenshots";
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };
      systemd.user.timers."order-screenshots" =
        renderTimer "Screenshots ordering" "" "" cfg.ordering.timespec;
    })
    (mkIf (cfg.enable && cfg.wm.enable) {
      wmCommon.keys = [
        {
          key = [ "Print" ];
          cmd = "${pkgs.flameshot}/bin/flameshot screen --path ${cfg.baseDir}";
          mode = "root";
        }
        {
          key = [ "Control" "Print" ];
          cmd = "${pkgs.flameshot}/bin/flameshot full --path ${cfg.baseDir}";
          mode = "root";
        }
        {
          key = [ prefix "Print" ];
          cmd = "${pkgs.flameshot}/bin/flameshot gui";
          mode = "root";
        }
      ];
    })
  ];
}
