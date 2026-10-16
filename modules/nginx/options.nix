{
  flake.modules.nixos.nginx-options =
    { lib, ... }:

    {
      options = {
        services.nginx.n0099 = {
          baseUrls = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ ];
          };
          proxyPassByUrl = lib.mkOption {
            type =
              with lib.types;
              str
              |> attrsOf
              |> listOf
              |> attrsOf;
            default = { };
          };
        };
      };
    };
}
