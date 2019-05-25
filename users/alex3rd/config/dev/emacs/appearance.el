(use-package font-core
  :hook
  (after-init-hook . (lambda () (global-font-lock-mode 1))))

(use-package font-lock
  :config
  (setq font-lock-maximum-decoration t))

(use-package face-remap
  :general
  ("C-=" 'text-scale-increase)
  ("C--" 'text-scale-decrease))

(use-package unicode-fonts
  :ensure t
  :after (persistent-soft)
  :hook
  (after-init-hook . unicode-fonts-setup))

(use-package doom-modeline
  :ensure t
  :hook
  (after-init-hook . doom-modeline-init)
  :custom
  (doom-modeline-height 25)
  (doom-modeline-icon t)
  (doom-modeline-major-mode-icon nil)
  (doom-modeline-minor-modes nil))

;; Also some other good-looking theme is "material-theme"
(use-package nord-theme :ensure t :config (load-theme 'nord t) :disabled)
(use-package kaolin-themes :ensure t :config (load-theme 'kaolin-dark t) :disabled)
(use-package hc-zenburn-theme :ensure t :config (load-theme 'hc-zenburn t))
(use-package darkburn-theme :ensure t :config (load-theme 'darkburn t) :disabled)
(use-package solarized-theme :ensure t :config (load-theme 'solarized-dark t) :disabled)
(use-package gotham-theme :ensure t :config (load-theme 'gotham t) :disabled)

(use-package tooltip
  :config
  (tooltip-mode 0))

(use-package tool-bar
  :config
  (tool-bar-mode -1))

(use-package scroll-bar
  :config
  (scroll-bar-mode -1)
  (when (>= emacs-major-version 25)
    (horizontal-scroll-bar-mode -1)))

(use-package menu-bar
  :general
  (:keymaps 'mode-specific-map
            "b" 'toggle-debug-on-error
            "q" 'toggle-debug-on-quit)
  :config
  (menu-bar-mode -1))

(use-package hl-line
  :config
  (global-hl-line-mode 1))

(use-package highlight-numbers
  :ensure t
  :hook
  (prog-mode . highlight-numbers-mode))

(use-package highlight-escape-sequences
  :ensure t
  :config (hes-mode))

(use-package time
  :defer t
  :config
  (display-time)
  :custom
  (display-time-day-and-date t)
  ;; (display-time-form-list (list 'time 'load))
  (display-time-world-list
   '(("@timeZone@" "@timeZone@")))
  (display-time-mail-file t)
  (display-time-default-load-average nil)
  (display-time-24hr-format t)
  (display-time-string-forms '( day " " monthname " (" dayname ") " 24-hours ":" minutes)))

(use-package uniquify
  :custom
  (uniquify-buffer-name-style 'post-forward)
  (uniquify-separator ":")
  (uniquify-ignore-buffers-re "^\\*")
  (uniquify-strip-common-suffix nil))

(use-package avoid
  :config
  (mouse-avoidance-mode 'jump))
