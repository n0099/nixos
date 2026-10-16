{
  flake.modules.nixos.nginx-options =
    { lib, ... }:

    {
      options = {
        services.nginx.n0099 = {
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
