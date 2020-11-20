{ config, inputs, lib, pkgs, ... }:
with import ../../util.nix { inherit config inputs lib pkgs; };
with lib;

let
  cfg = config.custom.dev.golang;
  user = config.attributes.mainUser.name;
  nurpkgs = pkgs.unstable.nur.repos.wiedzmin;
in {
  options = {
    custom.dev.golang = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable Golang dev infrastructure.";
      };
      goPath = mkOption {
        type = types.str;
        default = "";
        description = "Path to be used as $GOPATH root.";
      };
      privateModules = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Glob patterns of Go modules to consider private (e.g. GOPRIVATE contents).";
      };
      golangciLintConfig = mkOption {
        type = types.attrs;
        default = { };
        description = "Initial config for golangci-lint";
      };
      packaging.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable packaging toolset.";
      };
      packaging.path = mkOption {
        type = types.str;
        default = "workspace/go2nix";
        description = "Packaging sandbox root relative to $HOME.";
      };
      misc.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable miscelanneous tools.";
      };
      emacs.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable Emacs Golang setup.";
      };
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable) {
      # FIXME: debug assertion with flakes
      # assertions = [{
      #   assertion = (cfg.goPath != "" && builtins.pathExists cfg.goPath);
      #   message = "dev/golang: cannot proceed without valid $GOPATH value.";
      # }];

      home-manager.users.${user} = {
        home.packages = with pkgs; [
          delve
          gopls
          go
        ];
        programs.zsh.sessionVariables = {
          GOPATH = cfg.goPath;
        } // lib.optionalAttrs (cfg.privateModules != [ ]) {
          GOPRIVATE = builtins.concatStringsSep "," cfg.privateModules;
        };
        programs.zsh.initExtra = ''
          path+=${cfg.goPath}/bin
        '';
      };
      ide.emacs.environment = {
        GOPATH = cfg.goPath;
      } // lib.optionalAttrs (cfg.privateModules != [ ]) {
        GOPRIVATE = builtins.concatStringsSep "," cfg.privateModules;
      };
    })
    (mkIf (cfg.enable && cfg.packaging.enable) {
      home-manager.users.${user} = {
        home.packages = with pkgs; [ dep2nix go2nix vgo2nix ];
      };
    })
    (mkIf (cfg.enable && cfg.misc.enable) {
      nixpkgs.config.packageOverrides = _: rec {
        modedit = mkPythonScriptWithDeps "modedit" (with pkgs; [ nurpkgs.pystdlib ])
          (readSubstituted ../subst.nix ./scripts/modedit.py);
        go-install-wrapper = mkShellScriptWithDeps "go-install-wrapper" (with pkgs; [ ]) ''
          go install ./...
        '';
      };
      home-manager.users.${user} = { home.packages = with pkgs; [ go-install-wrapper gore modedit ]; };
    })
    (mkIf (cfg.enable && cfg.emacs.enable) {
      home-manager.users.${user} = {
        home.file = {
          "${cfg.packaging.path}/default.nix".text = ''
            with import <nixpkgs> {};

            stdenv.mkDerivation {
                name = "go-generate-nix";
                buildInputs = with pkgs; [
                    go
                    git
                    go2nix
                ];
                src = null;
                shellHook = '''
                    export GOPATH=`pwd`
                    echo "====================================="
                    echo " 1) go get <github.com/user/repo>    "
                    echo "                                     "
                    echo " 2) cd src/<github.com/user/repo>    "
                    echo "                                     "
                    echo " 3) go get                           "
                    echo " 3') go build                        "
                    echo "                                     "
                    echo " 3) go2nix save                      "
                    echo "====================================="
                ''';
            }
          '';
        };
      };
      ide.emacs.extraPackages = epkgs: [
        epkgs.flycheck-golangci-lint
        epkgs.go-mode
        epkgs.go-tag
        epkgs.gotest
      ];
      ide.emacs.config = readSubstituted ../subst.nix ./emacs/golang.el;
    })
    (mkIf (cfg.enable && config.attributes.debug.scripts) {
      home-manager.users."${user}" = { home.packages = with pkgs; [ modedit ]; };
    })
  ];
}
