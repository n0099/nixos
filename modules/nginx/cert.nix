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
    };
}
