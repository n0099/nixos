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

    base.inputs.flake-parts.outputs.lib.mkFlake { inherit inputs; } (
      { lib, ... }:

      (
        let
          specialArgs = {
            # https://jade.fyi/blog/flakes-arent-real/#injecting-dependencies
            inputs = lib.removeAttrs inputs [ "base" ] // inputs.base.inputs;
          };
        in
        {
          systems = [ "x86_64-linux" ];
          # systems = base.outputs.systems;
          flake.nixosConfigurations.nixos = base.inputs.nixpkgs.lib.nixosSystem {
            # system is not needed with freshly generated hardware-configuration.nix
            system = "x86_64-linux"; # or set nixpkgs.hostPlatform in a module.
            inherit specialArgs;
            modules = [
              {
                imports = lib.attrValues base.outputs.nixosModules ++ [
                  inputs.nur.modules.nixos.default # https://nur.nix-community.org/documentation/#using-the-flake-in-nixos
                  ./configuration.nix
                  ./boot.nix
                  ./zfs.nix
                  ./march.nix
                  ./stdenv.nix
                  ./desktop.nix
                  ./malloc.nix
                  ./kde.nix
                  ./font.nix
                  ./game.nix
                  ./substituters.nix
                  ./containers
                  ./secrets
                  ./proxy.nix
                  ./wireguard.nix
                ];
              }
              {
                home-manager = {
                  extraSpecialArgs = specialArgs; # https://discourse.nixos.org/t/pass-specialargs-to-the-home-manager-module/33068
                  users.n0099.imports = lib.attrValues base.outputs.homeModules ++ [
                    inputs.plasma-manager.homeModules.plasma-manager
                    inputs.nur.modules.homeManager.default # https://haseebmajid.dev/posts/2023-06-22-til-use-nur-with-home-manager-flake/
                    ./home/n0099.nix
                  ];
                };
              }
            ];
          };
        }
      )
    );
}
