{config, pkgs, lib, ...}:

{
    home-manager.users.kotya = {
        programs.firefox = {
            enable = true;
            enableIcedTea = true;
        };
        home.file = {
            ".config/tridactyl/tridactylrc".text = ''
                " Move this to $XDG_CONFIG_DIR/tridactyl/tridactylrc (that's
                " ~/.config/tridactyl/tridactylrc to mere mortals) or ~/.tridactylrc and
                " install the native messenger (:installnative in Tridactyl). Run :source to
                " get it in the browser, or just restart.

                " NB: If you want "vim-like" behaviour where removing a line from
                " here makes the setting disappear, uncomment the line below.
                "sanitise tridactyllocal tridactylsync

                set storageloc local

                set historyresults 100

                colorscheme dark

                guiset_quiet gui none
                guiset_quiet tabs autohide
                guiset_quiet navbar autohide


                "
                " Binds
                "

                " Comment toggler for Reddit and Hacker News
                bind ;c hint -c [class*="expand"],[class="togg"]

                bind qnt composite js javascript:location.href="org-protocol:///capture?template=nt&url=" + encodeURIComponent(location.href) + "&title=" + encodeURIComponent(document.title) + "&body=" + encodeURIComponent(window.getSelection())
                bind qnc composite js javascript:location.href="org-protocol:///capture?template=nc&url=" + encodeURIComponent(location.href) + "&title=" + encodeURIComponent(document.title) + "&body=" + encodeURIComponent(window.getSelection())
                bind qet composite js javascript:location.href="org-protocol:///capture?template=et&url=" + encodeURIComponent(location.href) + "&title=" + encodeURIComponent(document.title) + "&body=" + encodeURIComponent(window.getSelection())
                bind qec composite js javascript:location.href="org-protocol:///capture?template=ec&url=" + encodeURIComponent(location.href) + "&title=" + encodeURIComponent(document.title) + "&body=" + encodeURIComponent(window.getSelection())
                bind qxt composite js javascript:location.href="org-protocol:///capture?template=xt&url=" + encodeURIComponent(location.href) + "&title=" + encodeURIComponent(document.title) + "&body=" + encodeURIComponent(window.getSelection())
                bind qxc composite js javascript:location.href="org-protocol:///capture?template=xc&url=" + encodeURIComponent(location.href) + "&title=" + encodeURIComponent(document.title) + "&body=" + encodeURIComponent(window.getSelection())
                bind qd composite js javascript:location.href="org-protocol:///capture?template=d&url=" + encodeURIComponent(location.href) + "&title=" + encodeURIComponent(document.title) + "&body=" + encodeURIComponent(window.getSelection())
                bind qjt composite js javascript:location.href="org-protocol:///capture?template=jt&url=" + encodeURIComponent(location.href) + "&title=" + encodeURIComponent(document.title) + "&body=" + encodeURIComponent(window.getSelection())
                bind qjc composite js javascript:location.href="org-protocol:///capture?template=jc&url=" + encodeURIComponent(location.href) + "&title=" + encodeURIComponent(document.title) + "&body=" + encodeURIComponent(window.getSelection())
                bind qjr composite js javascript:location.href="org-protocol:///capture?template=jr&url=" + encodeURIComponent(location.href) + "&title=" + encodeURIComponent(document.title) + "&body=" + encodeURIComponent(window.getSelection())
                bind qm composite js javascript:location.href="org-protocol:///capture?template=m&url=" + encodeURIComponent(location.href) + "&title=" + encodeURIComponent(document.title) + "&body=" + encodeURIComponent(window.getSelection())

                "
                " Misc settings
                "

                " set editorcmd to suckless terminal, or use the defaults on other platforms
                js tri.browserBg.runtime.getPlatformInfo().then(os=>{const editorcmd = os.os=="linux" ? "emacsclient" : "auto"; tri.config.set("editorcmd", editorcmd)})

                " Sane hinting mode
                set hintfiltermode vimperator-reflow
                set hintchars 4327895610
                set hintuppercase false
                set hintnames numeric

                set tabopenpos last

                set yankto both
                set putfrom clipboard

                " Make Tridactyl work on more sites at the expense of some security
                set csp clobber
                fixamo_quiet

                " Make quickmarks for the sane Tridactyl issue view
                quickmark T https://github.com/cmcaine/tridactyl/issues?utf8=%E2%9C%93&q=sort%3Aupdated-desc+
                quickmark t https://github.com/tridactyl/tridactyl

                "
                " URL redirects
                "

                " Map keys between layouts
                keymap ё `
                keymap й q
                keymap ц w
                keymap у e
                keymap к r
                keymap е t
                keymap н y
                keymap г u
                keymap ш i
                keymap щ o
                keymap з p
                keymap х [
                keymap ъ ]
                keymap ф a
                keymap ы s
                keymap в d
                keymap а f
                keymap п g
                keymap р h
                keymap о j
                keymap л k
                keymap д l
                keymap ж ;
                keymap э '
                keymap я z
                keymap ч x
                keymap с c
                keymap м v
                keymap и b
                keymap т n
                keymap ь m
                keymap б ,
                keymap ю .
                keymap Ё ~
                keymap Й Q
                keymap Ц W
                keymap У E
                keymap К R
                keymap Е T
                keymap Н Y
                keymap Г U
                keymap Ш I
                keymap Щ O
                keymap З P
                keymap Х {
                keymap Ъ }
                keymap Ф A
                keymap Ы S
                keymap В D
                keymap А F
                keymap П G
                keymap Р H
                keymap О J
                keymap Л K
                keymap Д L
                keymap Ж :
                keymap Э "
                keymap Я Z
                keymap Ч X
                keymap С C
                keymap М V
                keymap И B
                keymap Т N
                keymap Ь M
                keymap Б <
                keymap Ю >

                keymap <C-х> <C-[>
                keymap пш gi
                keymap пп gg
                keymap нн yy
                keymap нс yc

                keymap . /
            '';
        };
    };
}