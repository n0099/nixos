{ lib, ... }:

{
  flake.modules.nixos.nginx-options =
    { config, ... }:

    {
      options = {
        n0099.nginx = {
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
        with config.n0099.nginx;
        !(baseUrls == [ ] || proxyPassByUrl == { }) |> lib.mkDefault;
    };
}
