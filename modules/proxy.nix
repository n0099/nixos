let
  host = "localhost";
  port = 1080;
  proxy = "${host}:${builtins.toString port}";
in
{
  flake.modules = {
    nixos.proxy =
      { config, lib, ... }:

      lib.mkMerge [
        {
          networking.proxy = {
            default = "socks5h://${proxy}";
            noProxy = "127.0.0.1,localhost";
          };
        }
        {
          systemd.services.sanoid.environment = config.networking.proxy.envVars;
        }
      ];
    homeManager.proxy =
      { lib, pkgs, ... }:

      lib.mkMerge [
        {
          programs.librewolf.policies.Proxy = {
            Mode = "manual";
            SOCKSProxy = proxy;
          };
        }
        {
          programs.ssh.settings."github.com".proxyCommand =
            # https://stackoverflow.com/questions/1728934/accessing-a-git-repository-via-ssh-behind-a-firewall/8255371#8255371
            "${lib.getExe pkgs.socat} - PROXY:${host}:%h:%p,proxyport=${builtins.toString port}";
        }
      ];
  };
}
