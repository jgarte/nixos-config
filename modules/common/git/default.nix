let
  deps = import ../../../nix/sources.nix;
  nixpkgs-pinned-16_04_20 = import deps.nixpkgs-pinned-16_04_20 { config.allowUnfree = true; };
in { config, lib, pkgs, ... }:
with import ../../util.nix { inherit config lib pkgs; };
with lib;

let
  cfg = config.custom.dev.git;
  globalRoot = config.custom.navigation.workspaceRoots.global;
in {
  options = {
    custom.dev.git = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable Git VCS infrastructure.";
      };
      defaultMainBranchName = mkOption {
        type = types.str;
        default = "master";
        description = "Name of main branch.";
      };
      defaultUpstreamRemote = mkOption {
        type = types.str;
        default = "upstream";
        description = "Name of upstream repo remote.";
      };
      defaultOriginRemote = mkOption {
        type = types.str;
        default = "origin";
        description = "Name of origin repo remote.";
      };
      credentials.mapping = mkOption {
        type = types.attrs;
        default = { };
        description = "Mapping forges urls to pass credentials paths.";
      };
      urlSubstitutes = mkOption {
        type = types.attrsOf types.attrs;
        default = { };
        description = "Config' `insteadOf` entries mapping.";
      };
      wip.idleTime = mkOption {
        type = types.int;
        default = 3600;
        description = "Seconds of X idle time to start WIP-saving actions.";
      };
      wip.minChangedLines = mkOption {
        type = types.int;
        default = 100;
        description = "Changed WIP LOC count to consider pushing upstream.";
      };
      pager.diff-so-fancy.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable diff-so-fancy pager.";
      };
      pager.delta.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable delta pager.";
      };
      signing.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable cryptographic objects signing.";
      };
      hooks.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable custom hooks.";
      };
      gitignore = mkOption {
        type = types.lines;
        default = "";
        visible = false;
        internal = true;
        description = "Global gitignore contents.";
      };
      assets.dirName = mkOption {
        type = types.str;
        default = "git-assets";
        description = "Assets(templates, etc.) home subdir.";
      };
      myrepos.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable Myrepos setup.";
      };
      myrepos.subconfigs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Myrepos subconfigs to include.";
      };
      ghq.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable ghq tooling.";
      };
      ghq.importCommands = mkOption {
        type = types.attrs;
        default = { };
        description = "Custom import commands for ghq.";
      };
      github.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable Github connectivity.";
      };
      github.user = mkOption {
        type = types.str;
        default = "";
        description = "Github user ID.";
      };
      fetchUpdates.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable batch updates fetching.";
      };
      fetchUpdates.when = mkOption {
        type = types.str;
        default = "";
        description = "When to fetch updates (on calendar).";
      };
      pushUpdates.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable batch updates pushing.";
      };
      pushUpdates.when = mkOption {
        type = types.str;
        default = "";
        description = "When to push updates (on calendar).";
      };
      saveWip.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable work-in-progress saving.";
      };
      saveWip.when = mkOption {
        type = types.str;
        default = "";
        description = "When to save work-in-progress (on calendar).";
      };
      emacs.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable Emacs git-related setup.";
      };
      emacs.extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra settings to be added to Emacs config.";
      };
      staging.packages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "List of staging packages.";
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      assertions = [
        {
          assertion = config.attributes.mainUser.fullName != "" && config.attributes.mainUser.email != "";
          message = "git: Must provide authoring identity.";
        }
        {
          assertion = cfg.github.enable && cfg.github.user != "";
          message = "git: Must provide github ID when enabling Github connectivity.";
        }
        {
          assertion = let
            p = cfg.pager.diff-so-fancy.enable;
            q = cfg.pager.delta.enable;
          in (p || q) && !(p && q) || (!p && !q);
          message = "git: Must choose either none or exactly one (`diff-so-fancy` or `delta`) custom pager.";
        }
      ] ++ lib.optionals (cfg.signing.enable) [{
        assertion = config.attributes.mainUser.gpgKeyID != "";
        message = "git: Must provide GPG key ID when objects signing is enabled.";
      }];

      nixpkgs.config.packageOverrides = _: rec {
        gitctl =
          mkPythonScriptWithDeps "gitctl" (with pkgs; [ pyfzf pystdlib python3Packages.pygit2 python3Packages.redis ])
          (builtins.readFile
            (pkgs.substituteAll ((import ../subst.nix { inherit config pkgs lib; }) // { src = ./gitctl.py; })));
      };

      custom.housekeeping.metadataCacheInstructions = ''
        ${pkgs.redis}/bin/redis-cli set git/credentials_mapping ${
          lib.strings.escapeNixString (builtins.toJSON cfg.credentials.mapping)
        }
      '';

      home-manager.users."${config.attributes.mainUser.name}" = {
        home.file = { "${cfg.assets.dirName}/.gitignore".text = cfg.gitignore; };
        # https://github.com/languitar/pass-git-helper - review for more fine-grained control
        xdg.configFile."pass-git-helper/git-pass-mapping.ini".text = lib.generators.toINI { } cfg.credentials.mapping;
        programs.git = {
          enable = true;
          userName = config.attributes.mainUser.fullName;
          userEmail = config.attributes.mainUser.email;
          signing = {
            key = config.attributes.mainUser.gpgKeyID;
            signByDefault = true;
          };
          extraConfig = {
            "rebase" = {
              autoSquash = true;
              autoStash = true;
            };
            "core" = {
              autocrlf = false;
              excludesfile = homePrefix "${cfg.assets.dirName}/.gitignore";
              quotepath = false;
              askPass = "";
            };
            "credential" = { helper = "${pkgs.gitAndTools.pass-git-helper}/bin/pass-git-helper"; };
            "diff" = {
              algorithm = "patience";
              gpg = { textconv = "${pkgs.gnupg}/bin/gpg2 --no-tty --decrypt"; };
            };
            "push" = { default = "current"; };
            "absorb" = { maxstack = 75; }; # TODO: package https://github.com/torbiak/git-autofixup
          } // lib.optionalAttrs (cfg.github.enable) { "github" = { user = cfg.github.user; }; }
            // lib.optionalAttrs (cfg.pager.diff-so-fancy.enable) {
              "pager" = {
                diff = "${pkgs.gitAndTools.diff-so-fancy}/bin/diff-so-fancy | ${pkgs.less}/bin/less --tabs=4 -CR";
                show = "${pkgs.gitAndTools.diff-so-fancy}/bin/diff-so-fancy | ${pkgs.less}/bin/less --tabs=4 -CR";
                log = "${pkgs.gitAndTools.diff-so-fancy}/bin/diff-so-fancy | ${pkgs.less}/bin/less --tabs=4 -CR";
              };
            } // lib.optionalAttrs (cfg.pager.delta.enable) {
              "pager" = {
                diff = ''
                  ${pkgs.gitAndTools.delta}/bin/delta --dark --plus-color="#34ad3a" --minus-color="#ad3436" --highlight-removed --theme="zenburn"'';
                show = ''
                  ${pkgs.gitAndTools.delta}/bin/delta --dark --plus-color="#34ad3a" --minus-color="#ad3436" --highlight-removed --theme="zenburn"'';
                log = ''
                  ${pkgs.gitAndTools.delta}/bin/delta --dark --plus-color="#34ad3a" --minus-color="#ad3436" --highlight-removed --theme="zenburn"'';
              };
            } // lib.optionalAttrs (cfg.urlSubstitutes != { }) cfg.urlSubstitutes;
        };
      };
      environment.systemPackages = with pkgs;
        [
          file
          git-quick-stats
          git-sizer
          gitAndTools.git-absorb
          gitAndTools.git-crypt
          gitAndTools.git-extras
          gitAndTools.git-machete
          gitAndTools.git-octopus
          gitAndTools.pass-git-helper
          gitstats
          nixpkgs-pinned-16_04_20.gitAndTools.thicket

          gitAndTools.git-trim
          gitAndTools.git-reparent
        ] ++ lib.optionals (cfg.staging.packages != [ ]) cfg.staging.packages;
    })
    (mkIf (cfg.enable && cfg.ghq.enable) {
      assertions = [{
        assertion = globalRoot != "";
        message = "git: Must provide workspace root directory for ghq tool.";
      }];

      environment.systemPackages = with pkgs; [ gitAndTools.ghq ];
      home-manager.users."${config.attributes.mainUser.name}" = {
        programs.git.extraConfig = { "ghq" = { root = homePrefix globalRoot; }; };
      };
      custom.navigation.workspaceRoots = let ghqRoot = globalRoot;
      in {
        github = "${ghqRoot}/github.com";
        gitlab = "${ghqRoot}/gitlab.com";
        bitbucket = "${ghqRoot}/bitbucket.org";
      };
    })
    (mkIf (cfg.enable && cfg.myrepos.enable) {
      custom.dev.git.myrepos.subconfigs = [ "${homePrefix globalRoot}/github.com/wiedzmin/.mrconfig" ];
      home-manager.users."${config.attributes.mainUser.name}" = {
        home.packages = with pkgs; [ mr gitctl ];
        home.file = {
          ".mrtrust".text = builtins.concatStringsSep "\n" (cfg.myrepos.subconfigs ++ [ (homePrefix ".mrconfig") ]);
          ".mrconfig".text = ''
            [DEFAULT]
            update =
              ${pkgs.gitctl}/bin/gitctl update --op fetch
              ${pkgs.gitctl}/bin/gitctl update --op rebase
            savewip =
              ${pkgs.gitctl}/bin/gitctl wip
            push =
              ${pkgs.gitctl}/bin/gitctl update --op push
            usync =
              ${pkgs.gitctl}/bin/gitctl update --op fetch --remote ${cfg.defaultUpstreamRemote}
              ${pkgs.gitctl}/bin/gitctl update --op merge
            synctags =
              ${pkgs.gitctl}/bin/gitctl tags --sync
            usynctags =
              ${pkgs.gitctl}/bin/gitctl tags --sync --remote ${cfg.defaultUpstreamRemote}
            direnv =
              [ -f .envrc ] && direnv allow || exit 0
            trim =
              ${pkgs.gitAndTools.git-trim}/bin/git-trim --delete=merged-local

            ${lib.concatMapStrings (config: ''
              include = cat ${config}
            '') cfg.myrepos.subconfigs}
          '';
          "${globalRoot}/github.com/wiedzmin/.mrconfig".text = lib.generators.toINI { } {
            "${homePrefix globalRoot}/github.com/wiedzmin/bitcoinbook" = {
              checkout = "git clone 'https://github.com/wiedzmin/bitcoinbook.git' 'bitcoinbook'";
            };
            "${homePrefix globalRoot}/github.com/wiedzmin/git-hooks" = {
              checkout = "git clone 'https://github.com/wiedzmin/git-hooks.git' 'git-hooks'";
            };
            "${homePrefix globalRoot}/github.com/wiedzmin/kbdd" = {
              checkout = "git clone 'https://github.com/wiedzmin/kbdd.git' 'kbdd'";
            };
            "${homePrefix globalRoot}/github.com/wiedzmin/pgsql-listen-exchange" = {
              checkout = "git clone 'https://github.com/wiedzmin/pgsql-listen-exchange.git' 'pgsql-listen-exchange'";
            };
            "${homePrefix globalRoot}/github.com/wiedzmin/rc" = {
              checkout = "git clone 'https://github.com/wiedzmin/rc.git' 'rc'";
            };
            "${homePrefix globalRoot}/github.com/wiedzmin/shepherd" = {
              checkout = "git clone 'https://github.com/wiedzmin/shepherd.git' 'shepherd'";
            };
            "${homePrefix globalRoot}/github.com/wiedzmin/cl-study" = {
              checkout = "git clone 'https://github.com/wiedzmin/cl-study.git' 'cl-study'";
            };
            "${homePrefix globalRoot}/github.com/wiedzmin/gourmet" = {
              checkout = "git clone 'https://github.com/wiedzmin/gourmet.git' 'gourmet'";
            };
            "${homePrefix globalRoot}/github.com/wiedzmin/lisp-koans" = {
              checkout = "git clone 'https://github.com/wiedzmin/lisp-koans.git' 'lisp-koans'";
            };
            "${homePrefix globalRoot}/github.com/wiedzmin/mlbot" = {
              checkout = "git clone 'https://github.com/wiedzmin/mlbot.git' 'mlbot'";
            };
            "${homePrefix globalRoot}/github.com/wiedzmin/nixpkgs" = {
              checkout = "git clone 'https://github.com/wiedzmin/nixpkgs.git' 'nixpkgs'";
            };
            "${homePrefix globalRoot}/github.com/wiedzmin/science_chemphys" = {
              checkout = "git clone 'https://github.com/wiedzmin/science_chemphys.git' 'science_chemphys'";
            };
            "${homePrefix globalRoot}/github.com/wiedzmin/stumpwm" = {
              checkout = "git clone 'https://github.com/wiedzmin/stumpwm.git' 'stumpwm'";
            };
            "${homePrefix globalRoot}/github.com/wiedzmin/first-order-model" = {
              checkout = "git clone 'https://github.com/wiedzmin/first-order-model.git' 'first-order-model'";
            };
            "${homePrefix globalRoot}/github.com/wiedzmin/passdmenu" = {
              checkout = "git clone 'https://github.com/wiedzmin/passdmenu.git' 'passdmenu'";
            };
            "${homePrefix globalRoot}/github.com/wiedzmin/stumpwm-contrib" = {
              checkout = "git clone 'https://github.com/wiedzmin/stumpwm-contrib.git' 'stumpwm-contrib'";
            };
            "${homePrefix globalRoot}/github.com/wiedzmin/xmonad-config" = {
              checkout = "git clone 'https://github.com/wiedzmin/xmonad-config.git' 'xmonad-config'";
            };
          };
        };
      };
    })
    (mkIf (cfg.enable && cfg.hooks.enable) {
      home-manager.users."${config.attributes.mainUser.name}" = {
        home.packages = with pkgs; [ gitAndTools.pre-commit nixfmt ];
      };
      environment.etc = {
        "nixos/.pre-commit-config.yaml".text = builtins.toJSON {
          repos = [
            {
              repo = "https://github.com/wiedzmin/git-hooks";
              rev = "master";
              hooks = [ { id = "forbid-pushing-wip"; } { id = "nixfmt"; } ];
            }
            {
              repo = "https://github.com/jumanjihouse/pre-commit-hooks";
              rev = "master";
              hooks = [{
                id = "shfmt";
                args = [ "-i" "2" ];
              }];
            }
          ];
        };
        "nixos/.envrc".text = ''
          source <(direnv apply_dump .envrc.cache)
        '';
        "nixos/shell.nix".text = ''
          let
            pkgs = import <nixpkgs> {};
          in
            pkgs.mkShell {
              buildInputs = with pkgs; [
                shfmt
              ];
            }
        '';
      };
    })
    (mkIf (cfg.enable && cfg.fetchUpdates.enable) {
      assertions = [
        {
          assertion = cfg.myrepos.enable;
          message = "git: automatic updates fetching requires myrepos setup to be enabled.";
        }
        {
          assertion = cfg.fetchUpdates.when != "";
          message = "git: automatic updates fetching is enabled while not scheduled.";
        }
      ];

      systemd.user.services."git-fetch-updates" = {
        description = "Fetch updates from registered git upstream(s)";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.mr}/bin/mr update";
          WorkingDirectory = homePrefix "";
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };
      systemd.user.timers."git-fetch-updates" =
        renderTimer "Fetch updates from registered git upstream(s)" "1m" "2m" cfg.fetchUpdates.when;
    })
    (mkIf (cfg.enable && cfg.pushUpdates.enable) {
      assertions = [
        {
          assertion = cfg.myrepos.enable;
          message = "git: automatic updates pushing requires myrepos setup to be enabled.";
        }
        {
          assertion = cfg.pushUpdates.when != "";
          message = "git: automatic updates pushing is enabled while not scheduled.";
        }
      ];

      systemd.services."git-push-updates" = {
        description = "Push updates to registered git upstream(s)";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.mr}/bin/mr push";
          WorkingDirectory = homePrefix "";
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };
      systemd.timers."git-push-updates" =
        renderTimer "Push updates to registered git upstream(s)" "10m" "15m" cfg.pushUpdates.when;
    })
    (mkIf (cfg.enable && cfg.saveWip.enable) {
      assertions = [
        {
          assertion = cfg.myrepos.enable;
          message = "git: automatic WIP saving requires myrepos setup to be enabled.";
        }
        {
          assertion = cfg.saveWip.when != "";
          message = "git: automatic WIP saving is enabled while not scheduled.";
        }
      ];

      systemd.user.services."git-save-wip" = {
        description = "Save work-in-progress in registered git repo(s)";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''${pkgs.bash}/bin/bash -c "${pkgs.mr}/bin/mr savewip"'';
          WorkingDirectory = homePrefix "";
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };
      systemd.user.timers."git-save-wip" =
        renderTimer "Save work-in-progress in registered git repo(s)" "2m" "3m" cfg.saveWip.when;
    })
    (mkIf (cfg.enable && cfg.emacs.enable) {
      home-manager.users."${config.attributes.mainUser.name}" = {
        programs.emacs.extraPackages = epkgs: [
          epkgs.browse-at-remote
          epkgs.dired-git-info
          epkgs.git-commit
          epkgs.git-identity
          epkgs.git-link
          epkgs.git-msg-prefix
          epkgs.git-timemachine
          epkgs.git-walktree
          epkgs.helm-ghq
          epkgs.magit
          epkgs.magit-filenotify
          epkgs.magit-popup # *
          epkgs.magit-todos
        ];
      };
      ide.emacs.config = builtins.readFile
        (pkgs.substituteAll ((import ../subst.nix { inherit config pkgs lib; }) // { src = ./git.el; })) + "\n"
        + cfg.emacs.extraConfig;
    })
  ];
}

# * it seems some magit-dependent packages yet depend on magit-popup in some path, so we introduced
#   this explicit dependency and will keep it until transition to "transient" library is fully done
#   by all affected packages. (or some other root cause of "magit-popup"" will pop up)

# think of automation (maybe using existing tools) for providing branch name for Jira-related (and
# maybe not only) projects
