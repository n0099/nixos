{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  home.packages =
    let
      # https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree
      # https://discourse.nixos.org/t/1000-instances-of-nixpkgs/17347
      pkgs-unfree = import inputs.nixpkgs {
        inherit (pkgs) system;
        config.allowUnfreePredicate =
          pkg:
          lib.elem (lib.getName pkg) [
            "idea-ultimate"
            "datagrip"
            "phpstorm"
            "rider"
          ];
      };
    in
    with pkgs-unfree.jetbrains;
    [
      idea-ultimate
      datagrip
      phpstorm
      rider
    ];
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
  };
}
