{
  flake.modules.nixos.nginx-cert =
    { config, lib, ... }:

    let
      secondLevelDomain =
        domain: domain |> lib.splitString "." |> lib.takeEnd 2 |> lib.concatStringsSep ".";
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
      baseDomains =
        config.n0099.nginx.baseUrls |> map (lib.splitString "/") |> map lib.head |> lib.unique;
      withWWWSubDomain = map (domain: "www.${domain}");
    in
    {
      services.nginx.virtualHosts = lib.mkMerge [
        (lib.genAttrs baseDomains certByDomain)
        (lib.genAttrs
          # https://news.ycombinator.com/item?id=2455864
          (baseDomains |> map secondLevelDomain |> lib.unique |> withWWWSubDomain)
          (
            domain:
            certByDomain domain
            // {
              locations."/".return = "301 https://${secondLevelDomain domain}";
            }
          )
        )
      ];
    };
}
