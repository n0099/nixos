let
  proxy = "localhost:1080";
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
    homeManager.proxy.programs.librewolf.policies.Proxy = {
      Mode = "manual";
      SOCKSProxy = proxy;
    };
  };
}
