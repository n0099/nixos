{
  name,
  subnetPrefix,
  internetAccessInterface ? "",
  containerConfig ? { },
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
  networking.nat = lib.mkIf (internetAccessInterface != "") {
    # https://blog.beardhatcode.be/2020/12/Declarative-Nixos-Containers.html#give-internet-access
    enable = true;
    internalInterfaces = [ ("ve-" + name) ];
    externalInterface = internetAccessInterface;
  };
  containers."${name}" = {
    autoStart = true;
    ephemeral = true;
    privateUsers = "identity"; # https://www.freedesktop.org/software/systemd/man/latest/systemd-nspawn.html#--private-users=
    privateNetwork = true;
    hostAddress = subnetPrefix + "1";
    localAddress = subnetPrefix + "2";
    config =
      attrs:
      lib.mkMerge [
        (configBuilder attrs)
        {
          system = { inherit (config.system) stateVersion; };
          nixpkgs = lib.mkForce { inherit pkgs; }; # https://github.com/NixOS/nixpkgs/issues/65690
          networking.firewall = lib.mkIf (containerConfig ? forwardPorts) (
            let
              portsByProtocol =
                protocol:
                lib.catAttrs "containerPort" (
                  lib.filter (ports: ports.protocol or "tcp" == protocol) containerConfig.forwardPorts
                );
            in
            {
              # https://blog.beardhatcode.be/2020/12/Declarative-Nixos-Containers.html#real-port-forwarding
              allowedTCPPorts = portsByProtocol "tcp";
              allowedUDPPorts = portsByProtocol "udp";
            }
          );
        }
      ];
  }
  // containerConfig;
}
