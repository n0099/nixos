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
      openssh.authorizedKeys.keys = (import ./toBeFilled/lib.nix lib).readStrings ./toBeFilled/users/n0099/sshPublicKeys;
    };
  };
  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    vnstat.enable = true;
    netdata.enable = true;
  };
  programs = {
    zsh.enable = true;
    git.enable = true;
    atop = {
      enable = true;
      atopService.enable = false;
      settings.interval = 1;
    };
  };
  security = {
    # https://unix.stackexchange.com/questions/382060/change-default-sudo-password-timeout
    sudo.configFile = "Defaults timestamp_timeout=15";
  };
  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };
}
