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
      }
      {
        hardware.rasdaemon.enable = true;
      }
      {
        environment.systemPackages = [ pkgs.pcm ];
        boot.kernelModules = [ "msr" ];
      }
      {
        systemd.coredump.extraConfig = /* ini */ ''
          # https://www.freedesktop.org/software/systemd/man/247/systemd-coredump.html#Disabling%20coredump%20processing
          Storage=none
          ProcessSizeMax=0
        '';
      }
      {
        n0099.stdenv.enable = true;
      }
      {
        environment.systemPackages = [ pkgs.devenv ];
        nixpkgs.overlays = [
          (final: prev: {
            haskellPackages = prev.haskellPackages.extend (
              # https://github.com/NixOS/nixpkgs/issues/26561
              final: prev: {
                cryptonite = prev.cryptonite.overrideAttrs { doCheck = false; }; # test fails at `verify sig` of `Ed448`: https://github.com/haskell-crypto/cryptonite/blob/d163f69512a3d162baa69a95927f3d6369833f7d/tests/KAT_Ed448.hs#L89
              }
            );
          })
        ];
        nix.settings = {
          extra-substituters = [ "https://devenv.cachix.org" ];
          extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
        };
      }
    ];
}
