(use-package iqa
  :ensure t
  :init
  (setq iqa-user-init-file (concat user-emacs-directory "init.el"))
  :config
  (iqa-setup-default))

(use-package restart-emacs
  :ensure t
  :config
  (global-set-key (kbd "C-x C-c") 'restart-emacs))

(use-package bug-hunter :disabled)

(use-package no-littering
  :ensure t
  :custom
  (no-littering-var-directory (expand-file-name "data/" user-emacs-directory)))

(use-package subr-x)

(setq home-directory (getenv "HOME"))
(setq config-basedir
      (file-name-directory
       (or (buffer-file-name) load-file-name)))

(defun concat-normalize-slashes (prefix suffix)
  (concat "/"
          (string-join
           (split-string
            (string-join (list prefix suffix) "/") "/" t) "/")))

(defun at-homedir (&optional suffix)
  (concat-normalize-slashes home-directory suffix))

(defun at-org-dir (&optional suffix)
  (concat-normalize-slashes (at-homedir "/docs/org")
                            suffix))

(defun at-org-kb-dir (&optional suffix)
  (concat-normalize-slashes (at-homedir "/docs/org-kb")
                            suffix))

(defun at-config-basedir (&optional suffix)
  (concat-normalize-slashes config-basedir suffix))

(defun at-user-data-dir (&optional suffix)
  (concat-normalize-slashes no-littering-var-directory suffix))

(defun at-workspace-dir (&optional suffix)
  (concat-normalize-slashes (at-homedir "/workspace") suffix))

(defvar enable-experimental-packages nil)

(use-package auto-compile
  :ensure t
  :config
  (auto-compile-on-load-mode 1)
  (auto-compile-on-save-mode 1)
  :custom
  (auto-compile-display-buffer nil)
  (auto-compile-mode-line-counter t))

(use-package f
  :ensure t
  :after (s dash))

(use-package names :ensure t)
(use-package anaphora :ensure t)

(use-package delight :ensure t)

(use-package emacs
  :general
  ("M-\"" 'eval-region)
  ([remap kill-buffer] 'kill-this-buffer)
  :secret "identity.el.gpg"
  :config
  (fset 'yes-or-no-p 'y-or-n-p)
  (setq scalable-fonts-allowed t)
  (setq use-dialog-box nil)
  (setq enable-recursive-minibuffers t)
  ;; don't let the cursor go into minibuffer prompt
  (setq minibuffer-prompt-properties
        '(read-only t point-entered minibuffer-avoid-prompt face minibuffer-prompt))
  (when (eq system-type 'gnu-linux)
    (setq x-alt-keysym 'meta))
  (put 'downcase-region 'disabled nil)
  (put 'erase-buffer 'disabled nil)
  (put 'narrow-to-region 'disabled nil)
  (put 'scroll-left 'disabled nil)
  (put 'scroll-right 'disabled nil)
  (put 'upcase-region 'disabled nil)
  (setq scroll-preserve-screen-position 'always)
  ;; reduce point movement lag, see https://emacs.stackexchange.com/questions/28736/emacs-pointcursor-movement-lag/28746
  (setq auto-window-vscroll nil)
  (setq undo-limit 1000000)
  (advice-add 'undo-auto--last-boundary-amalgamating-number :override #'ignore) ;; https://stackoverflow.com/a/41560712/2112489
  (setq indent-tabs-mode nil)
  (set-default 'indent-tabs-mode nil);; Never insert tabs, !!!DO NOT REMOVE!!!
  (setq-default tab-width 4)
  (setq mark-even-if-inactive nil)
  (setq-default fill-column 200)
  (setq-default indicate-empty-lines t)
  (setq-default truncate-lines t)
  (setq x-stretch-cursor t)
  ;; print symbols
  (setq print-circle t)
  (setq print-gensym t)
  ;; encodings
  (setq locale-coding-system 'utf-8)
  (define-coding-system-alias 'UTF-8 'utf-8)
  (define-coding-system-alias 'utf-8-emacs 'utf-8) ; needed by bbdb...
  (define-coding-system-alias 'utf_8 'utf-8)
  (set-default buffer-file-coding-system 'utf-8-unix)
  (setq sentence-end-double-space nil)
  (setq tab-always-indent t)
  (setq frame-inhibit-implied-resize nil)
  (setq split-width-threshold nil)
  (setq split-height-threshold nil)
  (setq same-window-buffer-names
        '("*Help*")))

(use-package notifications)

(use-package cus-edit
  :hook (kill-emacs-hook . (lambda () (delete-file custom-file)))
  :custom
  (custom-file (at-config-basedir "customizations.el")))

(use-package server
  :defer 2
  :preface
  (defun custom/server-save-edit ()
    (interactive)
    (save-buffer)
    (server-edit))
  (defun custom/save-buffer-clients-on-exit ()
    (interactive)
    (if (and (boundp 'server-buffer-clients) server-buffer-clients)
        (server-save-edit)
      (save-buffers-kill-emacs t)))
  :hook (server-visit-hook . (lambda () (local-set-key (kbd "C-c C-c") 'custom/server-save-edit)))
  :config
  (unless (and (string-equal "root" (getenv "USER"))
               (server-running-p))
    (require 'server)
    (server-start))
  (advice-add 'save-buffers-kill-terminal :before 'custom/save-buffer-clients-on-exit))

(use-package novice
  :config
  (setq disabled-command-function nil))

;; for some reason feature 'files' provided with use-package
;; brings more headache than it deserves, so a little bit of
;; dirty imperative style below (still hope on fixing it later)
(defun custom/untabify-buffer ()
  (when (member major-mode '(haskell-mode
                             emacs-lisp-mode
                             lisp-mode
                             python-mode))
    (untabify (point-min) (point-max))))
(add-hook 'before-save-hook #'delete-trailing-whitespace)
(add-hook 'before-save-hook #'custom/untabify-buffer)
(when (> emacs-major-version 25) (auto-save-visited-mode 1))
(setq require-final-newline t)
(setq enable-local-variables nil)
;; backup settings
(setq auto-save-default nil)
(setq backup-by-copying t)
(setq backup-by-copying-when-linked t)
(setq backup-directory-alist '(("." . "~/.cache/emacs/backups")))
(setq delete-old-versions -1)
(setq kept-new-versions 6)
(setq kept-old-versions 2)
(setq version-control t)
(setq save-abbrevs 'silently)
(global-set-key (kbd "C-x f") 'find-file) ; I never use set-fill-column and I hate hitting it by accident.

(use-package amx
  :ensure t
  :general ("M-x" 'amx)
  :custom
  (amx-backend 'ivy)
  (amx-save-file (at-user-data-dir "amx-items")))

(use-package paradox
  :ensure t
  :after (seq let-alist spinner)
  :secret "vcs.el.gpg"
  :commands paradox-list-packages
  :custom
  (paradox-execute-asynchronously t)
  (paradox-column-width-package 27)
  (paradox-column-width-version 13)
  :config
  (remove-hook 'paradox-after-execute-functions #'paradox--report-buffer-print))

(use-package executable
  :hook (after-save-hook . executable-make-buffer-file-executable-if-script-p))

(use-package text-mode
  :hook (text-mode-hook . text-mode-hook-identify))

(use-package jka-cmpr-hook
  :config
  (auto-compression-mode 1))

(use-package kmacro
  :custom
  (setq kmacro-ring-max 16))
