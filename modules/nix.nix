{ inputs, ... }:

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
  flake.modules.nixos.nix.nix = {
    settings.experimental-features = features;
    channel.enable = false; # https://github.com/NixOS/nix/issues/2982#issuecomment-2477618346
    # https://wiki.nixos.org/wiki/Storage_optimization
    gc.automatic = true;
    optimise.automatic = true;
  };
}
