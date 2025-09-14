{
  inputs = {
    nixpkgs.url = "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixos-25.05/nixexprs.tar.xz";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    {
      withModules =
        extraInputs:
        let
          specialArgs = {
            # https://jade.fyi/blog/flakes-arent-real/#injecting-dependencies
            inputs = {
              inherit nixpkgs home-manager;
            }
            // inputs
            // extraInputs;
          };
        in
        extraModules: {
          nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            inherit specialArgs;
            modules = [
              {
                nix.settings.substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ]; # https://mirrors.tuna.tsinghua.edu.cn/help/nix-channels/
              }
              ./system.nix
              ./nginx.nix
              ./nixvim.nix
              ./containers.nix
              home-manager.nixosModules.home-manager
              {
                home-manager = {
                  extraSpecialArgs = specialArgs; # https://discourse.nixos.org/t/pass-specialargs-to-the-home-manager-module/33068
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  users.n0099 = import ./home/n0099.nix extraModules.home-manager;
                };
              }
            ]
            ++ extraModules.nixos;
          };
        };
    };
}
