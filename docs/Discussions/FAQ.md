Some random questions and answers that are too short to grant being in
their own file.

# Why did you create this repo?

I spent a lot of time trying to setup a Haskell project for building
web apps that would work with `haskell-language-server`. And since I
always liked to build tools that help people, I'm sharing this.
Hopefully this will help you.

# Why haskell.nix instead of reflex-platform?

Good question. I actually started with reflex-platform and have
[another repo](https://github.com/ibizaman/hs-template-nix-reflexfrp)
setup with it. I spent a _lot_ of time trying to get
`haskell-language-server` to work, mostly on getting the exact
versions of dependencies correctly, and managed it once. But then I
tried catching up on `reflex-platform` versions and couldn't build
`haskell-language-server`.

I liked that `haskell.nix` would automatically figure out a plan given
the constraints in a `.cabal` file. Everything didn't work out of the
box but at least I didn't need to figure out myself the exact version
of my dependencies.

# Why Reflex and Reflex-dom to build the frontend?

I don't think there's a good reason apart from this FRP idiom really
resonates with me and I want to try using it.

# Why cmdargs instead of optparse-applicative?

I did [try
out](https://github.com/ibizaman/haskell-godaddy/blob/master/app/Args.hs)
`optparse-applicative` but find it a bit too verbose to my taste. I
wanted to try something else and found `cmdargs`. We'll see how that
goes.

# Since this project doesn't provide ghcjs yet, how do you install it?

I'm using NixOS/nixpkgs so I can only offer help if you use that. I
simply installed the `pkgs.haskell.compiler.ghcjs` package.

# What are the next steps here?

See the [Readme.md](../../Readme.md#wip).
