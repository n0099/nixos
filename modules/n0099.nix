{
  flake.modules.homeManager.n0099 =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        clash-verge-rev
        kdePackages.krdc
        kdePackages.krfb
        libreoffice-qt-fresh
      ];
    };
}
