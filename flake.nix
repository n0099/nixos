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
    {
      base,
      nur,
      plasma-manager,
      ...
    }@inputs:
    (base.outputs.withModules ({ inherit nur; } // inputs) {
      nixos = [
        nur.modules.nixos.default # https://nur.nix-community.org/documentation/#using-the-flake-in-nixos
        ./configuration.nix
        ./boot.nix
        ./zfs.nix
        ./desktop.nix
        ./substituters.nix
        ./containers
        ./secrets
        ./proxy.nix
        ./wireguard.nix
      ];
      home-manager = [
        plasma-manager.homeModules.plasma-manager
        ./home/n0099.nix
      ];
    });
}
