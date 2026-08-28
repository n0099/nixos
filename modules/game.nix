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
        environment.systemPackages = with pkgs; [
          wineWow64Packages.waylandFull
          winetricks # https://github.com/NixOS/nixpkgs/issues/338367#issuecomment-3759333790
        ];
      }
      {
        programs.steam = {
          protontricks.enable = true;
          extraCompatPackages = with pkgs; [
            proton-ge-bin
            dwproton-bin
          ];
        };
        environment.systemPackages = [ pkgs.umu-launcher ];
      }
      {
        environment.systemPackages = [ pkgs.mangohud ];
      }
      {
        programs.steam.gamescopeSession.enable = true;
      }
      {
        # https://discourse.nixos.org/t/unable-to-activate-gamescope-capsysnice-option/37843/6
        # https://github.com/NixOS/nixpkgs/issues/312195
        # programs.gamescope.capSysNice = true;
        services.ananicy = {
          enable = true;
          package = pkgs.ananicy-cpp;
          rulesProvider = pkgs.ananicy-rules-cachyos;
        };
      }
      {
        services.scx.enable = true;
      }
    ];
}
