{ lib, config, ... }:

{
  services = {
    zfs.autoScrub.enable = true;
    sanoid = {
      enable = true;
      datasets = lib.listToAttrs (
        map (fs: lib.nameValuePair fs.device { useTemplate = [ "default" ]; }) (
          lib.filter (fs: fs.fsType == "zfs") (lib.attrValues config.fileSystems)
        )
      );
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
        # T04:00+08:00
        daily_hour = 20;
        daily_min = 0;
        daily_warn = "25h";
        daily_crit = "36h";

        monthly = 1;
        # ---02T03:00+08:00 https://stackoverflow.com/questions/25161485/is-the-mm-dd-format-for-month-day-part-of-iso-8601
        monthly_mday = 1;
        monthly_hour = 19;
        monthly_min = 0;
        monthly_warn = "31d";
        monthly_crit = "32d";
      };
    };
    logrotate.settings.prefer-zfs-compression = {
      compress = false;
      global = true;
    };
  };
}
