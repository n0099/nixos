{ lib, ... }:

lib.foldl lib.recursiveUpdate { } [
  {
    flake.modules = {
      nixos.osu.n0099.permittedUnfreePackages = [ "osu-lazer-bin" ];
      homeManager.osu =
        { pkgs, ... }:

        {
          home.packages = [ pkgs.osu-lazer-bin ];
        };
    };
  }
  {
    flake.modules = {
      nixos.ratbag.services.ratbagd.enable = true;
      homeManager.piper =
        { pkgs, ... }:

        {
          home.packages = [ pkgs.piper ];
        };
    };
  }
]
