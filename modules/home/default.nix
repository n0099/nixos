{ inputs, ... }:

{
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager/release-26.05";
    inputs.nixpkgs.follows = "nixpkgs"; # https://discourse.nixos.org/t/flake-how-make-nixpkgs-self-follow-another-inputs-nixpkgs/10867
  };
  flake.modules = {
    nixos.home-manager = {
      imports = [ inputs.home-manager.nixosModules.home-manager ];
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
      };
    };
    homeManager.home =
      { osConfig, ... }:

      {
        home.stateVersion = osConfig.system.nixos.release;
      };
  };
}
