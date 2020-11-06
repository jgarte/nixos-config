{ config, inputs, lib, pkgs, ... }:
with lib;

let cfg = config.custom.knowledgebase;
in {
  options = {
    custom.knowledgebase = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable knowledge base facilities.";
      };
      secondBrain.enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable "second brain" functionality, such as various
          information organizing tools, mindmaps implementations, etc.
        '';
      };
      man.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable man pages.";
      };
      info.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable TeXInfo pages.";
      };
      doc.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable documentation.";
      };
      dev.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable dev documentation.";
      };
      nixos.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable NixOS documentation.";
      };
      emacs.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable Emacs documentation setup.";
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      documentation = {
        enable = true;
        man.enable = cfg.man.enable;
        info.enable = cfg.info.enable;
        doc.enable = cfg.doc.enable;
        dev.enable = cfg.dev.enable;
        nixos = {
          enable = cfg.nixos.enable;
          includeAllModules = false; # FIXME build error
        };
      };
      home-manager.users."${config.attributes.mainUser.name}" = {
        programs = {
          info.enable = true;
          man.enable = true;
        };
      };
    })
    (mkIf (cfg.enable && cfg.secondBrain.enable) {
      home-manager.users."${config.attributes.mainUser.name}" = { home.packages = with pkgs; [ heimer ]; };
    })
    (mkIf (cfg.enable && cfg.emacs.enable) {
      ide.emacs.extraPackages = epkgs: [ epkgs.helpful epkgs.which-key ];
      ide.emacs.config = builtins.readFile (pkgs.substituteAll
        ((import ../subst.nix { inherit config pkgs lib inputs; }) // { src = ./emacs/knowledgebase.el; }));
    })
  ];
}
