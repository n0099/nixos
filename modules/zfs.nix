{
  flake.modules.nixos.zfs =
    {
      pkgs,
      lib,
      config,
      ...
    }:

    {
      services = {
        zfs.autoScrub.enable = true;
        sanoid = lib.mkMerge [
          {
            enable = true;
            package = pkgs.sanoid.override { zfs = config.boot.zfs.package; };
            datasets =
              config.fileSystems
              |> lib.filterAttrs (mountpoint: _: mountpoint != "/nix/store")
              |> lib.attrValues
              |> lib.filter (fs: fs.fsType == "zfs")
              |> map (fs: lib.nameValuePair fs.device { useTemplate = [ "default" ]; })
              |> lib.listToAttrs;
            templates.default = {
              autosnap = true;
              autoprune = true;
              monitor = "yes";

              hourly = 24;
              hourly_warn = "30m";
              hourly_crit = "1h";

              daily = 7;
              # https://github.com/jimsalterjrs/sanoid/issues/720
              # https://github.com/jimsalterjrs/sanoid/issues/617
              # https://github.com/jimsalterjrs/sanoid/issues/560
              daily_hour = 4;
              daily_min = 0;
              daily_warn = "25h";
              daily_crit = "36h";

              monthly = 1;
              monthly_mday = 1;
              monthly_hour = 3;
              monthly_min = 0;
              monthly_warn = "31d";
              monthly_crit = "32d";
            };
          }
          (
            let
              frequent_period = 15;
              frequent_period_str = toString frequent_period;
            in
            {
              # https://github.com/jimsalterjrs/sanoid/blob/74b61d149f9e6aaec48fb7d2ba84594f1df59880/sanoid.defaults.conf#L41
              interval = "*:0/${frequent_period_str}:00";
              templates.default = {
                frequently = 60 / frequent_period;
                inherit frequent_period;
                frequently_warn = "10m";
                frequently_crit = "${frequent_period_str}m";
              };
            }
          )
        ];
        logrotate.settings.prefer-zfs-compression = {
          compress = false;
          global = true;
        };
      };
    };
}
