{ ... }: {
  imports = [
    ./appearance
    ./browsers
    ./browsers/firefox.nix
    ./ccpp
    ./content
    ./dbms
    ./dev
    ./ebook
    ./emacs
    ./email
    ./email/mbsync.nix
    ./git
    ./golang
    ./housekeeping
    ./knowledgebase
    ./navigation
    ./networking
    ./packaging
    ./paperworks
    ./pim
    ./powermanagement
    ./python
    ./security
    ./shell
    ./shell/tmux.nix
    ./sound
    ./video
    ./virt
    ./wm
    ./wm/i3
    ./wm/stumpwm
    ./wm/xmonad
    ./xinput
  ];
}
