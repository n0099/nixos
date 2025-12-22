{
  flake.modules = {
    nixos.sudo.security.sudo.configFile = "Defaults timestamp_timeout=15"; # https://unix.stackexchange.com/questions/382060/change-default-sudo-password-timeout
    homeManager.sudo.home.shellAliases.sudo = "sudo "; # https://askubuntu.com/questions/22037/aliases-not-available-when-using-sudo/22043#22043
  };
}
