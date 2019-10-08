(use-package atomic-chrome
  :ensure t
  :defer 2
  :custom
  (atomic-chrome-buffer-open-style 'frame)
  (atomic-chrome-server-ghost-text-port 4001)
  (atomic-chrome-url-major-mode-alist
   '(("reddit\\.com" . markdown-mode)
     ("github\\.com" . gfm-mode)
     ("redmine" . textile-mode))
   "Major modes for URLs.")
  :config
  (atomic-chrome-start-server))

(use-package browse-url
  :if (and (eq system-type 'gnu/linux)
           (eq window-system 'x))
  :defer 5
  :preface
  (defun custom/buffer-urls--candidates ()
    (save-excursion
      (save-restriction
        (let ((urls))
          (goto-char (point-min))
          (while (re-search-forward org-plain-link-re nil t)
            (push (thing-at-point 'url) urls))
          (remove nil urls)))))
  (defun custom/open-url-current-buffer ()
    (interactive)
    (ivy-read "URLs: "
              (funcall #'custom/buffer-urls--candidates)
              :action #'(lambda (candidate)
                          (browse-url candidate))
              :require-match t
              :caller 'custom/open-url-current-buffer))
  (defun feh-browse (url &rest ignore)
    "Browse image using feh."
    (interactive (browse-url-interactive-arg "URL: "))
    (start-process (concat "feh " url) nil "feh" url))
  (defun mpv-browse (url &rest ignore)
    "Browse video using mpv."
    (interactive (browse-url-interactive-arg "URL: "))
    (start-process (concat "mpv --loop-file=inf" url) nil "mpv" "--loop-file=inf" url))
  :secret "media.el.gpg"
  :custom
  (browse-url-browser-function 'browse-url-generic)
  (browse-url-generic-program "xdg-open"))

(use-package eww
  :defer 6
  :preface
  (defun eww-more-readable () ;;TODO: add to appropriate hook
    "Makes eww more pleasant to use. Run it after eww buffer is loaded."
    (interactive)
    (setq eww-header-line-format nil) ;; removes page title
    (setq mode-line-format nil) ;; removes mode-line
    (set-window-margins (get-buffer-window) 20 20) ;; increases size of margins
    (redraw-display) ;; apply mode-line changes
    (eww-reload 'local))
  :custom
  (eww-search-prefix "https://duckduckgo.com/html/?kd=-1&q="))

(use-package pass
  :ensure t
  :bind
  (:prefix-map custom-pass-map
               :prefix "<f6>"
               ("p" . pass)
               ("!" . ivy-pass))
  :config
  (use-package ivy-pass :ensure t))

(use-package webpaste
  :ensure t
  :bind
  (:prefix-map custom-webpaste-map
               :prefix "M-p"
               ("b" . webpaste-paste-buffer)
               ("r" . webpaste-paste-region))
  :custom
  (webpaste-provider-priority '("ix.io" "gist.github.com")))

(imagemagick-register-types)