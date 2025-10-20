{ config, lib, ... }:

{
  containers.vaultwarden = {
    subnetPrefix = "172.16.0.";
    bindMounts = {
      "/var/lib/vaultwarden" = {
        hostPath = "/srv/vaultwarden";
        isReadOnly = false;
      };
    }
    // (
      let
        path = "/etc/ssl/self-signed";
      in
      {
        ${path}.hostPath = path;
      }
    );
    forwardPorts = [
      {
        containerPort = 443;
        hostPort = 50000;
      }
    ];
    config =
      { ... }:

      let
        domain = (import ../base/toBeFilled/lib.nix lib).readString ../toBeFilled/vaultwarden/domain;
      in
      {
        services.vaultwarden = {
          enable = true;
          config = {
            ROCKET_ADDRESS = "::1";
            DOMAIN = "https://${domain}";
            SIGNUPS_ALLOWED = false;
            INVITATIONS_ALLOWED = false;
          };
        };
        services.nginx = {
          enable = true;
          virtualHosts.${domain} = {
            locations."/" = {
              proxyPass = "http://localhost:8000";
              proxyWebsockets = true; # https://github.com/dani-garcia/vaultwarden/wiki/Enabling-WebSocket-notifications
              recommendedProxySettings = true;
            };
            forceSSL = true;
            inherit (config.services.nginx.virtualHosts.default) sslCertificate sslCertificateKey;
          };
        };
      };
  };
}
