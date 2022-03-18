# Build

## Prerequesites

This template project assumes you have ghcjs in your path. You don't
need ghc. I'm working on this project providing ghcjs directly but
it's not there yet.

## Environment

All the commands need to run inside a nix shell environment, so run
the following command and issue all commands inside:

```bash
nix-shell
```

## Change package.yaml

```bash
find . -name package.yaml -exec hpack '{}' ';'
```

## Backend

You need to build the `backend` with GHC.

```bash
cabal build --cabal-file=cabal.project --ghc backend
```

You can leave out the `--cabal-file` and `--ghc` arguments as those
are the default.

## Frontend

You can either build the frontend as a desktop application or as a
javascript app.

For a desktop application, build the frontend with GHC:

```bash
cabal build --cabal-file=cabal.project --ghc frontend
```

For a javascript application, build the frontend with GHCJS:

```bash
cabal build --cabal-file=cabal.ghcjs.project --ghcjs frontend
```

Although the `cabal.ghcjs.project` defines the `with-compiler: ghcjs`
field, you still need to give the `--ghcjs` argument.

# Run

Whatever the frontend, the backend is run the same way:

```bash
cabal run --cabal-file=cabal.project --ghc backend-exe
```

Giving arguments to the backend is done by separating them with a
double dash:

```bash
cabal run --cabal-file=cabal.project --ghc backend-exe -- --help
cabal run --cabal-file=cabal.project --ghc backend-exe -- --listen-port=8000 --listen-address="127.0.0.1"
```

For a desktop app, run the frontend like this:

```bash
cabal run --cabal-file=cabal.project --ghc frontend-exe
```

# Test

```bash
cabal run --cabal-file=cabal.project --ghc backend-test
cabal run --cabal-file=cabal.project --ghc backend-common
```
