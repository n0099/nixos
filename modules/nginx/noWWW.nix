{ lib, ... }:

{
  flake.modules.nixos.nginx-noWWW = { config, ... }: {
    options.services.nginx.n0099.noWWWDomains = lib.mkOption { type = with lib.types; listOf str; };
    config.services.nginx.virtualHosts =
      lib.genAttrs (config.services.nginx.n0099.noWWWDomains |> map (domain: "www.${domain}"))
        (domain: {
          # https://news.ycombinator.com/item?id=2455864
          globalRedirect = lib.removePrefix "www." domain;
          redirectCode = 308; # https://stackoverflow.com/questions/42136829/whats-the-difference-between-http-301-and-308-status-codes
          extraConfig = ''
            # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/http-3xx-status-codes.html
            add_header Cache-Control max-age=${7 * 24 * 60 * 60 |> toString};
          '';
        });
  };
}
