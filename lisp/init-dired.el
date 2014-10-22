(require-package 'dired+)
(require-package 'dired-sort)

(setq-default diredp-hide-details-initially-flag nil
              dired-dwim-target t)

(after-load 'dired
  (require 'dired+)
  (require 'dired-sort)
  (when (fboundp 'global-dired-hide-details-mode)
    (global-dired-hide-details-mode -1))
  (setq dired-recursive-deletes 'top)
  (define-key dired-mode-map [mouse-2] 'dired-find-file)
  (add-hook 'dired-mode-hook
            (lambda () (guide-key/add-local-guide-key-sequence "%"))))


(defun set-window-width (n)
  "Set the selected window's width."
  (adjust-window-trailing-edge (selected-window) (- n (window-width)) t))

(defun sorpaas/speed-dired-set-columns ()
  "Set the selected window to 80 columns."
  (set-window-width 22))

(defun sorpaas/speed-dired-install ()
  "Install speed dired"
  (eval-after-load "dired"
    '(progn
       (define-key dired-mode-map (kbd "<f1>") 'sorpaas/speed-dired-toggle))))

(defun sorpaas/speed-dired-toggle ()
  "Speed up dired by auto change frame size and toggle dired details"
  (interactive)
  (dired-hide-details-mode)
  (sorpaas/speed-dired-set-columns))

(sorpaas/speed-dired-install)

(provide 'init-dired)
