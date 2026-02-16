{
  flake.modules.nixos.game =
    { pkgs, lib, ... }:

    lib.mkMerge [
      {
        n0099.permittedUnfreePackages = [
          "steam"
          "steam-unwrapped"
        ];
        programs.steam.enable = true;
        services.sanoid.datasets."rpool/ENC/STEAM".autosnap = false;
      }
      {
        environment.systemPackages = [ pkgs.mangohud ];
      }
      {
        # https://github.com/NixOS/nixpkgs/issues/351516#issuecomment-3584219555
        # programs.steam.gamescopeSession.enable = true;
        # programs.gamescope.capSysNice = true;
        services.ananicy = {
          enable = true;
          package = pkgs.ananicy-cpp;
          rulesProvider = pkgs.ananicy-rules-cachyos;
        };
      }
    ];
}
