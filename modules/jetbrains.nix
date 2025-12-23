{
  flake.modules = {
    nixos.jetbrains.n0099.permittedUnfreePackages = [
      "idea-ultimate"
      "datagrip"
      "phpstorm"
      "rider"
    ];
    homeManager.jetbrains =
      { pkgs, ... }:

      {
        home.packages = with pkgs.jetbrains; [
          idea-ultimate
          datagrip
          phpstorm
          rider
        ];
      };
  };
}
