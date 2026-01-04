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
          lib.mapAttrs (_: proxyPassKeyByBaseUrl: {
            locations =
              proxyPassKeyByBaseUrl
              |> map (
                lib.concatMapAttrs (
                  location: proxyPass:
                  let
                    locationBlock = {
                      proxyPass = "http://${proxyPass}";
                    };
                  in
                  if location == "/" then
                    { ${location} = locationBlock; }
                  else
                    {
                      # https://stackoverflow.com/questions/5948659/when-should-i-use-a-trailing-slash-in-my-url
                      "= ${location}".return = "302 ${location}/";
                      "${location}/" = locationBlock;
                    }
                )
              )
              |> lib.mkMerge;
          }) proxyPassByUrl
        );
      };
    };
}
