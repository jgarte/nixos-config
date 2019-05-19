{config, pkgs, lib, ...}:
with import ../../const.nix {inherit config pkgs;};
let
    shell-capture = pkgs.writeShellScriptBin "shell-capture" ''
        TEMPLATE="$1"
        if [[ ! -n $TEMPLATE ]]
        then
            exit 1
        fi
        TITLE="$*"
        if [[ -n $TMUX ]]
        then
            TITLE=$(${pkgs.tmux}/bin/tmux display-message -p '#S')
            ${pkgs.tmux}/bin/tmux send -X copy-pipe-and-cancel "${pkgs.xsel}/bin/xsel -i --primary"
        fi

        if [[ -n $TITLE ]]
        then
            emacsclient -n "org-protocol://capture?template=$TEMPLATE&title=$TITLE"
        else
            emacsclient -n "org-protocol://capture?template=$TEMPLATE"
        fi
    '';
    maybe_ssh_host = pkgs.writeShellScriptBin "maybe_ssh_host" ''
        # tmux: pane_tty: pts/5
        PANE_TTY=$(${pkgs.tmux}/bin/tmux display-message -p '#{pane_tty}' | ${pkgs.coreutils}/bin/cut -c 6-)

        # get IP/hostname according to pane_tty
        REMOTE_SESSION=$(${pkgs.procps}/bin/pgrep -t $pane_tty -a -f "ssh " | ${pkgs.gawk}/bin/awk 'NF>1{print $NF}')

        if [[ "$REMOTE_SESSION" != "" ]]; then
            echo $REMOTE_SESSION
        else
            echo $(whoami)@$(${pkgs.nettools}/bin/hostname)
        fi
    '';
    tmuxPluginsBundle = with pkgs; [
        fzf-tmux-url-with-history # patched version, see overlays
        tmuxPlugins.battery
        tmuxPlugins.copycat
        tmuxPlugins.cpu
        tmuxPlugins.fpp
        tmuxPlugins.logging
        tmuxPlugins.prefix-highlight
        tmuxPlugins.sessionist
        tmuxPlugins.yank
    ];
in
{
    home-manager.users.alex3rd = {
        home.file = {
            "tmuxp/housekeeping.yml".text = ''
                session_name: housekeeping
                windows:
                  - window_name: system
                    layout: 9295,152x109,0,0[152x64,0,0,134,152x44,0,65,135]
                    start_directory: /etc/nixos
                    panes:
                      - null
                      - shell_command:
                        - cd /etc/nixos/pkgs/nixpkgs-channels
                        - nix repl '<nixpkgs/nixos>'
                  - window_name: mc
                    start_directory: /home/${userName}
                    panes:
                      - mc
            '';
            "tmuxp/media.yml".text = ''
                session_name: media
                windows:
                  - window_name: youtube
                    panes:
                      - mpsyt
            '';
            "tmuxp/dev.yml".text = ''
                session_name: dev
                windows:
                  - window_name: mc
                    start_directory: ${config.dev.workspacePath}/github.com/wiedzmin
                    panes:
                      - mc
            '';
            # TODO: divide into "local" and "remote" parts, where the latter is subset of the former, with remote-friendly settings (i.e. without plugins, etc.)
            ".tmux.conf".text = ''
                # indexes
                set -g base-index 1             # first window index
                set -g renumber-windows on
                setw -g pane-base-index 1

                # misc
                set -g default-shell ${pkgs.zsh}/bin/zsh
                set -g repeat-time 1000
                set -g history-limit 102400
                set -g mouse on
                set -g prefix M-x
                set -g status-keys emacs
                set -sg escape-time 0 # faster functioning for Esc-bound apps (ex. Vim)
                setw -g aggressive-resize on
                setw -g automatic-rename on
                setw -g mode-keys emacs
                set -g set-titles on
                set -g set-titles-string '#(${maybe_ssh_host}/bin/maybe_ssh_host):#(pwd="#{pane_current_path}"; echo $pwd)'
                setenv EDITOR ${pkgs.emacs}/bin/emacsclient

                set-hook -g after-select-pane "run-shell \"tmux set -g window-active-style "bg='brightblack'" && sleep .05 && tmux set -g window-active-style '''\""

                # activity
                set -g bell-action any
                set -g visual-activity off
                set -g visual-bell off
                set -g visual-silence off
                setw -g monitor-activity on

                # statusbar
                set -g display-panes-time 2000
                set -g display-time 2000
                set -g status on
                set -g status-interval 1
                set -g status-justify centre
                set -g status-left '#{prefix_highlight}#[fg=green](#S) #(whoami)@#H'
                set -g status-left-length 30
                set -g status-right '#[fg=blue,bright]%k:%M:%S %d/%m/%Y \
                | #{cpu_fg_color}#{cpu_icon}#{cpu_percentage}'
                set -g status-right-length 140
                setw -g clock-mode-style 24
                setw -g window-status-current-format \
                        '#[bg=blue,fg=cyan,bold]#I#[bg=blue,fg=cyan]:#[fg=colour230]#T#[fg=dim]#F'
                setw -g window-status-format '#[fg=cyan,dim]#I#[fg=blue]:#[default]#W#[fg=grey,dim]#F'

                # colors
                set -g default-terminal "screen-256color"
                set -g message-attr bright
                set -g message-bg black
                set -g message-fg white
                set -g pane-active-border-bg default
                set -g pane-active-border-fg colour240 #base01
                set -g pane-border-bg default
                set -g pane-border-fg colour235 #base02
                set -g status-attr default
                set -g status-bg default
                set -g status-fg white
                set -ga terminal-overrides 'xterm*:smcup@:rmcup@,xterm-256color:Tc'
                setw -g clock-mode-colour green #green
                setw -g window-status-attr dim
                setw -g window-status-bg default
                setw -g window-status-current-attr bright
                setw -g window-status-current-bg default
                setw -g window-status-current-bg red
                setw -g window-status-current-fg colour166 # TODO was white, check if it works somewhere else
                setw -g window-status-fg cyan

                # TODO: investigate how session names may be templated in Nix
                # keybindings
                unbind C-b

                bind * list-clients
                bind -n C-left prev
                bind -n C-right next
                bind -n C-x send-prefix     # prefix commands for nested tmux sessions
                bind -n S-left swap-window -t -1
                bind -n S-right swap-window -t +1
                bind T neww -n "Tmux manual" "exec man tmux"
                bind l refresh-client
                bind m select-pane -m

                bind-key "|" split-window -h -c "#{pane_current_path}"
                bind-key "\\" split-window -fh -c "#{pane_current_path}"
                bind-key "-" split-window -v -c "#{pane_current_path}"
                bind-key "_" split-window -fv -c "#{pane_current_path}"
                bind-key "#" split-window -h -c "#{pane_current_path}"
                bind-key '@' split-window -v -c "#{pane_current_path}"

                bind M-0 select-window -t :10
                bind M-1 select-window -t :11
                bind M-2 select-window -t :12
                bind M-3 select-window -t :13
                bind M-4 select-window -t :14
                bind M-5 select-window -t :15
                bind M-6 select-window -t :16
                bind M-7 select-window -t :17
                bind M-8 select-window -t :18
                bind M-9 select-window -t :19

                bind F10 select-window -t :20
                bind F1 select-window -t :21
                bind F2 select-window -t :22
                bind F3 select-window -t :23
                bind F4 select-window -t :24
                bind F5 select-window -t :25
                bind F6 select-window -t :26
                bind F7 select-window -t :27
                bind F8 select-window -t :28
                bind F9 select-window -t :29

                bind BSpace last-window

                bind -n C-y run -b "exec </dev/null; ${pkgs.xsel}/bin/xsel -o --clipboard | tmux load-buffer - ; \
                                    tmux paste-buffer"
                bind s split-window -v "tmux list-sessions | sed -E 's/:.*$//' | \
                                        grep -v \"^$(tmux display-message -p '#S')\$\" | \
                                        ${pkgs.fzf}/bin/fzf --reverse | xargs tmux switch-client -t"

                bind -T copy-mode M-e run-shell "${shell-capture}/bin/shell-capture es"
                bind -T copy-mode M-j run-shell "${shell-capture}/bin/shell-capture js"
                bind -T copy-mode M-n run-shell "${shell-capture}/bin/shell-capture ns"
                bind -T copy-mode M-x run-shell "${shell-capture}/bin/shell-capture xs"

                bind F12 send-key "#############################################################################################"
                bind F11 send-key "git open" "Enter"

                bind z split-window -v "${pkgs.procps}/bin/ps -ef | \
                                        ${pkgs.gnused}/bin/sed 1d | \
                                        ${pkgs.fzf}/bin/fzf | ${pkgs.gawk}/bin/awk '{print $2}' | xargs kill -15"
                bind Z split-window -v "${pkgs.procps}/bin/ps -ef | \
                                        ${pkgs.gnused}/bin/sed 1d | \
                                        ${pkgs.fzf}/bin/fzf | ${pkgs.gawk}/bin/awk '{print $2}' | xargs kill -9"

                bind b split-window -c '#{pane_current_path}' \
                                    -v "${pkgs.is-git-repo}/bin/is-git-repo && ${pkgs.git}/bin/git -p show --color=always \
                                        $(${pkgs.git}/bin/git log --decorate=short --graph --oneline --color=always | \
                                        ${pkgs.fzf}/bin/fzf --ansi +m +s | ${pkgs.gawk}/bin/awk '{print $2}') | less -R"

                bind r source-file ~/.tmux.conf \; display "  Config reloaded..."
                bind y set-window-option synchronize-panes

                # plugins settings
                set -g @fzf-url-bind 'o'
                # add all the plugins
                ${lib.concatStrings (map (x: "run-shell ${x.rtp}\n") tmuxPluginsBundle)}
            '';
        };
    };
}

# TODO: some impl/binding for ix.io posts