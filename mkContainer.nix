{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.containers = lib.mkOption {
    type =
      with {
        inherit (lib.types)
          str
          nullOr
          attrsOf
          submodule
          addCheck
          ;
      };
      attrsOf (submodule {
        options = {
          subnetPrefix = lib.mkOption {
            type = addCheck str (
              value:
              let
                matches = builtins.match "^([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\." value;
                octets = lib.map lib.toIntBase10 matches;
                isOctet = octet: octet >= 0 && octet <= 255;
              in
              if matches == null then
                false
              # https://datatracker.ietf.org/doc/rfc1918/
              else if lib.head octets == 10 then
                lib.all isOctet (lib.drop 1 octets)
              else if lib.head octets == 172 then
                let
                  octet = lib.elemAt octets 1;
                in
                octet >= 16 && octet <= 31 && isOctet (lib.elemAt octets 2)
              else if
                lib.take 2 octets == [
                  192
                  168
                ]
              then
                isOctet (lib.elemAt octets 2)
              else
                false
            );
          };
          internetAccessInterface = lib.mkOption {
            type = nullOr str;
            default = null;
          };
        };
        config = {
          autoStart = true;
          ephemeral = true;
          privateUsers = "identity"; # https://www.freedesktop.org/software/systemd/man/latest/systemd-nspawn.html#--private-users=
          privateNetwork = true;
          hostAddress = "${container.subnetPrefix}1";
          localAddress = "${container.subnetPrefix}2";
          config = {
            system = { inherit (config.system) stateVersion; };
            nixpkgs = lib.mkForce { inherit pkgs; }; # https://github.com/NixOS/nixpkgs/issues/65690
            networking.firewall = lib.mkIf (container.containerConfig ? forwardPorts) (
              let
                portsByProtocol =
                  protocol:
                  lib.catAttrs "containerPort" (
                    lib.filter (ports: ports.protocol or "tcp" == protocol) container.containerConfig.forwardPorts
                  );
              in
              {
                # https://blog.beardhatcode.be/2020/12/Declarative-Nixos-Containers.html#real-port-forwarding
                allowedTCPPorts = portsByProtocol "tcp";
                allowedUDPPorts = portsByProtocol "udp";
              }
            );
          };
        };
      });
  };
  config = {
    networking.nat = lib.mkMerge (
      lib.mapAttrsToList (name: container: {
        # https://blog.beardhatcode.be/2020/12/Declarative-Nixos-Containers.html#give-internet-access
        enable = true;
        internalInterfaces = [ "ve-${name}" ];
        externalInterface = container.internetAccessInterface;
      }) (lib.filterAttrs (_: container: container.internetAccessInterface != null) config.containers)
    );
  };
}
