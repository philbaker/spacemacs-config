;; -*- mode: emacs-lisp; lexical-binding: t -*-

;; ---------------------------------------
;; General Configuration changes
;; ---------------------------------------

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

;; ---------------------------------------
