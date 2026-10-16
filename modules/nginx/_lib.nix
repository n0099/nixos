lib:

{
  overrideOption =
    modules:
    lib.mkOption {
      # https://discourse.nixos.org/t/use-mapattrs-with-nixos-modules/22692/3
      # https://discourse.nixos.org/t/nginx-default-locations-across-all-virtualhosts/16140/5
      # https://releases.nixos.org/nix-dev/2015-July/017563.html
      type = with lib.types; attrsOf (submodule modules);
    };
  mkServiceConditionAllOfPathsExists = map (path: "|!${path}"); # https://stackoverflow.com/questions/37313677/what-is-the-difference-between-conditionpathexists-and-conditionpathexists-in/37313765#37313765
  mkServiceRequiredByNginx =
    config:
    lib.mkMerge [
      config
      (
        let
          nginx = [ "nginx.service" ];
        in
        {
          before = nginx;
          requiredBy = nginx;
          enableStrictShellChecks = true;
          serviceConfig = {
            Type = "oneshot";
          };
        }
      )
    ];
}
