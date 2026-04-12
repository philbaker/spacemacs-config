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
