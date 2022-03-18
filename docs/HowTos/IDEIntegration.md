# How to integrate haskell-language-server in your IDE

I'm using Emacs so I only know about how to configure this one. If
anyone has links to other editor setups, I'd be happy to add them
here.

I just know the usual recommendation is to start your editor from `nix-shell` directly, something like:
```bash
nix-shell
node .
```

## Emacs

I'm running Emacs as a daemon so it can't start from the nix-shell of
this project. Instead, I'm using `nix-sandbox` from
[travisbhartwell/nix-emacs](https://github.com/travisbhartwell/nix-emacs).
This allows emacs to pick the binaries from `nix-shell` and to
fallback to the environment when they can't be found. The only caveat
is you sometimes need to run these commands to pick up new things,
like after changing the `.cabal` files.

```elisp
nix-clear-caches
lsp-workspace-restart
```

Note: I am copy-pasting the relevant sections of my configuration.
Some settings are left that has nothing to do with the IDE integration
but I left them in.

```elisp
(use-package nix-sandbox
  :straight t)
```

Setting up flycheck:

```elisp
(use-package flycheck
  :straight t
  :after nix-sandbox
  :init
  (add-hook 'after-init-hook 'global-flycheck-mode)

  ;; from https://github.com/travisbhartwell/nix-emacs#flycheck
  (defun my/nix--flycheck-command-wrapper (command)
    (if-let ((sandbox (nix-current-sandbox)))
        (apply 'nix-shell-command sandbox command)
      command))
  (defun my/nix--flycheck-executable-find (cmd)
    (if-let ((sandbox (nix-current-sandbox)))
        (nix-executable-find sandbox cmd)
      (flycheck-default-executable-find cmd)))

  :config
  (setq flycheck-check-syntax-automatically '(save idle-change idle-buffer-switch)
        flycheck-relevant-error-other-file-show nil
        flycheck-command-wrapper-function 'my/nix--flycheck-command-wrapper
        flycheck-executable-find 'my/nix--flycheck-executable-find)
  (add-to-list 'display-buffer-alist
               `(,(rx bos "*Flycheck errors*" eos)
                 (display-buffer-reuse-window
                  display-buffer-in-side-window)
                 (side            . bottom)
                 (reusable-frames . visible)
                 (window-height   . 0.33))))
```

Setting up haskell-mode:

(I didn't spend a lot of time cleaning this up, so there's a bit hardcoded here)

```elisp
(use-package haskell-mode
  :straight t
  :after nix-sandbox
  :init
  (defun my/haskell-set-stylish ()
    (if-let* ((sandbox (nix-current-sandbox))
              (fullcmd (nix-shell-command sandbox "stylish-haskell"))
              (path (car fullcmd))
              (args (cdr fullcmd)))
      (setq-local haskell-mode-stylish-haskell-path path
                  haskell-mode-stylish-haskell-args args)))
  (defun my/haskell-set-hoogle ()
    (if-let* ((sandbox (nix-current-sandbox)))
        (setq-local haskell-hoogle-command (nix-shell-string sandbox "hoogle"))))
  :hook ((haskell-mode . capitalized-words-mode)
         (haskell-mode . haskell-decl-scan-mode)
         (haskell-mode . haskell-indent-mode)
         (haskell-mode . haskell-indentation-mode)
         (haskell-mode . my/haskell-set-stylish)
         (haskell-mode . my/haskell-set-hoogle)
         (haskell-mode . lsp-deferred)
         (haskell-mode . haskell-auto-insert-module-template))
  :config
  (defun my/haskell-hoogle--server-command (port)
    (if-let* ((hooglecmd `("hoogle" "serve" "--local" "-p" ,(number-to-string port)))
              (sandbox (nix-current-sandbox)))
        (apply 'nix-shell-command sandbox hooglecmd)
      hooglecmd))
  (setq haskell-hoogle-server-command 'my/haskell-hoogle--server-command
        haskell-stylish-on-save t
		lsp-haskell-formatting-provider "stylish-haskell"))
```

lsp-haskell setup:

```elisp
(use-package lsp-haskell
  :straight t
  :after nix-sandbox
  :init
  (setq lsp-prefer-flymake nil)
  (require 'lsp-haskell)
  :config
  ;; from https://github.com/travisbhartwell/nix-emacs#haskell-mode
  (defun my/nix--lsp-haskell-wrapper (args)
    (if-let ((sandbox (nix-current-sandbox)))
        (apply 'nix-shell-command sandbox args)
      args))
  (setq lsp-haskell-server-path "haskell-language-server"
        lsp-haskell-server-wrapper-function 'my/nix--lsp-haskell-wrapper))
```
