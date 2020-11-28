{ config, inputs, lib, pkgs, ... }:
with import ../../util.nix { inherit config inputs lib pkgs; };
with lib;

let
  cfg = config.tools.ebooks;
  user = config.attributes.mainUser.name;
  nurpkgs = pkgs.unstable.nur.repos.wiedzmin;
in {
  options = {
    tools.ebooks = {
      readers.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable ebook readers for various formats.";
      };
      readers.roots = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Paths to search ebooks under.";
      };
      readers.extensions = mkOption {
        type = types.listOf types.str;
        default = [ "pdf" "djvu" "epub" ];
        description = "Ebook file extensions to consider.";
      };
      readers.booksSearchCommand = mkOption {
        type = types.str;
        default = "${pkgs.fd}/bin/fd --full-path --absolute-path ${
            lib.concatStringsSep " " (lib.forEach cfg.readers.extensions (ext: "-e ${ext}"))
          }";
        visible = false;
        internal = true;
        description = "Shell command to use for collecting ebooks' paths.";
      };
      processors.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable ebooks processors (mostly pdf-centric).";
      };
      wm.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable WM keybindings.";
      };
      staging.packages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "List of staging packages.";
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.readers.enable {
      fileSystems."${config.services.syncthing.dataDir}/bookshelf" = {
        device = homePrefix "bookshelf";
        options = [ "bind" ];
      };
      custom.housekeeping.metadataCacheInstructions = ''
        ${pkgs.redis}/bin/redis-cli set content/ebook_roots ${
          lib.strings.escapeNixString (builtins.toJSON (localEbooks config.custom.navigation.bookmarks.entries))
        }
      '';
      nixpkgs.config.packageOverrides = _: rec {
        bookshelf = mkPythonScriptWithDeps "bookshelf" (with pkgs; [ nurpkgs.pystdlib python3Packages.redis zathura ])
          (readSubstituted ../subst.nix ./scripts/bookshelf.py);
        update-bookshelf = mkPythonScriptWithDeps "update-bookshelf" (with pkgs; [ nurpkgs.pystdlib python3Packages.redis ])
          (readSubstituted ../subst.nix ./scripts/update-bookshelf.py);
      };
      systemd.user.services."update-ebooks" = {
        description = "Update bookshelf contents";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.update-bookshelf}/bin/update-bookshelf";
          StandardOutput = "journal";
          StandardError = "journal";
        };
      };
      systemd.user.timers."update-ebooks" = renderTimer "Update ebooks entries" "1h" "1h" "";
      custom.pim.timeTracking.rules = ''
        current window $title =~ /.*pdf.*/ ==> tag read:pdf,
        current window $title =~ /.*djvu.*/ ==> tag read:djvu,
        current window $title =~ /.*epub.*/ ==> tag read:epub,
        current window $title =~ /.*mobi.*/ ==> tag read:mobi,
        current window $title =~ /.*fb2.*/ ==> tag read:fb2,

        current window $title =~ m!.*papers/.*! ==> tag ebooks:papers,
      '';
      home-manager.users.${user} = {
        xdg.mimeApps.defaultApplications = mapMimesToApp config.attributes.mimetypes.ebook "org.pwmt.zathura.desktop";
        home.packages = with pkgs; [ calibre djview djvulibre ];
        programs.zathura = {
          enable = true;
          options = {
            pages-per-row = 1;
            selection-clipboard = "clipboard";
          };
        };
      };
    })
    (mkIf cfg.processors.enable {
      home-manager.users.${user} = {
        home.packages = with pkgs; [ enca pandoc pdfcpu pdftk ];
      };
    })
    (mkIf (cfg.wm.enable && cfg.readers.enable) {
      wmCommon.keys = [{
        key = [ "b" ];
        cmd = "${pkgs.bookshelf}/bin/bookshelf";
        mode = "select";
      }];
    })
    (mkIf (cfg.staging.packages != [ ]) {
      home-manager.users.${user} = { home.packages = cfg.staging.packages; };
    })
    (mkIf (config.attributes.debug.scripts) {
      home-manager.users.${user} = {
        home.packages = with pkgs; [ bookshelf update-bookshelf ];
      };
    })
  ];
}
