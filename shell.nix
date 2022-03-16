(import ./default.nix).shellFor {
  tools = {
    cabal = "latest";
    hlint = "latest";
    hspec-discover = "latest";
    haskell-language-server = "latest";
  };

  # crossPlatforms = p: [ p.ghcjs ];
}
