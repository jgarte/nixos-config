(use-package eldoc
  :delight eldoc-mode
  :hook ((emacs-lisp-mode-hook lisp-interaction-mode-hook ielm-mode-hook) . turn-on-eldoc-mode)
  :custom
  (eldoc-idle-delay 0))

(use-package c-eldoc
  :ensure t
  :after (eldoc)
  :hook ((c-mode-hook c++-mode-hook) . c-turn-on-eldoc-mode))

(use-package eldoc-eval
  :ensure t
  :after (eldoc))

;;TODO: extend setup
(use-package compile)
(use-package multi-compile :ensure t)

(use-package prog-fill
  :ensure t
  :general
  (:keymaps 'prog-mode-map
            "M-q" 'prog-fill))

(use-package diff-mode
  :mode ("diff" . diff-mode))

(use-package lsp-mode
  :ensure t
  :hook (lsp-after-open-hook . lsp-enable-imenu)
  :custom
  (lsp-message-project-root-warning t)
  (lsp-inhibit-message t)
  (lsp-prefer-flymake nil)
  :config
  (use-package lsp-clients))

(use-package lsp-ui
  :ensure t
  :after (lsp-mode)
  :hook (lsp-mode-hook . lsp-ui-mode)
  :general
  (:keymaps 'lsp-ui-mode-map
            [remap xref-find-definitions] 'lsp-ui-peek-find-definitions
            [remap xref-find-references] 'lsp-ui-peek-find-references)
  (:keymaps 'mode-specific-map
            "R" 'lsp-restart-workspace))

(use-package company-lsp
  :ensure t
  :custom
  (company-lsp-cache-candidates 'auto)
  (company-lsp-async t)
  (company-lsp-enable-recompletion t)
  :config
  (push 'company-lsp company-backends))

(use-package magit
  :ensure t
  :after (async dash with-editor git-commit magit-popup)
  :commands magit-status magit-blame
  :mode (("COMMIT_EDITMSG" . conf-javaprop-mode)
         ("COMMIT" . git-commit-mode))
  :general
  (:prefix "C-'"
           "s" 'magit-status
           "f" 'magit-log-buffer-file
           "c" 'magit-checkout
           "w" 'magit-diff-working-tree
           "r" 'magit-reflog
           "b" 'magit-blame-addition
           "B" 'magit-branch-manager
           "l" 'magit-log
           "l" 'open-global-repos-list)
  (:keymaps 'magit-status-mode-map
            "E" 'magit-rebase-interactive
            "q" 'custom/magit-kill-buffers)
  :preface
  (defun open-global-repos-list ()
    (interactive)
    (let ((repos-buffer (get-buffer "*Magit Repositories*")))
      (if repos-buffer
          (switch-to-buffer repos-buffer)
        (magit-list-repositories))))
  (defun custom/magit-restore-window-configuration (&optional kill-buffer)
    "Bury or kill the current buffer and restore previous window configuration."
    (let ((winconf magit-previous-window-configuration)
          (buffer (current-buffer))
          (frame (selected-frame)))
      (quit-window kill-buffer (selected-window))
      (when (and winconf (equal frame (window-configuration-frame winconf)))
        (set-window-configuration winconf)
        (when (buffer-live-p buffer)
          (with-current-buffer buffer
            (setq magit-previous-window-configuration nil))))))
  (defun custom/magit-kill-buffers ()
    "Restore window configuration and kill all Magit buffers."
    (interactive)
    (let ((buffers (magit-mode-get-buffers)))
      (magit-restore-window-configuration)
      (mapc #'kill-buffer buffers)))
  :custom
  (magit-completing-read-function 'ivy-completing-read)
  (magit-blame-heading-format "%H %-20a %C %s")
  (magit-diff-refine-hunk t)
  (magit-display-buffer-function 'magit-display-buffer-fullframe-status-topleft-v1)
  (magit-repository-directories private/magit-repositories)
  :config
  (use-package magit-filenotify
    :ensure t
    :delight (magit-filenotify-mode " FN")
    :after magit
    :hook (magit-status-mode-hook . (lambda ()
                                      (condition-case nil
                                          (magit-filenotify-mode)
                                        (error (magit-filenotify-mode -1))))))
  (use-package vdiff-magit
    :ensure t
    :general
    (:keymaps 'magit-mode-map
              "d" 'vdiff-magit-dwim
              "p" 'vdiff-magit-popup)
    :config
    (setcdr (assoc ?e (plist-get magit-dispatch-popup :actions))
            '("vdiff dwim" 'vdiff-magit-dwim))
    (setcdr (assoc ?E (plist-get magit-dispatch-popup :actions))
            '("vdiff popup" 'vdiff-magit-popup))))

(use-package magithub
  :disabled
  :ensure t
  :after (magit)
  :custom
  (magithub-clone-default-directory (at-workspace-dir "foss"))
  :config
  (magithub-feature-autoinject t))

(use-package git-timemachine
  :ensure t
  :after (ivy)
  :demand t
  :preface
  ;; credits to @binchen
  (defun custom/git-timemachine-show-selected-revision ()
    "Show last (current) revision of file."
    (interactive)
    (let* ((collection (mapcar (lambda (rev)
                                 ;; re-shape list for the ivy-read
                                 (cons (concat (substring-no-properties (nth 0 rev) 0 7) "|" (nth 5 rev) "|" (nth 6 rev)) rev))
                               (git-timemachine--revisions))))
      (ivy-read "commits:"
                collection
                :action (lambda (rev)
                          ;; compatible with ivy 9+ and ivy 8
                          (unless (string-match-p "^[a-z0-9]*$" (car rev))
                            (setq rev (cdr rev)))
                          (git-timemachine-show-revision rev))
                :unwind (lambda () (if (not (eq last-command-event 13))
                                       (git-timemachine-quit))))))
  (defun custom/git-timemachine ()
    "Open git snapshot with the selected version.  Based on ivy-mode."
    (interactive)
    (git-timemachine--start #'custom/git-timemachine-show-selected-revision))
  :general
  (:keymaps 'mode-specific-map
            ";" 'custom/git-timemachine))

(use-package diff-hl
  :ensure t
  :hook
  (magit-post-refresh-hook . diff-hl-magit-post-refresh)
  (dired-mode-hook . diff-hl-dired-mode)
  :config
  (diff-hl-margin-mode 1)
  (diff-hl-amend-mode 1)
  (diff-hl-flydiff-mode 1)
  (global-diff-hl-mode 1))

(use-package git-msg-prefix
  :ensure t
  :general
  (:keymaps 'git-commit-mode-map
            "C-c i" 'commit-msg-prefix)
  :custom
  (git-msg-prefix-log-flags " --since='1 week ago' ")
  (commit-msg-prefix-input-method 'ivy-read))

(use-package browse-at-remote
  :ensure t
  :general
  (:keymaps 'mode-specific-map
            "g g" 'browse-at-remote)
  (:keymaps 'magit-status-mode-map
            "o" 'browse-at-remote)
  :custom
  (browse-at-remote-prefer-symbolic nil))

(use-package smerge-mode
  :delight (smerge-mode "∓")
  :general
  (:keymaps 'mode-specific-map
            "g k" 'smerge-prev
            "g j" 'smerge-next)
  (:keymaps 'local
            :predicate '(bound-and-true-p smerge-mode)
            "n" 'smerge-next
            "p" 'smerge-prev
            "b" 'smerge-keep-base
            "u" 'smerge-keep-upper
            "l" 'smerge-keep-lower
            "a" 'smerge-keep-all
            "RET" 'smerge-keep-current
            "C-m" 'smerge-keep-current
            "<" 'smerge-diff-base-upper
            "=" 'smerge-diff-upper-lower
            ">" 'smerge-diff-base-lower
            "R" 'smerge-refine
            "E" 'smerge-ediff
            "C" 'smerge-combine-with-next
            "r" 'smerge-resolve
            "k" 'smerge-kill-current
            "ZZ" '(lambda ()
                    (interactive)
                    (save-buffer)
                    (bury-buffer)))
  :hook (find-file-hooks . (lambda ()
                             (save-excursion
                               (goto-char (point-min))
                               (when (re-search-forward "^<<<<<<< " nil t)
                                 (smerge-mode 1))))))

(use-package edebug-x :ensure t)

(use-package elisp-slime-nav
  :delight elisp-slime-nav-mode
  :ensure t
  :hook ((emacs-lisp-mode-hook ielm-mode-hook) . elisp-slime-nav-mode))

(use-package elisp-mode
  :hook ((emacs-lisp-mode-hook . (lambda ()
                                   (auto-fill-mode 1)
                                   (setq indent-tabs-mode nil)
                                   (setq comment-start ";;")
                                   (turn-on-eldoc-mode)))))

(use-package company-elisp
  :after (elisp-mode company)
  :config
  (add-to-list 'company-backends 'company-elisp))

(add-hook 'eval-expression-minibuffer-setup-hook #'eldoc-mode)
(add-hook 'eval-expression-minibuffer-setup-hook #'eldoc-mode)

(dolist (mode '(paredit-mode smartparens-mode))
  (when (fboundp mode)
    (add-hook 'eval-expression-minibuffer-setup-hook mode)))

(use-package slime
  :ensure t
  :pin melpa-stable ;; corresponds to quicklisp version
  :hook ((lisp-mode-hook . (lambda ()
                             (slime-mode t)
                             (set (make-local-variable 'slime-lisp-implementations)
                                  (list (assoc 'sbcl slime-lisp-implementations)))))
         (inferior-lisp-mode-hook . inferior-slime-mode)
         (slime-mode-hook . (lambda () (when (> emacs-major-version 25)
                                         (slime-autodoc-mode -1)))) ;; some signature down the call stack is broken in 2.20
         (lisp-mode-hook . (lambda ()
                             (auto-fill-mode 1)
                             (setq indent-tabs-mode nil))))
  :init
  (use-package slime-autoloads)
  :custom
  (slime-complete-symbol*-fancy t)
  (slime-complete-symbol-function 'slime-fuzzy-complete-symbol)
  (slime-net-coding-system 'utf-8-unix)
  :config
  (defadvice slime-documentation-lookup
      (around change-browse-url-browser-function activate)
    "Use w3m for slime documentation lookup."
    (let ((browse-url-browser-function 'w3m-browse-url))
      ad-do-it))
  (slime-setup
   '(slime-fancy-inspector slime-fancy-trace slime-fontifying-fu
     slime-hyperdoc slime-package-fu slime-references slime-trace-dialog
     slime-xref-browser slime-asdf slime-autodoc slime-banner slime-fancy
     slime-fuzzy slime-repl slime-sbcl-exts))
  (add-to-list 'slime-lisp-implementations '(sbcl ("sbcl")  :coding-system utf-8-unix)))

;;TODO: check if there is any conflict inconsistency between slime-builtin/company completion
(use-package slime-company
  :ensure t
  :after (slime company))

(use-package inf-lisp
  :config
  (setq inferior-lisp-program "sbcl"))

(use-package common-lisp-snippets
  :ensure t
  :after (yasnippet))

(use-package python
  :mode ("\\.py$" . python-mode)
  :hook
  (python-mode-hook . (lambda ()
                        (setq indent-tabs-mode nil)
                        (setq tab-width 4)
                        (setq imenu-create-index-function 'imenu-default-create-index-function)
                        (auto-fill-mode 1)))
  ;; Highlight the call to ipdb, src http://pedrokroger.com/2010/07/configuring-emacs-as-a-python-ide-2/
  (python-mode-hook . (lambda ()
                        (highlight-lines-matching-regexp "import ipdb")
                        (highlight-lines-matching-regexp "ipdb.set_trace()")
                        (highlight-lines-matching-regexp "import wdb")
                        (highlight-lines-matching-regexp "wdb.set_trace()")))
  (python-mode-hook . lsp)
  (python-mode-hook . flycheck-mode)
  :general
  (:keymaps 'python-mode-map
            "M-_" 'python-indent-shift-left
            "M-+" 'python-indent-shift-right)
  :config
  (add-function :before-until (local 'eldoc-documentation-function)
                #'(lambda () "")))

(use-package py-yapf :ensure t)

(use-package pyvenv
  :ensure t
  :after (projectile dash)
  :init
  (defun custom/switch-python-project-context ()
    (let ((project-root (projectile-project-root)))
      (when (-non-nil (mapcar (lambda (variant) (file-exists-p (concat project-root variant)))
                              '("requirements.pip" "requirements.txt")))
        (pyvenv-deactivate)
        (pyvenv-activate (format "%s/%s"
                                 (pyvenv-workon-home)
                                 (file-name-base
                                  (directory-file-name
                                   project-root)))))))
  :config
  (pyvenv-mode 1)
  :hook ((projectile-after-switch-project-hook . custom/switch-python-project-context)
         (python-mode . custom/switch-python-project-context)))

(use-package pip-requirements
  :ensure t
  :delight (pip-requirements-mode "PyPA Requirements")
  :preface
  (defun custom/pip-requirements-ignore-case ()
    (setq-local completion-ignore-case t))
  :mode ("requirements\\." . pip-requirements-mode)
  :hook (pip-requirements-mode . custom/pip-requirements-ignore-case))

;; * isort
;; * incorrect flake8 config (excludes)
;; * check/add W0512
;; * check epc/importmagic work
;; * actualize py-isort setup
;; * review pylint setup

;;TODO: some harness either here or withoin shell to automate the burden of setting up new golang project's boilerplate

(use-package go-mode
  :ensure t
  :no-require t
  :after (multi-compile)
  :mode ("\\.go$" . go-mode)
  :hook (before-save-hook . gofmt-before-save)
  :general
  (:keymaps 'go-mode-map
            "C-c C-c" 'multi-compile-run
            "M-." 'godef-jump
            "M-," 'pop-tag-mark)
  :config
  (use-package godoctor :ensure t)
  (setq  gofmt-command "goimports")
  (add-to-list 'multi-compile-alist
               '(go-mode . (("go-build/git" "go build -v"
                             (locate-dominating-file buffer-file-name ".git")) ;;TODO: try to guess binary name from project name (investigate how this refers to libraries builds, etc.)
                            ("go-build/main" "go build -v"
                             (locate-dominating-file buffer-file-name "main.go"))
                            ("go-build-and-run/git" "go build -v && echo '########## build finished ##########' && eval ./${PWD##*/}"
                             (multi-compile-locate-file-dir ".git"))
                            ("go-build-and-run/main" "go build -v && echo '########## build finished ##########' && eval ./${PWD##*/}"
                             (multi-compile-locate-file-dir "main.go"))))))

(use-package company-go
  :ensure t
  :after (go-mode company)
  :config
  (add-to-list 'company-backends 'company-go))

(use-package go-guru
  :ensure t
  :hook (go-mode-hook . go-guru-hl-identifier-mode))

(use-package flycheck-gometalinter
  :ensure t
  :custom
  ;; only run fast linters
  (flycheck-gometalinter-fast t)
  ;; use in tests files
  (flycheck-gometalinter-test t)
  (flycheck-gometalinter-deadline "10s")
  ;; gometalinter: skips 'vendor' directories and sets GO15VENDOREXPERIMENT=1
  (flycheck-gometalinter-vendor t)
  ;; gometalinter: only enable selected linters
  (flycheck-gometalinter-disable-all t)
  (flycheck-gometalinter-enable-linters
   '("golint" "vet" "vetshadow" "golint" "ineffassign" "goconst" "errcheck" "deadcode"))
  :config
  (flycheck-gometalinter-setup))

(use-package go-eldoc
  :ensure t
  :hook (go-mode-hook . go-eldoc-setup))

(use-package gotest
  :ensure t
  :after (go-mode)
  :general
  (:keymaps 'go-mode-map
            "C-c C-x f" 'go-test-current-file
            "C-c C-x t" 'go-test-current-test
            "C-c C-x p" 'go-test-current-project
            "C-c C-x T" 'go-test-current-benchmark
            "C-c C-x F" 'go-test-current-file-benchmarks
            "C-c C-x P" 'go-test-current-project-benchmarks
            "C-c C-x x" 'go-run))

(use-package go-tag
  :ensure t
  :no-require t
  :after (go-mode)
  :general
  (:keymaps 'go-mode-map
            "C-c t" 'go-tag-add
            "C-c T" 'go-tag-remove)
  :custom
  (go-tag-args '("-transform" "camelcase")))

(use-package go-playground
  :ensure t
  :after (go-mode))

(use-package gorepl-mode
  :ensure t
  :hook (go-mode-hook . gorepl-mode))

;; try to integrate https://getgb.io/

(use-package lua-mode
  :ensure t
  :preface
  (defun lua-broken-indentation-fix ()
    (save-excursion
      (lua-forward-line-skip-blanks 'back)
      (let* ((current-indentation (current-indentation))
             (line (thing-at-point 'line t))
             (busted-p (s-matches?
                        (rx (+ bol (* space)
                               (or "context" "describe" "it" "setup" "teardown")
                               "("))
                        line)))
        (when busted-p
          (+ current-indentation lua-indent-level)))))
  (defun rgc-lua-calculate-indentation-override (old-function &rest arguments)
    (or (lua-broken-indentation-fix)
        (apply old-function arguments)))
  :mode ("\\.lua$" . lua-mode)
  :hook (lua-mode-hook . (lambda ()
                           (setq flycheck-checker 'lua-luacheck)))
  :config
  (advice-add #'lua-calculate-indentation-override
              :around #'rgc-lua-calculate-indentation-override))

(use-package company-lua
  :ensure t
  :after (lua-mode company))

(use-package nix-mode
  :ensure t
  :mode (("\\.nix$" . nix-mode)
         ((rx (eval "configuration.nix") (zero-or-more anything) eol) . nix-mode)))

(use-package company-nixos-options
  :ensure t
  :disabled
  :config
  (add-to-list 'company-backends 'company-nixos-options))

(use-package rustic
  :ensure t
  :hook (rust-mode-hook . lsp)
  :custom (rustic-rls-pkg 'lsp-mode)
  :mode ("\\.rs" . rustic-mode))

(use-package clojure-mode
  :defer t
  :config
  (define-clojure-indent
    (alet 'defun)
    (mlet 'defun)))

(use-package clojure-snippets
  :defer t)

(use-package cider
  :defer t
  ;; :custom
  ;; (cider-repl-display-help-banner nil)
  :config
  ;; sadly, we can't use :diminish keyword here, yet
  (diminish 'cider-mode
            '(:eval (format " 🍏%s" (cider--modeline-info)))))

(use-package kibit-helper
  :disabled ;;TODO: setup kibit first
  :defer t)

(use-package ccls
  :ensure t
  :after (lsp-mode)
  :hook ((c-mode-hook c++-mode-hook objc-mode-hook) . (lambda () (require 'ccls) (lsp)))
  :custom
  (ccls-executable "/run/current-system/sw/bin/ccls")
  :config
  (setq-default flycheck-disabled-checkers '(c/c++-clang c/c++-cppcheck c/c++-gcc)))

(use-package emmet-mode
  :ensure t
  :delight emmet-mode
  :commands emmet-mode
  :general
  (:keymaps 'emmet-mode-keymap
            "C-j" nil
            "<C-return>" nil
            "C-c C-j" 'emmet-expand-line)
  :hook ((sgml-mode-hook nxml-mode-hook django-mode sgml-mode-hook css-mode-hook) . emmet-mode)
  :custom
  (emmet-move-cursor-between-quotes t)
  (emmet-indentation 2))

(use-package company-ansible
  :ensure t
  :after (company)
  :config
  (add-to-list 'company-backends 'company-ansible))

(use-package poly-ansible
  :ensure t)

(use-package docker
  :ensure t
  :after (dash docker-tramp s tablist json-mode)
  :delight docker-mode
  :custom
  (docker-containers-show-all t)
  :config
  ;;TODO: bind keys
  ;;FIXME: epkgs.docker is something another then the original - investigate this
  (docker-global-mode 1))

(use-package regex-tool
  :ensure t
  :commands regex-tool
  :custom
  (regex-tool-backend 'perl))

(use-package xr
  :ensure t)

(use-package fic-mode :ensure t)

;; *** try 3rdparty packages
;; **** https://github.com/nsf/gocode
;; **** https://github.com/sebastiw/distel-completion
;; **** https://github.com/iquiw/company-ghc
;; **** https://github.com/iquiw/company-cabal
;; **** https://github.com/iquiw/company-restclient
;; **** https://github.com/Valloric/ycmd + https://github.com/abingham/emacs-ycmd

;; *** BACKLOG [#A] find some way (maybe smth like spacemacs dashboard) to represent the states of repos from some list (either hardcoded or created dynamically), with unstaged/unpushed/whatever_useful info displayed