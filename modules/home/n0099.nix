{
  flake.modules.homeManager.n0099 =
    { pkgs, inputs, ... }:

    {
      home.packages =
        with pkgs;
        [
          clash-verge-rev
          kdePackages.krdc
          kdePackages.krfb
          libreoffice-qt-fresh
        ]
        ++ (
          let
            # https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree
            # https://discourse.nixos.org/t/1000-instances-of-nixpkgs/17347
            pkgs-unfree = import inputs.nixpkgs {
              inherit (pkgs) system;
              config.allowUnfreePredicate = pkg: lib.elem (lib.getName pkg) [ "osu-lazer-bin" ];
            };
          in
          [ pkgs-unfree.osu-lazer-bin ]
        );
    };
}
