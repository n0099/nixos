{ lib, ... }:

{
  flake.modules.nixos.nginx-options.options.n0099.nginx.baseUrls = lib.mkOption {
    type = with lib.types; listOf str;
    default = [ ];
  };
}
