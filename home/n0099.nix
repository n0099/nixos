{ pkgs, ... }:

{
  home.packages =
    with pkgs;
    [
      clash-verge-rev
      remmina
      kdePackages.krdc
      kdePackages.krfb
    ];
}
