{
  nixConfig.experimental-features = [
    # https://github.com/NixOS/nix/issues/5988
    "nix-command"
    "flakes"
    "pipe-operators"
  ];
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs"; # https://discourse.nixos.org/t/flake-how-make-nixpkgs-self-follow-another-inputs-nixpkgs/10867
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs =
    { flake-parts, ... }@inputs:

    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:

      {
        imports = [
          flake-parts.flakeModules.modules
          inputs.home-manager.flakeModules.home-manager
        ];
        flake = {
          nixosModules =
            lib.genAttrs' [
              ./system.nix
              ./remoteBuild.nix
              ./unfree.nix
              ./boot.nix
              ./zfs.nix
              ./zram.nix
              ./nixvim.nix
              ./nginx
            ] (path: lib.nameValuePair (builtins.baseNameOf path) path)
            // {
              nix.nix.settings.experimental-features = [
                "nix-command"
                "flakes"
                "pipe-operators"
              ];
            }
            // {
              secrets = ./secrets;
              agenix = inputs.agenix.nixosModules.default;
              agenix-cli.environment.systemPackages = [ inputs.agenix.packages.x86_64-linux.default ];
            }
            // {
              home-manager = inputs.home-manager.nixosModules.home-manager;
              home-manager-nixos-module.home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
              };
            };
          homeModules.n0099 = ./home/n0099.nix;
        };
      }
    );
}
