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
  };
  outputs =
    {
      base,
      nur,
      plasma-manager,
      ...
    }@inputs:
    (base.outputs.withModules ({ inherit nur; } // inputs) {
      nixos = [
        {
          nix.settings = {
            # https://nix-community.org/cache/
            substituters = [ "https://nix-community.cachix.org" ];
            trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
          };
        }
        nur.modules.nixos.default # https://nur.nix-community.org/documentation/#using-the-flake-in-nixos
        ./configuration.nix
        ./desktop.nix
        ./zfs.nix
        ./proxy.nix
      ];
      home-manager = [
        plasma-manager.homeModules.plasma-manager
        ./home/n0099.nix
      ];
    });
}
