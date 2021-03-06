(when (< emacs-major-version 24)
  (require-package 'org))
(require-package 'org-fstree)
(when *is-a-mac*
  (require-package 'org-mac-link)
  (autoload 'org-mac-grab-link "org-mac-link" nil t)
  (require-package 'org-mac-iCal))

(define-key global-map (kbd "C-c l") 'org-store-link)
(define-key global-map (kbd "C-c a") 'org-agenda)

;; Various preferences
(setq org-log-done t
      org-startup-indented t
      org-fast-tag-selection-single-key (quote expert)
      org-completion-use-ido t
      org-edit-timestamp-down-means-later t
      org-agenda-start-on-weekday nil
      org-agenda-span 14
      org-agenda-include-diary t
      org-agenda-window-setup 'current-window
      org-agenda-tags-todo-honor-ignore-options t
      org-agenda-skip-deadline-if-done t
      org-agenda-skip-scheduled-if-done t
      org-agenda-ndays 7
      org-fast-tag-selection-single-key 'expert
      org-html-validation-link nil
      org-export-kill-product-buffer-when-displayed t
      org-tags-column 80
      org-directory "~/org"
      org-agenda-files "~/org/agenda-files")

(add-hook 'org-mode-hook 'turn-on-auto-fill)

; Enables the given minor mode for the current buffer it it matches regex
; my-pair is a cons cell (regular-expression . minor-mode)
(defun enable-minor-mode (my-pair)
  (if (buffer-file-name) ; If we are visiting a file,
      ; and the filename matches our regular expression,
      (if (string-match (car my-pair) buffer-file-name)
      (funcall (cdr my-pair))))) ; enable the minor mode

(add-hook 'org-mode-hook
          (lambda () (enable-minor-mode '("\\(facebook\\|google\\)_cal\\.\\(org\\|org_archive\\)$" . auto-revert-mode))))
(add-hook 'org-mode-hook
          (lambda () (enable-minor-mode '("/home/sorpaas/org/inbox\\.org" . auto-revert-mode))))

(define-key global-map "\C-cl" 'org-store-link)
(define-key global-map "\C-cb" 'org-iswitchb)

; Refile targets include this file and any file contributing to the agenda - up to 5 levels deep
(setq org-refile-targets (quote ((nil :maxlevel . 5) (org-agenda-files :maxlevel . 5))))
; Targets start with the file name - allows creating level 1 tasks
(setq org-refile-use-outline-path (quote file))
; Targets complete in steps so we start with filename, TAB shows the next level of targets etc
(setq org-outline-path-complete-in-steps t)

;;; - Org: TODO Keywords
(setq org-todo-keywords
      (quote ((sequence "TODO(t)" "NEXT(n)" "WAITING(w@/!)" "STARTED" "|" "DONE(d)")
              (sequence "HOLD(h@/!)" "|" "CANCELLED(c@/!)" "SUB(s)")
              (sequence "CHECKPOINT(c)" "|" "DONE(d)"))))

(setq org-todo-keyword-faces
      (quote (("TODO" :foreground "black" :background "burlywood" :weight bold)
              ("DONE" :foreground "black" :background "SpringGreen1" :weight bold)
              ("CHECKPOINT" :foreground "black" :background "yellow1" :weight bold)
              ("WAITING" :foreground "black" :background "gold1" :weight bold)
              ("HOLD" :foreground "black" :background "pink1" :weight bold)
              ("CANCELLED" :foreground "black" :background "SpringGreen1" :weight bold)
              ("SUB" :foreground "black" :background "SpringGreen1" :weight bold)
              ("STARTED" :foreground "black" :background "LightSkyBlue1"))))

;;; - Org: Tag
; Tags with fast selection keys
(setq org-tag-alist (quote (("list" . ?l)
                            ("event" . ?e)
                            ("export" . ?')
                            ("PROJECT" . ?p)
                            ("THOUGHT" . ?t)
                            ("HOLD" . ?h)
                            ("CANCELED" . ?c)
                            ("DONE" . ?d)
                            ("preparation" . ?w)
                            ("interest" . ?v)
                            ("future" . ?z)
                            ("meta" . ?s)
                            ("research" . ?r)
                            ("need_deadline")
                            ("info" . ?i)
                            ("@outdoor" . ?o))))

; Inheritance Settings
(setq org-tags-exclude-from-inheritance '("PROJECT" "HOLD" "CANCELED" "DONE" "list"))

; Allow setting single tags without the menu
(setq org-fast-tag-selection-single-key (quote expert))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org capture
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setq org-default-notes-file "~/org/notes.org")
(define-key global-map [(control meta ?r)] 'org-capture)
;; Capture templates for: TODO tasks, Notes, appointments, phone calls, meetings, and org-protocol
(setq org-capture-templates
      (quote (("t" "Todo" entry (file "~/org/inbox.org")
               "* TODO %?\n%U\n%a\n")
              ("n" "Note" entry (file "~/org/inbox.org")
               "* %? :NOTE:\n%U\n%a\n")
              ("j" "Journal" entry (file+datetree "~/org/journal.org")
               "* %?\n%U\n" :clock-in t :clock-resume t)
              ("N" "Serious Notes" entry (file+datetree "~/org/notes.org")
               "* %?\n%U\n" :clock-in t :clock-resume t)
              ("R" "Reflections" entry (file+datetree "~/org/thoughts/reflections.org")
               "* %?\n%U\n" :clock-in t :clock-resume t)
              ("e" "Essays" entry (file+datetree "~/org/essays.org")
               "* %?" :clock-in t :clock-resume t)
              ("w" "Org-protocol" entry (file "~/org/inbox.org")
               "* TODO Review %c\n%U\n" :immediate-finish t))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org agenda
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Stuck Projects
(setq org-stuck-projects
      '("+PROJECT/-HOLD-CANCELED-DONE" ("TODO" "NEXT") ("meta") "\\<IGNORE\\>"))

(defvar bh/hide-scheduled-and-waiting-next-tasks t)

(defun zin/org-agenda-skip-tag (tag &optional others)
  "Skip all entries that correspond to TAG.

If OTHERS is true, skip all entries that do not correspond to TAG."
  (let ((next-headline (save-excursion (or (outline-next-heading) (point-max))))
        (current-headline (or (and (org-at-heading-p)
                                   (point))
                              (save-excursion (org-back-to-heading)))))
    (if others
        (if (not (member tag (org-get-tags-at current-headline)))
            next-headline
          nil)
      (if (member tag (org-get-tags-at current-headline))
          next-headline
        nil))))

(defun sp/org-agenda-skip-tag-and-scheduled (tag)
  "Skip all entries that correspond to TAG or has been scheduled."
  (let ((next-headline (save-excursion (or (outline-next-heading) (point-max))))
        (current-headline (or (and (org-at-heading-p)
                                   (point))
                              (save-excursion (org-back-to-heading)))))
    (if (equal next-headline (zin/org-agenda-skip-tag tag))
        next-headline
      (org-agenda-skip-entry-if 'scheduled))))

(defun sp/org-agenda-skip-tag-and-not-deadline (tag)
  "Skip all entried that correspond to TAG and has no deadline."
   (let ((next-headline (save-excursion (or (outline-next-heading) (point-max))))
        (current-headline (or (and (org-at-heading-p)
                                   (point))
                              (save-excursion (org-back-to-heading)))))
     (if (and (member tag (org-get-tags-at current-headline)) (not (org-get-deadline-time current-headline)))
         next-headline
       nil)))

;;; - Org: Agenda Commands
(setq org-agenda-custom-commands
      '(("n" "Notes" tags "NOTE"
         ((org-agenda-overriding-header "Notes")
          (org-tags-match-list-sublevels t)))
        ("d" "Today's plan"
         ((agenda "" ((org-agenda-ndays 2)
                      ))
          (todo "TODO" ((org-agenda-overriding-header "Unscheduled Tasks")
                        (org-agenda-todo-ignore-scheduled t)
                        (org-agenda-todo-ignore-deadlines t)))
          (todo "WAITING" ((org-agenda-overriding-header "Waiting Tasks")
                           ))
          (tags "REFILE"
                ((org-agenda-overriding-header "Tasks to Refile")
                 (org-tags-match-list-sublevels nil)))
          (stuck ""
                 ((org-agenda-overriding-header "Stuck Projects")
                  (org-agenda-prefix-format " %t %s")
                  (org-agenda-sorting-strategy '(alpha-up))))
          (tags "+PROJECT/-HOLD-CANCELED-DONE"
                ((org-agenda-overriding-header "All Other Projects")
                 (org-agenda-prefix-format " %t %s")
                 (org-agenda-sorting-strategy '(alpha-up))))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org refine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Targets include this file and any file contributing to the agenda - up to 9 levels deep
(setq org-refile-targets (quote ((nil :maxlevel . 9)
                                 (org-agenda-files :maxlevel . 9))))

; Use full outline paths for refile targets - we file directly with IDO
(setq org-refile-use-outline-path t)

; Targets complete directly with IDO
(setq org-outline-path-complete-in-steps nil)

(setq ido-max-directory-size 100000)

; Allow refile to create parent tasks with confirmation
(setq org-refile-allow-creating-parent-nodes (quote confirm))

; Use the current window for indirect buffer display
(setq org-indirect-buffer-display 'current-window)

;;;; Refile settings
; Exclude DONE state tasks from refile targets
(defun bh/verify-refile-target ()
  "Exclude todo keywords with a done state from refile targets"
  (and
   (not (member "ARCHIVE" (org-get-tags)))
   (not (member (nth 2 (org-heading-components)) org-done-keywords))))

(setq org-refile-target-verify-function 'bh/verify-refile-target)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org mobile
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Set to the location of your Org files on your local system
(setq org-directory "~/org")
;; Set to the name of the file where new notes will be stored
(setq org-mobile-inbox-for-pull "~/org/inbox.org")
;; Set to <your Dropbox root directory>/MobileOrg.
(setq org-mobile-directory "~/Dropbox/Apps/MobileOrg")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org clock
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Save the running clock and all clock history when exiting Emacs, load it on startup
(setq org-clock-persistence-insinuate t)
(setq org-clock-persist t)
(setq org-clock-in-resume t)

;; Save clock data and notes in the LOGBOOK drawer
(setq org-clock-into-drawer t)
;; Removes clocked tasks with 0:00 duration
(setq org-clock-out-remove-zero-time-clocks t)

;; Show clock sums as hours and minutes, not "n days" etc.
(setq org-time-clocksum-format
      '(:hours "%d" :require-hours t :minutes ":%02d" :require-minutes t))

;; Show the clocked-in task - if any - in the header line
(defun sanityinc/show-org-clock-in-header-line ()
  (setq-default header-line-format '((" " org-mode-line-string " "))))

(defun sanityinc/hide-org-clock-from-header-line ()
  (setq-default header-line-format nil))

(add-hook 'org-clock-in-hook 'sanityinc/show-org-clock-in-header-line)
(add-hook 'org-clock-out-hook 'sanityinc/hide-org-clock-from-header-line)
(add-hook 'org-clock-cancel-hook 'sanityinc/hide-org-clock-from-header-line)

(after-load 'org-clock
  (define-key org-clock-mode-line-map [header-line mouse-2] 'org-clock-goto)
  (define-key org-clock-mode-line-map [header-line mouse-1] 'org-clock-menu))


(require-package 'org-pomodoro)
(after-load 'org-agenda
  (define-key org-agenda-mode-map (kbd "P") 'org-pomodoro))


;; ;; Show iCal calendars in the org agenda
;; (when (and *is-a-mac* (require 'org-mac-iCal nil t))
;;   (setq org-agenda-include-diary t
;;         org-agenda-custom-commands
;;         '(("I" "Import diary from iCal" agenda ""
;;            ((org-agenda-mode-hook #'org-mac-iCal)))))

;;   (add-hook 'org-agenda-cleanup-fancy-diary-hook
;;             (lambda ()
;;               (goto-char (point-min))
;;               (save-excursion
;;                 (while (re-search-forward "^[a-z]" nil t)
;;                   (goto-char (match-beginning 0))
;;                   (insert "0:00-24:00 ")))
;;               (while (re-search-forward "^ [a-z]" nil t)
;;                 (goto-char (match-beginning 0))
;;                 (save-excursion
;;                   (re-search-backward "^[0-9]+:[0-9]+-[0-9]+:[0-9]+ " nil t))
;;                 (insert (match-string 0))))))


(after-load 'org
  (define-key org-mode-map (kbd "C-M-<up>") 'org-up-element)
  (when *is-a-mac*
    (define-key org-mode-map (kbd "M-h") nil))
  (define-key org-mode-map (kbd "C-M-<up>") 'org-up-element)
  (when *is-a-mac*
    (define-key org-mode-map (kbd "C-c g") 'org-mac-grab-link)))

(after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((R . t)
     (ditaa . t)
     (dot . t)
     (emacs-lisp . t)
     (gnuplot . t)
     (haskell . nil)
     (latex . t)
     (ledger . t)
     (ocaml . nil)
     (octave . t)
     (python . t)
     (ruby . t)
     (screen . nil)
     (sh . t)
     (sql . nil)
     (sqlite . t))))


(provide 'init-org)
