;;; +haskell.el --- description -*- lexical-binding: t; -*-

(require 'dash)

(defun grfn/haskell-test-file-p ()
  (string-match-p (rx (and ".hs" eol))
                  (buffer-file-name)))

(defun grfn/intero-run-tests ()
  (interactive)
  (when (grfn/haskell-test-file-p)
    (intero-repl-load)
    (let ((last-buffer (current-buffer)))
      (intero-with-repl-buffer nil
        (comint-simple-send
         (get-buffer-process (current-buffer))
         "main"))
      ;;(switch-to-buffer-other-window last-buffer)
      )))


(def-package! intero
  :after haskell-mode
  :config
  (setq haskell-font-lock-symbols t)
  (intero-global-mode 1)
  (eldoc-mode)
  (turn-off-smartparens-mode)
  (flycheck-add-next-checker 'intero 'haskell-hlint)

  ;; (let (m-symbols
  ;;       '(("`mappend`" . "⊕")
  ;;         ("<>"        . "⊕")))
  ;;   (dolist (item m-symbols) (add-to-list 'haskell-font-lock-symbols-alist item)))

  (setq haskell-font-lock-symbols-alist (-reject
                                         (lambda (elem)
                                           (string-equal "()" (car elem)))
                                         haskell-font-lock-symbols-alist)))

(map!
 (:after haskell-mode
  (:map haskell-mode-map
     :n "K"     'intero-info
     :n "g i"   'intero-info
     :n "g d"   'intero-goto-definition
     :n "g SPC" 'intero-repl-load
     :n "g \\"  'intero-repl
     :n "g y"   'intero-type-at
     :n "g t"   'intero-type-at
     :n "g RET" 'grfn/intero-run-tests)))


(defun urbint/format-haskell-source ()
  (interactive)
  (let ((output-buffer (generate-new-buffer "brittany-out"))
        (config-file-path
         (concat (string-trim
                  (shell-command-to-string "stack path --project-root"))
                 "/brittany.yaml")))
    (when (= 0 (call-process-region
                (point-min) (point-max)
                "stack"
                nil output-buffer nil
                "exec" "--" "brittany" "--config-file" config-file-path))
      (let ((pt (point))
            (wst (window-start))
            (formatted-source (with-current-buffer output-buffer
                                (buffer-string))))
        (erase-buffer)
        (insert formatted-source)
        (goto-char pt)
        (set-window-start nil wst)))))

(add-hook
 'before-save-hook
 (lambda ()
   (when (eq major-mode 'haskell-mode)
     (urbint/format-haskell-source))))

