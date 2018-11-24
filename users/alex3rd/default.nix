{config, pkgs, lib, ...}:

{
    imports = [
        <home-manager/nixos>
        ./desktop/org_protocol.nix
        ./scripts/services.nix
        ./dotfiles/shell/common.nix
        ./dotfiles/shell/term.nix
        ./dotfiles/shell/tmux.nix
        ./dotfiles/shell/zsh.nix
        ./dotfiles/x11/autorandr.nix
        ./dotfiles/x11/misc.nix
        ./dotfiles/x11/taffybar.nix
        ./dotfiles/x11/xresources.nix
        ./dotfiles/x11/browser.nix
        ./dotfiles/mail.nix
        ./dotfiles/dev/editor.nix
        ./dotfiles/dev/git.nix
        ./dotfiles/dev/lisp.nix
        ./dotfiles/dev/python.nix
        ./services/sshuttle.nix
        ./services/imapfilter.nix
        ./services/vpn.nix
        ./services/git-auto.nix
        ./services/collect-garbage.nix
        ./services/watch-dunst.nix
        ./services/nixpkgs-update-status.nix
        ./services/xkeysnail.nix
    ];

    users.extraUsers = {
        alex3rd = {
            isNormalUser = true;
            uid = 1000;
            description = "Alex Ermolov";
            shell = pkgs.zsh;
            extraGroups = [ "audio" "docker" "input" "lp" "networkmanager" "scanner" "vboxusers" "video" "wheel" ];
        };
    };

    nix.trustedUsers = [ "alex3rd" ];

    networking.extraHosts = (builtins.concatStringsSep
                             "\n" (lib.mapAttrsToList (ip: names: ip + "   " + names)
                                  (config.job.extra_hosts // config.misc.extra_hosts)));

    home-manager.users.alex3rd = {
        home.packages = with pkgs; [
            # base
            file
            glibcLocales

            backlightctl
            jobvpnctl
            sshuttlectl
            volumectl
            wifictl

            job-mysql-cli
        ];
    };
}
