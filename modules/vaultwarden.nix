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
      containers.vaultwarden = lib.mkMerge [
        {
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
        }
        {
          # website favicon
          # https://github.com/dani-garcia/vaultwarden/wiki/Using-custom-website-icons#website-icon-troubleshooting
          # https://old.reddit.com/r/vaultwarden/comments/15jrn01/is_it_possible_to_have_icon_without_internet/
          # and push notification based sync
          # https://github.com/dani-garcia/vaultwarden/wiki/Enabling-Mobile-Client-push-notification
          # https://github.com/dani-garcia/vaultwarden/blob/36f0620fd19af0816a7ee2ed882d368b1b298ddc/src/api/push.rs#L68
          # require internet access
          n0099.outboundInterface = readToBeFilled "outboundInterface";
          config.services.vaultwarden.config =
            lib.mkIf (lib.pathExists ../toBeFilled/vaultwarden/pushInstallation/id)
              {
                PUSH_ENABLED = true;
                PUSH_INSTALLATION_ID = readToBeFilled "pushInstallation/id";
                PUSH_INSTALLATION_KEY = readToBeFilled "pushInstallation/key";
                PUSH_RELAY_URI = readToBeFilled "pushRelayUri";
                PUSH_IDENTITY_URI = readToBeFilled "pushIdentityUri";
              };
        }
      ];
    };
}
