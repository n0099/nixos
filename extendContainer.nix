{
  config,
  lib,
  pkgs,
  ...
}:

with {
  inherit (lib) mkOption;
  inherit (lib.types) attrsOf submodule;
};
{
  imports = [
    {
      options.containers = mkOption {
        type = attrsOf (submodule {
          config = {
            autoStart = true;
            ephemeral = true;
            privateUsers = "identity"; # https://www.freedesktop.org/software/systemd/man/latest/systemd-nspawn.html#--private-users=
            privateNetwork = true;
            config = {
              system = { inherit (config.system) stateVersion; };
              nixpkgs = lib.mkForce { inherit pkgs; }; # https://github.com/NixOS/nixpkgs/issues/65690
            };
          };
        });
      };
    }
    {
      options.containers =
        with {
          inherit (lib)
            map
            all
            head
            drop
            take
            elemAt
            toIntBase10
            ;
          inherit (lib.types)
            addCheck
            str
            ;
        };
        mkOption {
          type = attrsOf (
            submodule (
              { ... }@container:

              {
                options.n0099.subnetPrefix = mkOption {
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
                config = {
                  hostAddress = "${container.config.n0099.subnetPrefix}1";
                  localAddress = "${container.config.n0099.subnetPrefix}2";
                };
              }
            )
          );
        };
    }
    {
      options.containers = mkOption {
        type = attrsOf (submodule {
          options.n0099.internetAccessInterface = mkOption {
            type = with lib.types; nullOr str;
            default = null;
          };
        });
      };
      config.networking.nat = lib.mkMerge (
        lib.mapAttrsToList
          (name: container: {
            # https://blog.beardhatcode.be/2020/12/Declarative-Nixos-Containers.html#give-internet-access
            # https://wiki.archlinux.org/title/Systemd-nspawn#Use_NAT_networking
            enable = true;
            internalInterfaces = [ "ve-${name}" ];
            externalInterface = container.n0099.internetAccessInterface;
          })
          (lib.filterAttrs (_: container: container.n0099.internetAccessInterface != null) config.containers)
      );
    }
    {
      options.containers = mkOption {
        type = attrsOf (
          submodule (
            { ... }@container:

            {
              options.n0099.forwardPorts = mkOption {
                type =
                  with {
                    inherit (lib.types)
                      str
                      port
                      either
                      listOf
                      ;
                  };
                  listOf attrsOf {
                    hostListenStreams = listOf str; # https://github.com/NixOS/nixpkgs/blob/78e34d1667d32d8a0ffc3eba4591ff256e80576e/nixos/lib/systemd-unit-options.nix#L628
                    containerPort = port;
                    protocol = either "tcp" "udp";
                  };
              };
              config.config.networking.firewall = lib.mkIf (container.config.n0099 ? forwardPorts) (
                let
                  portsByProtocol =
                    protocol:
                    lib.catAttrs "containerPort" (
                      lib.filter (ports: ports.protocol or "tcp" == protocol) container.config.n0099.forwardPorts
                    );
                in
                {
                  # https://blog.beardhatcode.be/2020/12/Declarative-Nixos-Containers.html#real-port-forwarding
                  allowedTCPPorts = portsByProtocol "tcp";
                  allowedUDPPorts = portsByProtocol "udp";
                }
              );
            }
          )
        );
      };
      config.systemd = lib.mkMerge lib.mapAttrsToList (
        name: container:
        lib.map (
          forwardPort:
          let
            unitName = "container@${name}-forward-port:${forwardPort.containerPort}.socket";
          in
          {
            # https://www.freedesktop.org/software/systemd/man/latest/systemd-socket-proxyd.html#Simple%20Example
            sockets.${unitName} = {
              listenStreams = forwardPort.hostListenStreams;
              wantedBy = [ "sockets.target" ];
            };
            services.${unitName} =
              let
                requiredUnits = [
                  "container@${name}.service"
                  "${unitName}.socket"
                ];
              in
              {
                requires = requiredUnits;
                after = requiredUnits;
                serviceConfig = {
                  Type = "notify";
                  ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ${container.config.localAddress}:${forwardPort.containerPort}"; # not using `systemd.services.*.script` to prevent https://github.com/systemd/systemd/blob/a6146b250efcce88ed836e62ead527f699049a8e/src/socket-proxy/socket-proxyd.c#L674-L678
                };
              };
          }
        ) container.forwardPorts
      ) config.containers;
    }
  ];
}
