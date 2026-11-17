{
  flake.modules.nixos.vaultwarden =
    { config, lib, ... }:

    let
      readToBeFilled =
        filename:
        ../toBeFilled/vaultwarden/${filename} |> (import ../base/toBeFilled/lib.nix lib).readString;
      domain = readToBeFilled "domain";
      listen = {
        address = config.containers.vaultwarden.localAddress;
        port = 8000; # https://github.com/dani-garcia/vaultwarden/blob/3e2cef7e8b27cf33cb735d428553f835bc5dd6c2/.env.template#L659
      };
    in
    {
      networking = {
        hosts."${config.containers.vaultwarden.n0099.subnetPrefix}1" = [ domain ];
        proxy.envVars =
          let
            noProxy = config.networking.proxy.noProxy;
            no_proxy = if isNull noProxy then "127.0.0.1,localhost" else noProxy; # https://github.com/NixOS/nixpkgs/blob/78e9c786dc08cd4f3420c2395cd977206a9b1da2/nixos/modules/config/networking.nix#L236
          in
          { no_proxy = no_proxy + ",${domain}"; } |> lib.mkAfter;
      };
      services.nginx = {
        enable = true;
        n0099.proxyPassByUrl.${domain}."/" = "${listen.address}:${toString listen.port}";
        virtualHosts.${domain}.locations."/".proxyWebsockets = true; # https://github.com/dani-garcia/vaultwarden/wiki/Enabling-WebSocket-notifications
      };
      containers.vaultwarden = {
        n0099.subnetPrefix = "172.16.0.";
        bindMounts = {
          "/var/lib/vaultwarden" = {
            hostPath = "/srv/vaultwarden";
            isReadOnly = false;
          };
        };
        config = {
          networking.firewall.allowedTCPPorts = [ listen.port ];
          services.vaultwarden = {
            enable = true;
            config = {
              ROCKET_ADDRESS = listen.address;
              DOMAIN = "https://${domain}";
              SIGNUPS_ALLOWED = false;
              INVITATIONS_ALLOWED = false;
            };
          };
        };
      };
    };
}
