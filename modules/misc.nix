{
  flake.modules.nixos.misc =
    { lib, pkgs, ... }:

    lib.mkMerge [
      {
        n0099.cachyos = {
          enable = true;
          variant = "bmq-lto";
        };
      }
      {
        boot.zfs.package = pkgs.zfs_2_4;
        networking.hostId = "ec1ca6eb";
        n0099.sanoid.enable = true;
        services.sanoid.datasets =
          lib.genAttrs
            (map (dataset: "rpool/ENC/${dataset}") [
              "WIN11"
              "NIX-BUILD"
              "NIX-BUILD-LOG"
            ])
            (_: {
              autosnap = false;
            });
      }
      {
        hardware.rasdaemon.enable = true;
      }
      {
        environment.systemPackages = [ pkgs.pcm ];
        boot.kernelModules = [ "msr" ];
      }
      {
        systemd.coredump.settings.Coredump = {
          # https://www.freedesktop.org/software/systemd/man/247/systemd-coredump.html#Disabling%20coredump%20processing
          Storage = "none";
          ProcessSizeMax = 0;
        };
      }
      {
        n0099.stdenv.enable = true;
      }
      {
        environment.systemPackages = [ pkgs.devenv ];
      }
    ];
}
