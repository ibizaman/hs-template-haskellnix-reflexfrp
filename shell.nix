(import ./default.nix).shellFor {
  tools = {
    cabal = "latest";
    happy = "1.20.0"; # Needed for haskell-src-exts
    hlint = "latest";
    hspec-discover = "latest";
    haskell-language-server = "latest";
  };

  # crossPlatforms = p: [ p.ghcjs ];
}
