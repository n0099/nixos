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
      attrsOf (
        submodule (
          { ... }@container:

          {
            options =
              with {
                inherit (lib)
                  mkOption
                  map
                  all
                  head
                  drop
                  take
                  elemAt
                  toIntBase10
                  ;
              }; {
                subnetPrefix = mkOption {
                  type = addCheck str (
                    value:
                    let
                      matches = builtins.match "^([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\." value;
                      octets = map toIntBase10 matches;
                      isOctet = octet: octet >= 0 && octet <= 255;
                    in
                    if matches == null then
                      false
                    # https://datatracker.ietf.org/doc/rfc1918/
                    else if head octets == 10 then
                      all isOctet (drop 1 octets)
                    else if head octets == 172 then
                      let
                        octet = elemAt octets 1;
                      in
                      octet >= 16 && octet <= 31 && isOctet (elemAt octets 2)
                    else if
                      take 2 octets == [
                        192
                        168
                      ]
                    then
                      isOctet (elemAt octets 2)
                    else
                      false
                  );
                };
                internetAccessInterface = mkOption {
                  type = nullOr str;
                  default = null;
                };
              };
            config = {
              autoStart = true;
              ephemeral = true;
              privateUsers = "identity"; # https://www.freedesktop.org/software/systemd/man/latest/systemd-nspawn.html#--private-users=
              privateNetwork = true;
              hostAddress = "${container.config.subnetPrefix}1";
              localAddress = "${container.config.subnetPrefix}2";
              config = {
                system = { inherit (config.system) stateVersion; };
                nixpkgs = lib.mkForce { inherit pkgs; }; # https://github.com/NixOS/nixpkgs/issues/65690
                networking.firewall = lib.mkIf (container.config ? forwardPorts) (
                  let
                    portsByProtocol =
                      protocol:
                      lib.catAttrs "containerPort" (
                        lib.filter (ports: ports.protocol or "tcp" == protocol) container.config.forwardPorts
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
          }
        )
      );
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
