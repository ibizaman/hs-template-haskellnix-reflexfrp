# Introduction

This document explains the various apps found in this projects.

All the commands are to be run inside the `nix` shell environment:

```bash
nix-shell
```

# Backend

```bash
cabal run backend-exe
```

# Frontend

We have 3 GHC frontend apps and 2 of them cross-compilable with GHCJS.
A few combinations make sense and are explained below.

## NoCss (GHC)

A "legacy" app that runs the frontend without any CSS.

### GHC version

```bash
cabal run frontend-nocss
```

## GHCJS version

```bash
cabal build --cabal-file=cabal.ghcjs.project --ghcjs frontend-nocss
# open main.html in a browser
```

## GenerateCss - ExternalCss

These two apps work in tandem. The `GenerateCss` app generates a CSS
file that is used by the `ExternalCss` one. The `ExternalCss` app
references the CSS file by path so both apps need to agree on the file
location.

### GHC version for GenerateCss and ExternalCss

```bash
cabal run frontend-generatecss
cabal run frontend-externalcss
```

### GHC version for GenerateCss and GHCJS for ExternalCss

```bash
cabal run frontend-generatecss
cabal build --cabal-file=cabal.ghcjs.project --ghcjs frontend-externalcss
# open main.html in a browser
```
