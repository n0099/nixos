{ pkgs, ... }:

{
  imports = [
    ./browser.nix
  ];
  home.packages =
    with pkgs;
    [
      clash-verge-rev
      remmina
      kdePackages.krdc
      kdePackages.krfb
    ];
}
