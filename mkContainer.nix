{
  name,
  subnetPrefix,
}:
configBuilder:
{
  # https://discourse.nixos.org/t/passing-parameters-into-import/34082/2
  config,
  lib,
  pkgs,
  ...
}:

{
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
        system = { inherit (config.system) stateVersion; };
        nixpkgs = lib.mkForce { inherit pkgs; }; # https://github.com/NixOS/nixpkgs/issues/65690
      };
  };
}
