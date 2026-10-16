{
  flake.modules.nixos.nginx-cert =
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
      config = (
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
      );
    };
}
