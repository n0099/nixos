{
  flake.modules.nixos.nginx-proxy =
    { config, lib, ... }:

    {
      options.n0099.nginx.proxyPassByUrl = lib.mkOption {
        type = with lib.types; str |> attrsOf |> listOf |> attrsOf;
        default = { };
      };
      config = {
        n0099.nginx.baseUrls =
          config.n0099.nginx.proxyPassByUrl
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
          }) config.n0099.nginx.proxyPassByUrl
        );
      };
    };
}
