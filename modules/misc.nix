{
  flake.modules.nixos.misc =
    {
      lib,
      pkgs,
      inputs,
      ...
    }:

    lib.mkMerge [
      {
        # https://discourse.nixos.org/t/chaotic-nyx-is-archved-what-are-some-alternatives/73073
        nixpkgs.overlays = [ inputs.nix-cachyos-kernel.outputs.overlay ]; # https://github.com/xddxdd/nix-cachyos-kernel/blob/dc3941ceb1cc0b303ddefc5e5fa1577a2d7856d7/flake.nix#L95
        boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto.extend (
          final: prev: {
            kernel = prev.kernel.override {
              inherit (pkgs.linuxPackages_6_17.kernel) version src; # https://github.com/xddxdd/nix-cachyos-kernel/blob/dc3941ceb1cc0b303ddefc5e5fa1577a2d7856d7/kernel-cachyos/default.nix#L16
              structuredExtraConfig = with lib.kernel; {
                LTO_CLANG_FULL = yes;
                LTO_CLANG_THIN = no; # https://github.com/xddxdd/nix-cachyos-kernel/blob/52d03c7f4e6f78cbf9e1ec1d78101b2369ff8f7c/kernel-cachyos/mkCachyKernel.nix#L108-L111
              };
            };
          }
        ); # https://wiki.cachyos.org/features/kernel/#variants
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
    ];
}
