{ config, lib, pkgs, ... }:

with lib;
let cfg = config.themes.fonts.source-code-pro;
in {
  options.themes.fonts.source-code-pro = { enable = mkEnableOption "source-code-pro"; };

  config = mkIf cfg.enable {
    fonts = {
      fonts = with pkgs; [
        source-code-pro

        config.attributes.fonts.basic.package
      ];
    };
    # TODO: think of providing some reasonable defaults when particular theme module does not apply some options
    wm.xmonad.font = "xft:Source Code Pro:style=Bold:pixelsize=10";
    attributes.fonts.xmobar = config.attributes.fonts.basic.xft;
    attributes.fonts.dmenu = "xft:Source Code Pro:style=Bold:pixelsize=12";
    attributes.fonts.xmonadDefault = "xft:Source Code Pro:weight=Bold:size=10";
    home-manager.users."${config.attributes.mainUser.name}" = {
      gtk.font = lib.optionalAttrs (config.custom.appearance.gtk.enable) {
        package = pkgs.source-code-pro;
        name = "Source Code Pro Bold 8";
      };
      programs.alacritty.settings.font = {
        normal = {
          family = "Source Code Pro";
          Style = "Bold";
        };
        bold = {
          family = "Source Code Pro";
          style = "Bold";
        };
        italic = {
          family = "Source Code Pro";
          style = "Italic";
        };
        size = 11.0;
      };
      programs.zathura.options.font = "Source Code Pro Bold 10";
      services.dunst.settings.global.font = "Source Code Pro Bold 10";
      xresources.properties = {
        "Emacs*XlwMenu.font" = "Source Code Pro:weight=Bold:size=12";
        "Emacs.Font" = "Source Code Pro:weight=Bold:size=12";
        "Emacs.dialog*.font" = "Source Code Pro:weight=Bold:size=12";

        "Xmessage*faceName" = "Source Code Pro";
        "Xmessage*faceSize" = "12";
        "Xmessage*faceWeight" = "Bold";

        "dzen2.font" = "Source Code Pro:weight=Bold:size=12";
      };
    };
  };
}
