{ lib, ... }:

{
  flake.modules.nixos.nginx-noWWW = { config, ... }: {
    options.services.nginx.n0099.noWWWDomains = lib.mkOption { type = with lib.types; listOf str; };
    config.services.nginx.virtualHosts =
      lib.genAttrs (config.services.nginx.n0099.noWWWDomains |> map (domain: "www.${domain}"))
        (domain: {
          # https://news.ycombinator.com/item?id=2455864
          locations."/".return = "301 https://${lib.removePrefix "www." domain}";
        });
  };
}
