{
  flake.modules.nixos.system =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    {
      nix = {
        channel.enable = false; # https://github.com/NixOS/nix/issues/2982#issuecomment-2477618346
        # https://wiki.nixos.org/wiki/Storage_optimization
        gc.automatic = true;
        optimise.automatic = true;
      };
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
      security = {
        dhparams = {
          enable = true;
          stateful = false;
          defaultBitSize = 4096;
        };
      };
    };
}
