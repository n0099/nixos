{
  flake.modules.nixos."nginx/proxy" =
    { config, lib, ... }:

    {
      options.services.nginx.n0099.proxyPassByUrl = lib.mkOption {
        type = with lib.types; str |> attrsOf |> attrsOf;
        default = { };
      };
      config.services.nginx = {
        virtualHosts = lib.mapAttrs (_: proxyPassByUrl: {
          locations = lib.concatMapAttrs (
            url: proxyPass:
            let
              locationBlock = {
                proxyPass = "http://${proxyPass}";
              };
            in
            if url == "/" then
              { ${url} = locationBlock; }
            else
              {
                # https://stackoverflow.com/questions/5948659/when-should-i-use-a-trailing-slash-in-my-url
                # https://stackoverflow.com/questions/2068418/whats-the-difference-between-a-302-and-a-307-redirect
                "= ${url}".return = "307 ${url}/";
                "${url}/" = locationBlock;
              }
          ) proxyPassByUrl;
        }) config.services.nginx.n0099.proxyPassByUrl;
      };
    };
}
