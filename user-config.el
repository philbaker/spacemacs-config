;; -*- mode: emacs-lisp; lexical-binding: t -*-

;; ---------------------------------------
;; General Configuration changes
;; ---------------------------------------
(setq bookmark-default-file "~/org-sync/bookmarks")

(defmacro comment (&rest _body)
  "Clojure-style comment block. Body is never evaluated."
  nil)

;; ---------------------------------------
;; Line numbers
;; native line numbers taking up lots of space?
(setq-default display-line-numbers-width nil)
;; ---------------------------------------

;; ---------------------------------------
;; Searching
;; replace / search with helm-swoop in Evil normal state
(evil-global-set-key 'normal "/" 'helm-swoop)
;;
;; ---------------------------------------

;; ---------------------------------------
;; Helm Descbinds
;; Recent release of helm-descbinds package breaks which-key menu
;; Remove helm-discbinds-mode from helm mode hook to avoid activating
;; https://github.com/syl20bnr/spacemacs/issues/16276
(remove-hook 'helm-mode-hook 'helm-descbinds-mode)

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

;; ---------------------------------------
;; Spacehammer integration
;; ---------------------------------------
(when (eq system-type 'darwin)
  (server-start)
  (load "~/.hammerspoon/spacehammer.el"))

;; ---------------------------------------
;; Clojure formatting
;; ---------------------------------------
(with-eval-after-load 'apheleia
  (setf (alist-get 'zprint apheleia-formatters)
    '("zprint" "{:style [:community] :map {:comma? false}}"))

  (setf (alist-get 'clojure-mode apheleia-mode-alist) 'zprint
    (alist-get 'clojure-ts-mode apheleia-mode-alist) 'zprint)

  (apheleia-global-mode -1))

;; ---------------------------------------
;; Clerk notebooks
;; ---------------------------------------
(defun clerk-show ()
  (interactive)
  (when-let
    ((filename
       (buffer-file-name)))
    (save-buffer)
    (cider-interactive-eval
      (concat "(nextjournal.clerk/show! \"" filename "\")"))))

;; ---------------------------------------
;; Send to Vterm
;; ---------------------------------------
(defun my/send-to-vterm (cmd)
  "Send CMD to vterm buffer."
  (let ((buf (get-buffer "*vterm*")))
    (if buf
      (progn
        (switch-to-buffer-other-window buf)
        (vterm-send-string (concat cmd "\n")))
      (message "No *vterm* buffer found. Start one with M-x vterm."))))

(defun my/send-region-to-vterm (start end)
  (interactive "r")
  (my/send-to-vterm (buffer-substring-no-properties start end)))


;; ---------------------------------------
;; Testing
;; ---------------------------------------
(defun my/vitest-file ()
  (interactive)
  (my/send-to-vterm (concat "npx vitest run " (buffer-file-name))))

(defun my/vitest-suite ()
  (interactive)
  (my/send-to-vterm "npx vitest run"))

(defun my/vitest-nearest ()
  (interactive)
  (save-excursion
    (let ((test-name nil))
      (while (and (not test-name) (not (bobp)))
        (beginning-of-line)
        (when (looking-at ".*\\bit(\"\\([^\"]+\\)\"")
          (setq test-name (match-string 1)))
        (when (looking-at ".*\\btest(\"\\([^\"]+\\)\"")
          (setq test-name (match-string 1)))
        (forward-line -1))
      (if test-name
        (my/send-to-vterm (concat "npx vitest run --reporter=verbose -t '" test-name "' " (buffer-file-name)))
        (message "No test found at point")))))

(defun my/pest-file ()
  (interactive)
  (my/send-to-vterm (concat "./vendor/bin/pest " (buffer-file-name))))

(defun my/pest-suite ()
  (interactive)
  (my/send-to-vterm "./vendor/bin/pest"))

(defun my/pest-nearest ()
  (interactive)
  (save-excursion
    (let ((test-name nil))
      (while (and (not test-name) (not (bobp)))
        (beginning-of-line)
        ;; Pest style: it('test name') or test('test name')
        (when (looking-at ".*\\b\\(?:it\\|test\\)(\"\\([^\"]+\\)\"")
          (setq test-name (match-string 1)))
        (when (looking-at ".*\\b\\(?:it\\|test\\)('\\([^']+\\)'")
          (setq test-name (match-string 1)))
        ;; PHPUnit style: public function it_does_something
        (when (looking-at ".*public function \\([a-z_]+\\)")
          (setq test-name (match-string 1)))
        (forward-line -1))
      (if test-name
        (my/send-to-vterm (concat "./vendor/bin/pest --filter='" test-name "' " (buffer-file-name)))
        (message "No test found at point")))))

;; ---------------------------------------
;; Claude code
;; ---------------------------------------
(use-package claude-code
  :bind-keymap ("C-c c" . claude-code-command-map)
  :config
  (setq claude-code-terminal-backend 'vterm))

;; ---------------------------------------
;; Harpoon
;; ---------------------------------------
(defun my/harpoon-from-branch-diff ()
  "Populate harpoon with all changed files vs main, including uncommitted."
  (interactive)
  (let* ((cmd "git diff --name-only --diff-filter=d main...HEAD && git diff --name-only --diff-filter=d && git diff --name-only --diff-filter=d --cached")
          (raw (split-string
                 (shell-command-to-string cmd)
                 "\n" t))
          (files (delete-dups raw)))
    (f-write-text
      (mapconcat 'identity files "\n")
      'utf-8
      (harpoon--file-name))
    (message "Harpoon populated with %d changed files." (length files))))

(defun my/harpoon-to-org-block ()
  "Insert current harpoon file list as org code block at point."
  (interactive)
  (let ((contents (f-read (harpoon--file-name) 'utf-8)))
    (insert (concat "#+begin_src text\n" contents "\n#+end_src\n"))))

(comment
  (defvar repl/notes-dir (getenv "NOTES_DIR"))
  (defvar repl/clo-dir   (getenv "CLO_DIR"))
  (defvar repl/target-dir (expand-file-name "notebooks" (expand-file-name repl/clo-dir repl/notes-dir)))
  (expand-file-name (concat (format-time-string "%Y%m%d") "-") repl/target-dir)
  nil)
