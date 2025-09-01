{ pkgs, ... }:

{
  users.users.n0099 = {
    extraGroups = [
      "wheel"
      "docker"
    ];
    isNormalUser = true;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLshjq9QWQoWa8lDt3wFuWtcaM6o7hj8rF0s9QGedkn"
    ];
  };
  environment.systemPackages = with pkgs; [ _7zz ];
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
    mysql = {
      enable = true;
      package = pkgs.mariadb_114;
    };
    postgresql.enable = true;
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
  virtualisation.docker = {
    enable = true;
    package = pkgs.docker_28;
  };
  security = {
    # https://unix.stackexchange.com/questions/382060/change-default-sudo-password-timeout
    sudo.configFile = "Defaults timestamp_timeout=15";
  };
  zramSwap.enable = true;
}
