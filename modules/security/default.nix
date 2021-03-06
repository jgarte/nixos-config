{ config, inputs, lib, pkgs, ... }:
with import ../util.nix { inherit config inputs lib pkgs; };
with lib;

let
  cfg = config.custom.security;
  user = config.attributes.mainUser.name;
  nurpkgs = pkgs.unstable.nur.repos.wiedzmin;
in {
  options = {
    custom.security = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable security tools.";
      };
      pinentryFlavor = mkOption {
        type = types.enum pkgs.pinentry.flavors;
        example = "gnome3";
        description = "Pinentry flavor to use.";
      };
      polkit.silentAuth = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to allow special users to do some things without authentication.";
      };
      passwordStorePath = mkOption {
        description = "Default path to Pass password store";
        type = types.str;
        default = homePrefix ".password-store";
      };
      lockScreenCommand = mkOption {
        description = "Command to use for screen locking";
        type = types.str;
        default = "${pkgs.i3lock-color}/bin/i3lock-color -c 232729 && ${pkgs.xorg.xset}/bin/xset dpms force off";
      };
      emacs.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable Emacs security-related setup.";
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
      assertions = [{
        assertion = cfg.pinentryFlavor != null;
        message = "security: Must select exactly one pinentry flavor.";
      }];

      security.wrappers.sudo = {
        source = "${pkgs.sudo}/bin/sudo";
        owner = "root";
        permissions = "u+s";
      };

      nixpkgs.config.packageOverrides = _: rec {
        passctl = mkPythonScriptWithDeps "passctl"
          (with pkgs; [ nurpkgs.pyfzf nurpkgs.pystdlib python3Packages.pygit2 python3Packages.redis xdotool ])
          (readSubstituted ../subst.nix ./scripts/passctl.py);
      };

      home-manager.users.${user} = {
        home.packages = with pkgs; [ paperkey ];
        programs.password-store = {
          enable = true;
          package = pkgs.pass.withExtensions (ext: with ext; [ pass-audit pass-checkup pass-import pass-update ]);
          settings = {
            PASSWORD_STORE_CLIP_TIME = "60";
            PASSWORD_STORE_DIR = cfg.passwordStorePath;
          };
        };
        programs.gpg = {
          enable = true;
          settings = {
            keyserver = "hkp://keys.openpgp.org";
            require-cross-certification = true;
            use-agent = true;
          };
        };
        services.gpg-agent = {
          enable = true;
          defaultCacheTtl = 34560000;
          defaultCacheTtlSsh = 34560000;
          maxCacheTtl = 34560000;
          enableSshSupport = true;
          enableExtraSocket = true;
          extraConfig = ''
            allow-emacs-pinentry
            no-allow-loopback-pinentry
          '';
          pinentryFlavor = cfg.pinentryFlavor;
        };
      };
    })
    (mkIf (cfg.enable && cfg.emacs.enable) {
      ide.emacs.extraPackages = epkgs: [ epkgs.auth-source-pass epkgs.ivy-pass epkgs.pass ];
      ide.emacs.config = readSubstituted ../subst.nix ./emacs/security.el;
    })
    (mkIf (cfg.polkit.silentAuth) {
      security.polkit.extraConfig = ''
        /* Allow users in wheel group to manage systemd units without authentication */
        polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
                subject.isInGroup("wheel")) {
                return polkit.Result.YES;
            }
        });

        /* Allow users in wheel group to run programs with pkexec without authentication */
        polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.policykit.exec" &&
                subject.isInGroup("wheel")) {
                return polkit.Result.YES;
            }
        });
      '';
    })
    (mkIf (cfg.enable && cfg.wm.enable) {
      wmCommon.keys = [
        {
          key = [ "XF86ScreenSaver" ];
          cmd = "${cfg.lockScreenCommand}";
          mode = "root";
        }
        {
          key = [ "p" ];
          cmd = "${pkgs.passctl}/bin/passctl";
          mode = "select";
        }
      ];
    })
    (mkIf (cfg.enable && config.attributes.debug.scripts) {
      home-manager.users.${user} = { home.packages = with pkgs; [ passctl ]; };
    })
  ];
}
