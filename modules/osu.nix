{ lib, ... }:

lib.foldl lib.recursiveUpdate { } [
  {
    flake.modules = {
      nixos.osu.n0099.permittedUnfreePackages = [ "osu-lazer-bin" ]; # https://github.com/ppy/osu-framework/issues/2784
      homeManager.osu =
        { pkgs, ... }:

        {
          home.packages = [ pkgs.osu-lazer-bin ]; # https://github.com/ppy/osu/pull/27681
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
