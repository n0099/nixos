{
  flake.modules.nixos.nginx-proxy =
    { config, lib, ... }:

    {
      options.n0099.nginx.proxyPassByUrl = lib.mkOption {
        type = with lib.types; str |> attrsOf |> listOf |> attrsOf;
        default = { };
      };
      config.services.nginx.virtualHosts = (
        lib.mapAttrs (_: baseUrlsKeyByProxyPass: {
          locations =
            baseUrlsKeyByProxyPass
            |> map (lib.mapAttrs (_: proxyPass: { proxyPass = "http://${proxyPass}"; }))
            |> lib.mkMerge;
        }) config.n0099.nginx.proxyPassByUrl
      );
    };
}
