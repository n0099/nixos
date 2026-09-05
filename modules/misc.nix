{
  flake.modules.nixos.misc =
    { lib, pkgs, ... }:

    lib.mkMerge [
      {
        n0099.cachyos = {
          enable = true;
          variant = "bmq-lto";
          mkCachyKernelOverrides.prePatch =
            let
              patch = pkgs.fetchpatch {
                url = "https://github.com/CachyOS/linux/commit/d286c785c4c385e10eb1c8c440a6a0c4496a73ad.patch";
                hash = "sha256-cjV+MyFgzFQwu4mTxd0qUGV3uY2q9Gj/fo5HqRaUi7Y=";
              };
            in
            "patch -Rp1 < ${patch}";
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
        environment.systemPackages = [ pkgs.devenv ];
      }
    ];
}
