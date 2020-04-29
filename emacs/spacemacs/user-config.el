(defun std::edit-org-user-config ()
  "Edit the org user config file, in the current window."
  (interactive)
  (find-file-existing (concat dotspacemacs-directory "/user-config.org")))

(spacemacs/set-leader-keys
  "feo" #'std::edit-org-user-config)

(defun std::org-files ()
  (interactive)
  (require 'helm)
  (helm :prompt "Org File: "
        :buffer "*helm org files*"
        :sources (helm-build-sync-source "Org Files"
                   :candidates (--map (cons (f-filename it) it) (f-files org-directory))
                   :action #'find-file-existing
                   :filtered-candidate-transformer #'helm-fuzzy-highlight-matches)))

(spacemacs/set-leader-keys
  "aof" #'std::org-files)

(defmacro after! (feature &rest body)
  "Run BODY after loading FEATURE.
Same as `with-eval-after-load', but there is no need to quote FEATURE."
  (declare (debug (sexp body)) (indent 1))
  `(with-eval-after-load ,(if (stringp feature) feature `(quote ,feature))
     ,@body))

(defmacro keybind! (keymaps &rest keybinds)
  (declare (indent 1))
  (cl-assert (= 0 (% (length keybinds) 2)) "Uneven number of keybinds!")
  (unless (listp keymaps)
    (setq keymaps (list keymaps)))
  (unless (listp keymaps)
    (setq keymaps (list keymaps)))
  (-let [bind-forms nil]
    (while keybinds
      (-let [(key func . rest) keybinds]
        (-let [key (if (vectorp key) key `(kbd ,key))]
          (dolist (keymap keymaps)
            (push `(define-key ,keymap ,key ,func) bind-forms)))
        (setq keybinds rest)))
    `(progn ,@(nreverse bind-forms))))

(defmacro set-local! (&rest binds)
  (cl-assert (cl-evenp (length binds)))
  (-let [pairs nil]
    (while binds
      (push (cons (pop binds) (pop binds)) pairs))
    `(progn
       ,@(--map
          `(setq-local ,(car it) ,(cdr it))
          (nreverse pairs)))))

(global-company-mode t)

(after! company
  (setq
   company-abort-manual-when-too-short t
   company-auto-complete               nil
   company-async-timeout               10
   company-dabbrev-code-ignore-case    nil
   company-dabbrev-downcase            nil
   company-dabbrev-ignore-case         nil
   company-etags-ignore-case           nil
   company-idle-delay                  0.5
   company-minimum-prefix-length       2
   company-require-match               nil
   company-selection-wrap-around       t
   company-show-numbers                t
   company-tooltip-flip-when-above     nil))

(after! company
  (setq
   company-tooltip-minimum-width              70
   company-tooltip-align-annotations          t
   company-tooltip-margin                     2))

(after! company
  (defconst std::company::backend-priorities
    '((company-fish-shell   . 10)
      (company-shell        . 11)
      (company-shell-env    . 12)
      (company-anaconda     . 10)
      (company-capf         . 50)
      (company-yasnippet    . 60)
      (company-keywords     . 70)
      (company-files        . 80)
      (company-dabbrev-code . 90)
      (company-dabbrev      . 100))
    "Alist of backends' priorities.  Smaller number means higher priority.")

  (defun std::company::priority-of-backend (backend)
    "Will retrieve priority of BACKEND.
Defauts to 999 if BACKEND is nul or has no priority defined."
    (let ((pr (cdr (assoc backend std::company::backend-priorities))))
      (if (null pr) 999 pr)))

  (defun std::company::priority-compare (c1 c2)
    "Compares the priorities of C1 & C2."
    (let* ((b1   (get-text-property 0 'company-backend c1))
           (b2   (get-text-property 0 'company-backend c2))
           (p1   (std::company::priority-of-backend b1))
           (p2   (std::company::priority-of-backend b2))
           (diff (- p1 p2)))
      (< diff 0)))

  (defun std::company::sort-by-backend-priority (candidates)
    "Will sort completion CANDIDATES according to their priorities."
    (sort (delete-dups candidates) #'std::company::priority-compare)))

(defun std::company::use-completions-priority-sorting ()
  (setq-local company-transformers '(company-flx-transformer company-sort-by-occurrence std::company::sort-by-backend-priority)))

(--each '(rust-mode-hook fish-mode-hook python-mode-hook)
  (add-hook it #'std::company::use-completions-priority-sorting))

(after! company
  (company-flx-mode t)
  (setq company-flx-limit 100))

(global-set-key (kbd "C-@") 'company-complete)

(after! org
  (defun org-switch-to-buffer-other-window (&rest args)
    "Same as the original, but lacking the wrapping call to `org-no-popups'"
    (apply 'switch-to-buffer-other-window args)))

(after! org
  (defun std::org::capture-std-target ()
    `(file+headline
      ,(concat org-directory "Capture.org")
      ,(if (s-equals? (system-name) "a-laptop")
           "Ideen"
         "Postfach"))))

(after! org
  (defun std::org::table-recalc ()
    "Reverse the prefix arg bevaviour of `org-table-recalculate', such that
by default the entire table is recalculated, while with a prefix arg recalculates
only the current cell."
    (interactive)
    (setq current-prefix-arg (not current-prefix-arg))
    (call-interactively #'org-table-recalculate)))

(after! org
  (defun std::org::table-switch-right ()
    "Switch content of current table cell with the cell to the right."
    (interactive)
    (when (org-at-table-p)
      (std::org::table-switch (org-table-current-line) (1+ (org-table-current-column)))))

  (defun std::org::table-switch-left ()
    "Switch content of current table cell with the cell to the left."
    (interactive)
    (when (org-at-table-p)
      (std::org::table-switch (org-table-current-line) (1- (org-table-current-column)))))

  (defun std::org::table-switch (x2 y2)
    (let* ((p  (point))
           (x1 (org-table-current-line))
           (y1 (org-table-current-column))
           (t1 (org-table-get x1 y1))
           (t2 (org-table-get x2 y2)))
      (org-table-put x1 y1 t2)
      (org-table-put x2 y2 t1 t)
      (goto-char p))))

(after! org
  (defun std::org::plot-table ()
    "Plot table at point and clear image cache.
The cache clearing will update tables visible as inline images."
    (interactive)
    (save-excursion
      (org-plot/gnuplot)
      (clear-image-cache))))

(setq-default org-directory          "~/Documents/Org/"
              org-default-notes-file (concat org-directory "Notes.org"))

(after! org
  (setq org-startup-folded             t
        org-startup-indented           nil
        org-startup-align-all-tables   t
        org-startup-with-inline-images nil))

(setq org-agenda-files (list "~/Documents/Org/Agenda.org"))



(after! org
  (setq-default org-todo-keywords '((sequence "[TODO]" "|" "[DONE]"))))

(after! org
  (setq
   org-special-ctrl-k         t
   org-special-ctrl-o         nil
   org-special-ctrl-a/e       t
   org-ctrl-k-protect-subtree nil))

(after! org
  (setq
   org-capture-templates
   `(("t" "Idee/Todo" entry
      ,(std::org::capture-std-target)
      "** [TODO] %?\n %U"))))

(after! org
  (setq
   ;; ARTHUR Customs
   org-checkbox-hierarchical-statistics    nil
   org-export-backends                     '(ascii html icalendar latex md odt)
   org-hierarchical-todo-statistics        nil))

(after! org
   (require 'ob-shell)
   (require 'ob-python)

    (org-babel-do-load-languages 'org-babel-load-languages
    '((shell . t)
      (python . t)
      (ditaa . t)
      (emacs-lisp . t))))

(after! org
    (setq org-org-ditaa-jar-path "/usr/share/ditaa/ditaa.jar"))

(defun std::projectile::magit-status (&optional arg)
  "Use projectile with Helm for running `magit-status'

  With a prefix ARG invalidates the cache first."
     (interactive "P")
     (if (projectile-project-p)
         (projectile-maybe-invalidate-cache arg))
     (let ((helm-ff-transformer-show-only-basename nil)
           (helm-boring-file-regexp-list           nil))
       (helm :prompt "Git status in project: "
             :buffer "*helm projectile*"
             :sources (helm-build-sync-source "Projectile Projects"
                        :candidates projectile-known-projects
                        :action #'magit-status
                        :filtered-candidate-transformer 'helm-fuzzy-highlight-matches))))

(after! projectile
  (spacemacs/set-leader-keys
    "pg"  nil
    "pt"  #'projectile-find-tag
    "psa" #'helm-projectile-ag
    "pgs" #'std::projectile::magit-status
    "pC"  #'projectile-cleanup-known-projects))

(after! projectile
  (setq projectile-switch-project-action #'projectile-dired))

(global-set-key (kbd "C-S-c C-S-c") 'mc/edit-lines)
(global-set-key (kbd "C->") 'mc/mark-next-like-this)
(global-set-key (kbd "C-<") 'mc/mark-previous-like-this)

(add-to-list 'auto-mode-alist '("\\.launch\\'" . xml-mode))

(add-hook 'python-mode (lambda()
                         (require sphinx-doc)
                         (sphinx-doc-mode t)))

(global-set-key (kbd "M-]") 'fixup-whitespace)

(global-set-key [f12]
                '(lambda ()
                   (interactive)
                   (if (buffer-file-name)
                       (let*
                           ((fName (upcase (file-name-nondirectory (file-name-sans-extension buffer-file-name))))
                            (ifDef (concat "#ifndef " fName "_H" "\n#define " fName "_H" "\n"))
                            (begin (point-marker))
                            )
                         (progn
                                      ;Insert the Header Guard
                           (goto-char (point-min))
                           (insert ifDef)
                           (goto-char (point-max))
                           (insert "\n#endif" " //" fName "_H")
                           (goto-char begin))
                         )
                                      ;else
                     (message (concat "Buffer " (buffer-name) " must have a filename"))
                     )
                   )
                )

(setq
  scroll-conservatively           20
  scroll-margin                   10
  scroll-preserve-screen-position t)

(global-subword-mode t)

;; (global-hl-line-mode -1)
(blink-cursor-mode -1)

(setq-default
 prettify-symbols-alist
 `(("lambda" . "λ")
   ("!="     . "≠")))
(add-hook 'prog-mode-hook #'prettify-symbols-mode)

(setq imenu-list-auto-resize nil)

(setq next-line-add-newlines nil)

(setq-default truncate-lines t)

(setq load-prefer-newer t)

(setq-default tab-width 4)

(setq vc-follow-symlinks t)

(setq browse-url-browser-function #'browse-url-firefox)
