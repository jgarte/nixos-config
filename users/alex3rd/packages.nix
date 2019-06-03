{ config, pkgs, ... }:
let
    # TODO: write script to query keywords which would provide packages names either from installed or whole nixpkgs
    stagingInactive = with pkgs; [
        # https://github.com/lotabout/rargs - make overlay
        genymotion
        git-tbdiff # make overlay
        handbrake # + service
        nq # for mp3 encoding
        paperless # see docs
        update-resolv-conf # review
    ];
    stagingCommon = with pkgs; [
        inetutils               # + network

        trash-cli # misc # TODO: think of automating trash emptying
        moreutils               # + misc
    ];
    stagingWork = with pkgs; [
        drone
        drone-cli
        jenkins
        terraform
    ];
    sandbox = with pkgs; [ # binaries for PATH
        # transmission + service
        deluge
        fd
        gnuplot                 # ? misc
        hstr                    # ? misc shell
        k2pdfopt
        lsd
        ncmpcpp
        rtorrent
        uget
        unison
        xdotool
        xlibs.xwininfo
        xorg.xdpyinfo
        xprintidle-ng
    ];
    devClojure = with pkgs; [
        boot
        cfr
        clojure
        leiningen
    ];
    devGolangTools = with pkgs; [
        # TODO: wait for/find/dismiss github.com/davecheney/graphpkg in nixpkgs
        # TODO: wait for/find/dismiss github.com/davecheney/prdeps in nixpkgs
        # TODO: wait for/find/dismiss github.com/motemen/gore in nixpkgs
        # TODO: wait for/find/dismiss github.com/stretchr/gorc in nixpkgs
        # TODO: wait for/find/dismiss godoctor in nixpkgs
        # TODO: wait for/find/dismiss gomvpkg in nixpkgs
        # TODO: wait for/find/dismiss unbed in nixpkgs
        # TODO: wait for/find/dismiss gitlab.com/opennota/check in nixpkgs
        # asmfmt # FIXME: try to solve problem with priorities (with gotools)
        deadcode
        errcheck
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
        go-check
    ];
    devGolangInfra = with pkgs; [
        dep
        dep2nix
        glide
        go
        vgo2nix
    ];
    devPythonTools = with pkgs; [
        python3Packages.virtualenv
        python3Packages.virtualenvwrapper
        yapf
    ];
    devClients = with pkgs; [
        http-prompt
        httplab
        litecli # TODO: shell automation: skim for selecting db file, you get the idea
        mycli
        nodePackages.elasticdump
        pgcenter
        pgcli
        redis-tui
        soapui
        wuzz
        zeal
    ];
    devVcsGit = with pkgs; [
        git-quick-stats
        git-sizer
        gitAndTools.ghq
        gitAndTools.git-absorb # TODO: review abilities and maybe use in some automation
        gitAndTools.git-extras
        gitAndTools.git-imerge
        gitAndTools.pass-git-helper
        gitAndTools.topGit
        gitstats
    ];
    forensics = with pkgs; [
        bbe
        binutils
        elfinfo
        flamegraph
        gdb
        gdbgui
        jd-gui
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
        vulnix
    ];
    devIde = with pkgs; [
        icdiff
        vimHugeX
    ];
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
        dotnet-sdk              # for building some binary releases
        extrace
        glogg
        gron
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
    monitoring = with pkgs; [
        bmon
        gotop
        gping
        iotop
        jnettop
        lsof
        nethogs
        nethogs
        nload
        pagemon
        psmisc
        python3Packages.glances
        reflex
        speedtest-cli
        watchexec
    ];
    miscClients = with pkgs; [
        aria2
        qbittorrent
        skype
        slack
        tdesktop
        teamviewer
        w3m-full
        zoom-us
    ];
    scanner = with pkgs; [ # enable when needed
        deskew
        scantailor-advanced
        simple-scan
        xsane # temporarily kept for debug
    ];
    org = with pkgs; [
        remind # + rem2ics (make overlay)
        wyrd
    ];
    miscMedia = with pkgs; [
        (mpv-with-scripts.override ({
            scripts = [ mpvScripts.mpris ];
        }))
        android-file-transfer
        bup
        clipgrab
        exif
        exiv2
        ffmpeg
        gallery-dl
        haskellPackages.arbtt
        imv
        jmtpfs # consider providing some (shell) automation
        maim
        mimeo
        minitube
        playerctl
        python3Packages.mps-youtube # TODO: make script + service to backup playlists data
        testdisk
        xsel # for firefox native clients
        you-get
        youtube-dl
        ytcc
    ] ++ [
        gimp
        ttyplot
        visidata # TODO: make overlay
    ];
    system =  with pkgs; [
        acpitool
        dmidecode
        iw
        lshw
        pciutils
        usbutils
        wirelesstools
    ];
    shell = with pkgs; [
        archiver
        fpart
        jdupes
        pbzip2
        pigz
        rmlint
        unar
        unshield
    ] ++ [
        xsv
    ] ++ [
        bc
        dateutils
        dex
        doitlive
        gcalcli
        loop
        mc
        plan9port
        replace
        shellcheck
        tmsu
        tree
        unicode-paracode
        wtf
    ] ++ [
        rdfind
    ] ++ [
        most
        ntfy
        procs
        progress
        pv
        shell-hist
        up
        xe
    ] ++ [
        optimize-nix
    ] ++ [
        eternal-terminal
    ] ++ [
        fpp
        skim
        tmux
    ] ++ [
        tmatrix
    ];
    text = with pkgs; [
        calibre
        djview
        djvulibre
        enca
        ghostscript
        pandoc
        pdfgrep
        pdfsandwich
        pdftk
        python3Packages.weasyprint
        zathura
    ];
    security = with pkgs; [
        (pass.withExtensions (ext: with ext; [ pass-audit pass-import pass-update ]))
        gnupg
        gpa
        paperkey
        pinentry
        rofi-pass
        srm
    ];
    nix = with pkgs; [
        nix-index # TODO: maybe make easier shell alias
        nix-prefetch
        nix-prefetch-github
        nix-prefetch-scripts
    ] ++ [
        nix-zsh-completions
    ] ++ [
        nodePackages.node2nix
        pypi2nix
    ];
in
{
    home-manager.users.alex3rd = {
        home.packages = devClients ++
                        devClojure ++
                        devGolangInfra ++
                        devGolangTools ++
                        devIde ++
                        devMisc ++
                        devPythonTools ++
                        devVcsGit ++
                        forensics ++
                        miscClients ++
                        miscMedia ++
                        monitoring ++
                        nix ++
                        sandbox ++
                        security ++
                        shell ++
                        stagingCommon ++
                        stagingWork ++
                        text;
    };
}
