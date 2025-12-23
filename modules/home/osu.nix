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
