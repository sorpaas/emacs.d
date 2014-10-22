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


; Refile targets include this file and any file contributing to the agenda - up to 5 levels deep
(setq org-refile-targets (quote ((nil :maxlevel . 5) (org-agenda-files :maxlevel . 5))))
; Targets start with the file name - allows creating level 1 tasks
(setq org-refile-use-outline-path (quote file))
; Targets complete in steps so we start with filename, TAB shows the next level of targets etc
(setq org-outline-path-complete-in-steps t)

;;; - Org: TODO Keywords
(setq org-todo-keywords
      (quote ((sequence "TODO(t)" "NEXT(n)" "WAITING(w@/!)" "|" "DONE(d)")
              (sequence "HOLD(h@/!)" "|" "CANCELLED(c@/!)" "SUB(s)")
              (sequence "CHECKPOINT(c)" "|" "DONE(d)"))))

(setq org-todo-keyword-faces
      (quote (("TODO" :foreground "black" :background "red" :weight bold)
              ("NEXT" :foreground "black" :background "blue" :weight bold)
              ("DONE" :foreground "black" :background "forest green" :weight bold)
              ("CHECKPOINT" :foreground "black" :background "yellow" :weight bold)
              ("WAITING" :foreground "black" :background "orange" :weight bold)
              ("HOLD" :foreground "black" :background "magenta" :weight bold)
              ("CANCELLED" :foreground "black" :background "forest green" :weight bold)
              ("SUB" :foreground "black" :background "forest green" :weight bold))))

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
                            ("info" . ?i))))

; Inheritance Settings
(setq org-tags-exclude-from-inheritance '("PROJECT" "HOLD" "CANCELED" "DONE" "list"))

; Allow setting single tags without the menu
(setq org-fast-tag-selection-single-key (quote expert))

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
        ("h" "Habits" tags-todo "STYLE=\"habit\""
         ((org-agenda-overriding-header "Habits")
          (org-agenda-sorting-strategy
           '(todo-state-down effort-up category-keep))))
        (" " "Agenda"
         ((agenda "" nil)
          (tags "REFILE"
                ((org-agenda-overriding-header "Tasks to Refile")
                 (org-tags-match-list-sublevels nil)))
          (tags-todo "-CANCELLED/!"
                     ((org-agenda-overriding-header "Stuck Projects")
                      (org-agenda-skip-function 'bh/skip-non-stuck-projects)
                      (org-agenda-sorting-strategy
                       '(category-keep))))
          (tags-todo "-HOLD-CANCELLED/!"
                     ((org-agenda-overriding-header "Projects")
                      (org-agenda-skip-function 'bh/skip-non-projects)
                      (org-tags-match-list-sublevels 'indented)
                      (org-agenda-sorting-strategy
                       '(category-keep))))
          (tags-todo "-CANCELLED/!NEXT"
                     ((org-agenda-overriding-header (concat "Project Next Tasks"
                                                            (if bh/hide-scheduled-and-waiting-next-tasks
                                                                ""
                                                              " (including WAITING and SCHEDULED tasks)")))
                      (org-agenda-skip-function 'bh/skip-projects-and-habits-and-single-tasks)
                      (org-tags-match-list-sublevels t)
                      (org-agenda-todo-ignore-scheduled bh/hide-scheduled-and-waiting-next-tasks)
                      (org-agenda-todo-ignore-deadlines bh/hide-scheduled-and-waiting-next-tasks)
                      (org-agenda-todo-ignore-with-date bh/hide-scheduled-and-waiting-next-tasks)
                      (org-agenda-sorting-strategy
                       '(todo-state-down effort-up category-keep))))
          (tags-todo "-REFILE-CANCELLED-WAITING-HOLD/!"
                     ((org-agenda-overriding-header (concat "Project Subtasks"
                                                            (if bh/hide-scheduled-and-waiting-next-tasks
                                                                ""
                                                              " (including WAITING and SCHEDULED tasks)")))
                      (org-agenda-skip-function 'bh/skip-non-project-tasks)
                      (org-agenda-todo-ignore-scheduled bh/hide-scheduled-and-waiting-next-tasks)
                      (org-agenda-todo-ignore-deadlines bh/hide-scheduled-and-waiting-next-tasks)
                      (org-agenda-todo-ignore-with-date bh/hide-scheduled-and-waiting-next-tasks)
                      (org-agenda-sorting-strategy
                       '(category-keep))))
          (tags-todo "-REFILE-CANCELLED-WAITING-HOLD/!"
                     ((org-agenda-overriding-header (concat "Standalone Tasks"
                                                            (if bh/hide-scheduled-and-waiting-next-tasks
                                                                ""
                                                              " (including WAITING and SCHEDULED tasks)")))
                      (org-agenda-skip-function 'bh/skip-project-tasks)
                      (org-agenda-todo-ignore-scheduled bh/hide-scheduled-and-waiting-next-tasks)
                      (org-agenda-todo-ignore-deadlines bh/hide-scheduled-and-waiting-next-tasks)
                      (org-agenda-todo-ignore-with-date bh/hide-scheduled-and-waiting-next-tasks)
                      (org-agenda-sorting-strategy
                       '(category-keep))))
          (tags-todo "-CANCELLED+WAITING|HOLD/!"
                     ((org-agenda-overriding-header "Waiting and Postponed Tasks")
                      (org-agenda-skip-function 'bh/skip-stuck-projects)
                      (org-tags-match-list-sublevels nil)
                      (org-agenda-todo-ignore-scheduled t)
                      (org-agenda-todo-ignore-deadlines t)))
          (tags "-REFILE/"
                ((org-agenda-overriding-header "Tasks to Archive")
                 (org-agenda-skip-function 'bh/skip-non-archivable-tasks)
                 (org-tags-match-list-sublevels nil))))
         nil)
      ("p" "All projects"
       ((tags "+PROJECT+meta"
              ((org-agenda-overriding-header "Meta Planning Projects")
               (org-agenda-prefix-format " %t %s")
               (org-agenda-sorting-strategy '(alpha-up))))
        (tags "+PROJECT+future"
              ((org-agenda-overriding-header "Future Projects")
               (org-agenda-prefix-format " %t %s")
               (org-agenda-sorting-strategy '(alpha-up))))
        (tags "+PROJECT+interest"
              ((org-agenda-overriding-header "Interest Projects")
               (org-agenda-prefix-format " %t %s")
               (org-agenda-sorting-strategy '(alpha-up))))
        (tags "+PROJECT+preparation"
              ((org-agenda-overriding-header "Preparation Projects")
               (org-agenda-prefix-format " %t %s")
               (org-agenda-sorting-strategy '(alpha-up))))
        (tags "+PROJECT+future+meta"
              ((org-agenda-overriding-header "Future Meta Projects")
               (org-agenda-prefix-format " %t %s")
               (org-agenda-sorting-strategy '(alpha-up))))
        (tags "+PROJECT+interest+meta"
              ((org-agenda-overriding-header "Interest Meta Projects")
               (org-agenda-prefix-format " %t %s")
               (org-agenda-sorting-strategy '(alpha-up))))
        (tags "+PROJECT+preparation+meta"
              ((org-agenda-overriding-header "Preparation Meta Projects")
               (org-agenda-prefix-format " %t %s")
               (org-agenda-sorting-strategy '(alpha-up))))
        (tags "+PROJECT+preparation+interest"
              ((org-agenda-overriding-header "Both Preparation and Interest Projects")
               (org-agenda-prefix-format " %t %s")
               (org-agenda-sorting-strategy '(alpha-up))))
        (stuck ""
               ((org-agenda-overriding-header "Stuck Projects")
                (org-agenda-prefix-format " %t %s")
                (org-agenda-sorting-strategy '(alpha-up))))
        (tags "+PROJECT/-HOLD-CANCELED-DONE"
              ((org-agenda-overriding-header "Active Projects")
               (org-agenda-prefix-format " %t %s")
               (org-agenda-sorting-strategy '(alpha-up))))
        (org-agenda-files)))
      ("i" "Ideas"
       ((tags "idea")
        ))
      ("d" "Today's plan"
       ((agenda "" ((org-agenda-ndays 2)
                    ))
        (todo "NEXT" ((org-agenda-overriding-header "Next Planned Tasks")
                      ))
        (todo "TODO" ((org-agenda-overriding-header "Unscheduled Tasks")
                      (org-agenda-todo-ignore-scheduled t)))
        (agenda "" ((org-agenda-overriding-header "Upcoming Deadlines")
                    (org-agenda-ndays 1)
                    (org-agenda-entry-types '(:deadline))
                    (org-deadline-warning-days 7)
                    (org-agenda-time-grid nil)))
        (todo "WAITING" ((org-agenda-overriding-header "Waiting Tasks")
                         ))
        (tags "REFILE"
              ((org-agenda-overriding-header "Tasks to Refile")
               (org-tags-match-list-sublevels nil)))
        (stuck ""
               ((org-agenda-overriding-header "Stuck Projects")
                (org-agenda-prefix-format " %t %s")
                (org-agenda-sorting-strategy '(alpha-up))))
        (tags "+PROJECT+meta"
              ((org-agenda-overriding-header "Meta Projects")
               (org-agenda-prefix-format " %t %s")
               (org-agenda-sorting-strategy '(alpha-up))))
        (tags "+PROJECT-meta/-HOLD-CANCELED-DONE"
              ((org-agenda-overriding-header "All Other Projects")
               (org-agenda-prefix-format " %t %s")
               (org-agenda-sorting-strategy '(alpha-up))))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org clock
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Save the running clock and all clock history when exiting Emacs, load it on startup
(setq org-clock-persistence-insinuate t)
(setq org-clock-persist t)
(setq org-clock-in-resume t)

;; Change task state to STARTED when clocking in
(setq org-clock-in-switch-to-state "STARTED")
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
