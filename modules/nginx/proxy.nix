{
  flake.modules.nixos.nginx-proxy =
    { config, lib, ... }:

    let
      proxyPassByUrl = config.n0099.nginx.proxyPassByUrl;
    in
    {
      config = {
        n0099.nginx.baseUrls =
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
        services.nginx.virtualHosts = (
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
