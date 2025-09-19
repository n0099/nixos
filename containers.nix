{
  lib,
  pkgs,
  config,
  ...
}:

let
  mkContainer = name: subnetPrefix: configBuilder: {
    networking.nat = {
      # https://blog.beardhatcode.be/2020/12/Declarative-Nixos-Containers.html#give-internet-access
      enable = true;
      internalInterfaces = [ ("ve-" + name) ];
      externalInterface = "eth0";
    };
    containers."${name}" = {
      autoStart = true;
      ephemeral = true;
      privateUsers = "pick";
      privateNetwork = true;
      hostAddress = subnetPrefix + "1";
      localAddress = subnetPrefix + "2";
      config =
        attrs:
        lib.recursiveUpdate (configBuilder attrs) {
          system.stateVersion = config.system.stateVersion;
          nixpkgs.pkgs = lib.mkForce pkgs; # https://github.com/NixOS/nixpkgs/issues/65690
        };
    };
  };
in
{
  config = lib.mkMerge [
    (mkContainer "php-fpm" "172.18.0." (
      { ... }:

      {
        users = {
          users.www = {
            isSystemUser = true;
            group = "www";
          };
          groups.www = { };
        };
        services.phpfpm.pools.www = {
          user = "www";
          group = "www";
          settings = {
            pm = "dynamic";
            "pm.max_children" = 20;
            "pm.start_servers" = 2;
            "pm.min_spare_servers" = 1;
            "pm.max_spare_servers" = 10;
          };
        };
      }
    ))
  ];
}
