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
    flake-file.inputs.detsys-nix.url = "https://flakehub.com/f/DeterminateSystems/nix-src/*";
    flake.modules = {
      nixos.detsys =
        { pkgs, ... }:

        {
          nix = {
            package = inputs.detsys-nix.packages."${pkgs.stdenv.system}".default;
            settings = {
              eval-cores = 0; # https://docs.determinate.systems/determinate-nix/#parallel-evaluation
              lazy-trees = true; # https://lobste.rs/s/wgn94m/introducing_lazy_trees_determinate_nix_3#c_hqsipx
            };
          };
        };
      homeManager.detsys.manual.manpages.enable = false; # https://github.com/nix-community/home-manager/issues/7935#issuecomment-3671184459
    };
  }
]
