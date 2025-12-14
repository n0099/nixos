{
  flake.modules.nixos.nginx =
    { lib, pkgs, ... }:

    let
      nginxLib = import ./_lib.nix lib;
    in
    {
      options.services.nginx.virtualHosts = nginxLib.overrideOption {
        locations."~ /\\.(?!nuxt|cache)".return = 404; # https://github.com/crissyfield/repo-lookout
      };
      config = lib.mkMerge [
        {
          services.nginx = lib.mkMerge [
            {
              enable = true;
              recommendedOptimisation = true;
              recommendedGzipSettings = true;
              recommendedBrotliSettings = true;
              recommendedProxySettings = true;
              appendConfig = ''
                worker_processes auto;
              '';
            }
            {
              appendHttpConfig = lib.mkMerge [
                ''
                  charset utf-8;
                  msie_padding off;
                ''
                ''
                  aio threads;
                  directio 128k;
                  output_buffers 2 128k;
                ''
                ''
                  limit_req_zone $binary_remote_addr zone=ip:10m rate=50r/s;
                  limit_req zone=ip burst=100 nodelay;
                  limit_req_status 429;
                ''
              ];
            }
            {
              additionalModules = [ pkgs.nginxModules.moreheaders ];
              appendHttpConfig = ''
                # https://wiki.nixos.org/wiki/Nginx#Hardened_setup_with_TLS_and_HSTS_preloading
                more_set_headers "X-Frame-Options: DENY";
                more_set_headers "X-Content-Type-Options: nosniff";
                more_set_headers "X-XSS-Protection: 1; mode=block";
              '';
            }
          ];
        }
        {
          networking.firewall.allowedTCPPorts = [
            80
            443
          ];
        }
        {
          services.resolved.enable = true;
          services.nginx.resolver.addresses = [ "127.0.0.53" ];
        }
        (
          let
            selfSignedCertDir = "/etc/ssl/self-signed";
            selfSignedCert = {
              key = "${selfSignedCertDir}/key.pem";
              cert = "${selfSignedCertDir}/cert.pem";
            };
          in
          {
            services.nginx.virtualHosts.default = {
              # https://serverfault.com/questions/914906/what-is-the-difference-between-server-name-and-server-name-in-nginx
              serverName = "_";
              serverAliases = [ "\"\"" ];
              listen =
                lib.map
                  (
                    listen:
                    listen
                    // {
                      extraParameters = [
                        "default_server"
                        "reuseport" # https://stackoverflow.com/questions/30559164/nginxs-reuseport-for-same-ipport-pair-on-different-virtual-hosts
                      ];
                    }
                  )
                  (
                    {
                      listen = [
                        { port = 80; }
                        {
                          port = 443;
                          ssl = true;
                        }
                      ];
                      addr = [
                        # https://serverfault.com/questions/638367/do-you-need-separate-ipv4-and-ipv6-listen-directives-in-nginx
                        { addr = "[::]"; }
                        { addr = "0.0.0.0"; }
                      ];
                    }
                    |> lib.mapCartesianProduct ({ listen, addr }: listen // addr)
                  );
              extraConfig = ''
                ssl_reject_handshake on;
                return 444;
              '';
              locations = { } |> lib.mkForce;
              addSSL = true;
              sslCertificate = selfSignedCert.cert;
              sslCertificateKey = selfSignedCert.key;
            };
            systemd.services.nginx-generate-self-signed-cert = nginxLib.mkServiceRequiredByNginx {
              unitConfig.ConditionFileNotEmpty =
                selfSignedCert |> lib.attrValues |> nginxLib.mkServiceConditionAllOfPathsExists;
              script = ''
                ${pkgs.coreutils}/bin/mkdir -p ${selfSignedCertDir}
                # https://stackoverflow.com/questions/10175812/how-can-i-generate-a-self-signed-ssl-certificate-using-openssl/41366949#41366949
                ${pkgs.openssl.bin}/bin/openssl req \
                  -batch -x509 -newkey rsa:4096 -sha256 -days 365 \
                  -keyout ${selfSignedCert.key} \
                  -noenc -out ${selfSignedCert.cert}
                ${pkgs.coreutils}/bin/chown -R nginx: ${selfSignedCertDir}
              '';
            };
          }
        )
      ];
    };
}
