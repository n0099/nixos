{
  flake.modules.homeManager.n0099 =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        kdePackages.krdc
        kdePackages.krfb
        libreoffice-qt-fresh
      ];
    };
}
