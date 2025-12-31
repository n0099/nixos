{
  flake.modules.nixos.nginx-proxy =
    { config, lib, ... }:

    let
      proxyPassByUrl = config.services.nginx.n0099.proxyPassByUrl;
    in
    {
      config.services.nginx = {
        n0099.baseUrls =
          proxyPassByUrl
          |> lib.mapAttrsToList (
            domain: urlPathsKeyByProxyPass:
            urlPathsKeyByProxyPass
            |> lib.concatMap (
              urlPathKeyByProxyPass:
              let
                concatBaseUrl = path: "${domain}${lib.optionalString (path != "/") path}";
              in
              urlPathKeyByProxyPass |> lib.attrNames |> map concatBaseUrl
            )
          )
          |> lib.flatten;
        virtualHosts = (
          lib.mapAttrs (_: baseUrlsKeyByProxyPass: {
            locations =
              baseUrlsKeyByProxyPass
              |> map (lib.mapAttrs (_: proxyPass: { proxyPass = "http://${proxyPass}"; }))
              |> lib.mkMerge;
          }) proxyPassByUrl
        );
      };
    };
}
