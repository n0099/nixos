{
  flake.modules = {
    nixos.jetbrains.n0099.permittedUnfreePackages = [
      "idea"
      "datagrip"
      "phpstorm"
      "rider"
    ];
    homeManager.jetbrains =
      { pkgs, ... }:

      {
        home.packages = with pkgs.jetbrains; [
          idea
          datagrip
          phpstorm
          rider
        ];
      };
  };
}
