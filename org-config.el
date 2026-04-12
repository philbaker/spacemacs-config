;; ---------------------------------------
;; Org Mode
;; ---------------------------------------
(defvar my/notes-dir
  (or (getenv "NOTES_DIR")
    (error "NOTES_DIR environment variable is not set")))

(defvar my/jotes-dir
  (or (getenv "JOTES_DIRECTORY")
    (error "JOTES_DIRECTORY environment variable is not set")))

(defun my/daily-note-template ()
  (concat
    "#+title: "
    (format-time-string "%Y-%m-%d")
    "\n\n"
    (with-temp-buffer
      (insert-file-contents
        (expand-file-name "t/stemplate.org" my/jotes-dir))
      (buffer-string))))

(defvar my/last-ticket-title nil)
(defvar my/last-ticket-file nil)

(defun my/ticket-template ()
  (let* ((title (read-string "Enter ticket title: "))
          (slug (downcase (replace-regexp-in-string "[[:space:]]+" "-" title)))
          (file (expand-file-name
                  (format "%s-%s.org"
                    (format-time-string "%Y%m%d")
                    slug)
                  (concat my/jotes-dir "/notebooks"))))
    (setq my/last-ticket-title title)
    (setq my/last-ticket-file file)
    (concat
      "#+title: " title
      "\n\n"
      (with-temp-buffer
        (insert-file-contents
          (expand-file-name "all/01-checklists/t.org" my/notes-dir))
        (buffer-string)))))

(defun my/note-path (prompt suffix)
  (let* ((notes-dir (or (getenv "NOTES_DIR")
                      (error "NOTES_DIR environment variable is not set")))
          (clo-dir   (or (getenv "CLO_DIR")
                       (error "CLO_DIR environment variable is not set")))
          (target-dir (expand-file-name "notebooks"
                        (expand-file-name clo-dir notes-dir)))
          (name (read-string prompt)))
    (expand-file-name
      (concat (format-time-string "%Y%m%d") "-" name suffix)
      target-dir)))

(defun my/dated-note-path ()
  (my/note-path "Note name (with extension): " ""))

(defun my/meeting-note-path ()
  (my/note-path "Meeting note name: " "-meeting.org"))

(defun my/mirror-headline-to-tasks ()
  (when (and org-capture-last-stored-marker
          (equal (plist-get org-capture-plist :key) "t")
          my/last-ticket-title)
    (with-current-buffer (find-file-noselect "~/org-sync/work.org")
      (goto-char (point-min))
      (insert (concat "*** TODO " my/last-ticket-title
                "\n"
                ":PROPERTIES:\n"
                ":PROJECT_FILE: [[file:" my/last-ticket-file "][Project Note]]\n"
                ":END:\n\n"))
      (save-buffer))
    (setq my/last-ticket-title nil)
    (setq my/last-ticket-file nil)))

(add-hook 'org-capture-after-finalize-hook
  #'my/mirror-headline-to-tasks)

(defun my/jump-to-project-file ()
  (interactive)
  (let ((project-link (org-entry-get (point) "PROJECT_FILE")))
    (when project-link
      (org-link-open-from-string project-link))))

(setq org-todo-keywords
  '((sequence "REPEAT(r)" "TODO(t)" "NEXT(n)" "ACTIVE(a!)" "C REVIEW(o)" "S REVIEW(e)" "CS REVIEW(v)" "R QUEUE(q)" "HOLD(l@/!)" "WAITING(w@/!)" "MAYBE(m)" "PROJ(p)" "|" "DONE(d!)" "CANCELLED(c@/!)")
     (sequence "HABIT(h)" "|" "DONE(d!)")))

(setq org-todo-keyword-faces
  '(("REPEAT"    . "white")
     ("TODO"      . "white")
     ("HABIT"     . "white")
     ("NEXT"      . "wheat")
     ("ACTIVE"    . "yellow")
     ("C REVIEW"  . "aquamarine")
     ("S REVIEW"  . "pale green")
     ("CS REVIEW" . "cornflower blue")
     ("R QUEUE"   . "deep sky blue")
     ("HOLD"      . "orange")
     ("WAITING"   . "salmon")
     ("MAYBE"     . "lavenderblush1")
     ("PROJ"      . "plum1")
     ("DONE"      . "green")
     ("CANCELLED" . "red")))

(setq org-agenda-files '("~/org-sync/mobile.org" "~/org-sync/laptop.org" "~/org-sync/ob.org" "~/org-sync/work.org"))

(setq org-capture-templates
  '(("i" "Inbox" entry
      (file+headline "~/org-sync/inbox.org" "Tasks")
      "* TODO %?\n  %U\n  %a")

     ("d" "Daily Note" plain
       (file (lambda ()
               (expand-file-name
                 (format-time-string "%Y%m%d-daily.org")
                 my/jotes-dir)))
       (function my/daily-note-template)
       :unnarrowed t)

     ("f" "New File" plain
       (file my/dated-note-path)
       "#+title: %<%Y-%m-%d>\n#+date: %<%Y-%m-%d>\n\n%?"
       :unnarrowed t)

     ("t" "Ticket" plain
       (file (lambda () my/last-ticket-file))
       (function my/ticket-template)
       :unnarrowed t)

     ("m" "Meeting Note" plain
       (file (lambda ()
               (my/meeting-note-path)))
       "#+title: %<%Y-%m-%d> %^{Meeting Title}
         #+date: %<%Y-%m-%d>
         #+time: %<%H:%M>

         * Meeting Details
         - *Date:* %<%A, %d %B %Y>
         - *Time:* %<%H:%M>
         - *Location/Call:* %^{Location|Remote|Office}
         - *Attendees:* %^{Attendees}

         * Notes
         %?

         * Action Items
         - [ ]

         * Decisions Made

         * Follow Up
         "
       :unnarrowed t)))

(require 'org-habit)

(add-to-list 'org-modules 'org-habit)

(setq org-habit-graph-column 60)

(setq org-habit-show-all-today t)
