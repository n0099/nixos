lib:

{
  overrideOption =
    config:
    lib.mkOption {
      # https://discourse.nixos.org/t/nginx-default-locations-across-all-virtualhosts/16140/5
      # https://discourse.nixos.org/t/infinite-recursion-in-module-with-mkmerge/10989
      type =
        with lib.types;
        attrsOf (submodule {
          inherit config;
        });
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
