{ config, ... }:

{
  imports = [
    (import ../base/mkContainer.nix
      {
        name = "vaultwarden";
        subnetPrefix = "172.16.0.";
        containerConfig = {
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
        };
      }
      (
        { ... }:

        {
          services.vaultwarden = {
            enable = true;
            config = {
              ROCKET_ADDRESS = "::1";
              SIGNUPS_ALLOWED = false;
              INVITATIONS_ALLOWED = false;
            };
          };
          services.nginx = {
            enable = true;
            virtualHosts."_" = {
              locations."/" = {
                proxyPass = "http://localhost:8000";
                proxyWebsockets = true; # https://github.com/dani-garcia/vaultwarden/wiki/Enabling-WebSocket-notifications
                recommendedProxySettings = true;
              };
              forceSSL = true;
              inherit (config.services.nginx.virtualHosts.default) sslCertificate sslCertificateKey;
            };
          };
        }
      )
    )
  ];
}
