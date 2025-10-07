{ lib, pkgs, ... }:

lib.mkMerge [
  { services.nginx.enable = true; }
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
]
