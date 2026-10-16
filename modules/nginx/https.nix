{
  flake.modules.nixos."nginx/https" =
    { lib, pkgs, ... }:

    let
      secondLevelDomain =
        domain:
        domain
        |> lib.splitString "."
        |> lib.takeEnd 2
        |> lib.concatStringsSep ".";
      certByDomain =
        domain:
        let
          certBasePath = "/etc/ssl/certs/${secondLevelDomain domain}";
        in
        {
          forceSSL = true;
          sslCertificate = "${certBasePath}/fullchain.pem"; # https://stackoverflow.com/questions/26191463/ssl-error0b080074x509-certificate-routinesx509-check-private-keykey-values/41154564#41154564
          sslCertificateKey = "${certBasePath}/privkey.pem";
        };
      nginxLib = import ./_lib.nix lib;
    in
    {
      options.services.nginx.virtualHosts = nginxLib.overrideOption (
        { name, ... }:

        certByDomain name |> lib.mkIf (name != "default")
      );
      config = lib.mkMerge [
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
                ${lib.getExe pkgs.openssl} req \
                  -batch -x509 -newkey ed448 -days 365 \
                  -noenc -keyout ${selfSignedCert.key} \
                  -out ${selfSignedCert.cert}
                ${pkgs.coreutils}/bin/chown -R nginx: ${selfSignedCertDir}
              '';
            };
          }
        )
        {
          services.nginx = lib.mkMerge [
            {
              # not using https://github.com/NixOS/nixpkgs/blob/20c4598c84a671783f741e02bf05cbfaf4907cff/nixos/modules/services/web-servers/nginx/default.nix#L207-L221
              sslProtocols = "TLSv1.3"; # https://caniuse.com/tls1-3
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
              '';
            }
          ];
        }
      ];
    };
}
