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
      services.nginx = {
        n0099.proxyPassByUrl."${domain}" = [
          { "/" = "${listen.address}:${toString listen.port}"; }
        ];
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
            config = lib.mkMerge [
              {
                ROCKET_ADDRESS = listen.address;
                DOMAIN = "https://${domain}";
                SIGNUPS_ALLOWED = false;
                INVITATIONS_ALLOWED = false;
              }
              (lib.mkIf (lib.pathExists ../toBeFilled/vaultwarden/pushInstallation/id) {
                PUSH_ENABLED = true;
                PUSH_INSTALLATION_ID = readToBeFilled "pushInstallation/id";
                PUSH_INSTALLATION_KEY = readToBeFilled "pushInstallation/key";
                PUSH_RELAY_URI = readToBeFilled "pushRelayUri";
                PUSH_IDENTITY_URI = readToBeFilled "pushIdentityUri";
              })
            ];
          };
        };
      };
    };
}
