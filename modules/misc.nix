{
  flake.modules.nixos.misc =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    {
      time.timeZone = "UTC";
      i18n.defaultLocale = "C.UTF-8";
      users = {
        mutableUsers = false;
        users.n0099 = {
          extraGroups = [ "wheel" ];
          isNormalUser = true;
          shell = pkgs.zsh;
          hashedPasswordFile = config.age.secrets."users.n0099.hashedPassword".path;
          openssh.authorizedKeys.keys =
            ../toBeFilled/users/n0099/sshPublicKeys |> (import ../toBeFilled/lib.nix lib).readStrings;
        };
      };
      services = {
        vnstat.enable = true;
        netdata.enable = true;
      };
      programs.atop = {
        enable = true;
        # netatop.enable = true; # https://github.com/Atoptool/atop/issues/351
        settings.interval = 1;
      }
      // {
        atopService.enable = false;
        atopRotateTimer.enable = false;
      };
      systemd.settings.Manager.StatusUnitFormat = "combined"; # https://github.com/systemd/systemd/pull/15957
      services.kmscon = {
        enable = true;
        useXkbConfig = true;
        fonts = [
          {
            name = "FiraCode Nerd Font Ret";
            package = pkgs.nerd-fonts.fira-code;
          }
        ];
      };
    };
}
