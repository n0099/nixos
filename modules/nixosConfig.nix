{
  config,
  lib,
  inputs,
  ...
}:

# https://github.com/drupol/infra/blob/b27e16e42f26d4130dbd2a54d07b2b5d7498ccab/modules/flake-parts/host-machines.nix
let
  specialArgs = { inherit inputs; };
in
{
  flake.nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    inherit specialArgs; # https://jade.fyi/blog/flakes-arent-real/#injecting-dependencies
    modules = [
      { imports = lib.attrValues config.flake.modules.nixos; } # https://github.com/drupol/infra/blob/b27e16e42f26d4130dbd2a54d07b2b5d7498ccab/modules/hosts/imac/default.nix
      {
        home-manager = {
          users.n0099.imports = lib.attrValues config.flake.modules.homeManager;
          extraSpecialArgs = specialArgs; # https://discourse.nixos.org/t/pass-specialargs-to-the-home-manager-module/33068
        };
      }
    ];
  };
}
