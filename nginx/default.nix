{ lib, pkgs, ... }:

{
  options.services.nginx.virtualHosts = lib.mkOption {
    # https://discourse.nixos.org/t/nginx-default-locations-across-all-virtualhosts/16140/5
    # https://discourse.nixos.org/t/infinite-recursion-in-module-with-mkmerge/10989
    type =
      with lib.types;
      attrsOf (submodule {
        config = {
          locations."~ /\\.(?!nuxt|cache)".return = 404; # https://github.com/crissyfield/repo-lookout
          quic = true;
        };
      });
  };
  config = lib.mkMerge [
    {
      services.nginx = lib.mkMerge [
        {
          enable = true;
          recommendedOptimisation = true;
          recommendedGzipSettings = true;
          recommendedBrotliSettings = true;
          recommendedZstdSettings = true;
          recommendedProxySettings = true;
          appendConfig = ''
            worker_processes auto;
          '';
        }
        {
          # not using https://github.com/NixOS/nixpkgs/blob/20c4598c84a671783f741e02bf05cbfaf4907cff/nixos/modules/services/web-servers/nginx/default.nix#L207-L221
          sslProtocols = "TLSv1.3"; # https://caniuse.com/tls1-3
          sslDhparam = ../toBeFilled/nginx/dhparam.pem;
          appendHttpConfig = ''
            ssl_ecdh_curve secp384r1; # https://community.letsencrypt.org/t/would-it-be-a-good-idea-to-use-x448-only-for-maximum-security/239502

            # https://github.com/igrigorik/istlsfastyet.com/issues/63
            # https://blog.cloudflare.com/optimizing-tls-over-tcp-to-reduce-latency/
            ssl_buffer_size 1400;

            # https://github.com/mozilla/server-side-tls/issues/135#issuecomment-1293210243
            # https://upb-syssec.github.io/blog/2023/session-tickets/
            # https://www.wolfssl.com/tls-session-id-vs-tickets/
            # https://old.reddit.com/r/nginx/comments/11b1hrm/should_ssl_session_cache_be_turned_off_for_tlsv13/
            ssl_session_tickets on;
          '';
        }
        {
          additionalModules = [ pkgs.nginxModules.moreheaders ];
          appendHttpConfig = ''
            # https://wiki.nixos.org/wiki/Nginx#Hardened_setup_with_TLS_and_HSTS_preloading
            map $scheme $hsts_header {
              https "max-age=63072000; includeSubdomains; preload";
            }
            more_set_headers "Strict-Transport-Security $hsts_header";
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
      networking.firewall.allowedUDPPorts = [ 443 ];
      services.nginx = {
        enableQuicBPF = true;
        package = pkgs.nginxQuic;
        additionalModules = [ pkgs.nginxModules.moreheaders ];
        appendHttpConfig = ''
          more_set_headers 'Alt-Svc: h3=":$server_port"; ma=86400'; # https://github.com/NixOS/nixpkgs/pull/449454
        '';
      };
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
                  addr = "[::]";
                  extraParameters = [
                    "default_server"
                    "reuseport" # https://stackoverflow.com/questions/30559164/nginxs-reuseport-for-same-ipport-pair-on-different-virtual-hosts
                  ];
                }
              )
              [
                { port = 80; }
                {
                  port = 443;
                  ssl = true;
                }
              ];
          extraConfig = ''
            ssl_reject_handshake on;
            return 444;
          '';
          locations = lib.mkForce { };
          addSSL = true;
          sslCertificate = selfSignedCert.cert;
          sslCertificateKey = selfSignedCert.key;
        };
        systemd.services.nginx-generate-self-signed-cert = {
          before = [ "nginx.service" ];
          requiredBy = [ "nginx.service" ];
          unitConfig.ConditionFileNotEmpty = [
            "!${selfSignedCert.key}"
            "!${selfSignedCert.cert}"
          ];
          serviceConfig = {
            Type = "oneshot";
            ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${selfSignedCertDir}";
            # https://stackoverflow.com/questions/10175812/how-can-i-generate-a-self-signed-ssl-certificate-using-openssl/41366949#41366949
            ExecStart = ''
              ${pkgs.openssl.bin}/bin/openssl req \
                -batch -x509 -newkey rsa:4096 -sha256 -days 365 \
                -keyout ${selfSignedCert.key} \
                -noenc -out ${selfSignedCert.cert}
            '';
            ExecStartPost = "${pkgs.coreutils}/bin/chown -R nginx: ${selfSignedCertDir}";
          };
        };
      }
    )
  ];
}
