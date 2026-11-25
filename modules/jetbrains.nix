{
  flake.modules = {
    nixos.jetbrains = {
      n0099.permittedUnfreePackages = [
        "idea"
        "datagrip"
        "phpstorm"
        "rider"
      ];
      nixpkgs.config.permittedInsecurePackages = [ "rider-2026.2.4" ]; # https://github.com/NixOS/nixpkgs/pull/590462
    };
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
