{
  flake.modules.nixos.nginx-proxy =
    { config, lib, ... }:

    {
      config.services.nginx = {
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
                      "= ${location}".return = "307 ${location}/";
                      "${location}/" = locationBlock;
                    }
                )
              )
              |> lib.mkMerge;
          }) config.services.nginx.n0099.proxyPassByUrl
        );
      };
    };
}
