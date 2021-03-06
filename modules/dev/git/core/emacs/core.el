(use-package magit
  :preface
  (defun custom/magit-hide-devenv ()
    (interactive)
    (magit-with-toplevel
      (magit-call-git "hideenv")
      (magit-refresh)))
  (defun custom/magit-unhide-devenv ()
    (interactive)
    (magit-with-toplevel
      (magit-call-git "unhideenv")
      (magit-refresh)))
  (defun custom/magit-dump-devenv ()
    (interactive)
    (magit-with-toplevel
      (magit-call-git "dumpenv")
      (magit-refresh)))
  (defun custom/magit-restore-devenv ()
    (interactive)
    (magit-with-toplevel
      (magit-call-git "restoreenv")
      (magit-refresh)))
  :mode (("COMMIT_EDITMSG" . conf-javaprop-mode)
         ("COMMIT" . git-commit-mode))
  :bind
  (:prefix-map custom-magit-map
               :prefix "C-'"
               ("i" . magit-init)
               ("s" . magit-status)
               ("." . magit-dispatch)
               ("," . magit-file-dispatch)
               ("r" . magit-reflog-current)
               ("R" . magit-reflog-other)
               ("c" . magit-checkout))
  (:map magit-status-mode-map
        ("N" . magit-notes-edit)
        ("C-c k" . magit-process-kill))
  (:map dired-mode-map
        ("@" . magit-dired-log))
  :config
  (advice-add 'magit-whitespace-disallowed :around (lambda (orig-fun &rest args) (interactive) (insert "-")))
  (transient-append-suffix 'magit-stash "z" '("h" "Hide dev environment" custom/magit-hide-devenv))
  (transient-append-suffix 'magit-stash "h" '("u" "Unhide dev environment" custom/magit-unhide-devenv))
  (transient-append-suffix 'magit-stash "u" '("d" "Dump/backup dev environment" custom/magit-dump-devenv))
  (transient-append-suffix 'magit-stash "d" '("r" "Restore dev environment" custom/magit-restore-devenv))
  :custom
  (magit-blame-heading-format "%H %-20a %C %s")
  (magit-section-visibility-indicator '("..." . t))
  (magit-completing-read-function 'ivy-completing-read)
  (magit-section-initial-visibility-alist '((stashes . hide) (untracked . hide) (unpushed . hide)))
  (magit-diff-refine-hunk t)
  (magit-display-buffer-function 'magit-display-buffer-same-window-except-diff-v1))

(use-package magit-filenotify
  :delight " ⛶"
  :hook (magit-status-mode-hook . (lambda ()
                                    (condition-case nil
                                        (magit-filenotify-mode)
                                      (error (magit-filenotify-mode -1))))))
