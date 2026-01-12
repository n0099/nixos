{
  flake.modules.nixos.misc =
    { lib, pkgs, ... }:

    lib.mkMerge [
      {
        n0099.cachyos = {
          enable = true;
          variant = "bore-lto";
        };
        boot.zfs.package = pkgs.zfs_2_4;
      }
      {
        hardware.rasdaemon.enable = true;
      }
      {
        environment.systemPackages = [ pkgs.pcm ];
        boot.kernelModules = [ "msr" ];
      }
      {
        systemd.coredump.extraConfig = ''
          # https://www.freedesktop.org/software/systemd/man/247/systemd-coredump.html#Disabling%20coredump%20processing
          Storage=none
          ProcessSizeMax=0
        '';
      }
      {
        n0099.stdenv.enable = true;
      }
    ];
}
