{ inputs, ... }:

{
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
