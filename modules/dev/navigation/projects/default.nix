{ config, inputs, lib, pkgs, ... }:
with import ../../../util.nix { inherit config inputs lib pkgs; };
with lib;

let
  cfg = config.dev.navigation.projects;
  user = config.attributes.mainUser.name;
  nurpkgs = pkgs.unstable.nur.repos.wiedzmin;
in {
  options = {
    dev.navigation.projects = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable projects navigation.";
      };
      bookmarks.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable bookmarked project accessibility.";
      };
      fuzzySearch.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable global repositories fuzzy search.";
      };
      fuzzySearch.root = mkOption {
        type = types.str;
        default = homePrefix config.custom.navigation.workspaceRootGlobal;
        description = "Search root.";
      };
      fuzzySearch.depth = mkOption {
        type = types.int;
        default = 4;
        description = "Search depth.";
      };
      wm.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable WM keybindings.";
      };
    };
  };

  config = mkMerge [
    (mkIf (cfg.bookmarks.enable && config.custom.navigation.bookmarks.enable) {
      nixpkgs.config.packageOverrides = _: rec {
        open-project = mkPythonScriptWithDeps "open-project" (with pkgs; [ nurpkgs.pystdlib python3Packages.redis ])
          (readSubstituted ../../../subst.nix ./scripts/open-project.py);
      };
    })
    (mkIf cfg.fuzzySearch.enable {
      nixpkgs.config.packageOverrides = _: rec {
        reposearch =
          mkPythonScriptWithDeps "reposearch" (with pkgs; [ fd python3Packages.libtmux xsel emacs nurpkgs.pystdlib ])
          (readSubstituted ../../../subst.nix ./scripts/reposearch.py);
      };
    })
    (mkIf (cfg.wm.enable) {
      wmCommon.keys = lib.optionals (cfg.fuzzySearch.enable) [{
        key = [ "r" ];
        cmd = "${pkgs.reposearch}/bin/reposearch";
        mode = "dev";
      }] ++ lib.optionals (cfg.bookmarks.enable && config.custom.navigation.bookmarks.enable) [{
        key = [ "p" ];
        cmd = "${pkgs.open-project}/bin/open-project";
        mode = "dev";
      }];
    })
    (mkIf (cfg.enable && config.attributes.debug.scripts) {
      home-manager.users.${user} = { home.packages = with pkgs; [ open-project reposearch ]; };
    })
  ];
}
