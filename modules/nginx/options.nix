{ lib, ... }:

{
  flake.modules.nixos.nginx-options =
    { config, ... }:

    {
      options = {
        services.nginx.n0099 = {
          baseUrls = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ ];
          };
          proxyPassByUrl = lib.mkOption {
            type = with lib.types; str |> attrsOf |> listOf |> attrsOf;
            default = { };
          };
        };
      };
      config.services.nginx.enable =
        with config.services.nginx.n0099;
        !(baseUrls == [ ] || proxyPassByUrl == { }) |> lib.mkDefault;
    };
}
