{
  inputs = {
    base.url = "./base";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "base/nixpkgs"; # https://discourse.nixos.org/t/flake-how-make-nixpkgs-self-follow-another-inputs-nixpkgs/10867
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "base/nixpkgs";
      inputs.home-manager.follows = "base/home-manager";
    };
    minegrub-world-sel-theme = {
      url = "github:Lxtharia/minegrub-world-sel-theme";
      inputs.nixpkgs.follows = "base/nixpkgs";
    };
  };
  outputs =
    { base, ... }@inputs:

    with { inherit (base.inputs) flake-parts import-tree; };
    flake-parts.lib.mkFlake { inputs = base.inputs // inputs; } {
      imports = [
        { flake.modules.nixos.configuration.imports = [ ./configuration.nix ]; }
      ]
      ++ [
        flake-parts.flakeModules.modules
        (import-tree [
          ./base/modules
          ./modules
        ])
      ];
    };
}
