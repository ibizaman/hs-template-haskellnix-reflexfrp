let
  sources = import ./nix/sources.nix {};

  # Fetch the haskell.nix commit we have pinned with Niv
  haskellNix = import sources.haskellNix {
    sourcesOverride = {
      hackage = sources.hackage;
      stackage = sources.stackage;
    };
  };

  # If haskellNix is not found run:
  #   niv add input-output-hk/haskell.nix -n haskellNix

  # Import nixpkgs and pass the haskell.nix provided nixpkgsArgs
  pkgs = import
    # haskell.nix provides access to the nixpkgs pins which are used by our CI,
    # hence you will be more likely to get cache hits when using these.
    # But you can also just use your own, e.g. '<nixpkgs>'.
    haskellNix.sources.nixpkgs-unstable
    # These arguments passed to nixpkgs, include some patches and also
    # the haskell.nix functionality itself as an overlay.
    haskellNix.nixpkgsArgs;
  project = pkgs.haskell-nix.project {
    # 'cleanGit' cleans a source directory based on the files known by git
    src = pkgs.haskell-nix.haskellLib.cleanGit {
      name = "hs-template-haskellnix-reflexfrp";
      src = ./.;
    };
    # Specify the GHC version to use. See
    # https://input-output-hk.github.io/haskell.nix/reference/supported-ghc-versions/
    # and
    # https://github.com/input-output-hk/haskell.nix/blob/master/ci.nix
    # for which versions are cached by CI.
    compiler-nix-name = "ghc8107";
  };
in project
