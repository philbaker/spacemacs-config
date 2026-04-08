;; -*- mode: emacs-lisp; lexical-binding: t -*-

;; ---------------------------------------
;; General Configuration changes
;; ---------------------------------------
(setq bookmark-default-file "~/org-sync/bookmarks")

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

(defun my/ticket-template ()
  (concat
    "#+title: "
    (read-string "Enter ticket title: ")
    "\n\n"
    (with-temp-buffer
      (insert-file-contents
        (expand-file-name "all/01-checklists/t.org" my/notes-dir))
      (buffer-string))))

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
       (file (lambda ()
               (expand-file-name
                 (format-time-string "%Y%m%d-ticket.org")
                 my/jotes-dir)))
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
;; Send to Vterm
;; ---------------------------------------
(defun my/send-region-to-vterm (start end)
  (interactive "r")
  (let* ((text (buffer-substring-no-properties start end))
          (buf (get-buffer "*vterm*")))
    (if buf
      (with-current-buffer buf
        (vterm-send-string text)
        (vterm-send-return))
      (message "No *vterm* buffer found. Start one with M-x vterm."))))

;; ---------------------------------------
;; Claude code
;; ---------------------------------------
(use-package claude-code
  :bind-keymap ("C-c c" . claude-code-command-map)
  :config
  (setq claude-code-terminal-backend 'vterm))

;; ---------------------------------------
;; Treesitter
;; ---------------------------------------
(setq treesit-language-source-alist
  '((javascript . ("https://github.com/tree-sitter/tree-sitter-javascript" "master" "src"))
     (php . ("https://github.com/tree-sitter/tree-sitter-php" "master" "php/src"))
     (phpdoc . ("https://github.com/claytonrcarter/tree-sitter-phpdoc" "master" "src"))))

(dolist (lang '(javascript php phpdoc))
  (unless (treesit-language-available-p lang)
    (treesit-install-language-grammar lang)))

(when (fboundp 'php-ts-mode-install-parsers)
  (unless (treesit-language-available-p 'phpdoc)
    (php-ts-mode-install-parsers)))

(add-to-list 'auto-mode-alist '("\\.js\\'" . js-ts-mode))
(add-to-list 'auto-mode-alist '("\\.php\\'" . php-ts-mode))

;; ---------------------------------------
;; Testing
;; ---------------------------------------
(let ((testrun-dir "~/.emacs.d/private/testrun"))
  (unless (file-directory-p testrun-dir)
    (shell-command
      (concat "git clone https://github.com/martini97/testrun.el " testrun-dir)))
  (add-to-list 'load-path testrun-dir)
  (require 'testrun)
  (require 'testrun-jest)
  (require 'testrun-pytest)
  (require 'testrun-ert)
  (require 'testrun-buttercup)
  (put 'testrun-runners 'safe-local-variable #'listp)
  (put 'testrun-mode-alist 'safe-local-variable #'listp))

(setq testrun-runners
  '((jest . (npx "vitest" "run" "--reporter=verbose" "--color"))
     (pest . ("./vendor/bin/pest"))
     (ert . ("cask" "exec" "ert-runner"))))

(setq testrun-mode-alist
  '((js-mode . jest)
     (js-ts-mode . jest)
     (typescript-mode . jest)
     (typescript-ts-mode . jest)
     (tsx-ts-mode . jest)
     (php-mode . pest)
     (php-ts-mode . pest)
     (emacs-lisp-mode . ert)))

(defun testrun-pest-get-test (scope)
  "Get pest test for SCOPE."
  (pcase scope
    ("nearest"
      (let* ((node (treesit-node-at (point)))
              ;; Try Pest-style first: it() / test()
              (pest-node (treesit-parent-until
                           node
                           (lambda (n)
                             (and (string= (treesit-node-type n) "function_call_expression")
                               (member (treesit-node-text
                                         (treesit-node-child n 0) t)
                                 '("it" "test"))))))
              ;; Try PHPUnit-style: method_declaration
              (phpunit-node (treesit-parent-until
                              node
                              (lambda (n)
                                (string= (treesit-node-type n) "method_declaration")))))
        (cond
          (pest-node
            (let* ((args (treesit-node-child-by-field-name pest-node "arguments"))
                    (name (treesit-node-text (treesit-node-child args 1) t)))
              (concat (buffer-file-name) " --filter=" name)))
          (phpunit-node
            (let ((name (treesit-node-text
                          (treesit-node-child-by-field-name phpunit-node "name") t)))
              (concat (buffer-file-name) " --filter=" name)))
          (t (buffer-file-name)))))
    ("namespace" (buffer-file-name))
    ("file" (buffer-file-name))
    ("all" nil)))

(add-to-list 'testrun-runner-function-alist '(pest . testrun-pest-get-test))


(treesit-language-available-p 'php)
