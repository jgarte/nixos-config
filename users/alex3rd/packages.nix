{ config, pkgs, ... }:
let
  # TODO: write script to query keywords which would provide packages names either from installed or whole nixpkgs
  stagingInactive = with pkgs; [ ];
  stagingCommon = with pkgs; [
    # !system-config-printer
    # gImageReader
    # git-repo
    # gitAndTools.git-subrepo
    # graphicsmagick
    # https://github.com/unixorn/git-extra-commands # TODO: package
    # hyperkitty
    # lab
    # matcha theme
    # multitail (remote)
    # nohang
    # r stats tool(s)
    # rargs
    # rmount # https://github.com/Luis-Hebendanz/rmount
    # skype-call-recorder
    # tesseract
    # vegeta # TODO: package
    _3llo
    aerc
    afl # http://lcamtuf.coredump.cx/afl/
    apfs-fuse
    blsd
    bolt
    checkbashism
    chrome-export
    codesearch # TODO: timer + service for reindexing + https://github.com/abingham/emacs-codesearch for emacs
    curlie
    datamash
    davfs2
    dia
    diffoscope
    drawio
    drm_info
    dua
    feedreader
    firecracker
    gmvault
    gopass
    gource
    grab-site # https://github.com/ArchiveTeam/grab-site
    gramps
    img2pdf
    ix
    j4-dmenu-desktop
    jhead
    jl # https://github.com/chrisdone/jl
    keychain
    kid3
    lazydocker
    lightlocker
    mediainfo
    mediainfo-gui
    nfs-utils # for vagrant
    nix-review # https://github.com/Mic92/nix-review
    nixos-generators
    nnn # review https://github.com/jarun/nnn
    noti
    out-of-tree
    # paperless # see docs
    pciutils
    peco
    pipreqs # adapt to py3
    progress
    pshs
    psrecord
    python3Packages.autopep8
    python3Packages.glances
    python3Packages.importmagic
    q-text-as-data
    qmmp
    rawtherapee
    rclone
    recoll
    rofi-tmux # TODO: more descriptive tmux window titles
    rsclock
    satysfi
    screenfetch
    seturgent
    skim
    slmenu
    slop
    spyder # + kernels
    sqlitebrowser
    strace
    sysdig
    tcpreplay
    termtosvg
    textql
    uq
    usbtop
    valgrind
    wayback_machine_downloader
    wire-desktop
    xdg-user-dirs
    xlsfonts
    yj
  ];
  stagingWork = with pkgs; [
    # https://github.com/Matty9191/ssl-cert-check
    # https://github.com/alexmavr/swarm-nbt
    # https://github.com/moncho/dry
    # https://hub.docker.com/r/nicolaka/netshoot/
    # rstudio # qt plugins broken
    drone
    drone-cli
    jenkins
    nmon
    nsjail
    python3Packages.deprecated
    python3Packages.unittest-data-provider
    terracognita
    terraform
    tflint
  ];
  stagingPublish = with pkgs; [ ocrmypdfWorking.ocrmypdf pdfcpu pdfgrep pdfsandwich pdftk ];
  sandbox = with pkgs; [
    # binaries for PATH
    # transmission + service https://transmissionbt.com/ + stig
    gnuplot # ? misc
    hstr # ? misc shell
    ncmpcpp
    uget
    xdotool
    xlibs.xwininfo
    xorg.xdpyinfo
    xprintidle-ng
  ];
  devClojure = with pkgs; [ boot cfr clojure leiningen ];
  devGolangTools = with pkgs; [
    # TODO: wait for/find/dismiss github.com/davecheney/graphpkg in nixpkgs
    # TODO: wait for/find/dismiss github.com/davecheney/prdeps in nixpkgs
    # TODO: wait for/find/dismiss github.com/motemen/gore in nixpkgs
    # TODO: wait for/find/dismiss github.com/stretchr/gorc in nixpkgs
    # TODO: wait for/find/dismiss gitlab.com/opennota/check in nixpkgs
    # TODO: wait for/find/dismiss godoctor in nixpkgs
    # TODO: wait for/find/dismiss gomvpkg in nixpkgs
    # TODO: wait for/find/dismiss unbed in nixpkgs
    # asmfmt # FIXME: try to solve problem with priorities (with gotools)
    # gocode
    deadcode
    errcheck
    go-check
    go-langserver
    go-tools
    gocode-gomod
    goconst
    goconvey
    gocyclo
    godef
    gogetdoc
    golint
    gometalinter
    gomodifytags
    gosec
    gotags
    gotools
    govers
    iferr
    impl
    ineffassign
    interfacer
    maligned
    manul
    reftools
    unconvert
  ];
  devGolangInfra = with pkgs; [ dep dep2nix glide go go2nix vgo2nix ];
  devPythonTools = with pkgs; [ python3Packages.virtualenv python3Packages.virtualenvwrapper yapf ];
  devClients = with pkgs; [
    anydesk
    hpWorking.http-prompt
    httplab
    litecliWorking.litecli # TODO: shell automation: skim for selecting db file, you get the idea
    mypgWorking.mycli
    nodePackages.elasticdump
    pgcenter
    mypgWorking.pgcli
    redis-tui
    soapui
    wuzz
    zeal
  ];
  forensics = with pkgs; [
    # jd-gui
    bbe
    binutils
    elfinfo
    flamegraph
    gdb
    gdbgui
    hopper
    jid
    netsniff-ng
    ngrep
    patchelf
    patchutils
    pcapfix
    radare2
    radare2-cutter
    sysdig
    valgrind
    vmtouch
    vnstat
    vulnix
  ];
  devIde = with pkgs; [ icdiff vimHugeX ];
  vim_plugins = with pkgs.vimPlugins; [
    bufexplorer
    command-t
    direnv-vim
    editorconfig-vim
    emmet-vim
    fastfold
    jedi-vim
    vim-addon-nix
    vim-fugitive
    vim-gitbranch
    vim-gitgutter
    vim-go
    vim-indent-object
    vim-isort
    vim-javascript
    vim-jinja
    vim-json
    vim-jsonnet
    vim-lastplace
    vim-nerdtree-tabs
    vim-nix
    vim-parinfer
    vim-projectionist
    vim-repeat
    vim-snipmate
    vim-surround
    vim-yapf
    youcompleteme
    zenburn
  ];
  devMisc = with pkgs; [
    certigo
    cloc
    dnsrecon
    dotnet-sdk # for building some binary releases
    extrace
    glogg
    gron
    hss
    hyperfine
    ipcalc
    just
    k6
    libwhich
    ltrace
    miniserve
    mkcert
    mr
    patchutils
    sloccount
    socat
    sslscan
    tcpreplay
    tokei
    vcstool
    websocat
    weighttp
    wiggle
    xtruss
    xurls
  ];
  devMiscRare = with pkgs; [ cachix ];
  monitoring = with pkgs; [
    bmon
    gotop
    gping
    iotop
    jnettop
    lsof
    nethogs
    nload
    pagemon
    psmisc
    python3Packages.glances
    reflex
    speedtest-cli
    watchexec
  ];
  miscClients = with pkgs; [ aria2 inetutils qbittorrent skype slack tdesktop w3m-full ];
  miscClientsRare = with pkgs; [ teamviewer zoom-us ];
  org = with pkgs; [
    remind # + rem2ics (make overlay)
    wyrd
  ];
  miscMedia = with pkgs;
    [
      # mpv
      # FIXME: make closure for last working version
      (
        mpv-with-scripts.override (
          {
            scripts = [ mpvScripts.mpris ];
          }
        )
      )
      android-file-transfer
      ccextractor
      clipgrab
      desktop-file-utils
      exif
      exiftool
      exiv2
      ffmpeg
      gallery-dl
      haskellPackages.arbtt
      jmtpfs # consider providing some (shell) automation
      maim
      mimeo
      mpd-mpris # TODO: incorporate into user infrastructure
      playerctl
      shared-mime-info
      testdisk
      xsel # for firefox native clients
      you-get
      ytcc
    ] ++ [
      gimp
      ttyplot
      visidata # TODO: make overlay
    ];
  system = with pkgs; [ acpitool dmidecode iw lshw pciutils usbutils wirelesstools ];
  shell = with pkgs;
    [
      # docker-slim # TODO: make package https://github.com/docker-slim/docker-slim
      # tsvutils # TODO: make package https://github.com/brendano/tsvutils
      archiver
      fd
      fpart
      jdupes
      lsd
      lzip
      moreutils
      nq
      pbzip2
      pigz
      ripgrep-all
      rmlint
      sd
      unar
      unshield
    ] ++ [ xsv ]
    ++ [ bc dateutils dex doitlive gcalcli loop mc plan9port replace shellcheck tmsu tree unicode-paracode ]
    ++ [ rdfind ] ++ [ most ntfy procs progress pv shell-hist up xe ] ++ [ eternal-terminal ] ++ [ fpp skim tmux ]
    ++ [ tmatrix ];
  text = with pkgs; [
    # python3Packages.weasyprint
    calibre
    djview
    djvulibre
    enca
    ghostscript
    pandoc
  ];
  security = with pkgs; [
    (pass.withExtensions (ext: with ext; [ pass-audit pass-import pass-update ]))
    clair # https://werner-dijkerman.nl/2019/01/28/scanning-docker-images-with-coreos-clair/
    gnupg
    paperkey
    rofi-pass
    srm
  ];
  nix = with pkgs;
    [
      nix-index # TODO: maybe make easier shell alias
      nix-prefetch
      nix-prefetch-github
      nix-prefetch-scripts
      nixfmt
    ] ++ [ nix-zsh-completions ] ++ [ nodePackages.node2nix pypi2nix ];
in {
  home-manager.users."${config.attributes.mainUser.name}" = {
    home.packages = devClients ++ devGolangInfra ++ devGolangTools ++ devIde ++ devMisc ++ devPythonTools
      ++ forensics ++ miscClients ++ miscMedia ++ monitoring ++ nix ++ org ++ sandbox ++ security ++ shell
      ++ stagingCommon ++ stagingPublish ++ stagingWork ++ text;
  };
}
