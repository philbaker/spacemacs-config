;; ---------------------------------------
;; Version Control configuration - Git, etc
;;
;; https://develop.spacemacs.org/layers/+source-control/version-control/README.html
;; https://develop.spacemacs.org/layers/+source-control/git/README.html
;; Git Delta guide - https://dandavison.github.io/delta/
;; ---------------------------------------

;; ---------------------------------------
;; Spacemacs as $EDITOR (or $GIT_EDITOR) for commit messages
;; for `git commit` on command line
;; (global-git-commit-mode t)
;; ---------------------------------------


;; ---------------------------------------
;; Magit

;; Set locations of all your Git repositories
;; with a number to define how many sub-directories to search
;; `SPC g L' - list all Git repositories in the defined paths,
(setq magit-repository-directories
  '(("~/dev/" . 2)))
