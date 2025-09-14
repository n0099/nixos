{
  # https://discourse.nixos.org/t/enable-different-priority-substituters-with-flake/56073/7
  nixConfig.substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
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
          # https://jade.fyi/blog/flakes-arent-real/#injecting-dependencies
          specialArgs = {
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
              ./system.nix
              ./nginx.nix
              ./nixvim.nix
              ./containers.nix
              home-manager.nixosModules.home-manager
              {
                home-manager = {
                  # https://discourse.nixos.org/t/pass-specialargs-to-the-home-manager-module/33068
                  extraSpecialArgs = specialArgs;
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
