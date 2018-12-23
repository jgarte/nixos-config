{config, pkgs, lib, ...}:

{
    imports = [
        ../../private/traits/common.nix
    ];

    system.activationScripts.refreshShellBookmarks = "echo '" +
        (builtins.concatStringsSep "\n"
             (lib.mapAttrsToList (bmk: path: bmk + " : " + path)
             (config.common.shell_bookmarks))) +
        "' > $HOME/.bookmarks";

    home-manager.users.kotya = {
        home.packages = with pkgs; [
            optimize-nix
        ];

        programs.htop.enable = true;
        programs.command-not-found.enable = true;
        programs.lesspipe.enable = true;
        programs.man.enable = true;
        programs.info.enable = true;
        programs.fzf = {
            enable = true;
            enableZshIntegration = true;
        };
        programs.direnv = {
            enable = true;
            enableZshIntegration = true;
        };
    };
}
