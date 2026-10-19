{ lib, inputs, ... }:

lib.foldl lib.recursiveUpdate { } [
  (
    let
      features = [
        # https://github.com/NixOS/nix/issues/5988
        "nix-command"
        "flakes"
      ]
      ++ [
        "pipe-operators"
      ];
    in
    {
      imports = [ inputs.flake-file.flakeModules.default ];
      flake-file.nixConfig.experimental-features = features;
      flake.modules.nixos.nix.nix.settings.experimental-features = features;
    }
  )
  {
    flake.modules.nixos.nix.nix = {
      channel.enable = false; # https://github.com/NixOS/nix/issues/2982#issuecomment-2477618346
    }
    // {
      # https://wiki.nixos.org/wiki/Storage_optimization
      gc.automatic = true;
      optimise.automatic = true;
    };
  }
  {
    flake-file.inputs.detsys-nix = {
      url = "https://flakehub.com/f/DeterminateSystems/nix-src/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake.modules = {
      nixos.detsys = {
        nixpkgs.overlays = [
          (
            final: _:
            let
              nixComponents = inputs.detsys-nix.lib.makeComponents { pkgs = final; };
              wasmtime = nixComponents.callPackage ({ wasmtime }: wasmtime) { }; # https://github.com/NixOS/nixpkgs/blob/52a12bfc679e1930f1a043407935b7eddf55b999/lib/customisation.nix#L725
              overrideWasmtime = pkg: pkg.override { wasmtime = wasmtime.overrideAttrs { doCheck = false; }; }; # https://github.com/DeterminateSystems/nix-src/pull/703
              overridedScope = nixComponents.overrideScope (
                _: prev: {
                  # https://github.com/DeterminateSystems/nix-src/blob/50a2d3cf03b5afc3738b917426e6ddd0585d41a3/packaging/components.nix#L450-L459
                  nix-store = overrideWasmtime prev.nix-store; # https://github.com/DeterminateSystems/nix-src/blob/0eea07b88772bff7ffb41fc31db0616b328cab89/src/libstore/package.nix#L90
                  nix-expr = overrideWasmtime prev.nix-expr; # https://github.com/DeterminateSystems/nix-src/blob/b3649bb3dfae15b1a0018d6cb1cadd881a5f3cdf/src/libexpr/package.nix#L76
                }
              );
            in
            {
              nix = overridedScope.nix-everything; # https://github.com/DeterminateSystems/nix-src/issues/379
            }
          )
        ];
        nix.settings = {
          eval-cores = 0; # https://docs.determinate.systems/determinate-nix/#parallel-evaluation
          lazy-trees = true; # https://lobste.rs/s/wgn94m/introducing_lazy_trees_determinate_nix_3#c_hqsipx
        };
      };
      homeManager.detsys.manual.manpages.enable = false; # https://github.com/nix-community/home-manager/issues/7935#issuecomment-3671184459
    };
  }
]
