RUSSIAN = 'йцукенгшщзхъфывапролджэячсмитьбю.'
ENGLISH = 'qwertyuiop[]asdfghjkl;\'zxcvbnm,./'

c.bindings.key_mappings = {
    **{r: e for r, e in zip(RUSSIAN, ENGLISH)},
    **{r.upper(): e.upper() for r, e in zip(RUSSIAN, ENGLISH)}
}

config.bind('xb', 'config-cycle statusbar.hide')

# config.bind('e', 'open-editor') # TODO: bind appropriately
config.bind("<Alt-,>", "back")
config.bind("<Alt-.>", "forward")
config.bind("<ctrl+shift+tab>", "tab-prev")
config.bind("<ctrl+tab>", "tab-next")
config.bind("b", "set-cmd-text -s :buffer")
config.bind("t", "set-cmd-text -s :open -t")
config.bind('<Ctrl-F5>', 'reload -f')
config.bind('<Ctrl-Return>', 'follow-selected -t')
config.bind('<Ctrl-Shift-T>', 'undo')
config.bind('<Ctrl-W>', 'tab-close')
config.bind('<Ctrl-g>', 'stop')
config.bind('<Ctrl-p>', 'tab-pin')
config.bind('<F12>', 'inspector')
config.bind('<F5>', 'reload')
config.bind('<Return>', 'follow-selected')
config.bind('Ctrl-r', 'reload')
config.bind('Sh', 'open qute://history')
config.bind('ct', 'open -t -- {clipboard}')
config.bind('cw', 'open -w -- {clipboard}')
config.bind('d', 'tab-close')
config.bind('g$', 'tab-focus last')
config.bind('g0', 'tab-focus 1')
config.bind('gc', 'tab-clone')
config.bind('gj', 'tab-move +')
config.bind('gk', 'tab-move -')
config.bind('go', 'spawn ${pkgs.chromium}/bin/chromium {url}')
config.bind('gs', 'view-source')
config.bind('gw', 'set-cmd-text -s :tab-give')
config.bind('pt', 'open -t -- {primary}')
config.bind('pw', 'open -w -- {primary}')

config.bind("yy", "yank")
config.bind('yd', 'yank domain')
config.bind('ym', 'spawn mpv {url}')
config.bind('yo', 'yank inline [[{url}][{title}]]')
config.bind('yp', 'yank pretty-url')
config.bind('yt', 'yank title')
config.bind('y;', 'spawn org-capture -u "{url}" -t "{title}" -e title')
config.bind("y'", 'spawn org-capture -u "{url}" -t "{title}" -b "{primary}" -e title')

config.bind(';;', 'hint links download')
config.bind(';I', 'hint images tab')
config.bind(';O', 'hint links fill :open -t -r {hint-url}')
config.bind(';R', 'hint --rapid links window')
config.bind(';b', 'hint all tab-bg')
config.bind(';d', 'hint links download')
config.bind(';f', 'hint all tab-fg')
config.bind(';h', 'hint all hover')
config.bind(';i', 'hint images')
config.bind(';c', 'hint images spawn yank-image {hint-url}')
config.bind(';o', 'hint links fill :open {hint-url}')
config.bind(';r', 'hint --rapid links tab-bg')
config.bind(';t', 'hint inputs')
config.bind(';v', 'hint links spawn --detach mpv --ytdl-format="bestvideo[height<=1000][vcodec!=vp9]+bestaudio/best" --force-window yes {hint-url}')
config.bind(';y', 'hint links yank')

config.bind('ad', 'download-cancel')
config.bind('cd', 'download-clear')
config.bind('gd', 'download')

config.bind('<Ctrl-y>', 'insert-text -- {clipboard}', mode='insert')
config.bind('<Ctrl-y>', 'insert-text {clipboard}', mode='insert')
config.bind('<Shift-y>', 'insert-text -- {primary}', mode='insert')
config.bind('<Shift-y>', 'insert-text {primary}', mode='insert')
config.bind('i', 'enter-mode insert')

# TODO: review and rework pass setup
config.bind(',P', 'spawn --userscript qute-pass --dmenu-invocation dmenu --password-only')
config.bind(',p', 'spawn --userscript qute-pass --dmenu-invocation dmenu')
config.bind('<z><l>', 'spawn --userscript qute-pass --username-target secret --username-pattern "^Username: (.+)$"')
config.bind('<z><l>', 'spawn --userscript qute-pass')
config.bind('<z><p><l>', 'spawn --userscript qute-pass --password-only --username-target secret --username-pattern "^Username: (.+)$"')
config.bind('<z><p><l>', 'spawn --userscript qute-pass --password-only')
config.bind('<z><u><l>', 'spawn --userscript qute-pass --username-only --username-target secret --username-pattern "^Username: (.+)$"')
config.bind('<z><u><l>', 'spawn --userscript qute-pass --username-only')

config.bind('@', 'run-macro')
config.bind('AD', 'adblock-update')
config.bind('CH', 'history-clear')

config.bind('cr', 'config-source')
config.bind('sf', 'save')
config.bind('ws', 'config-write-py --force --defaults config.current.py')