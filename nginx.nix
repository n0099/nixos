{ lib, pkgs, ... }:

{
  options.services.nginx.virtualHosts = lib.mkOption {
    # https://discourse.nixos.org/t/nginx-default-locations-across-all-virtualhosts/16140/5
    # https://discourse.nixos.org/t/infinite-recursion-in-module-with-mkmerge/10989
    type =
      with lib.types;
      attrsOf (submodule {
        config = {
          locations."~ /\.(?!nuxt|cache)".return = 404; # https://github.com/crissyfield/repo-lookout
          extraConfig = lib.mkBefore ''
            more_set_headers "Strict-Transport-Security: max-age=63072000; includeSubDomains; preload";
            more_set_headers "X-Frame-Options: DENY";
            more_set_headers "X-Content-Type-Options: nosniff";
            more_set_headers "X-XSS-Protection: 1; mode=block";
          '';
        };
      });
  };
  config = lib.mkMerge [
    {
      services.nginx = {
        enable = true;
        recommendedOptimisation = true;
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;
        recommendedBrotliSettings = true;
        recommendedZstdSettings = true;
        recommendedProxySettings = true;
        additionalModules = [ pkgs.nginxModules.moreheaders ];
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
          serverAliases = [
            "_"
            ""
          ];
          forceSSL = true;
          sslCertificate = selfSignedCert.cert;
          sslCertificateKey = selfSignedCert.key;
        };
        systemd.services."nginx-generate-self-signed-cert" = {
          before = [ "nginx.service" ];
          wantedBy = [ "nginx.service" ];
          unitConfig = {
            ConditionFileNotEmpty = [
              "!${selfSignedCert.key}"
              "!${selfSignedCert.cert}"
            ];
          };
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
