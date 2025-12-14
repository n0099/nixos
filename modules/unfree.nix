{ config, lib, ... }:

{
  # https://github.com/NixOS/nixpkgs/issues/55674#issuecomment-3215219392
  options.n0099.permittedUnfreePackages = lib.mkOption {
    type = with lib.types; listOf str;
    default = [ ];
  };
  config.nixpkgs.config.allowUnfreePredicate =
    pkg: lib.elem (lib.getName pkg) config.n0099.permittedUnfreePackages;
}
