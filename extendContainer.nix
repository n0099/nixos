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
                      matches = value |> builtins.match "^([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\.";
                      octets = matches |> map toIntBase10;
                      isOctet = octet: octet >= 0 && octet <= 255;
                    in
                    if matches == null then
                      false
                    # https://datatracker.ietf.org/doc/rfc1918/
                    else if head octets == 10 then
                      octets |> drop 1 |> all isOctet
                    else if head octets == 172 then
                      let
                        octet = 1 |> elemAt octets;
                      in
                      octet >= 16 && octet <= 31 && (2 |> elemAt octets |> isOctet)
                    else if
                      take 2 octets == [
                        192
                        168
                      ]
                    then
                      2 |> elemAt octets |> isOctet
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
        type = attrsOf (
          submodule (
            { ... }@container:

            {
              options.n0099.outboundInterface = mkOption {
                type = with lib.types; nullOr str;
                default = null;
              };
              config.config = lib.mkIf (container.config.n0099.outboundInterface != null) {
                services.resolved.enable = true;
                networking.useHostResolvConf = false; # https://github.com/NixOS/nixpkgs/blob/daf6dc47aa4b44791372d6139ab7b25269184d55/nixos/modules/system/boot/resolved.nix#L177-L178
              };
            }
          )
        );
      };
      config.networking.nat =
        config.containers
        |> lib.filterAttrs (_: container: container.n0099.outboundInterface != null)
        |> lib.mapAttrsToList (
          name: container: {
            # https://blog.beardhatcode.be/2020/12/Declarative-Nixos-Containers.html#give-internet-access
            # https://wiki.archlinux.org/title/Systemd-nspawn#Use_NAT_networking
            enable = true;
            internalInterfaces = [ "ve-${name}" ];
            externalInterface = container.n0099.outboundInterface;
          }
        )
        |> lib.mkMerge;
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
                      listOf
                      strMatching
                      ;
                  };
                  listOf (submodule {
                    options = {
                      hostListenStreams = mkOption { type = listOf str; }; # https://github.com/NixOS/nixpkgs/blob/78e34d1667d32d8a0ffc3eba4591ff256e80576e/nixos/lib/systemd-unit-options.nix#L628
                      containerPort = mkOption { type = port; };
                      protocol = mkOption {
                        type = strMatching "^(tcp|udp)$";
                        default = "tcp";
                      };
                    };
                  });
                default = [ ];
              };
              config.config.networking.firewall = lib.mkIf (container.config.n0099 != [ ]) (
                let
                  portsByProtocol =
                    protocol:
                    container.config.n0099.forwardPorts
                    |> lib.filter (ports: ports.protocol == protocol)
                    |> lib.catAttrs "containerPort";
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
      config.systemd =
        config.containers
        |> lib.mapAttrsToList (
          name: container:
          container.n0099.forwardPorts
          |> lib.map (
            forwardPort:
            let
              containerPort = forwardPort.containerPort |> builtins.toString;
              unitName = "container@${name}-forward-port:${containerPort}";
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
                    # not using `systemd.services.*.script` to prevent https://github.com/systemd/systemd/blob/a6146b250efcce88ed836e62ead527f699049a8e/src/socket-proxy/socket-proxyd.c#L674-L678
                    ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ${container.localAddress}:${containerPort}";
                  };
                };
            }
          )
        )
        |> lib.flatten
        |> lib.mkMerge;
    }
  ];
}
