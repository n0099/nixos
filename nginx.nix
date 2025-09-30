{ lib, pkgs, ... }:

lib.mkMerge [
  { services.nginx.enable = true; }
  (
    let
      selfSignedCertDir = "/etc/ssl/self-signed";
      selfSignedCert = {
        key = selfSignedCertDir + "/key.pem";
        cert = selfSignedCertDir + "/cert.pem";
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
        wantedBy = [ "nginx.service" ];
        unitConfig = {
          ConditionFileNotEmpty = [
            ("!" + selfSignedCert.key)
            ("!" + selfSignedCert.cert)
          ];
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStartPre = pkgs.coreutils + "/bin/mkdir " + selfSignedCertDir;
          ExecStart =
            pkgs.openssl.bin
            + "/bin/openssl req -batch -x509 -newkey ed448 -days 3650 -keyout "
            + selfSignedCert.key
            + " -noenc -out "
            + selfSignedCert.cert;
          ExecStartPost = pkgs.coreutils + "/bin/chown -R nginx: " + selfSignedCertDir;
        };
      };
    }
  )
]
