{
  flake.modules.nixos.misc =
    { lib, pkgs, ... }:

    lib.mkMerge [
      {
        n0099.cachyos = {
          enable = true;
          variant = "bmq-lto";
          baseKernel = pkgs.linux_6_18.override {
            argsOverride = rec {
              version = "6.18.33";
              modDirVersion = version;
              src = pkgs.fetchurl {
                url = "mirror://kernel/linux/kernel/v${lib.versions.major version}.x/linux-${version}.tar.xz";
                hash = "sha256-bxb/MCWZ9v40dCiQMizwd1cDEF+9h2dEloL8pq8Pt4I=";
              };
            };
          };
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
