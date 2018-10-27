{config, pkgs, lib, ...}:

# TODO: https://github.com/rycee/home-manager/blob/master/modules/xresources.nix
{
    home-manager.users.alex3rd = {
        home.file = {
            ".Xresources".text = ''
                ! -*-	mode: conf-xdefaults;	-*-

                ! TODO: provide host-dependent setup part + automate

                ! TODO: play with non-XFT/non-mono fonts

                #define FG_BASE #000000
                #define BG_BASE #FFFAFA

                !black
                xterm*color0: #353535
                xterm*color8: #666666
                !red
                xterm*color1: #AE4747
                xterm*color9: #EE6363
                !green
                xterm*color2: #556B2F
                xterm*color10: #9ACD32
                !brown/yellow
                xterm*color3: #DAA520
                xterm*color11: #FFC125
                !blue
                xterm*color4: #6F99B4
                xterm*color12: #7C96B0
                !magenta
                xterm*color5: #8B7B8B
                xterm*color13: #D8BFD8
                !cyan
                xterm*color6: #A7A15E
                xterm*color14: #F0E68C
                !white
                xterm*color7: #DDDDDD
                xterm*color15: #FFFFFF

                dzen2.font: Iosevka:weight=Bold:size=16

                Xmessage*faceName: Iosevka
                Xmessage*faceWeight: bold
                Xmessage*faceSize: 16

                Xmessage*background:            #3c3c3c
                Xmessage*foreground:            #c2c2c2
                Xmessage*form.*.shapeStyle:     rectangle
                Xmessage*Scrollbar.width:       1
                Xmessage*Scrollbar.borderWidth: 0
                Xmessage*Buttons:               Quit
                Xmessage*defaultButton:         Quit
                Xmessage*international:         true
                #ifndef XFTMONOFONT
                  #define XFTMONOFONT Iosevka:weight=Bold:size=14
                #endif

                !Emacs*useXIM:false
                Emacs.FontBackend: xft,x
                Emacs*XlwMenu.font: XFTMONOFONT
                Emacs.dialog*.font: XFTMONOFONT
                Emacs*Paned*XlwMenu.background: gray90
                Emacs*Paned*XlwMenu.foreground: black
                Emacs.fullscreen: maximized
                Emacs.Font: XFTMONOFONT
                Emacs.menuBar: 0
                Emacs.toolBar: 0
                Emacs.verticalScrollBars: off
                URxvt.depth: 32
                URxvt.font: xft:Iosevka:weight=Bold:size=12
                URxvt.geometry: 80x27
                URxvt.lineSpace: 0
                URxvt.letterSpace: -1
                URxvt*foreground: #f6f0e8
                ! URxvt*foreground: #dcdccc
                URxvt*background: #1A1A1A
                ! URxvt*background: rgba:3f00/3f00/3f00/dddd
                URxvt.fading: 40
                URxvt.shading: 100
                URxvt.transparent: false
                URxvt.fadeColor: #666666
                URxvt.tintColor: #354040
                urgentOnBell: True
                visualBell: True
                ! URxvt*saveLines: 65535
                ! URxvt.scrollstyle: plain
                URxvt.scrollBar: false
                ! do not scroll with output
                URxvt*scrollTtyOutput: false
                ! scroll in relation to buffer (with mouse scroll or Shift+Page Up)
                URxvt*scrollWithBuffer: true
                ! scroll back to the bottom on keypress
                URxvt*scrollTtyKeypress: true
                URxvt*secondaryScreen: 1
                URxvt*secondaryScroll: 0

                URxvt.loginShell: True

                URxvt.cursorBlink: false
                URxvt.borderless: true
                URxvt.internalBorder: 3
                URxvt.externalBorder: 3

                Urxvt*perl-lib: /usr/lib/urxvt/perl/
                URxvt.perl-ext-common:clipboard,default,font-size,fullscreen,keyboard-select,matcher,selection,url-select

                URxvt.matcher.button: 1
                ! russian utf-8
                URxvt.matcher.pattern.0:  (?:https?:\\/\\/|ftp:\\/\\/|news:\\/\\/|mailto:|file:\\/\\/|\\bwww\\.)\n\
                                           [a-zA-Z0-9\\x{0410}-\\x{044F}\\-\\@;\\/?:&=%\\$_.+!*\\x27,~#]*\n\
                                           (\n\
                                             \\([a-zA-Z0-9\\x{0410}-\\x{044F}\\-\\@;\\/?:&=%\\$_.+!*\\x27,~#]*\\)| # Allow a pair of matched parentheses\n\
                                             [a-zA-Z0-9\\x{0410}-\\x{044F}\\-\\@;\\/?:&=%\\$_+*~]  # exclude some trailing characters (heuristic)\n\
                                           )+

                URxvt.keysym.C-Delete: perl:matcher:last
                URxvt.keysym.M-Delete: perl:matcher:list
                URxvt.keysym.M-u: perl:url-select:select_next
                URxvt.keysym.M-w: perl:clipboard:copy
                URxvt.keysym.C-y: perl:clipboard:paste
                URxvt.keysym.F11: perl:fullscreen:switch
                URxvt.keysym.M-z: perl:fullscreen:switch
                URxvt.keysym.M-Esc: perl:keyboard-select:activate
                URxvt.keysym.M-Escape: perl:keyboard-select:activate
                URxvt.keysym.M-Plus: perl:font-size:increase
                URxvt.keysym.M-Minus: perl:font-size:decrease
                URxvt.keysym.M-/: perl:keyboard-select:search
                URxvt.keysym.C-equal: perl:font-size:incglobal
                URxvt.keysym.C-minus: perl:font-size:decglobal
                URxvt.keysym.M-k: command:\033]720;8\007
                URxvt.keysym.M-j: command:\033]721;8\007

                URxvt.url-select.launcher: firefox -new-tab
                URxvt.url-select.underline: true

                URxvt.underlineURLs: true

                URxvt*colorUL: #c5f779
                URxvt*underlineColor: #c5f779

                ! URxvt.inheritPixmap: true

                URxvt*color0: #3f3f3f
                URxvt*color1: #705050
                URxvt*color2: #60b48a
                URxvt*color3: #dfaf8f
                URxvt*color4: #506070
                URxvt*color5: #dc8cc3
                URxvt*color6: #8cd0d3
                URxvt*color7: #DCDCCC

                URxvt*color8: #709080
                URxvt*color9: #cc9393
                URxvt*color10: #7f9f7f
                URxvt*color11: #f0dfaf
                URxvt*color12: #94bff3
                URxvt*color13: #ec93d3
                URxvt*color14: #93e0e3
                URxvt*color15: #ffffff
                !! Fonts settings
                ! http://www.freedesktop.org/wiki/ScreenFontSettings
                ! Settings read by both Cairo and libXft:
                Xft.antialias: true       ! Xft.antialias:  (bool)   // FC_ANTIALIAS  Whether glyphs can be antialiased
                Xft.dpi: 120.0            ! Xft.dpi:        (double) // FC_DPI        Target dots per inch
                Xft.hinting: true         ! Xft.hinting:    (bool)   // FC_HINTING    Whether the rasterizer should use hinting
                ! Xft.hintstyle: hintnone   ! Xft.hintstyle:  (int)    // FC_HINT_STYLE Automatic hinting style - hintnone hintslight hintmedium hintfull
                Xft.hintstyle: hintslight
                Xft.rgba: none            ! Xft.rgba:       (int)    // FC_RGBA       unknown, rgb, bgr, vrgb, vbgr, none - subpixel geometry
                Xft.lcdfilter: lcddefault ! Xft.lcdfilter   (int)    // FC_LCD_FILTER type of lcd filter to use - lcdnone lcddefault lcdlight lcdlegacy
                ! Settings specific to libXft:
                ! Xft.scale (double) // FC_SCALE
                ! Xft.render (bool) // XFT_RENDER
                ! Xft.embolden (bool) // FC_EMBOLDEN true if emboldening needed
                Xft.autohint: false ! Xft.autohint (bool) // FC_AUTOHINT Use autohinter instead of normal hinter
                ! Xft.minspace (bool) // FC_MINSPACE use minimum line spacing
                ! Xft.maxglyphmemory (int) // XFT_MAX_GLYPH_MEMORY

                ! These ones seem to be unused?
                ! Xft.core (bool) //  XFT_CORE
                ! Xft.xlft (string) // XFT_XLFD
            '';
        };
    };
}
