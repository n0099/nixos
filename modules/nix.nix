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
  flake.modules.nixos.nix.nix.settings.experimental-features = features;
}
