{
  nixConfig.experimental-features = [
    # https://github.com/NixOS/nix/issues/5988
    "nix-command"
    "flakes"
  ];
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs"; # https://discourse.nixos.org/t/flake-how-make-nixpkgs-self-follow-another-inputs-nixpkgs/10867
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs: {
    withModules =
      extraInputs:
      let
        specialArgs = {
          # https://jade.fyi/blog/flakes-arent-real/#injecting-dependencies
          inputs = inputs // extraInputs;
        };
      in
      extraModules: {
        nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem (
          let
            system = "x86_64-linux";
          in
          {
            inherit specialArgs;
            modules = [
              {
                nix.settings.experimental-features = [
                  "nix-command"
                  "flakes"
                ];
              }
              ./system.nix
              ./boot.nix
              ./zfs.nix
              ./nginx.nix
              ./nixvim.nix
              inputs.home-manager.nixosModules.home-manager
              {
                home-manager = {
                  extraSpecialArgs = specialArgs; # https://discourse.nixos.org/t/pass-specialargs-to-the-home-manager-module/33068
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  users.n0099 = import ./home/n0099.nix extraModules.home-manager or [ ];
                };
              }
            ]
            ++ extraModules.nixos or [ ];
          }
        );
      };
  };
}
